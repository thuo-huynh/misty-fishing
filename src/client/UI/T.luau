-- T(key, args?, fallback?) -> text for the player's locale, from the "UI" LocalizationTable (localization/UI.csv).
-- Content names use key "<kind>_<id>" with the Content name as fallback, e.g. T("rods_basic", nil, rod.name).
local RS = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local Text = require(RS:WaitForChild("Text"))

return Text.new(LocalizationService:WaitForChild("UI"):GetEntries(), LocalizationService.RobloxLocaleId)
