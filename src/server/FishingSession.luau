-- Fishing Session (pure): one player's cast state machine, idle -> waiting -> bite -> reeling -> idle.
-- No Roblox APIs and no requires (tested by Lune): time `now` (seconds) and `rng` are passed in,
-- Fishing Rules come in through new(Catch, content) with content = { species, balance }.
local FishingSession = {}

function FishingSession.new(catch, content)
	return { state = "idle", catch = catch, content = content }
end

-- req = { holdingRod, distance (studs), zone (Zone ID or falsy), bait, baitLeft, rod, hour }.
-- Returns true, or false and the reason to show the player. Does not use up the Bait.
function FishingSession.cast(s, req, now, rng)
	local balance = s.content.balance
	if s.state ~= "idle" then return false, "Already fishing" end
	if not req.holdingRod then return false, "Equip your rod first" end
	if req.distance > balance.maxCastDistance then return false, "Too far!" end
	if not req.zone then return false, "Cast into the water" end
	if req.baitLeft <= 0 then return false, "Out of " .. req.bait.name end
	local fish, kg = s.catch.roll(s.content, { zone = req.zone, bait = req.bait, rod = req.rod, hour = req.hour }, rng)
	if not fish then return false, "Nothing bites " .. req.bait.name .. " here. Try another bait." end
	s.state, s.fish, s.kg, s.zone = "waiting", fish, kg, req.zone
	s.biteAt = now + s.catch.biteDelay(balance, req.bait, rng)
	return true
end

-- Call every frame. Returns "bite" when the fish bites, "escaped" when the hook window passed, else nil.
function FishingSession.update(s, now)
	if s.state == "waiting" and now >= s.biteAt then
		s.state, s.hookUntil = "bite", now + s.content.balance.hookWindow
		return "bite"
	elseif s.state == "bite" and now > s.hookUntil then
		FishingSession.cancel(s)
		return "escaped"
	end
	return nil
end

-- Player strikes: hooks the fish only during the hook window.
function FishingSession.hook(s, now)
	if s.state ~= "bite" or now > s.hookUntil then return false end
	s.state, s.reelStart = "reeling", now
	return true
end

-- shortcut: the draft minigame runs on the client and only reports the result; #10 moves reeling to the server (Tension).
local MIN_REEL = 1.5 -- seconds: the minigame cannot be won faster than this after the hook

-- Client reports the minigame result. Returns the Catch { fish, kg, zone } on a believable win, else nil. Always ends the session.
function FishingSession.finishReel(s, now, success)
	local catch = nil
	if s.state == "reeling" and success == true and now - s.reelStart >= MIN_REEL then
		catch = { fish = s.fish, kg = s.kg, zone = s.zone }
	end
	if s.state == "reeling" then FishingSession.cancel(s) end
	return catch
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
	s.state, s.fish, s.kg, s.zone, s.biteAt, s.hookUntil, s.reelStart = "idle", nil, nil, nil, nil, nil, nil
end

return FishingSession
