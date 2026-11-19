-- Balance constants. Colors are {r, g, b} 0..255.
return {
	maxCastDistance = 80, -- studs from character to bobber
	bagSize = 30,         -- Catches carried before you must sell
	hookWindow = 1.5,     -- seconds to react when the bobber dips
	dayLength = 720,      -- real seconds for one in-game day

	-- Reeling simulation (src/shared/Rules/Tension.luau). Tension is 0..1 of the Line's maxTension.
	-- Fish force = kg * kgForce + difficulty * difficultyForce (same units as Line maxTension).
	tension = {
		escapeDistance = 80,  -- studs; fish further than this escapes
		fleeSpeed = 2,        -- studs/s per difficulty the fish swims away while not holding
		relaxRate = 1,        -- Tension lost per second while not holding
		riseRate = 1,         -- Tension gained per second while holding = riseRate * force / maxTension
		kgForce = 4,
		difficultyForce = 10,
		thrashSpike = 1,      -- Tension jump per thrash = thrashSpike * force / maxTension
		thrashInterval = 4,   -- base seconds between thrashes, divided by difficulty, times 0.5..1.5 random
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
