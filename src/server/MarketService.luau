-- MarketService: the fish market on the map. A part/model tagged `SellNPC` (ADR 0001) gets a ProximityPrompt
-- that sells the whole bag in one action, server-side; kept Catches stay (pure rules in ProfileData.sellBag).
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Catch = require(RS:WaitForChild("Rules"):WaitForChild("Catch"))
local PlayerProfile = require(script.Parent:WaitForChild("PlayerProfile"))
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))

local TAG = "SellNPC"
local GOLD = Color3.fromRGB(255, 220, 80)

local MarketService = {}

local function onMarket(inst, sync, notify)
	local part = if inst:IsA("Model") then inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) else inst
	if not part then return warn(`{TAG} has no part for a prompt:`, inst:GetFullName()) end
	local prompt = Instance.new("ProximityPrompt")
	-- text keys, translated by the client (localization/UI.csv)
	prompt:SetAttribute("TextKey", "Prompt_SellFish")
	prompt:SetAttribute("ObjectKey", "Prompt_FishMarket")
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		local total = PlayerProfile.sellBag(player, Catch.sellPrice)
		if not total then return end
		if total == 0 then return notify(player, "Msg_NothingToSell") end
		notify(player, "Msg_Sold", { coins = total }, GOLD)
		TutorialService.event(player, "sold")
		sync(player)
	end)
end

-- syncFn(player) pushes Profile data; notifyFn(player, key, args?, color?) shows a message.
function MarketService.start(syncFn, notifyFn)
	for _, inst in CollectionService:GetTagged(TAG) do task.spawn(onMarket, inst, syncFn, notifyFn) end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst) onMarket(inst, syncFn, notifyFn) end)
end

return MarketService
