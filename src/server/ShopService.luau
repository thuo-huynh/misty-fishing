-- ShopService: Tackle shops on the map and equipping Tackle (pure rules in ProfileData).
-- Map parts/models tagged RodShop / LineShop / BaitShop carry the Content ID in attribute RodId / LineId / BaitId (ADR 0001).
-- The ProximityPrompt opens the client shop panel; a Buy is only accepted for the shop the player last opened.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Content = require(RS:WaitForChild("Content"))
local PlayerProfile = require(script.Parent:WaitForChild("PlayerProfile"))
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))

local SHOPS = { RodShop = { "rods", "RodId" }, LineShop = { "lines", "LineId" }, BaitShop = { "baits", "BaitId" } }
local KINDS = { rods = true, lines = true, baits = true }
local RED, BLUE = Color3.fromRGB(255, 90, 90), Color3.fromRGB(120, 220, 255)

local ShopService = {}
local sync, notify
local opened = {} -- [player] = { kind, id } of the last shop prompt they triggered

local function addPrompt(inst, kind, id)
	local part = if inst:IsA("Model") then inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) else inst
	if not part then return end
	local prompt = Instance.new("ProximityPrompt")
	-- text keys, translated by the client (localization/UI.csv); "<kind>_<id>" is the Content name key
	prompt:SetAttribute("TextKey", "Prompt_Shop")
	prompt:SetAttribute("ObjectKey", `{kind}_{id}`)
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

-- remotes: the FishingRemotes folder. syncFn(player) pushes Profile data; notifyFn(player, key, args?, color?) shows a message.
function ShopService.start(remotes, syncFn, notifyFn)
	sync, notify = syncFn, notifyFn
	local function remote(name)
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
		return r
	end
	local OpenShopEv, BuyEv, EquipEv = remote("OpenShop"), remote("Buy"), remote("Equip")

	for tag, spec in SHOPS do
		local kind, attr = spec[1], spec[2]
		local function onShop(inst)
			local id = string.lower(inst:GetAttribute(attr) or "")
			local item = Content[kind][id]
			if not item or item.price == 0 then return warn(`{tag} missing valid {attr}:`, inst:GetFullName()) end
			local prompt = addPrompt(inst, kind, id)
			if not prompt then return end
			prompt.Triggered:Connect(function(player)
				opened[player] = { kind = kind, id = id }
				OpenShopEv:FireClient(player, kind, id)
			end)
		end
		for _, inst in CollectionService:GetTagged(tag) do task.spawn(onShop, inst) end
		CollectionService:GetInstanceAddedSignal(tag):Connect(onShop)
	end

	BuyEv.OnServerEvent:Connect(function(player, kind, id)
		local shop = opened[player]
		if not shop or shop.kind ~= kind or shop.id ~= id then return end
		local ok, why = PlayerProfile.buy(player, kind, id)
		if ok == nil then return end
		if not ok then return notify(player, if why == "coins" then "Msg_NotEnoughCoins" else "Msg_CantBuy", nil, RED) end
		local item = Content[kind][id]
		notify(player, if kind == "baits" then "Msg_Bought" else "Msg_Equipped", { count = item.pack, name = { kind, id } }, BLUE)
		TutorialService.event(player, "bought", kind)
		sync(player)
	end)

	EquipEv.OnServerEvent:Connect(function(player, kind, id)
		if typeof(kind) ~= "string" or typeof(id) ~= "string" or not KINDS[kind] then return end
		if PlayerProfile.equip(player, kind, id) then sync(player) end
	end)

	Players.PlayerRemoving:Connect(function(player) opened[player] = nil end)
end

-- Use one Bait for a cast; tells the player when their paid Bait ran out and Worm is back on.
function ShopService.takeBait(player)
	local bait, ranOut = PlayerProfile.takeBait(player)
	if ranOut then
		notify(player, "Msg_BaitRanOut", { bait = { "baits", bait.id }, next = { "baits", PlayerProfile.get(player).equipped.bait } }, RED)
	end
	return bait
end

return ShopService
