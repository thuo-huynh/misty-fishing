-- Pure Player Profile data: shape, load-time reconcile and named operations. No Roblox APIs (tested with Lune).
-- `content` is shaped like shared/Content.luau: content.<kind>[id] and content.list.<kind>.
-- Saves hold Content IDs only (ADR 0003). IDs missing from content are ignored, never deleted,
-- so the data comes back if the content is restored.
local ProfileData = {}

ProfileData.VERSION = 1

local function firstFree(list)
	for _, r in list do
		if r.price == 0 then return r.id end
	end
end

function ProfileData.new(content)
	local rod, line = firstFree(content.list.rods), firstFree(content.list.lines)
	return {
		version = ProfileData.VERSION,
		coins = 0,
		xp = 0,
		ownedRods = { rod },
		ownedLines = { line },
		baits = {}, -- [baitId] = count left; free baits are unlimited and not stored
		equipped = { rod = rod, line = line, bait = firstFree(content.list.baits) },
		bag = {}, -- { species, kg, zone, time, kept }
		collection = {}, -- [speciesId] = { count, bestKg }
		dailyQuests = { day = 0, quests = {} }, -- quests: { id, progress, claimed }
		tutorialStep = 0,
	}
end

local OWNED = { rods = "ownedRods", lines = "ownedLines" }

-- kind: "rods" | "lines". Unknown IDs count as not owned.
function ProfileData.owns(d, content, kind, id)
	return content[kind][id] ~= nil and table.find(d[OWNED[kind]], id) ~= nil
end

-- math.huge for free baits, 0 for unknown ones.
function ProfileData.baitCount(d, content, id)
	local bait = content.baits[id]
	if not bait then return 0 end
	return if bait.price == 0 then math.huge else d.baits[id] or 0
end

-- Run on every load: fill fields missing from older saves, swap invalid equipped Tackle for the free default.
function ProfileData.reconcile(d, content)
	local default = ProfileData.new(content)
	for k, v in default do
		if d[k] == nil then
			d[k] = v
		elseif type(v) == "table" and k ~= "ownedRods" and k ~= "ownedLines" then
			for k2, v2 in v do
				if d[k][k2] == nil then d[k][k2] = v2 end
			end
		end
	end
	local e = d.equipped
	for kind, slot in { rods = "rod", lines = "line" } do
		if not ProfileData.owns(d, content, kind, e[slot]) then e[slot] = default.equipped[slot] end
	end
	if ProfileData.baitCount(d, content, e.bait) <= 0 then e.bait = default.equipped.bait end
	return d
end

local SLOT = { rods = "rod", lines = "line", baits = "bait" }

-- Equip an owned Rod/Line or a Bait that has some left. Returns false if not allowed.
function ProfileData.equip(d, content, kind, id)
	local ok = if kind == "baits" then ProfileData.baitCount(d, content, id) > 0 else ProfileData.owns(d, content, kind, id)
	if ok then d.equipped[SLOT[kind]] = id end
	return ok
end

-- Rod/Line: buy once (already owned = just equip). Bait: buy one pack. Equips on success; false if unaffordable.
function ProfileData.buy(d, content, kind, id)
	local item = content[kind][id]
	if not item or (kind == "baits" and item.price == 0) then return false end
	if kind ~= "baits" and ProfileData.owns(d, content, kind, id) then return ProfileData.equip(d, content, kind, id) end
	if d.coins < item.price then return false end
	d.coins -= item.price
	if kind == "baits" then
		d.baits[id] = (d.baits[id] or 0) + item.pack
	else
		table.insert(d[OWNED[kind]], id)
	end
	return ProfileData.equip(d, content, kind, id)
end

-- Use one of the equipped Bait (always valid after reconcile) and return its record;
-- re-equips the free Bait when a paid one runs out.
function ProfileData.takeBait(d, content)
	local bait = content.baits[d.equipped.bait]
	if bait.price > 0 then
		d.baits[bait.id] -= 1
		if d.baits[bait.id] <= 0 then d.equipped.bait = firstFree(content.list.baits) end
	end
	return bait
end

-- catch = { species, kg, zone, time }. Returns false when the bag is full, else true and whether it is a new record.
function ProfileData.addCatch(d, content, catch)
	if #d.bag >= content.balance.bagSize then return false end
	table.insert(d.bag, { species = catch.species, kg = catch.kg, zone = catch.zone, time = catch.time, kept = false })
	local entry = d.collection[catch.species]
	local record = not entry or catch.kg > entry.bestKg
	d.collection[catch.species] = {
		count = (entry and entry.count or 0) + 1,
		bestKg = if record then catch.kg else entry.bestKg,
	}
	return true, record
end

-- Sell every Catch except kept ones and ones whose Species left content. Returns Coins earned.
function ProfileData.sellBag(d, content)
	local total, left = 0, {}
	for _, catch in d.bag do
		local species = content.species[catch.species]
		if species and not catch.kept then
			-- shortcut: copy of Rules/Catch.sellPrice (this module must stay require-free for Lune); share it if pricing grows
			total += math.max(1, math.floor(species.price * catch.kg + 1e-6))
		else
			table.insert(left, catch)
		end
	end
	d.bag = left
	d.coins += total
	return total
end

return ProfileData
