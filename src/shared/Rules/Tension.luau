-- Reeling simulation: pure time-step function, no Roblox APIs. Randomness comes in as rng() -> [0, 1).
-- State: { tension = 0..1 of line.maxTension, distance = studs to the fish, nextThrash = seconds until the next thrash }
-- Outcome: "reeling" | "landed" | "snapped" | "escaped". Constants live in content/balance.luau `tension`.
local Tension = {}

local function thrashDelay(species, rng, tuning)
	return tuning.thrashInterval / species.difficulty * (0.5 + rng())
end

function Tension.start(distance, species, rng, tuning)
	return { tension = 0, distance = distance, nextThrash = thrashDelay(species, rng, tuning) }
end

-- input = { holding, species, kg, rod, line, dt, rng, tuning }
function Tension.step(state, input)
	local tuning, species, dt = input.tuning, input.species, input.dt
	local tension, distance = state.tension, state.distance

	-- fish force relative to what the Line holds
	local load = (input.kg * tuning.kgForce + species.difficulty * tuning.difficultyForce) / input.line.maxTension

	if input.holding then
		tension += tuning.riseRate * load * dt
		distance -= input.rod.pull * dt
	else
		tension = math.max(0, tension - tuning.relaxRate * dt)
		distance += tuning.fleeSpeed * species.difficulty * dt
	end

	local nextThrash = state.nextThrash - dt
	if nextThrash <= 0 then
		tension += tuning.thrashSpike * load
		nextThrash += thrashDelay(species, input.rng, tuning)
	end

	local outcome = if tension >= 1
		then "snapped"
		elseif distance <= 0 then "landed"
		elseif distance >= tuning.escapeDistance then "escaped"
		else "reeling"
	return { tension = tension, distance = distance, nextThrash = nextThrash }, outcome
end

return Tension
