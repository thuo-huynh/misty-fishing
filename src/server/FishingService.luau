-- Fishing Service: Roblox glue around FishingSession (one per player). Clients only send intents;
-- the server checks the cast, times the bite and hook window, runs the reel (Tension) and cancels on unequip, death or leave.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Content = require(RS:WaitForChild("Content"))
local Catch = require(RS:WaitForChild("Rules"):WaitForChild("Catch"))
local Tension = require(RS:WaitForChild("Rules"):WaitForChild("Tension"))
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

-- deps = { remotes = Folder, contentOk = boolean, notify = fn(player, text, color), sync = fn(player) }
-- Remotes: Cast (RemoteFunction, target Vector3 -> { ok, msg | zone }), Hook / Cancel (client -> server),
-- Reel (client -> server: holding boolean; server -> client: tension 0..1, distance studs, every reel tick),
-- State (server -> client: "bite" | "reeling" | "idle").
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
		sessions[player] = sessions[player] or FishingSession.new(Catch, Tension, catchContent)
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
		if not FishingSession.allow(s, os.clock()) then return { ok = false, msg = "Slow down" } end
		if not deps.contentOk then return { ok = false, msg = "Content lỗi, xem Output" } end
		local d = PlayerProfile.get(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not d or not hrp or typeof(pos) ~= "Vector3" then return { ok = false, msg = "Not ready" } end
		local ok, msg = FishingSession.cast(s, {
			holdingRod = char:FindFirstChild("FishingRod") ~= nil,
			distance = (hrp.Position - pos).Magnitude,
			zone = zoneAt(pos) or false,
			bait = Content.baits[d.equipped.bait],
			baitLeft = PlayerProfile.baitCount(player, d.equipped.bait),
			rod = Content.rods[d.equipped.rod],
			line = Content.lines[d.equipped.line],
			hour = Lighting.ClockTime,
		}, os.clock(), math.random)
		if not ok then return { ok = false, msg = msg } end
		ShopService.takeBait(player) -- tells the player when a paid Bait runs out
		deps.sync(player)
		return { ok = true, zone = Content.zones[s.zone].name }
	end

	HookEv.OnServerEvent:Connect(function(player)
		local s = sessions[player]
		if not s or not FishingSession.allow(s, os.clock()) then return end
		if not FishingSession.hook(s, os.clock(), math.random) then return end -- too early or too late: update() handles the miss
		StateEv:FireClient(player, "reeling")
	end)

	ReelEv.OnServerEvent:Connect(function(player, holding)
		local s = sessions[player]
		if not s or s.state ~= "reeling" or not FishingSession.allow(s, os.clock()) then return end
		FishingSession.reel(s, holding)
	end)

	local function landed(player, c)
		local added, record = PlayerProfile.addCatch(player, { species = c.fish.id, kg = c.kg, zone = c.zone, time = os.time() })
		if not added then
			return deps.notify(player, "Bag full! Sell your fish first. (fish released)", Color3.fromRGB(255, 90, 90))
		end
		local r = Content.rarities[c.fish.rarity]
		deps.notify(player, string.format("%s %s - %.2f kg (%d coins)%s", r.name, c.fish.name, c.kg, Catch.sellPrice(c.fish, c.kg),
			record and "  NEW RECORD!" or ""), Color3.fromRGB(table.unpack(r.color)))
		deps.sync(player)
	end

	CancelEv.OnServerEvent:Connect(function(player)
		local s = sessions[player]
		if s and FishingSession.allow(s, os.clock()) then cancel(player) end
	end)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, s in sessions do
			local bait = s.bait
			local event, c = FishingSession.update(s, now)
			if event == "bite" then
				StateEv:FireClient(player, "bite")
			elseif event == "tick" then
				ReelEv:FireClient(player, s.reel.tension, s.reel.distance)
			elseif event then
				StateEv:FireClient(player, "idle")
				if event == "landed" then
					landed(player, c)
				elseif event == "snapped" then
					-- the Bait was used up at the cast; a snap is where the player feels it
					deps.notify(player, if bait.price > 0 then `Line snapped! Lost your {bait.name}.` else "Line snapped!",
						Color3.fromRGB(255, 90, 90))
				else
					deps.notify(player, if event == "missed" then "Too slow - it got away." else "The fish got away...",
						Color3.fromRGB(255, 140, 90))
				end
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
