-- LocalScript "FishingClient" in StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
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
local cast = nil     -- { basePos, bobber }; the server owns the real state

---------------------------------------------------------------- UI (Fusion modules in UI/)
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local UI = script.Parent:WaitForChild("UI")
local T = require(UI:WaitForChild("T"))
local Hud = require(UI:WaitForChild("Hud"))
local Notifications = require(UI:WaitForChild("Notifications"))
local ShopPanel = require(UI:WaitForChild("ShopPanel"))
local CollectionPanel = require(UI:WaitForChild("CollectionPanel"))
local ActionButton = require(UI:WaitForChild("ActionButton"))
local ReelBar = require(UI:WaitForChild("ReelBar"))
local BagPanel = require(UI:WaitForChild("BagPanel"))
local TutorialPanel = require(UI:WaitForChild("TutorialPanel"))
local peek = Fusion.peek

local scope = Fusion.scoped(Fusion)
local data = scope:Value(nil)       -- Profile data from Sync
local phase = scope:Value(state)     -- mirrors `state` for the action button
local shopItem = scope:Value(nil)    -- { kind, id } while the shop panel is open
local collectionOpen, bagOpen = scope:Value(false), scope:Value(false)

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
local function toggleBag() bagOpen:set(not peek(bagOpen)) end

local gui = scope:New "ScreenGui" {
	Name = "FishingUI",
	ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),
}
local messageLabel, notify = Notifications(scope)
-- server args may name Content as { kind, id }: show that name in the player's language
local function showMessage(key, args, color)
	for k, v in args or {} do
		if type(v) == "table" then args[k] = T(`{v[1]}_{v[2]}`, nil, Content[v[1]][v[2]].name) end
	end
	notify(T(key, args), color)
end
NotifyEv.OnClientEvent:Connect(showMessage)

local reelBar, reelUI = ReelBar(scope)
local onPress -- set in the fishing section
for _, child in {
	Hud(scope, { data = data, keyboard = UIS.KeyboardEnabled, onCycle = cycle, onBag = toggleBag,
		onCollection = toggleCollection }),
	reelBar,
	messageLabel,
	-- before the panels: later siblings draw on top, so an open panel covers the tutorial banner
	TutorialPanel(scope, { data = data, onSkip = function() remotes:WaitForChild("SkipTutorial"):FireServer() end }),
	ActionButton(scope, { phase = phase, touch = UIS.TouchEnabled, keyboard = UIS.KeyboardEnabled,
		onPress = function() onPress() end }),
	ShopPanel(scope, { data = data, item = shopItem, usable = usable,
		onBuy = function(kind, id) BuyEv:FireServer(kind, id) end,
		onEquip = function(kind, id) EquipEv:FireServer(kind, id) end }),
	CollectionPanel(scope, { data = data, open = collectionOpen }),
	BagPanel(scope, { data = data, open = bagOpen }),
} do
	child.Parent = gui
end

OpenShopEv.OnClientEvent:Connect(function(kind, id) shopItem:set({ kind = kind, id = id }) end)
SyncEv.OnClientEvent:Connect(function(d)
	myData = d
	data:set(d)
end)
-- shortcut: polls `state` instead of hooking each of its assignments; fine while there are few
RunService.Heartbeat:Connect(function() phase:set(state) end)

-- shop/market ProximityPrompts carry text keys (TextKey, ObjectKey) from the server; translate them here
local function localizePrompt(p)
	if not p:IsA("ProximityPrompt") or not p:GetAttribute("TextKey") then return end
	p.ActionText = T(p:GetAttribute("TextKey"))
	local key = p:GetAttribute("ObjectKey")
	local kind, id = string.match(key or "", "^(%l+)_(.+)$")
	local item = kind and Content[kind] and Content[kind][id]
	p.ObjectText = if key then T(key, nil, item and item.name) else ""
end
for _, d in workspace:GetDescendants() do localizePrompt(d) end
workspace.DescendantAdded:Connect(localizePrompt)

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
---------------------------------------------------------------- fishing
local function getRod()
	local char = player.Character
	return char and char:FindFirstChild("FishingRod")
end

local holding = false -- reel button down; sent to the server on change

local function cleanup()
	if cast then
		if cast.bobber then cast.bobber:Destroy() end
		cast = nil
	end
	reelUI.hide()
	CAS:UnbindAction("ReelSpace")
	holding = false
	state = "idle"
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

local function startReel()
	state = "reeling"
	reelUI.show()
	showMessage("Msg_Hooked", nil, Color3.fromRGB(120, 255, 140))
end

ReelEv.OnClientEvent:Connect(function(tension, distance)
	if state == "reeling" then reelUI.set(tension, distance) end
end)

local function setHolding(h)
	if state ~= "reeling" or h == holding then return end
	holding = h
	ReelEv:FireServer(h)
end

-- while reeling, Space reels instead of jumping: sink it above the default jump binding
local function reelSpace(_, inputState)
	setHolding(inputState == Enum.UserInputState.Begin)
	return Enum.ContextActionResult.Sink
end

RunService.RenderStepped:Connect(function(dt)
	if cast and cast.bobber then
		local base = cast.basePos
		local dip = state == "bite" and -0.8 or 0 -- sinks on a bite
		cast.bobber.Position = base + Vector3.new(0, math.sin(os.clock() * 3) * 0.08 + dip, 0)
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
StateEv.OnClientEvent:Connect(function(newState)
	if not cast then return end
	if newState == "bite" and state == "waiting" then
		state = "bite"
		biteSound:Play()
		showMessage("Msg_Bite", nil, Color3.fromRGB(255, 230, 60))
	elseif newState == "reeling" then
		startReel()
		CAS:BindActionAtPriority("ReelSpace", reelSpace, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
	elseif newState == "idle" then
		cleanup()
	end
end)

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.Space
end

UIS.InputBegan:Connect(function(input, processed)
	if state == "reeling" and isPress(input) then return setHolding(true) end
	if processed then return end
	if input.KeyCode == Enum.KeyCode.C then return toggleCollection() end
	if input.KeyCode == Enum.KeyCode.V then return toggleBag() end
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
	if isPress(input) then setHolding(false) end
end)

-- unequip, death and leave are cancelled by the server (State "idle"); a new character just clears the old bobber
player.CharacterAdded:Connect(cleanup)
