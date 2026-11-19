-- Lines, in shop order. `id` never changes once shipped (ADR 0003).
-- price 0 = owned from the start; maxTension = Tension the Line holds before it snaps
return {
	{ id = "basic",   name = "Basic Line",   price = 0,   maxTension = 100 },
	{ id = "braided", name = "Braided Line", price = 400, maxTension = 160 },
}
