-- Rods, in shop order. `id` never changes once shipped (ADR 0003).
-- price 0 = owned from the start; power = width of the green zone (0..1); luck boosts rare odds; maxKg = comfortable weight
return {
	{ id = "basic",  name = "Basic Rod",  price = 0,   power = 0.25, luck = 0, maxKg = 5 },
	{ id = "carbon", name = "Carbon Rod", price = 500, power = 0.30, luck = 1, maxKg = 25 },
}
