-- Kiểm tra các bảng trong content/: id hợp lệ, không trùng, tham chiếu đúng, đủ dữ liệu mẫu Lake.
local kinds = {
	species = require("../content/species"),
	zones = require("../content/zones"),
	rods = require("../content/rods"),
	lines = require("../content/lines"),
	baits = require("../content/baits"),
	rarities = require("../content/balance").rarities,
}

local function index(kind)
	local set = {}
	for _, r in kinds[kind] do
		assert(type(r.id) == "string" and r.id:match("^[a-z][a-z0-9_]*$"), `{kind}: id sai {r.id}`)
		assert(not set[r.id], `{kind}: trùng id {r.id}`)
		assert(type(r.name) == "string", `{kind} {r.id}: thiếu name`)
		set[r.id] = r
	end
	return set
end

return {
	["mọi bản ghi có id hợp lệ, không trùng, có name"] = function()
		for kind in kinds do index(kind) end
	end,

	["Species chỉ tham chiếu rarity, Zone, Bait có thật"] = function()
		local rarities, zones, baits = index("rarities"), index("zones"), index("baits")
		for _, s in kinds.species do
			assert(rarities[s.rarity], `species {s.id}: rarity lạ {s.rarity}`)
			for _, z in s.zones do assert(zones[z], `species {s.id}: zone lạ {z}`) end
			for _, b in s.baits do assert(baits[b], `species {s.id}: bait lạ {b}`) end
		end
	end,

	["dữ liệu mẫu Lake đủ để chơi thử"] = function()
		local lake = 0
		for _, s in kinds.species do
			if table.find(s.zones, "lake") then lake += 1 end
		end
		assert(lake == 8, `cần 8 Species ở Lake, có {lake}`)
		assert(#kinds.rods == 2 and #kinds.lines == 2 and #kinds.baits == 3, "số Rod/Line/Bait mẫu sai")
		assert(index("baits").worm.price == 0, "Worm phải miễn phí")
	end,
}
