-- Content Validator: mỗi loại lỗi/cảnh báo trong spec #1 có một test, cộng một test trên content thật.
local Validator = require("../src/shared/ContentValidator")

-- Content nhỏ, hợp lệ; mỗi test sửa một chỗ để gây đúng một lỗi.
local function fixture()
	return {
		zones = { { id = "lake", name = "Lake", level = 1 } },
		baits = { { id = "worm", name = "Worm", price = 0, pack = 0 } },
		rods = { { id = "basic", name = "Basic Rod", price = 0 } },
		lines = { { id = "basic", name = "Basic Line", price = 0 } },
		balance = { rarities = { { id = "common", name = "Common", weight = 1 } } },
		species = {
			{ id = "perch", name = "Perch", rarity = "common", zones = { "lake" }, baits = { "worm" }, kg = { 0.1, 1 }, price = 10, model = 1 },
		},
	}
end

local function published()
	return { zones = { "lake" }, baits = { "worm" }, rods = { "basic" }, lines = { "basic" }, rarities = { "common" }, species = { "perch" } }
end

-- Có đúng một mục chứa `needle`.
local function expectOne(list, needle)
	assert(#list == 1, `cần đúng 1, có {#list}: {table.concat(list, " | ")}`)
	assert(list[1]:find(needle, 1, true), `"{list[1]}" không chứa "{needle}"`)
end

local function expectNone(r)
	assert(#r.errors == 0 and #r.warnings == 0, `lỗi: {table.concat(r.errors, " | ")}; cảnh báo: {table.concat(r.warnings, " | ")}`)
end

return {
	["content hợp lệ không có lỗi hay cảnh báo"] = function()
		expectNone(Validator.validate(fixture(), published()))
	end,

	["Content ID trùng là lỗi"] = function()
		local c = fixture()
		table.insert(c.rods, { id = "basic", name = "Copy", price = 5 })
		expectOne(Validator.validate(c, published()).errors, "rods: Content ID 'basic' bị trùng")
	end,

	["Species tham chiếu Zone không tồn tại là lỗi"] = function()
		local c = fixture()
		table.insert(c.species[1].zones, "sea")
		expectOne(Validator.validate(c, published()).errors, "Species 'perch' tham chiếu Zone 'sea' không tồn tại")
	end,

	["Species tham chiếu Bait không tồn tại là lỗi"] = function()
		local c = fixture()
		table.insert(c.species[1].baits, "shrimp")
		expectOne(Validator.validate(c, published()).errors, "Species 'perch' tham chiếu Bait 'shrimp' không tồn tại")
	end,

	["độ hiếm không hợp lệ là lỗi"] = function()
		local c = fixture()
		c.species[1].rarity = "mythic"
		expectOne(Validator.validate(c, published()).errors, "Species 'perch' có độ hiếm 'mythic' không hợp lệ")
	end,

	["cân nặng min > max là lỗi"] = function()
		local c = fixture()
		c.species[1].kg = { 2, 1 }
		expectOne(Validator.validate(c, published()).errors, "Species 'perch' có cân nặng min (2) lớn hơn max (1)")
	end,

	["cân nặng ≤ 0 là lỗi"] = function()
		local c = fixture()
		c.species[1].kg = { 0, 1 }
		expectOne(Validator.validate(c, published()).errors, "Species 'perch' có cân nặng ≤ 0")
	end,

	["giá âm là lỗi, ở mọi loại content có giá"] = function()
		for _, kind in { "species", "rods", "lines", "baits" } do
			local c = fixture()
			c[kind][1].price = -1
			expectOne(Validator.validate(c, published()).errors, "giá âm (-1)")
		end
	end,

	["Zone không có Species nào là lỗi"] = function()
		local c, p = fixture(), published()
		table.insert(c.zones, { id = "river", name = "River", level = 5 })
		table.insert(p.zones, "river")
		expectOne(Validator.validate(c, p).errors, "Zone 'river' không có Species nào")
	end,

	["Zone chỉ có Species bị ẩn cũng là không có Species"] = function()
		local c = fixture()
		c.species[1].hidden = true
		expectOne(Validator.validate(c, published()).errors, "Zone 'lake' không có Species nào")
	end,

	["Zone + Bait trong cửa hàng mà không Species nào ăn là lỗi"] = function()
		local c, p = fixture(), published()
		table.insert(c.baits, { id = "corn", name = "Corn", price = 30, pack = 10 })
		table.insert(p.baits, "corn")
		expectOne(Validator.validate(c, p).errors, "Zone 'lake' + Bait 'corn': không có Species nào ăn")
	end,

	["Bait bị ẩn không cần Species ăn"] = function()
		local c, p = fixture(), published()
		table.insert(c.baits, { id = "corn", name = "Corn", price = 30, pack = 10, hidden = true })
		table.insert(p.baits, "corn")
		expectNone(Validator.validate(c, p))
	end,

	["Content ID đã phát hành bị mất là lỗi"] = function()
		local p = published()
		table.insert(p.rods, "bamboo")
		expectOne(Validator.validate(fixture(), p).errors, "rods: Content ID 'bamboo' đã phát hành nhưng bị mất")
	end,

	["Species không có model là cảnh báo, không phải lỗi"] = function()
		local c = fixture()
		c.species[1].model = nil
		local r = Validator.validate(c, published())
		assert(#r.errors == 0, table.concat(r.errors, " | "))
		expectOne(r.warnings, "Species 'perch' chưa có model")
	end,

	["Species chỉ ăn ban đêm mà ban ngày không loài nào ăn cùng Bait ở Zone đó là cảnh báo"] = function()
		local c = fixture()
		c.species[1].night = true
		local r = Validator.validate(c, published())
		assert(#r.errors == 0, table.concat(r.errors, " | "))
		expectOne(r.warnings, "Species 'perch' chỉ ăn ban đêm, nhưng ban ngày ở Zone 'lake' không có loài nào ăn Bait 'worm'")
	end,

	["Species ban đêm có loài ban ngày tương ứng thì không cảnh báo"] = function()
		local c, p = fixture(), published()
		table.insert(c.species, { id = "catfish", name = "Catfish", rarity = "common", zones = { "lake" }, baits = { "worm" }, kg = { 1, 9 }, price = 5, model = 2, night = true })
		table.insert(p.species, "catfish")
		expectNone(Validator.validate(c, p))
	end,

	-- CI chặn PR khi content thật của repo có lỗi
	["content thật của repo không có lỗi"] = function()
		local content = {
			species = require("../content/species"),
			zones = require("../content/zones"),
			rods = require("../content/rods"),
			lines = require("../content/lines"),
			baits = require("../content/baits"),
			balance = require("../content/balance"),
		}
		local r = Validator.validate(content, require("../content/published"))
		assert(#r.errors == 0, "\n  " .. table.concat(r.errors, "\n  "))
	end,
}
