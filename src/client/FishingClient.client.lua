-- LocalScript "FishingClient" in StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Content = require(RS:WaitForChild("Content"))
local ReelUI = require(script.Parent:WaitForChild("ReelUI"))
local BagUI = require(script.Parent:WaitForChild("BagUI"))
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

---------------------------------------------------------------- UI
local gui = Instance.new("ScreenGui")
gui.Name = "FishingUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o) make("UICorner", { CornerRadius = UDim.new(0, 8) }, o) end

local hud = make("Frame", { Size = UDim2.fromOffset(230, 160), Position = UDim2.fromOffset(12, 60),
	BackgroundColor3 = Color3.fromRGB(20, 30, 45), BackgroundTransparency = 0.25 }, gui)
corner(hud)
make("UIListLayout", { Padding = UDim.new(0, 4) }, hud)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }, hud)
local function hudLabel()
	return make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, hud)
end
local coinsLabel, bagLabel, clockLabel = hudLabel(), hudLabel(), hudLabel()
local function button(parent, text)
	local b = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Color3.fromRGB(50, 90, 130),
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, Text = text }, parent)
	corner(b)
	return b
end
-- one button per Tackle slot: click cycles to the next owned Rod/Line or Bait with some left
local rodButton, lineButton, baitButton = button(hud, "Rod"), button(hud, "Line"), button(hud, "Bait")

local collButton = make("TextButton", { Size = UDim2.fromOffset(230, 30), Position = UDim2.fromOffset(12, 226),
	BackgroundColor3 = Color3.fromRGB(200, 150, 40), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
	TextSize = 15, Text = "Collection (C)" }, gui)
corner(collButton)

local message = make("TextLabel", { Size = UDim2.new(0.8, 0, 0, 40), Position = UDim2.new(0.1, 0, 0.15, 0),
	BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3,
	Font = Enum.Font.GothamBlack, TextSize = 26, Text = "", TextWrapped = true }, gui)

local reelUI = ReelUI.mount(gui)
local bagUI = BagUI.mount(gui)

-- collection panel
local collPanel = make("Frame", { Size = UDim2.new(0, 380, 0.7, 0), Position = UDim2.new(0.5, -190, 0.15, 0),
	BackgroundColor3 = Color3.fromRGB(20, 30, 45), Visible = false }, gui)
corner(collPanel)
make("TextLabel", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "Fish Collection",
	TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 20 }, collPanel)
local collList = make("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -44), Position = UDim2.fromOffset(8, 38),
	BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6 }, collPanel)
make("UIListLayout", { Padding = UDim.new(0, 3) }, collList)

local function refreshCollection()
	for _, c in ipairs(collList:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	local caught = 0
	for i, f in Content.list.species do
		local entry = myData and myData.collection[f.id]
		if entry then caught += 1 end
		make("TextLabel", { Size = UDim2.new(1, -8, 0, 22), BackgroundTransparency = 1, LayoutOrder = i,
			TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = entry and Color3.fromRGB(table.unpack(Content.rarities[f.rarity].color)) or Color3.fromRGB(110, 110, 110),
			Text = entry and string.format("%s  [%s]  x%d  best %.2f kg%s", f.name, Content.rarities[f.rarity].name, entry.count, entry.bestKg, f.night and "  (night)" or "")
				or string.format("???  [%s]  %s", Content.rarities[f.rarity].name, Content.zones[f.zones[1]].name) }, collList)
	end
	collPanel:FindFirstChildOfClass("TextLabel").Text = string.format("Fish Collection  %d/%d", caught, #Content.list.species)
end

local function toggleCollection()
	collPanel.Visible = not collPanel.Visible
	if collPanel.Visible then refreshCollection() end
end
collButton.Activated:Connect(toggleCollection)

local msgToken = 0
local function showMessage(text, color)
	msgToken += 1
	local my = msgToken
	message.Text = text
	message.TextColor3 = color or Color3.new(1, 1, 1)
	task.delay(3.5, function()
		if msgToken == my then message.Text = "" end
	end)
end
NotifyEv.OnClientEvent:Connect(showMessage)

local function refreshHud()
	if not myData then return end
	local bait = Content.baits[myData.equipped.bait]
	coinsLabel.Text = "Coins: " .. myData.coins
	rodButton.Text = "Rod: " .. Content.rods[myData.equipped.rod].name
	lineButton.Text = "Line: " .. Content.lines[myData.equipped.line].name
	bagLabel.Text = string.format("Bag: %d/%d", #myData.bag, Content.balance.bagSize)
	baitButton.Text = "Bait: " .. bait.name .. (bait.price > 0 and (" x" .. (myData.baits[myData.equipped.bait] or 0)) or "") .. "  (B)"
end

local SLOT = { rods = "rod", lines = "line", baits = "bait" }
local function usable(kind, id)
	if kind == "baits" then return Content.baits[id].price == 0 or (myData.baits[id] or 0) > 0 end
	return table.find(myData[kind == "rods" and "ownedRods" or "ownedLines"], id) ~= nil
end

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
rodButton.Activated:Connect(function() cycle("rods") end)
lineButton.Activated:Connect(function() cycle("lines") end)
baitButton.Activated:Connect(function() cycle("baits") end)

-- shop panel (opened by a shop's ProximityPrompt); shortcut: plain Instances, #14 rebuilds it with Fusion
local shopPanel = make("Frame", { Size = UDim2.fromOffset(320, 210), Position = UDim2.new(0.5, -160, 0.3, 0),
	BackgroundColor3 = Color3.fromRGB(20, 30, 45), Visible = false }, gui)
corner(shopPanel)
make("UIListLayout", { Padding = UDim.new(0, 6) }, shopPanel)
make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8) }, shopPanel)
local shopTitle = make("TextLabel", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, shopPanel)
local shopStats = make("TextLabel", { Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true, Text = "" }, shopPanel)
local buyButton, equipButton, closeButton = button(shopPanel, "Buy"), button(shopPanel, "Equip"), button(shopPanel, "Close")
local shopItem = nil -- { kind, id }

-- stats shown per kind, compared with the equipped Tackle
local STATS = { rods = { "power", "luck", "maxKg", "pull" }, lines = { "maxTension" }, baits = { "luck", "biteSpeed" } }

local function refreshShop()
	if not shopItem or not myData then return end
	local kind, id = shopItem.kind, shopItem.id
	local item, cur = Content[kind][id], Content[kind][myData.equipped[SLOT[kind]]]
	local lines = {}
	for _, k in STATS[kind] do
		table.insert(lines, string.format("%s: %g  (equipped %g, %+g)", k, item[k], cur[k], item[k] - cur[k]))
	end
	-- shortcut: no Level line; Tackle content has no `level` field yet
	if kind == "baits" then table.insert(lines, "You have: " .. (myData.baits[id] or 0)) end
	local owned = usable(kind, id)
	shopTitle.Text = item.name .. "  -  " .. item.price .. " coins" .. (kind == "baits" and (" / " .. item.pack) or "")
	shopStats.Text = table.concat(lines, "\n")
	buyButton.Visible = kind == "baits" or not owned
	buyButton.Text = kind == "baits" and string.format("Buy %d (%d)", item.pack, item.price) or string.format("Buy (%d)", item.price)
	equipButton.Visible = owned and myData.equipped[SLOT[kind]] ~= id
end

OpenShopEv.OnClientEvent:Connect(function(kind, id)
	shopItem = { kind = kind, id = id }
	shopPanel.Visible = true
	refreshShop()
end)
buyButton.Activated:Connect(function() BuyEv:FireServer(shopItem.kind, shopItem.id) end)
equipButton.Activated:Connect(function() EquipEv:FireServer(shopItem.kind, shopItem.id) end)
closeButton.Activated:Connect(function() shopPanel.Visible = false end)

SyncEv.OnClientEvent:Connect(function(d)
	myData = d
	refreshHud()
	bagUI.set(d)
	if collPanel.Visible then refreshCollection() end
	if shopPanel.Visible then refreshShop() end
end)

RunService.Heartbeat:Connect(function()
	local t = Lighting.ClockTime
	clockLabel.Text = string.format("Time: %02d:%02d %s", math.floor(t), math.floor(t % 1 * 60), (t < 6 or t >= 18) and "(night)" or "")
end)

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
	showMessage("Hooked! Reel it in!", Color3.fromRGB(120, 255, 140))
end

ReelEv.OnClientEvent:Connect(function(tension, distance)
	if state == "reeling" then reelUI.set(tension, distance) end
end)

local function setHolding(h)
	if state ~= "reeling" or h == holding then return end
	holding = h
	ReelEv:FireServer(h)
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
		return showMessage("Aim at the water to cast")
	end
	state = "casting"
	local ok, res = pcall(CastFn.InvokeServer, CastFn, hit.Position)
	if not ok or not res or not res.ok then
		state = "idle"
		return showMessage(res and res.msg or "Cast failed", Color3.fromRGB(255, 140, 90))
	end
	cast = { basePos = hit.Position + Vector3.new(0, 0.2, 0) }
	cast.bobber = spawnBobber(cast.basePos)
	state = "waiting"
	showMessage("Waiting for a bite... (" .. res.zone .. ")  Click to reel in")
end

local biteSound = make("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 1 }, gui)

-- the server decides every transition; the client only shows it
StateEv.OnClientEvent:Connect(function(newState)
	if not cast then return end
	if newState == "bite" and state == "waiting" then
		state = "bite"
		biteSound:Play()
		showMessage("BITE! Click now!", Color3.fromRGB(255, 230, 60))
	elseif newState == "reeling" then
		startReel()
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
	if input.KeyCode == Enum.KeyCode.V then return bagUI.toggle() end
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

UIS.InputEnded:Connect(function(input)
	if isPress(input) then setHolding(false) end
end)

-- unequip, death and leave are cancelled by the server (State "idle"); a new character just clears the old bobber
player.CharacterAdded:Connect(cleanup)
