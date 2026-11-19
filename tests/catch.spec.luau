-- Fishing Rules: chọn loài cắn câu, thời gian chờ, giá bán (src/shared/Rules/Catch.luau).
local Catch = require("../src/shared/Rules/Catch")

local content = {
	species = require("../content/species"),
	balance = require("../content/balance"),
}
local baits = {}
for _, b in require("../content/baits") do baits[b.id] = b end
local rods = {}
for _, r in require("../content/rods") do rods[r.id] = r end

local function near(a, b) return math.abs(a - b) < 1e-9 end

-- nguồn ngẫu nhiên cố định: trả lần lượt các số cho trước
local function fixed(...)
	local seq, i = { ... }, 0
	return function()
		i += 1
		return assert(seq[i], "rng hết số")
	end
end

return {
	["odds: lọc theo Zone, Bait, giờ; trọng số theo độ hiếm"] = function()
		-- Lake + Worm ban ngày: Perch, Roach (common 60), Bream, Tench (uncommon 25); Wels Catfish chỉ ban đêm
		local odds = Catch.odds(content, { zone = "lake", bait = baits.worm, rod = rods.basic, hour = 12 })
		assert(near(odds.perch, 30 / 85) and near(odds.roach, 30 / 85), "common sai")
		assert(near(odds.bream, 12.5 / 85) and near(odds.tench, 12.5 / 85), "uncommon sai")
		assert(odds.wels_catfish == nil and odds.carp == nil, "loài không ăn Worm / ban đêm lọt vào")
	end,

	["odds: ban đêm có thêm loài chỉ cắn ban đêm"] = function()
		local odds = Catch.odds(content, { zone = "lake", bait = baits.worm, rod = rods.basic, hour = 23 })
		assert(odds.wels_catfish and odds.wels_catfish > 0, "Wels Catfish phải cắn ban đêm")
	end,

	["odds: may mắn (Rod cộng Bait) nâng độ hiếm cao, tổng vẫn bằng 1"] = function()
		local plain = Catch.odds(content, { zone = "lake", bait = baits.corn, rod = rods.basic, hour = 12 })
		local lucky = Catch.odds(content, { zone = "lake", bait = baits.corn, rod = rods.carbon, hour = 12 })
		assert(lucky.golden_koi > plain.golden_koi and lucky.carp > plain.carp, "độ hiếm cao phải tăng")
		assert(lucky.roach < plain.roach, "common phải giảm")
		-- legendary tăng theo tỉ lệ nhiều hơn rare
		assert(lucky.golden_koi / plain.golden_koi > lucky.carp / plain.carp, "may mắn phải nâng hạng hiếm hơn nhiều hơn")
		local sum = 0
		for _, p in lucky do sum += p end
		assert(near(sum, 1), `tổng xác suất {sum}`)
	end,

	["odds: rỗng khi không loài nào ăn mồi"] = function()
		local odds = Catch.odds(content, { zone = "sea", bait = baits.worm, rod = rods.basic, hour = 12 })
		assert(next(odds) == nil, "phải rỗng")
	end,

	["roll: chọn loài theo nguồn ngẫu nhiên cố định"] = function()
		local day = { zone = "lake", bait = baits.worm, rod = rods.basic, hour = 12 }
		-- thứ tự: Perch .353, Roach .706, Bream .853, Tench 1
		assert(Catch.roll(content, day, fixed(0.1, 0)).id == "perch", "0.1 -> Perch")
		local s, kg = Catch.roll(content, day, fixed(0.8, 0))
		assert(s.id == "bream" and kg == 0.5, `0.8 -> Bream 0.5kg, ra {s.id} {kg}`)
		assert(Catch.roll(content, day, fixed(0.99, 0)).id == "tench", "0.99 -> Tench")
	end,

	["roll: cân nặng lệch về phía nhẹ, làm tròn 0.01 kg"] = function()
		-- Pike 1..15 kg; điểm giữa ngẫu nhiên (0.5) phải nhẹ hơn điểm giữa khoảng (8 kg)
		local s, kg = Catch.roll(content, { zone = "lake", bait = baits.lure, rod = rods.basic, hour = 12 }, fixed(0, 0.5))
		assert(s.id == "pike" and kg == 4.5, `ra {s.id} {kg}`)
		local _, top = Catch.roll(content, { zone = "lake", bait = baits.lure, rod = rods.basic, hour = 12 }, fixed(0, 0.999999))
		assert(top <= 15 and top > 14.9, `max {top}`)
	end,

	["roll: nil khi không loài nào ăn mồi"] = function()
		assert(Catch.roll(content, { zone = "sea", bait = baits.worm, rod = rods.basic, hour = 12 }, fixed()) == nil, "phải nil")
	end,

	["biteDelay: ngẫu nhiên trong khoảng 3..10 s, chia tốc độ cắn của Bait"] = function()
		assert(near(Catch.biteDelay(content.balance, baits.worm, fixed(0)), 3), "Worm, rng 0 -> 3 s")
		assert(near(Catch.biteDelay(content.balance, baits.worm, fixed(0.5)), 6.5), "Worm, rng 0.5 -> 6.5 s")
		assert(near(Catch.biteDelay(content.balance, baits.lure, fixed(1)), 10 / 1.4), "Lure nhanh hơn 1.4 lần")
	end,

	["sellPrice: giá mỗi kg x cân nặng, làm tròn xuống, tối thiểu 1"] = function()
		assert(Catch.sellPrice({ price = 15 }, 2.29) == 34, "15 x 2.29 = 34.35 -> 34")
		assert(Catch.sellPrice({ price = 10 }, 0.05) == 1, "dưới 1 Coin -> 1")
		assert(Catch.sellPrice({ price = 100 }, 0.29) == 29, "0.29 x 100 không được ra 28 vì sai số số thực")
	end,
}
