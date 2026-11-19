-- ModuleScript "FishConfig" in ReplicatedStorage. Edit fish, rods, baits and balance here.
local Config = {}

Config.MaxCastDistance = 80   -- studs from character to bobber
Config.BagSize = 30           -- fish carried before you must sell
Config.HookWindow = 1.5       -- seconds to react when the bobber dips
Config.DayLength = 720        -- real seconds for one in-game day

Config.Rarities = {
	{ id = "Common",    weight = 60, color = Color3.fromRGB(210, 210, 210) },
	{ id = "Uncommon",  weight = 25, color = Color3.fromRGB(90, 210, 90) },
	{ id = "Rare",      weight = 10, color = Color3.fromRGB(80, 150, 255) },
	{ id = "Epic",      weight = 4,  color = Color3.fromRGB(190, 100, 255) },
	{ id = "Legendary", weight = 1,  color = Color3.fromRGB(255, 195, 40) },
}

-- kg = {min, max}; price = coins per kg; difficulty 1..5; night = only bites 18:00-06:00
Config.Fish = {
	-- Lake
	{ name = "Perch",         rarity = "Common",    zones = {"Lake", "River"}, kg = {0.1, 0.8}, price = 10,  difficulty = 1, baits = {"Worm"} },
	{ name = "Roach",         rarity = "Common",    zones = {"Lake"},          kg = {0.1, 0.5}, price = 12,  difficulty = 1, baits = {"Worm", "Corn"} },
	{ name = "Crucian Carp",  rarity = "Common",    zones = {"Lake"},          kg = {0.2, 1.5}, price = 10,  difficulty = 1, baits = {"Worm", "Corn"} },
	{ name = "Bream",         rarity = "Uncommon",  zones = {"Lake"},          kg = {0.5, 4},   price = 14,  difficulty = 2, baits = {"Worm", "Corn"} },
	{ name = "Tench",         rarity = "Uncommon",  zones = {"Lake"},          kg = {0.5, 3},   price = 18,  difficulty = 2, baits = {"Worm", "Corn"} },
	{ name = "Carp",          rarity = "Rare",      zones = {"Lake"},          kg = {2, 20},    price = 15,  difficulty = 3, baits = {"Corn"} },
	{ name = "Pike",          rarity = "Rare",      zones = {"Lake", "River"}, kg = {1, 15},    price = 20,  difficulty = 3, baits = {"Lure", "Shrimp"} },
	{ name = "Grass Carp",    rarity = "Epic",      zones = {"Lake"},          kg = {5, 35},    price = 18,  difficulty = 4, baits = {"Corn"} },
	{ name = "Wels Catfish",  rarity = "Epic",      zones = {"Lake", "River"}, kg = {10, 120},  price = 12,  difficulty = 5, baits = {"Worm", "Shrimp"}, night = true },
	{ name = "Golden Koi",    rarity = "Legendary", zones = {"Lake"},          kg = {3, 15},    price = 250, difficulty = 4, baits = {"Corn"} },
	-- River
	{ name = "Chub",          rarity = "Common",    zones = {"River"},         kg = {0.2, 2},   price = 12,  difficulty = 1, baits = {"Worm", "Corn"} },
	{ name = "Dace",          rarity = "Common",    zones = {"River"},         kg = {0.1, 0.4}, price = 15,  difficulty = 1, baits = {"Worm"} },
	{ name = "Grayling",      rarity = "Uncommon",  zones = {"River"},         kg = {0.3, 2},   price = 25,  difficulty = 2, baits = {"Worm", "Lure"} },
	{ name = "Brown Trout",   rarity = "Uncommon",  zones = {"River"},         kg = {0.5, 5},   price = 22,  difficulty = 2, baits = {"Worm", "Lure"} },
	{ name = "Asp",           rarity = "Rare",      zones = {"River"},         kg = {1, 8},     price = 28,  difficulty = 3, baits = {"Lure"} },
	{ name = "Zander",        rarity = "Rare",      zones = {"River"},         kg = {1, 12},    price = 30,  difficulty = 3, baits = {"Lure", "Shrimp"}, night = true },
	{ name = "Sturgeon",      rarity = "Epic",      zones = {"River"},         kg = {10, 80},   price = 25,  difficulty = 5, baits = {"Worm", "Shrimp"} },
	{ name = "Taimen",        rarity = "Legendary", zones = {"River"},         kg = {10, 60},   price = 60,  difficulty = 5, baits = {"Lure"} },
	-- Sea
	{ name = "Mackerel",      rarity = "Common",    zones = {"Sea"},           kg = {0.2, 1.5}, price = 12,  difficulty = 1, baits = {"Worm", "Shrimp"} },
	{ name = "Herring",       rarity = "Common",    zones = {"Sea"},           kg = {0.1, 0.6}, price = 14,  difficulty = 1, baits = {"Worm", "Shrimp"} },
	{ name = "Sea Bass",      rarity = "Uncommon",  zones = {"Sea"},           kg = {1, 8},     price = 22,  difficulty = 2, baits = {"Shrimp", "Lure"} },
	{ name = "Cod",           rarity = "Uncommon",  zones = {"Sea"},           kg = {1, 15},    price = 18,  difficulty = 2, baits = {"Worm", "Shrimp"} },
	{ name = "Halibut",       rarity = "Rare",      zones = {"Sea"},           kg = {5, 60},    price = 20,  difficulty = 3, baits = {"Shrimp"} },
	{ name = "Giant Squid",   rarity = "Epic",      zones = {"Sea"},           kg = {10, 100},  price = 20,  difficulty = 4, baits = {"Shrimp", "Lure"}, night = true },
	{ name = "Tuna",          rarity = "Epic",      zones = {"Sea"},           kg = {20, 250},  price = 15,  difficulty = 5, baits = {"Lure"} },
	{ name = "Marlin",        rarity = "Legendary", zones = {"Sea"},           kg = {50, 500},  price = 20,  difficulty = 5, baits = {"Lure"} },
}

-- power = width of the green zone in the reel minigame (0..1); luck boosts rare odds; maxKg = comfortable weight
Config.Rods = {
	Basic  = { name = "Basic Rod",  price = 0,     power = 0.25, luck = 0, maxKg = 5 },
	Carbon = { name = "Carbon Rod", price = 500,   power = 0.30, luck = 1, maxKg = 25 },
	Pro    = { name = "Pro Rod",    price = 2500,  power = 0.35, luck = 2, maxKg = 100 },
	Legend = { name = "Legend Rod", price = 12000, power = 0.42, luck = 4, maxKg = 600 },
}
Config.RodOrder = {"Basic", "Carbon", "Pro", "Legend"}

-- price 0 = free and unlimited; otherwise price buys a pack of `pack` baits
Config.Baits = {
	Worm   = { name = "Worm",   price = 0,   pack = 0,  luck = 0, biteSpeed = 1.0 },
	Corn   = { name = "Corn",   price = 30,  pack = 10, luck = 0, biteSpeed = 1.2 },
	Shrimp = { name = "Shrimp", price = 60,  pack = 10, luck = 1, biteSpeed = 1.2 },
	Lure   = { name = "Lure",   price = 150, pack = 10, luck = 2, biteSpeed = 1.4 },
}
Config.BaitOrder = {"Worm", "Corn", "Shrimp", "Lure"}

function Config.GetFish(name)
	for _, f in ipairs(Config.Fish) do
		if f.name == name then return f end
	end
end

function Config.GetRarity(id)
	for _, r in ipairs(Config.Rarities) do
		if r.id == id then return r end
	end
end

function Config.IsNight(clockTime)
	return clockTime < 6 or clockTime >= 18
end

return Config
