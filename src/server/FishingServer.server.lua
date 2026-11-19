-- Script "FishingServer" in ServerScriptService.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local Config = require(RS:WaitForChild("FishConfig"))
local store = DataStoreService:GetDataStore("FishingData_v1")

local remotes = Instance.new("Folder")
remotes.Name = "FishingRemotes"
local function remote(class, name)
	local r = Instance.new(class)
	r.Name = name
	r.Parent = remotes
	return r
end
local CastFn = remote("RemoteFunction", "Cast")
local ReelEv = remote("RemoteEvent", "Reel")
local EquipBaitEv = remote("RemoteEvent", "EquipBait")
local SyncEv = remote("RemoteEvent", "Sync")
local NotifyEv = remote("RemoteEvent", "Notify")
remotes.Parent = RS

local data = {}      -- [player] = save table
local canSave = {}   -- [player] = true only if load succeeded (never overwrite a save we failed to read)
local pending = {}   -- [player] = current cast

---------------------------------------------------------------- data
local function defaultData()
	return { money = 0, rods = { Basic = true }, rod = "Basic", baits = {}, bait = "Worm", bag = {}, collection = {} }
end

local function sync(player)
	local d = data[player]
	if not d then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Money.Value = d.money end
	SyncEv:FireClient(player, d)
end

local function notify(player, text, color)
	NotifyEv:FireClient(player, text, color)
end

local function save(player)
	local d = data[player]
	if not d or not canSave[player] then return end
	local ok, err = pcall(function()
		store:SetAsync("u_" .. player.UserId, d)
	end)
	if not ok then warn("Save failed for", player.Name, err) end
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

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = ls
	ls.Parent = player

	local ok, saved = pcall(function()
		return store:GetAsync("u_" .. player.UserId)
	end)
	local d = defaultData()
	if ok then
		canSave[player] = true
		if type(saved) == "table" then
			for k, v in pairs(saved) do d[k] = v end
		end
	else
		warn("Load failed for", player.Name, "- progress will not be saved this session")
	end
	if not Config.Rods[d.rod] then d.rod = "Basic" end
	if not Config.Baits[d.bait] then d.bait = "Worm" end
	data[player] = d

	player.CharacterAdded:Connect(function() giveRod(player) end)
	if player.Character then giveRod(player) end
	sync(player)
	if not canSave[player] then notify(player, "Data could not load - progress will NOT be saved.", Color3.fromRGB(255, 90, 90)) end
end)

Players.PlayerRemoving:Connect(function(player)
	save(player)
	data[player], canSave[player], pending[player] = nil, nil, nil
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do save(p) end
end)

task.spawn(function()
	while true do
		task.wait(120)
		for _, p in ipairs(Players:GetPlayers()) do save(p) end
	end
end)

---------------------------------------------------------------- day / night
task.spawn(function()
	while true do
		local dt = task.wait(1)
		Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / Config.DayLength) % 24
	end
end)

---------------------------------------------------------------- fishing
local function zoneAt(pos)
	for _, part in ipairs(CollectionService:GetTagged("FishingZone")) do
		if part:IsA("BasePart") then
			local rel = part.CFrame:PointToObjectSpace(pos)
			local half = part.Size / 2
			if math.abs(rel.X) <= half.X + 1 and math.abs(rel.Z) <= half.Z + 1 and math.abs(rel.Y) <= half.Y + 3 then
				return part:GetAttribute("Zone")
			end
		end
	end
end

local function rollFish(zone, baitId, luck)
	local night = Config.IsNight(Lighting.ClockTime)
	local byRarity = {}
	for _, f in ipairs(Config.Fish) do
		if table.find(f.zones, zone) and table.find(f.baits, baitId) and (not f.night or night) then
			byRarity[f.rarity] = byRarity[f.rarity] or {}
			table.insert(byRarity[f.rarity], f)
		end
	end
	local total, weights = 0, {}
	for i, r in ipairs(Config.Rarities) do
		if byRarity[r.id] then
			local w = r.weight * (1 + luck * 0.25 * (i - 1)) -- luck lifts rarer tiers more
			weights[r.id] = w
			total += w
		end
	end
	if total == 0 then return nil end
	local roll = math.random() * total
	for _, r in ipairs(Config.Rarities) do
		local w = weights[r.id]
		if w then
			roll -= w
			if roll <= 0 then
				local pool = byRarity[r.id]
				local fish = pool[math.random(#pool)]
				local kg = fish.kg[1] + (fish.kg[2] - fish.kg[1]) * math.random() ^ 2 -- big ones are rarer
				return fish, math.floor(kg * 100 + 0.5) / 100
			end
		end
	end
end

CastFn.OnServerInvoke = function(player, pos)
	local d = data[player]
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not d or not hrp or typeof(pos) ~= "Vector3" then return { ok = false, msg = "Not ready" } end
	if not char:FindFirstChild("FishingRod") then return { ok = false, msg = "Equip your rod first" } end
	local p = pending[player]
	if p and os.clock() - p.t < 120 then return { ok = false, msg = "Already fishing" } end
	if (hrp.Position - pos).Magnitude > Config.MaxCastDistance then return { ok = false, msg = "Too far!" } end
	local zone = zoneAt(pos)
	if not zone then return { ok = false, msg = "Cast into the water" } end

	local bait = Config.Baits[d.bait]
	if bait.price > 0 and (d.baits[d.bait] or 0) <= 0 then
		d.bait = "Worm"
		bait = Config.Baits.Worm
	end
	local rod = Config.Rods[d.rod]
	local fish, kg = rollFish(zone, d.bait, rod.luck + bait.luck)
	if not fish then return { ok = false, msg = "Nothing bites " .. bait.name .. " here. Try another bait." } end
	if bait.price > 0 then d.baits[d.bait] -= 1 end

	local id = HttpService:GenerateGUID(false)
	local biteDelay = (3 + math.random() * 7) / bait.biteSpeed / (1 + rod.luck * 0.08)
	local difficulty = fish.difficulty + math.min(3, kg / rod.maxKg * 1.5)
	pending[player] = { id = id, fish = fish, kg = kg, t = os.clock(), biteDelay = biteDelay }
	sync(player)
	return { ok = true, id = id, biteDelay = biteDelay, difficulty = difficulty, zone = zone }
end

ReelEv.OnServerEvent:Connect(function(player, id, success)
	local p = pending[player]
	local d = data[player]
	if not p or not d or p.id ~= id then return end
	pending[player] = nil
	if success ~= true then
		notify(player, "The fish got away...", Color3.fromRGB(255, 140, 90))
		return
	end
	-- the minigame cannot be won faster than ~2s after the bite
	if os.clock() - p.t < p.biteDelay + 1.5 then return end
	if #d.bag >= Config.BagSize then
		notify(player, "Bag full! Sell your fish first. (fish released)", Color3.fromRGB(255, 90, 90))
		return
	end
	local value = math.max(1, math.floor(p.kg * p.fish.price))
	table.insert(d.bag, { name = p.fish.name, kg = p.kg, value = value })
	local c = d.collection[p.fish.name]
	local record = not c or p.kg > c.best
	d.collection[p.fish.name] = { count = (c and c.count or 0) + 1, best = c and math.max(c.best, p.kg) or p.kg }
	local r = Config.GetRarity(p.fish.rarity)
	notify(player, string.format("%s %s - %.2f kg (%d coins)%s", p.fish.rarity, p.fish.name, p.kg, value, record and "  NEW RECORD!" or ""), r.color)
	sync(player)
end)

EquipBaitEv.OnServerEvent:Connect(function(player, baitId)
	local d = data[player]
	local bait = Config.Baits[baitId]
	if not d or not bait then return end
	if bait.price > 0 and (d.baits[baitId] or 0) <= 0 then return end
	d.bait = baitId
	sync(player)
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
		local d = data[player]
		if not d then return end
		if #d.bag == 0 then return notify(player, "Your bag is empty.") end
		local total = 0
		for _, f in ipairs(d.bag) do total += f.value end
		d.money += total
		d.bag = {}
		notify(player, string.format("Sold for %d coins!", total), Color3.fromRGB(255, 220, 80))
		sync(player)
	end)
end)

onTagged("RodShop", function(inst)
	local rodId = inst:GetAttribute("RodId")
	local rod = Config.Rods[rodId]
	if not rod then return warn("RodShop missing valid RodId:", inst:GetFullName()) end
	local prompt = promptOn(inst, string.format("Buy / equip (%d)", rod.price), rod.name)
	if not prompt then return end
	prompt.Triggered:Connect(function(player)
		local d = data[player]
		if not d then return end
		if not d.rods[rodId] then
			if d.money < rod.price then return notify(player, "Not enough coins.", Color3.fromRGB(255, 90, 90)) end
			d.money -= rod.price
			d.rods[rodId] = true
		end
		d.rod = rodId
		notify(player, "Equipped " .. rod.name, Color3.fromRGB(120, 220, 255))
		sync(player)
	end)
end)

onTagged("BaitShop", function(inst)
	local baitId = inst:GetAttribute("BaitId")
	local bait = Config.Baits[baitId]
	if not bait or bait.price == 0 then return warn("BaitShop missing valid BaitId:", inst:GetFullName()) end
	local prompt = promptOn(inst, string.format("Buy %d (%d)", bait.pack, bait.price), bait.name)
	if not prompt then return end
	prompt.Triggered:Connect(function(player)
		local d = data[player]
		if not d then return end
		if d.money < bait.price then return notify(player, "Not enough coins.", Color3.fromRGB(255, 90, 90)) end
		d.money -= bait.price
		d.baits[baitId] = (d.baits[baitId] or 0) + bait.pack
		d.bait = baitId
		notify(player, string.format("Bought %d %s", bait.pack, bait.name), Color3.fromRGB(120, 220, 255))
		sync(player)
	end)
end)
