-- Text: tra key trong bảng dịch (dạng LocalizationTable:GetEntries()) và điền {tham số}.
local Text = require("../src/shared/Text")

local entries = {
	{ Key = "Hud_Coins", Source = "Coins: {coins}", Values = { en = "Coins: {coins}", vi = "Xu: {coins}" } },
	{ Key = "Only_Source", Source = "Hi {name}", Values = {} },
}

return {
	["điền tham số vào bản tiếng Anh"] = function()
		local T = Text.new(entries, "en-us")
		assert(T("Hud_Coins", { coins = 25 }) == "Coins: 25", T("Hud_Coins", { coins = 25 }))
	end,

	["chọn theo ngôn ngữ của locale, thiếu thì về tiếng Anh rồi Source"] = function()
		assert(Text.new(entries, "vi-vn")("Hud_Coins", { coins = 3 }) == "Xu: 3")
		assert(Text.new(entries, "fr-fr")("Hud_Coins", { coins = 3 }) == "Coins: 3")
		assert(Text.new(entries, "vi-vn")("Only_Source", { name = "Ann" }) == "Hi Ann")
	end,

	["key thiếu trả fallback, không có fallback thì trả chính key"] = function()
		local T = Text.new(entries, "en-us")
		assert(T("species_perch", nil, "Perch") == "Perch")
		assert(T("Missing_Key") == "Missing_Key")
	end,

	["tham số thiếu giữ nguyên chỗ trống để dễ thấy lỗi"] = function()
		assert(Text.new(entries, "en")("Hud_Coins") == "Coins: {coins}")
	end,
}
