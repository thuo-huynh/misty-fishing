-- Pure check of the content/ tables. Run: lune run tests/content.spec.luau
local kinds = {
	species = require("../content/species"),
	zones = require("../content/zones"),
	rods = require("../content/rods"),
	lines = require("../content/lines"),
	baits = require("../content/baits"),
}
local balance = require("../content/balance")

local function ids(list, kind)
	local set = {}
	for _, r in list do
		assert(type(r.id) == "string" and r.id:match("^[a-z][a-z0-9_]*$"), `{kind}: bad id {r.id}`)
		assert(not set[r.id], `{kind}: duplicate id {r.id}`)
		assert(type(r.name) == "string", `{kind} {r.id}: missing name`)
		set[r.id] = r
	end
	return set
end

local by = {}
for kind, list in kinds do by[kind] = ids(list, kind) end
local rarities = ids(balance.rarities, "rarities")

for _, s in kinds.species do
	assert(rarities[s.rarity], `species {s.id}: unknown rarity {s.rarity}`)
	for _, z in s.zones do assert(by.zones[z], `species {s.id}: unknown zone {z}`) end
	for _, b in s.baits do assert(by.baits[b], `species {s.id}: unknown bait {b}`) end
end

local lake = 0
for _, s in kinds.species do
	if table.find(s.zones, "lake") then lake += 1 end
end
assert(lake == 8, `expected 8 Lake species, got {lake}`)
assert(#kinds.rods == 2 and #kinds.lines == 2 and #kinds.baits == 3, "MVP sample counts")
assert(by.baits.worm and by.baits.worm.price == 0, "Worm must be free")

print("content ok")
