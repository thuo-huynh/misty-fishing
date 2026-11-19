-- Fishing Session: máy trạng thái lượt câu phía server (src/server/FishingSession.luau).
local FishingSession = require("../src/server/FishingSession")
local Catch = require("../src/shared/Rules/Catch")

local content = {
	species = require("../content/species"),
	balance = require("../content/balance"),
}
local baits = {}
for _, b in require("../content/baits") do baits[b.id] = b end
local rods = {}
for _, r in require("../content/rods") do rods[r.id] = r end

-- nguồn ngẫu nhiên cố định: trả lần lượt các số cho trước
local function fixed(...)
	local seq, i = { ... }, 0
	return function()
		i += 1
		return assert(seq[i], "rng hết số")
	end
end

-- lượt quăng hợp lệ ở Lake bằng Worm; ghi đè từng trường để thử lý do từ chối
local function request(over)
	local r = { holdingRod = true, distance = 10, zone = "lake", bait = baits.worm, baitLeft = math.huge, rod = rods.basic, hour = 12 }
	for k, v in over or {} do r[k] = v end
	return r
end

-- quăng thành công lúc t = 0: Perch, chờ 3 s (Worm, rng 0)
local function waiting()
	local s = FishingSession.new(Catch, content)
	assert(FishingSession.cast(s, request(), 0, fixed(0.1, 0, 0)))
	return s
end

return {
	["cast: từ chối và báo lý do khi không quăng được"] = function()
		local cases = {
			{ { holdingRod = false }, "Equip your rod first" },
			{ { distance = 81 }, "Too far!" },
			{ { zone = false }, "Cast into the water" }, -- false: zoneAt found no ZoneId,
			{ { bait = baits.corn, baitLeft = 0 }, "Out of Corn" },
			{ { zone = "sea" }, "Nothing bites Worm here. Try another bait." },
		}
		for _, c in cases do
			local s = FishingSession.new(Catch, content)
			local ok, msg = FishingSession.cast(s, request(c[1]), 0, fixed(0.1, 0, 0))
			assert(not ok and msg == c[2], `muốn "{c[2]}", ra {ok} "{msg}"`)
			assert(s.state == "idle", "từ chối thì vẫn idle")
		end
	end,

	["cast: hợp lệ thì sang waiting, đã chọn cá và thời điểm cắn"] = function()
		local s = FishingSession.new(Catch, content)
		local ok = FishingSession.cast(s, request(), 100, fixed(0.1, 0, 0))
		assert(ok == true and s.state == "waiting", `ra {s.state}`)
		assert(s.fish.id == "perch" and s.zone == "lake", "cá sai")
		assert(s.biteAt == 103, `biteAt {s.biteAt}`)
	end,

	["cast: mỗi người chơi chỉ một lượt câu"] = function()
		local s = waiting()
		local ok, msg = FishingSession.cast(s, request(), 1, fixed(0.1, 0, 0))
		assert(not ok and msg == "Already fishing", msg)
	end,

	["update: cá cắn đúng lúc, giật trong hookWindow thì sang reeling"] = function()
		local s = waiting()
		assert(FishingSession.update(s, 2.9) == nil and s.state == "waiting", "chưa tới lúc cắn")
		assert(FishingSession.update(s, 3) == "bite" and s.state == "bite", "phải cắn lúc 3 s")
		assert(FishingSession.update(s, 3.5) == nil, "chỉ báo cắn một lần")
		assert(FishingSession.hook(s, 4.5) and s.state == "reeling", "giật trong 1.5 s phải dính")
	end,

	["hook: giật trước khi cá cắn thì không dính"] = function()
		local s = waiting()
		assert(not FishingSession.hook(s, 1) and s.state == "waiting", "chưa cắn")
	end,

	["update: giật chậm thì cá thoát, về idle"] = function()
		local s = waiting()
		FishingSession.update(s, 3)
		assert(FishingSession.update(s, 4.6) == "escaped" and s.state == "idle", `ra {s.state}`)
		assert(not FishingSession.hook(s, 4.6), "cá đã thoát")
	end,

	["finishReel: thắng minigame thì trả Catch, về idle"] = function()
		local s = waiting()
		FishingSession.update(s, 3)
		FishingSession.hook(s, 3.5)
		local c = FishingSession.finishReel(s, 6, true)
		assert(c and c.fish.id == "perch" and c.zone == "lake" and c.kg == 0.1, "Catch sai") -- rng 0: Perch nhẹ nhất 0.1 kg
		assert(s.state == "idle", "phải về idle")
		assert(FishingSession.finishReel(s, 7, true) == nil, "không nhận Catch hai lần")
	end,

	["finishReel: báo thắng quá nhanh hoặc thua thì không có Catch"] = function()
		for _, c in { { 4.9, true }, { 6, false } } do
			local s = waiting()
			FishingSession.update(s, 3)
			FishingSession.hook(s, 3.5)
			assert(FishingSession.finishReel(s, c[1], c[2]) == nil and s.state == "idle", `{c[1]} {c[2]}`)
		end
	end,

	["cancel: thu cần giữa chừng về idle, quăng lại được"] = function()
		local s = waiting()
		FishingSession.cancel(s)
		assert(s.state == "idle" and FishingSession.update(s, 10) == nil, "phải hủy hẳn")
		assert(FishingSession.cast(s, request(), 10, fixed(0.1, 0, 0)), "quăng lại được")
	end,

	["allow: giới hạn tần suất sự kiện từ client"] = function()
		local s = FishingSession.new(Catch, content)
		local n = 0
		for _ = 1, 20 do
			if FishingSession.allow(s, 0) then n += 1 end
		end
		assert(n == 10, `burst 10, ra {n}`)
		assert(not FishingSession.allow(s, 0.1), "chưa hồi đủ 1 lượt")
		assert(FishingSession.allow(s, 0.2), "5 lượt/s: sau 0.2 s có lại 1 lượt")
	end,
}
