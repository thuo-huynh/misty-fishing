-- Balance constants. Colors are {r, g, b} 0..255.
return {
	maxCastDistance = 80, -- studs from character to bobber
	bagSize = 30,         -- Catches carried before you must sell
	hookWindow = 1.5,     -- seconds to react when the bobber dips
	dayLength = 720,      -- real seconds for one in-game day

	-- Fishing Rules: catch (src/shared/Rules/Catch.luau)
	catch = {
		luckPerTier = 0.25,      -- each luck point adds this x tier index to a rarity's weight
		biteDelay = { 3, 10 },   -- seconds before a bite, divided by the Bait's biteSpeed
	},

	-- rarest last; `id` never changes once shipped (ADR 0003)
	rarities = {
		{ id = "common",    name = "Common",    weight = 60, color = { 210, 210, 210 } },
		{ id = "uncommon",  name = "Uncommon",  weight = 25, color = { 90, 210, 90 } },
		{ id = "rare",      name = "Rare",      weight = 10, color = { 80, 150, 255 } },
		{ id = "epic",      name = "Epic",      weight = 4,  color = { 190, 100, 255 } },
		{ id = "legendary", name = "Legendary", weight = 1,  color = { 255, 195, 40 } },
	},
}
