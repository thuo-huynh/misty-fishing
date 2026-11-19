-- Baits, in cycle/shop order. `id` never changes once shipped (ADR 0003).
-- price 0 = free and unlimited; otherwise price buys a pack of `pack` baits
return {
	{ id = "worm", name = "Worm", price = 0,   pack = 0,  luck = 0, biteSpeed = 1.0 },
	{ id = "corn", name = "Corn", price = 30,  pack = 10, luck = 0, biteSpeed = 1.2 },
	{ id = "lure", name = "Lure", price = 150, pack = 10, luck = 2, biteSpeed = 1.4 },
}
