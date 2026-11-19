-- Fishing Service: Roblox glue around FishingSession (one per player). Clients only send intents;
-- the server checks the cast, times the bite and hook window, and cancels on unequip, death or leave.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Content = require(RS:WaitForChild("Content"))
local Catch = require(RS:WaitForChild("Rules"):WaitForChild("Catch"))
local PlayerProfile = require(script.Parent:WaitForChild("PlayerProfile"))
local FishingSession = require(script.Parent:WaitForChild("FishingSession"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))

local catchContent = { species = Content.list.species, balance = Content.balance }
local sessions = {} -- [player] = FishingSession

local FishingService = {}

local function zoneAt(pos)
	for _, part in CollectionService:GetTagged("FishingZone") do
		if part:IsA("BasePart") then
			local rel = part.CFrame:PointToObjectSpace(pos)
			local half = part.Size / 2
			if math.abs(rel.X) <= half.X + 1 and math.abs(rel.Z) <= half.Z + 1 and math.abs(rel.Y) <= half.Y + 3 then
				return part:GetAttribute("ZoneId")
			end
		end
	end
	return nil
end

-- deps = { remotes = Folder, contentOk = boolean, notify = fn(player, key, args?, color?), sync = fn(player) }
-- Remotes: Cast (RemoteFunction, target Vector3 -> { ok, msg, args | zone }; msg is a text key), Hook / Reel(success) / Cancel (client -> server),
-- State (server -> client: "bite" | "reeling", difficulty | "idle").
function FishingService.start(deps)
	local function remote(class, name)
		local r = Instance.new(class)
		r.Name = name
		r.Parent = deps.remotes
		return r
	end
	local CastFn = remote("RemoteFunction", "Cast")
	local HookEv = remote("RemoteEvent", "Hook")
	local ReelEv = remote("RemoteEvent", "Reel")
	local CancelEv = remote("RemoteEvent", "Cancel")
	local StateEv = remote("RemoteEvent", "State")

	local function session(player)
		sessions[player] = sessions[player] or FishingSession.new(Catch, catchContent)
		return sessions[player]
	end

	local function cancel(player)
		local s = sessions[player]
		if s and s.state ~= "idle" then
			FishingSession.cancel(s)
			StateEv:FireClient(player, "idle")
		end
	end

	CastFn.OnServerInvoke = function(player, pos)
		local s = session(player)
		if not FishingSession.allow(s, os.clock()) then return { ok = false, msg = "Cast_SlowDown" } end
		if not deps.contentOk then return { ok = false, msg = "Cast_ContentError" } end
		local d = PlayerProfile.get(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not d or not hrp or typeof(pos) ~= "Vector3" then return { ok = false, msg = "Cast_NotReady" } end
		local ok, msg, args = FishingSession.cast(s, {
			holdingRod = char:FindFirstChild("FishingRod") ~= nil,
			distance = (hrp.Position - pos).Magnitude,
			zone = zoneAt(pos) or false,
			bait = Content.baits[d.equipped.bait],
			baitLeft = PlayerProfile.baitCount(player, d.equipped.bait),
			rod = Content.rods[d.equipped.rod],
			hour = Lighting.ClockTime,
		}, os.clock(), math.random)
		if not ok then return { ok = false, msg = msg, args = args } end
		ShopService.takeBait(player) -- tells the player when a paid Bait runs out
		deps.sync(player)
		return { ok = true, zone = s.zone }
	end

	HookEv.OnServerEvent:Connect(function(player)
		local s = sessions[player]
		if not s or not FishingSession.allow(s, os.clock()) then return end
		if not FishingSession.hook(s, os.clock()) then return end -- too early or too late: update() handles the escape
		local d = PlayerProfile.get(player)
		if not d then return cancel(player) end
		local rod = Content.rods[d.equipped.rod]
		StateEv:FireClient(player, "reeling", s.fish.difficulty + math.min(3, s.kg / rod.maxKg * 1.5))
	end)

	ReelEv.OnServerEvent:Connect(function(player, success)
		local s = sessions[player]
		if not s or s.state ~= "reeling" or not FishingSession.allow(s, os.clock()) then return end
		local c = FishingSession.finishReel(s, os.clock(), success)
		if not c then return deps.notify(player, "Msg_GotAway", nil, Color3.fromRGB(255, 140, 90)) end
		local added, record = PlayerProfile.addCatch(player, { species = c.fish.id, kg = c.kg, zone = c.zone, time = os.time() })
		if not added then
			return deps.notify(player, "Msg_BagFull", nil, Color3.fromRGB(255, 90, 90))
		end
		local r = Content.rarities[c.fish.rarity]
		-- shortcut: Content names go as English; key them by Content ID when names get translated
		deps.notify(player, if record then "Msg_CaughtRecord" else "Msg_Caught", {
			rarity = r.name, fish = c.fish.name, kg = string.format("%.2f", c.kg), coins = Catch.sellPrice(c.fish, c.kg),
		}, Color3.fromRGB(table.unpack(r.color)))
		deps.sync(player)
	end)

	CancelEv.OnServerEvent:Connect(function(player)
		local s = sessions[player]
		if s and FishingSession.allow(s, os.clock()) then cancel(player) end
	end)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, s in sessions do
			local event = FishingSession.update(s, now)
			if event == "bite" then
				StateEv:FireClient(player, "bite")
			elseif event == "escaped" then
				StateEv:FireClient(player, "idle")
				deps.notify(player, "Msg_TooSlow", nil, Color3.fromRGB(255, 140, 90))
			end
		end
	end)

	-- unequip (rod leaves the character), death and respawn cancel the cast; leaving drops the session
	local function onCharacter(player, char)
		cancel(player)
		char.ChildRemoved:Connect(function(c)
			if c.Name == "FishingRod" then cancel(player) end
		end)
		char:WaitForChild("Humanoid").Died:Connect(function() cancel(player) end)
	end
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
		if player.Character then task.spawn(onCharacter, player, player.Character) end
	end
	for _, p in Players:GetPlayers() do onPlayer(p) end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
end

return FishingService
