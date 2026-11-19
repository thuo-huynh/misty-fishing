-- Script "FishingServer" in ServerScriptService.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

-- Content Validator (#4): kiểm tra content trước khi dùng; có lỗi thì in ra Output và từ chối mọi lượt câu.
local contentOk = true
do
	local folder = RS:WaitForChild("ContentData")
	local raw = {}
	for _, kind in { "species", "zones", "rods", "lines", "baits", "balance" } do
		raw[kind] = require(folder:WaitForChild(kind))
	end
	local Validator = require(RS:WaitForChild("ContentValidator"))
	local report = Validator.validate(raw, require(folder:WaitForChild("published")))
	-- #13: map chỉ gặp content qua attribute ZoneId trên part có tag FishingZone (ADR 0001)
	local waters = {}
	for _, part in CollectionService:GetTagged("FishingZone") do
		table.insert(waters, { name = part:GetFullName(), zoneId = part:GetAttribute("ZoneId") })
	end
	for _, e in Validator.checkMap(raw.zones, waters) do table.insert(report.errors, e) end
	for _, w in report.warnings do warn(`[Content] Cảnh báo: {w}`) end
	for _, e in report.errors do warn(`[Content] LỖI: {e}`) end
	if #report.errors > 0 then
		contentOk = false
		warn(`[Content] Có {#report.errors} lỗi content — server từ chối mọi lượt câu cho tới khi sửa xong.`)
	end
end

local Content = require(RS:WaitForChild("Content"))
local PlayerProfile = require(script.Parent:WaitForChild("PlayerProfile"))
local FishingService = require(script.Parent:WaitForChild("FishingService"))
local Balance = Content.balance

local remotes = Instance.new("Folder")
remotes.Name = "FishingRemotes"
local function remote(class, name)
	local r = Instance.new(class)
	r.Name = name
	r.Parent = remotes
	return r
end
local EquipBaitEv = remote("RemoteEvent", "EquipBait")
local SyncEv = remote("RemoteEvent", "Sync")
local NotifyEv = remote("RemoteEvent", "Notify")
remotes.Parent = RS

---------------------------------------------------------------- data
local function sync(player)
	local d = PlayerProfile.get(player)
	if not d then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Coins.Value = d.coins end
	SyncEv:FireClient(player, d)
end

local function notify(player, text, color)
	NotifyEv:FireClient(player, text, color)
end

local function giveRod(player)
	local backpack = player:WaitForChild("Backpack")
	if backpack:FindFirstChild("FishingRod") or (player.Character and player.Character:FindFirstChild("FishingRod")) then return end
	local template = ServerStorage:FindFirstChild("FishingRod")
	local tool
	if template then
		tool = template:Clone()
	else
		tool = Instance.new("Tool")
		tool.Name = "FishingRod"
		tool.CanBeDropped = false
		tool.GripPos = Vector3.new(0, -2, 0)
		tool.GripForward = Vector3.new(0, 0.5, -0.87)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.2, 6, 0.2)
		handle.Color = Color3.fromRGB(110, 70, 40)
		handle.CanCollide = false
		handle.Parent = tool
	end
	local handle = tool:FindFirstChild("Handle")
	if handle and not handle:FindFirstChild("Tip") then
		local tip = Instance.new("Attachment")
		tip.Name = "Tip"
		tip.Position = Vector3.new(0, handle.Size.Y / 2, 0)
		tip.Parent = handle
	end
	tool.Parent = backpack
end

local function onPlayerAdded(player)
	if not PlayerProfile.load(player) then return end -- kicked with a message; old data untouched

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = ls
	ls.Parent = player

	player.CharacterAdded:Connect(function() giveRod(player) end)
	if player.Character then giveRod(player) end
	sync(player)
end

for _, p in Players:GetPlayers() do task.spawn(onPlayerAdded, p) end
Players.PlayerAdded:Connect(onPlayerAdded)

-- ProfileStore autosaves and saves on shutdown; we only release the session.
Players.PlayerRemoving:Connect(function(player)
	PlayerProfile.release(player)
end)

---------------------------------------------------------------- day / night
task.spawn(function()
	while true do
		local dt = task.wait(1)
		Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / Balance.dayLength) % 24
	end
end)

---------------------------------------------------------------- fishing (#9: FishingService)
FishingService.start({ remotes = remotes, contentOk = contentOk, notify = notify, sync = sync })

EquipBaitEv.OnServerEvent:Connect(function(player, baitId)
	if typeof(baitId) ~= "string" then return end
	if PlayerProfile.equip(player, "baits", baitId) then sync(player) end
end)

---------------------------------------------------------------- shops (ProximityPrompts, all server-side)
local function promptOn(inst, actionText, objectText)
	local parent = inst
	if inst:IsA("Model") then parent = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) end
	if not parent then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText or ""
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function onTagged(tag, fn)
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do task.spawn(fn, inst) end
	CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
end

onTagged("SellNPC", function(inst)
	local prompt = promptOn(inst, "Sell fish", "Fish Market")
	if not prompt then return end
	prompt.Triggered:Connect(function(player)
		local total = PlayerProfile.sellBag(player)
		if not total then return end
		if total == 0 then return notify(player, "Nothing to sell.") end
		notify(player, string.format("Sold for %d coins!", total), Color3.fromRGB(255, 220, 80))
		sync(player)
	end)
end)

onTagged("RodShop", function(inst)
	local rodId = string.lower(inst:GetAttribute("RodId") or "")
	local rod = Content.rods[rodId]
	if not rod then return warn("RodShop missing valid RodId:", inst:GetFullName()) end
	local prompt = promptOn(inst, string.format("Buy / equip (%d)", rod.price), rod.name)
	if not prompt then return end
	prompt.Triggered:Connect(function(player)
		local ok = PlayerProfile.buy(player, "rods", rodId)
		if ok == nil then return end
		if not ok then return notify(player, "Not enough coins.", Color3.fromRGB(255, 90, 90)) end
		notify(player, "Equipped " .. rod.name, Color3.fromRGB(120, 220, 255))
		sync(player)
	end)
end)

onTagged("BaitShop", function(inst)
	local baitId = string.lower(inst:GetAttribute("BaitId") or "")
	local bait = Content.baits[baitId]
	if not bait or bait.price == 0 then return warn("BaitShop missing valid BaitId:", inst:GetFullName()) end
	local prompt = promptOn(inst, string.format("Buy %d (%d)", bait.pack, bait.price), bait.name)
	if not prompt then return end
	prompt.Triggered:Connect(function(player)
		local ok = PlayerProfile.buy(player, "baits", baitId)
		if ok == nil then return end
		if not ok then return notify(player, "Not enough coins.", Color3.fromRGB(255, 90, 90)) end
		notify(player, string.format("Bought %d %s", bait.pack, bait.name), Color3.fromRGB(120, 220, 255))
		sync(player)
	end)
end)
