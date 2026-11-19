-- Tutorial (pure): the first-5-minutes steps, stored as Player Profile `tutorialStep`.
-- No Roblox APIs and no requires (tested by Lune). The server feeds events in; the client shows hint(step).
-- Steps: cast -> first catch -> sell at the market -> buy a Bait -> catch a second Species -> done.
local Tutorial = {}

local CAST, CATCH, SELL, BUY, CATCH_NEW, DONE = 0, 1, 2, 3, 4, 5

-- text: key in localization/UI.csv; target: CollectionService tag of the map part to point at (ADR 0001)
local HINTS = {
	[CAST] = { text = "Tut_Cast", target = "SpawnDock" },
	[CATCH] = { text = "Tut_Catch", target = "SpawnDock" },
	[SELL] = { text = "Tut_Sell", target = "SellNPC" },
	[BUY] = { text = "Tut_Buy", target = "BaitShop" },
	[CATCH_NEW] = { text = "Tut_CatchNew", target = "SpawnDock" },
}

local function speciesCaught(d)
	local n = 0
	for _ in d.collection do n += 1 end
	return n
end

-- event = { kind = "cast" | "landed" | "sold" | "bought" (item = Tackle kind) | "skip" }, sent after the
-- action changed the profile (a "landed" Catch is already in the collection). Mutates d; returns true when the step changed.
function Tutorial.advance(d, content, event)
	local step, kind = d.tutorialStep, event.kind
	local next = if step >= DONE then step
		elseif kind == "skip" then DONE
		elseif step == CAST and kind == "cast" then CATCH
		elseif step == CATCH and kind == "landed" then SELL
		elseif step == SELL and kind == "sold" then BUY
		elseif step == BUY and kind == "bought" and event.item == "baits" then CATCH_NEW
		elseif step == CATCH_NEW and kind == "landed" and speciesCaught(d) >= 2 then DONE
		else step
	if next == BUY and step ~= BUY then
		-- one small fish never pays for a Bait pack: top up to the cheapest paid one
		local cheapest = math.huge
		for _, b in content.list.baits do
			if b.price > 0 then cheapest = math.min(cheapest, b.price) end
		end
		if cheapest < math.huge then d.coins = math.max(d.coins, cheapest) end
	end
	d.tutorialStep = next
	return next ~= step
end

function Tutorial.done(d)
	return d.tutorialStep >= DONE
end

-- { text, target } for the step, or nil when the tutorial is over.
function Tutorial.hint(step)
	return HINTS[step]
end

-- The first Catch is guaranteed: the first Common Species eating this Bait in this Zone, at its lightest
-- (easiest reel). nil after the first Catch or when nothing fits (then the cast rolls as usual).
function Tutorial.forcedCatch(d, content, zone, bait)
	if d.tutorialStep > CATCH then return nil end
	for _, s in content.list.species do
		if s.rarity == "common" and not s.hidden and not s.night and table.find(s.zones, zone) and table.find(s.baits, bait.id) then
			return s, s.kg[1]
		end
	end
	return nil
end

return Tutorial
