-- Fishing Session (pure): one player's cast state machine, idle -> waiting -> bite -> reeling -> idle.
-- No Roblox APIs and no requires (tested by Lune): time `now` (seconds) and `rng` are passed in,
-- Fishing Rules come in through new(Catch, Tension, content) with content = { species, balance }.
local FishingSession = {}

local TICK = 0.1 -- seconds per Tension.step while reeling

function FishingSession.new(catch, tension, content)
	return { state = "idle", catch = catch, tension = tension, content = content }
end

-- req = { holdingRod, distance (studs), zone (Zone ID or falsy), bait, baitLeft, rod, line, hour }.
-- Returns true, or false plus the reason's text key and its args (localization/UI.csv). Does not use up the Bait.
function FishingSession.cast(s, req, now, rng)
	local balance = s.content.balance
	if s.state ~= "idle" then return false, "Cast_AlreadyFishing" end
	if not req.holdingRod then return false, "Cast_EquipRod" end
	if req.distance > balance.maxCastDistance then return false, "Cast_TooFar" end
	if not req.zone then return false, "Cast_NotWater" end
	if req.baitLeft <= 0 then return false, "Cast_OutOfBait", { bait = req.bait.name } end
	local fish, kg = s.catch.roll(s.content, { zone = req.zone, bait = req.bait, rod = req.rod, hour = req.hour }, rng)
	if not fish then return false, "Cast_NoBite", { bait = req.bait.name } end
	s.state, s.fish, s.kg, s.zone, s.bait, s.rod, s.line = "waiting", fish, kg, req.zone, req.bait, req.rod, req.line
	s.biteAt = now + s.catch.biteDelay(balance, req.bait, rng)
	return true
end

-- Call every frame. Returns "bite" when the fish bites, "missed" when the hook window passed;
-- while reeling, "tick" after each Tension step, or the outcome "landed" (+ Catch { fish, kg, zone }) | "snapped" | "escaped"
-- (the session is then back to idle). Else nil.
function FishingSession.update(s, now)
	if s.state == "waiting" and now >= s.biteAt then
		s.state, s.hookUntil = "bite", now + s.content.balance.hookWindow
		return "bite"
	elseif s.state == "bite" and now > s.hookUntil then
		FishingSession.cancel(s)
		return "missed"
	elseif s.state == "reeling" and now - s.reelAt >= TICK then
		local tuning = s.content.balance.tension
		local input = { holding = s.holding, species = s.fish, kg = s.kg, rod = s.rod, line = s.line, dt = TICK, rng = s.rng, tuning = tuning }
		local outcome = "reeling"
		while outcome == "reeling" and now - s.reelAt >= TICK do -- fixed step, catches up after a slow frame
			s.reel, outcome = s.tension.step(s.reel, input)
			s.reelAt += TICK
		end
		if outcome == "reeling" then return "tick" end
		local catch = if outcome == "landed" then { fish = s.fish, kg = s.kg, zone = s.zone } else nil
		FishingSession.cancel(s)
		return outcome, catch
	end
	return nil
end

-- Player strikes: hooks the fish only during the hook window. rng drives the fish's thrashes while reeling.
function FishingSession.hook(s, now, rng)
	if s.state ~= "bite" or now > s.hookUntil then return false end
	local tuning = s.content.balance.tension
	s.state, s.reelAt, s.holding, s.rng = "reeling", now, false, rng
	s.reel = s.tension.start(tuning.startDistance, s.fish, rng, tuning)
	return true
end

-- Client holds (true) or releases (false) the reel button.
function FishingSession.reel(s, holding)
	s.holding = holding == true
end

local RATE, BURST = 5, 10 -- client events per second, max burst

-- Token bucket shared by all of this player's fishing remotes; false = drop the event.
function FishingSession.allow(s, now)
	s.tokens = math.min(BURST, (s.tokens or BURST) + (now - (s.tokensAt or now)) * RATE)
	s.tokensAt = now
	if s.tokens < 1 then return false end
	s.tokens -= 1
	return true
end

-- Back to idle from any state (reel in, unequip, death, leave, lost fight).
function FishingSession.cancel(s)
	s.state, s.fish, s.kg, s.zone, s.bait, s.rod, s.line = "idle", nil, nil, nil, nil, nil, nil
	s.biteAt, s.hookUntil, s.reel, s.reelAt, s.holding, s.rng = nil, nil, nil, nil, nil, nil
end

return FishingSession
