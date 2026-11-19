-- Species. `id` never changes once shipped (ADR 0003); `name` is display only.
-- kg = {min, max}; price = Coins per kg; difficulty 1..5; night = only bites 18:00-06:00
-- rarity, zones and baits hold ids from balance.luau, zones.luau and baits.luau.
return {
	{ id = "perch",        name = "Perch",        rarity = "common",    zones = { "lake" }, kg = { 0.1, 0.8 }, price = 10,  difficulty = 1, baits = { "worm" } },
	{ id = "roach",        name = "Roach",        rarity = "common",    zones = { "lake" }, kg = { 0.1, 0.5 }, price = 12,  difficulty = 1, baits = { "worm", "corn" } },
	{ id = "bream",        name = "Bream",        rarity = "uncommon",  zones = { "lake" }, kg = { 0.5, 4 },   price = 14,  difficulty = 2, baits = { "worm", "corn" } },
	{ id = "tench",        name = "Tench",        rarity = "uncommon",  zones = { "lake" }, kg = { 0.5, 3 },   price = 18,  difficulty = 2, baits = { "worm", "corn" } },
	{ id = "carp",         name = "Carp",         rarity = "rare",      zones = { "lake" }, kg = { 2, 20 },    price = 15,  difficulty = 3, baits = { "corn" } },
	{ id = "pike",         name = "Pike",         rarity = "rare",      zones = { "lake" }, kg = { 1, 15 },    price = 20,  difficulty = 3, baits = { "lure" } },
	{ id = "wels_catfish", name = "Wels Catfish", rarity = "epic",      zones = { "lake" }, kg = { 10, 120 },  price = 12,  difficulty = 5, baits = { "worm" }, night = true },
	{ id = "golden_koi",   name = "Golden Koi",   rarity = "legendary", zones = { "lake" }, kg = { 3, 15 },    price = 250, difficulty = 4, baits = { "corn" } },
}
