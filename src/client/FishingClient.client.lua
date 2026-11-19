-- LocalScript "FishingClient" in StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Content = require(RS:WaitForChild("Content"))
local remotes = RS:WaitForChild("FishingRemotes")
local CastFn = remotes:WaitForChild("Cast")
local ReelEv = remotes:WaitForChild("Reel")
local EquipBaitEv = remotes:WaitForChild("EquipBait")
local SyncEv = remotes:WaitForChild("Sync")
local NotifyEv = remotes:WaitForChild("Notify")

local player = Players.LocalPlayer
local myData = nil
local state = "idle" -- idle | casting | waiting | bite | reeling
local cast = nil     -- { id, difficulty, bobber, beam }

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

local hud = make("Frame", { Size = UDim2.fromOffset(230, 132), Position = UDim2.fromOffset(12, 60),
	BackgroundColor3 = Color3.fromRGB(20, 30, 45), BackgroundTransparency = 0.25 }, gui)
corner(hud)
make("UIListLayout", { Padding = UDim.new(0, 4) }, hud)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }, hud)
local function hudLabel()
	return make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, hud)
end
local moneyLabel, rodLabel, bagLabel, clockLabel = hudLabel(), hudLabel(), hudLabel(), hudLabel()
local baitButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Color3.fromRGB(50, 90, 130),
	TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, Text = "Bait" }, hud)
corner(baitButton)

local collButton = make("TextButton", { Size = UDim2.fromOffset(230, 30), Position = UDim2.fromOffset(12, 198),
	BackgroundColor3 = Color3.fromRGB(200, 150, 40), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
	TextSize = 15, Text = "Collection (C)" }, gui)
corner(collButton)

local message = make("TextLabel", { Size = UDim2.new(0.8, 0, 0, 40), Position = UDim2.new(0.1, 0, 0.15, 0),
	BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3,
	Font = Enum.Font.GothamBlack, TextSize = 26, Text = "", TextWrapped = true }, gui)

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
			Text = entry and string.format("%s  [%s]  x%d  best %.2f kg%s", f.name, Content.rarities[f.rarity].name, entry.count, entry.best, f.night and "  (night)" or "")
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
	local bait = Content.baits[myData.bait]
	moneyLabel.Text = "Coins: " .. myData.money
	rodLabel.Text = "Rod: " .. Content.rods[myData.rod].name
	bagLabel.Text = string.format("Bag: %d/%d", #myData.bag, Content.balance.bagSize)
	baitButton.Text = "Bait: " .. bait.name .. (bait.price > 0 and (" x" .. (myData.baits[myData.bait] or 0)) or "") .. "  (B)"
end

SyncEv.OnClientEvent:Connect(function(d)
	myData = d
	refreshHud()
	if collPanel.Visible then refreshCollection() end
end)

local function cycleBait()
	if not myData then return end
	local baits = Content.list.baits
	local start = table.find(baits, Content.baits[myData.bait]) or 1
	for i = 1, #baits do
		local b = baits[(start + i - 1) % #baits + 1]
		if b.price == 0 or (myData.baits[b.id] or 0) > 0 then
			EquipBaitEv:FireServer(b.id)
			return
		end
	end
end
baitButton.Activated:Connect(cycleBait)

RunService.Heartbeat:Connect(function()
	local t = Lighting.ClockTime
	clockLabel.Text = string.format("Time: %02d:%02d %s", math.floor(t), math.floor(t % 1 * 60), (t < 6 or t >= 18) and "(night)" or "")
end)

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
	if cast then ReelEv:FireServer(cast.id, false) end
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

local function startReel()
	state = "reeling"
	local power = Content.rods[myData and myData.rod or "basic"].power
	reel.zone, reel.vel, reel.fish, reel.target, reel.nextMove, reel.progress = 0.5 - power / 2, 0, 0.5, 0.5, 0, 0.3
	zoneBar.Size = UDim2.fromScale(power, 1)
	reelFrame.Visible = true
	showMessage("Hooked! Reel it in!", Color3.fromRGB(120, 255, 140))
end

RunService.RenderStepped:Connect(function(dt)
	if cast and cast.bobber then
		local base = cast.basePos
		local dip = state == "bite" and -0.5 or 0
		cast.bobber.Position = base + Vector3.new(0, math.sin(os.clock() * 3) * 0.08 + dip, 0)
	end
	if state ~= "reeling" or not cast then return end
	if not getRod() then return fail() end

	local power = Content.rods[myData and myData.rod or "basic"].power
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
		ReelEv:FireServer(cast.id, true)
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
		return showMessage("Aim at the water to cast")
	end
	state = "casting"
	local ok, res = pcall(CastFn.InvokeServer, CastFn, hit.Position)
	if not ok or not res or not res.ok then
		state = "idle"
		return showMessage(res and res.msg or "Cast failed", Color3.fromRGB(255, 140, 90))
	end
	cast = { id = res.id, difficulty = res.difficulty, basePos = hit.Position + Vector3.new(0, 0.2, 0) }
	cast.bobber = spawnBobber(cast.basePos)
	state = "waiting"
	showMessage("Waiting for a bite... (" .. res.zone .. ")")
	local myId = res.id
	task.delay(res.biteDelay, function()
		if not cast or cast.id ~= myId or state ~= "waiting" then return end
		state = "bite"
		showMessage("BITE! Click now!", Color3.fromRGB(255, 230, 60))
		task.delay(Content.balance.hookWindow, function()
			if cast and cast.id == myId and state == "bite" then
				showMessage("Too slow - it got away.", Color3.fromRGB(255, 140, 90))
				fail()
			end
		end)
	end)
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.Space
end

UIS.InputBegan:Connect(function(input, processed)
	if state == "reeling" and isPress(input) then reel.holding = true return end
	if processed then return end
	if input.KeyCode == Enum.KeyCode.C then return toggleCollection() end
	if input.KeyCode == Enum.KeyCode.B then return cycleBait() end
	if state == "bite" and isPress(input) then return startReel() end
	if state == "idle" and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		tryCast(input.Position)
	end
end)

UIS.InputEnded:Connect(function(input)
	if isPress(input) then reel.holding = false end
end)

-- unequipping or dying cancels the cast
player.CharacterAdded:Connect(function(char)
	if cast then fail() end
	char.ChildRemoved:Connect(function(c)
		if c.Name == "FishingRod" and (state == "waiting" or state == "bite") then fail() end
	end)
end)
if player.Character then
	player.Character.ChildRemoved:Connect(function(c)
		if c.Name == "FishingRod" and (state == "waiting" or state == "bite") then fail() end
	end)
end
