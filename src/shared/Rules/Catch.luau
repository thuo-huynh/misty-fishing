-- Fishing Rules (pure): which Species bites, its weight, bite wait and sell price.
-- No Roblox APIs; `rng` is injected: a function returning a number in [0, 1).
-- content = { species = <species list>, balance = <balance table> }
-- cast = { zone = Zone ID, bait = Bait record, rod = Rod record, hour = in-game hour 0..24 }
local Catch = {}

-- Species that can bite, in file order, each with its probability.
local function candidates(content, cast)
	local night = cast.hour < 6 or cast.hour >= 18
	local luck = cast.rod.luck + cast.bait.luck
	local perTier = content.balance.catch.luckPerTier
	local byRarity = {}
	for _, s in content.species do
		if not s.hidden and table.find(s.zones, cast.zone) and table.find(s.baits, cast.bait.id) and (not s.night or night) then
			byRarity[s.rarity] = byRarity[s.rarity] or {}
			table.insert(byRarity[s.rarity], s)
		end
	end
	local total, tierWeight = 0, {}
	for i, r in content.balance.rarities do
		if byRarity[r.id] then
			tierWeight[r.id] = r.weight * (1 + luck * perTier * (i - 1)) -- luck lifts rarer tiers more
			total += tierWeight[r.id]
		end
	end
	local out = {}
	for _, s in content.species do
		local pool = byRarity[s.rarity]
		if pool and table.find(pool, s) then
			table.insert(out, { species = s, p = tierWeight[s.rarity] / total / #pool })
		end
	end
	return out
end

-- { [Species ID] = probability } for this cast; empty when nothing eats this Bait here.
function Catch.odds(content, cast)
	local odds = {}
	for _, c in candidates(content, cast) do odds[c.species.id] = c.p end
	return odds
end

-- Species record and weight in kg (2 decimals), or nil when nothing eats this Bait here.
function Catch.roll(content, cast, rng)
	local list = candidates(content, cast)
	if #list == 0 then return nil end
	local roll, s = rng(), list[#list].species
	for _, c in list do
		roll -= c.p
		if roll < 0 then
			s = c.species
			break
		end
	end
	local kg = s.kg[1] + (s.kg[2] - s.kg[1]) * rng() ^ 2 -- squared: big ones are rarer
	return s, math.floor(kg * 100 + 0.5) / 100
end

-- Seconds until a fish bites.
function Catch.biteDelay(balance, bait, rng)
	local lo, hi = table.unpack(balance.catch.biteDelay)
	return (lo + (hi - lo) * rng()) / bait.biteSpeed
end

-- Coins for one Catch (before any Gamepass multiplier).
function Catch.sellPrice(species, kg)
	return math.max(1, math.floor(species.price * kg + 1e-6)) -- epsilon: 0.29 * 100 is 28.999... in floats
end

return Catch
