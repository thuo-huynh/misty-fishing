-- Mô phỏng kéo cá (#7): chạy Tension.step tới khi có kết quả, với hạt ngẫu nhiên cố định.
local Tension = require("../src/shared/Rules/Tension")
local tuning = require("../content/balance").tension

local function byId(list)
	local t = {}
	for _, r in list do t[r.id] = r end
	return t
end
local species = byId(require("../content/species"))
local rods = byId(require("../content/rods"))
local lines = byId(require("../content/lines"))

-- LCG cố định để test lặp lại được
local function seeded(seed)
	return function()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
end

local DT = 0.1

-- policy(state) -> có giữ hay không; trả về kết quả cuối, số bước, và số lần Tension tăng khi đang thả
local function play(fish, kg, rod, line, policy)
	local rng = seeded(42)
	local input = { species = fish, kg = kg, rod = rod, line = line, dt = DT, rng = rng, tuning = tuning }
	local state = Tension.start(30, fish, rng, tuning)
	local spikes = 0
	for i = 1, 6000 do
		input.holding = policy(state)
		local before = state.tension
		local outcome
		state, outcome = Tension.step(state, input)
		if not input.holding and state.tension > before then spikes += 1 end
		if outcome ~= "reeling" then return outcome, i, spikes end
	end
	return "reeling", 6000, spikes
end

return {
	["không giữ thì cá thoát (escaped)"] = function()
		local outcome = play(species.perch, 0.5, rods.basic, lines.basic, function() return false end)
		assert(outcome == "escaped", `ra {outcome}`)
	end,

	["giữ liên tục với cá nặng và Line yếu thì dây đứt (snapped)"] = function()
		local outcome = play(species.carp, 18, rods.basic, lines.basic, function() return true end)
		assert(outcome == "snapped", `ra {outcome}`)
	end,

	["giữ hợp lý (thả khi căng, chừa chỗ cho cú vùng vẫy) thì kéo được cá lên (landed)"] = function()
		local outcome = play(species.bream, 3, rods.basic, lines.basic, function(s) return s.tension < 0.4 end)
		assert(outcome == "landed", `ra {outcome}`)
	end,

	["cá vùng vẫy làm Tension tăng vọt, cá khỏe vùng vẫy nhiều hơn"] = function()
		-- thả liên tục: Tension chỉ tăng khi cá vùng vẫy; tính số lần mỗi bước vì cá khỏe thoát sớm hơn
		local function spikeRate(fish)
			local _, steps, spikes = play(fish, 1, rods.basic, lines.braided, function() return false end)
			return spikes / steps
		end
		local weak, strong = spikeRate(species.perch), spikeRate(species.wels_catfish)
		assert(weak > 0, "cá yếu cũng phải vùng vẫy")
		assert(strong > weak * 2, `cá khỏe vùng vẫy {strong} lần, cá yếu {weak} lần`)
	end,
}
