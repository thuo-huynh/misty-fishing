-- LocalScript "FishingClient" in StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Content = require(RS:WaitForChild("Content"))
local remotes = RS:WaitForChild("FishingRemotes")
local CastFn = remotes:WaitForChild("Cast")
local ReelEv = remotes:WaitForChild("Reel")
local HookEv = remotes:WaitForChild("Hook")
local CancelEv = remotes:WaitForChild("Cancel")
local StateEv = remotes:WaitForChild("State")
local EquipEv = remotes:WaitForChild("Equip")
local BuyEv = remotes:WaitForChild("Buy")
local OpenShopEv = remotes:WaitForChild("OpenShop")
local SyncEv = remotes:WaitForChild("Sync")
local NotifyEv = remotes:WaitForChild("Notify")

local player = Players.LocalPlayer
local myData = nil
local state = "idle" -- idle | casting | waiting | bite | reeling
local cast = nil     -- { difficulty, basePos, bobber }; the server owns the real state

---------------------------------------------------------------- UI (Fusion modules in UI/)
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local UI = script.Parent:WaitForChild("UI")
local T = require(UI:WaitForChild("T"))
local Hud = require(UI:WaitForChild("Hud"))
local Notifications = require(UI:WaitForChild("Notifications"))
local ShopPanel = require(UI:WaitForChild("ShopPanel"))
local CollectionPanel = require(UI:WaitForChild("CollectionPanel"))
local ActionButton = require(UI:WaitForChild("ActionButton"))
local peek = Fusion.peek

local scope = Fusion.scoped(Fusion)
local data = scope:Value(nil)       -- Profile data from Sync
local phase = scope:Value(state)     -- mirrors `state` for the action button
local shopItem = scope:Value(nil)    -- { kind, id } while the shop panel is open
local collectionOpen = scope:Value(false)

local SLOT = { rods = "rod", lines = "line", baits = "bait" }
local function usable(kind, id)
	if kind == "baits" then return Content.baits[id].price == 0 or (myData.baits[id] or 0) > 0 end
	return table.find(myData[kind == "rods" and "ownedRods" or "ownedLines"], id) ~= nil
end

-- equip the next owned Rod/Line, or the next Bait with some left
local function cycle(kind)
	if not myData then return end
	local list = Content.list[kind]
	local start = table.find(list, Content[kind][myData.equipped[SLOT[kind]]]) or 1
	for i = 1, #list do
		local r = list[(start + i - 1) % #list + 1]
		if usable(kind, r.id) then
			EquipEv:FireServer(kind, r.id)
			return
		end
	end
end

local function toggleCollection() collectionOpen:set(not peek(collectionOpen)) end

local gui = scope:New "ScreenGui" {
	Name = "FishingUI",
	ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),
}
local messageLabel, notify = Notifications(scope)
local function showMessage(key, args, color) notify(T(key, args), color) end
NotifyEv.OnClientEvent:Connect(showMessage)

local onPress -- set in the fishing section
for _, child in {
	Hud(scope, { data = data, keyboard = UIS.KeyboardEnabled, onCycle = cycle, onCollection = toggleCollection }),
	messageLabel,
	ActionButton(scope, { phase = phase, touch = UIS.TouchEnabled, keyboard = UIS.KeyboardEnabled,
		onPress = function() onPress() end }),
	ShopPanel(scope, { data = data, item = shopItem, usable = usable,
		onBuy = function(kind, id) BuyEv:FireServer(kind, id) end,
		onEquip = function(kind, id) EquipEv:FireServer(kind, id) end }),
	CollectionPanel(scope, { data = data, open = collectionOpen }),
} do
	child.Parent = gui
end

OpenShopEv.OnClientEvent:Connect(function(kind, id) shopItem:set({ kind = kind, id = id }) end)
SyncEv.OnClientEvent:Connect(function(d)
	myData = d
	data:set(d)
end)
-- shortcut: polls `state` instead of hooking each assignment, so the reeling code stays untouched (#10)
RunService.Heartbeat:Connect(function() phase:set(state) end)

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o) make("UICorner", { CornerRadius = UDim.new(0, 8) }, o) end

-- reel minigame
local reelFrame = make("Frame", { Size = UDim2.fromOffset(420, 70), Position = UDim2.new(0.5, -210, 1, -170),
	BackgroundColor3 = Color3.fromRGB(15, 25, 40), BackgroundTransparency = 0.2, Visible = false }, gui)
corner(reelFrame)
local track = make("Frame", { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 8),
	BackgroundColor3 = Color3.fromRGB(40, 70, 110) }, reelFrame)
corner(track)
local zoneBar = make("Frame", { Size = UDim2.fromScale(0.25, 1), BackgroundColor3 = Color3.fromRGB(70, 220, 110),
	BackgroundTransparency = 0.3 }, track)
corner(zoneBar)
local fishIcon = make("TextLabel", { Size = UDim2.fromOffset(24, 30), AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1, Text = "><>", TextColor3 = Color3.fromRGB(255, 230, 90), Font = Enum.Font.GothamBlack, TextSize = 16 }, track)
local progBack = make("Frame", { Size = UDim2.new(1, -20, 0, 12), Position = UDim2.fromOffset(10, 48),
	BackgroundColor3 = Color3.fromRGB(60, 60, 60) }, reelFrame)
corner(progBack)
local progBar = make("Frame", { Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = Color3.fromRGB(255, 200, 60) }, progBack)
corner(progBar)
make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, -22), BackgroundTransparency = 1,
	Text = "Hold click / touch / Space to keep the fish in the green zone", TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0.4, Font = Enum.Font.GothamBold, TextSize = 14 }, reelFrame)

---------------------------------------------------------------- fishing
local function getRod()
	local char = player.Character
	return char and char:FindFirstChild("FishingRod")
end

local function cleanup()
	if cast then
		if cast.bobber then cast.bobber:Destroy() end
		cast = nil
	end
	reelFrame.Visible = false
	state = "idle"
end

local function fail()
	if state == "reeling" then ReelEv:FireServer(false) end
	cleanup()
end

local function spawnBobber(pos)
	local bobber = make("Part", { Name = "Bobber", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6),
		Color = Color3.fromRGB(230, 40, 40), Anchored = true, CanCollide = false, CanQuery = false, Position = pos }, workspace)
	local a1 = make("Attachment", {}, bobber)
	local rod = getRod()
	local handle = rod and rod:FindFirstChild("Handle")
	local a0 = handle and (handle:FindFirstChild("Tip") or make("Attachment", {}, handle))
	if a0 then
		make("Beam", { Attachment0 = a0, Attachment1 = a1, Width0 = 0.04, Width1 = 0.04, FaceCamera = true,
			Color = ColorSequence.new(Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0.2) }, bobber)
	end
	return bobber
end

local reel = { zone = 0, vel = 0, fish = 0.5, target = 0.5, nextMove = 0, progress = 0.3, holding = false }

local function startReel(difficulty)
	state = "reeling"
	cast.difficulty = difficulty
	local power = Content.rods[myData and myData.equipped.rod or "basic"].power
	reel.zone, reel.vel, reel.fish, reel.target, reel.nextMove, reel.progress = 0.5 - power / 2, 0, 0.5, 0.5, 0, 0.3
	zoneBar.Size = UDim2.fromScale(power, 1)
	reelFrame.Visible = true
	showMessage("Msg_Hooked", nil, Color3.fromRGB(120, 255, 140))
end

RunService.RenderStepped:Connect(function(dt)
	if cast and cast.bobber then
		local base = cast.basePos
		local dip = state == "bite" and -0.8 or 0 -- sinks on a bite
		cast.bobber.Position = base + Vector3.new(0, math.sin(os.clock() * 3) * 0.08 + dip, 0)
	end
	if state ~= "reeling" or not cast then return end
	if not getRod() then return fail() end

	local power = Content.rods[myData and myData.equipped.rod or "basic"].power
	local d = cast.difficulty
	-- green zone: push right while holding, falls back left otherwise
	reel.vel += (reel.holding and 2.2 or -2.2) * dt
	reel.vel = math.clamp(reel.vel, -1.2, 1.2)
	reel.zone += reel.vel * dt
	if reel.zone < 0 then reel.zone, reel.vel = 0, 0 end
	if reel.zone > 1 - power then reel.zone, reel.vel = 1 - power, 0 end
	-- fish darts to random targets; harder fish move faster and more often
	reel.nextMove -= dt
	if reel.nextMove <= 0 then
		reel.target = math.random()
		reel.nextMove = (0.4 + math.random() * 1.4) / (0.6 + d * 0.2)
	end
	local speed = 0.15 + d * 0.09
	local diff = reel.target - reel.fish
	reel.fish += math.clamp(diff, -speed * dt, speed * dt)

	local inside = reel.fish >= reel.zone and reel.fish <= reel.zone + power
	reel.progress += (inside and 0.35 / (1 + d * 0.12) or -0.2) * dt
	zoneBar.Position = UDim2.fromScale(reel.zone, 0)
	zoneBar.BackgroundColor3 = inside and Color3.fromRGB(70, 220, 110) or Color3.fromRGB(220, 90, 70)
	fishIcon.Position = UDim2.fromScale(reel.fish, 0)
	progBar.Size = UDim2.fromScale(math.clamp(reel.progress, 0, 1), 1)

	if reel.progress >= 1 then
		ReelEv:FireServer(true)
		cleanup()
	elseif reel.progress <= 0 then
		fail()
	end
end)

local function tryCast(screenPos)
	if state ~= "idle" or not getRod() then return end
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { player.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if not hit or not CollectionService:HasTag(hit.Instance, "FishingZone") then
		return showMessage("Msg_AimAtWater")
	end
	state = "casting"
	local ok, res = pcall(CastFn.InvokeServer, CastFn, hit.Position)
	if not ok or not res or not res.ok then
		state = "idle"
		return showMessage(res and res.msg or "Msg_CastFailed", res and res.args, Color3.fromRGB(255, 140, 90))
	end
	cast = { basePos = hit.Position + Vector3.new(0, 0.2, 0) }
	cast.bobber = spawnBobber(cast.basePos)
	state = "waiting"
	showMessage("Msg_Waiting", { zone = T(`zones_{res.zone}`, nil, Content.zones[res.zone].name) })
end

local biteSound = make("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 1 }, gui)

-- the server decides every transition; the client only shows it
StateEv.OnClientEvent:Connect(function(newState, difficulty)
	if not cast then return end
	if newState == "bite" and state == "waiting" then
		state = "bite"
		biteSound:Play()
		showMessage("Msg_Bite", nil, Color3.fromRGB(255, 230, 60))
	elseif newState == "reeling" then
		startReel(difficulty)
	elseif newState == "idle" then
		cleanup()
	end
end)

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.Space
end

UIS.InputBegan:Connect(function(input, processed)
	if state == "reeling" and isPress(input) then reel.holding = true return end
	if processed then return end
	if input.KeyCode == Enum.KeyCode.C then return toggleCollection() end
	if input.KeyCode == Enum.KeyCode.B then return cycle("baits") end
	if state == "bite" and isPress(input) then return HookEv:FireServer() end
	if state == "waiting" and isPress(input) then
		CancelEv:FireServer() -- reel in
		return cleanup()
	end
	if state == "idle" and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		tryCast(input.Position)
	end
end)

-- the big action button: cast ahead (screen point just below centre), hook on a bite, or reel the line back in
function onPress()
	if state == "idle" then
		local v = workspace.CurrentCamera.ViewportSize
		tryCast(Vector2.new(v.X / 2, v.Y * 0.6))
	elseif state == "bite" then
		HookEv:FireServer()
	elseif state == "waiting" then
		CancelEv:FireServer()
		cleanup()
	end
end

UIS.InputEnded:Connect(function(input)
	if isPress(input) then reel.holding = false end
end)

-- unequip, death and leave are cancelled by the server (State "idle"); a new character just clears the old bobber
player.CharacterAdded:Connect(cleanup)
