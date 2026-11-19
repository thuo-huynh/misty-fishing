-- Fishing Session: máy trạng thái lượt câu phía server (src/server/FishingSession.luau).
local FishingSession = require("../src/server/FishingSession")
local Catch = require("../src/shared/Rules/Catch")
local Tension = require("../src/shared/Rules/Tension")

local content = {
	species = require("../content/species"),
	balance = require("../content/balance"),
}
local baits = {}
for _, b in require("../content/baits") do baits[b.id] = b end
local rods = {}
for _, r in require("../content/rods") do rods[r.id] = r end
local lines = {}
for _, l in require("../content/lines") do lines[l.id] = l end

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
	local r = { holdingRod = true, distance = 10, zone = "lake", bait = baits.worm, baitLeft = math.huge, rod = rods.basic, line = lines.basic, hour = 12 }
	for k, v in over or {} do r[k] = v end
	return r
end

-- quăng thành công lúc t = 0: Perch, chờ 3 s (Worm, rng 0)
local function waiting()
	local s = FishingSession.new(Catch, Tension, content)
	assert(FishingSession.cast(s, request(), 0, fixed(0.1, 0, 0)))
	return s
end

-- dính cá lúc t = 3.5 (Perch 0.1 kg); rng 0.5 cho mọi cú vùng vẫy
local function reeling()
	local s = waiting()
	FishingSession.update(s, 3)
	assert(FishingSession.hook(s, 3.5, function() return 0.5 end))
	return s
end

-- chạy update mỗi 1/60 s tới khi có kết quả kéo cá; policy(s) -> có giữ không
local function play(s, policy)
	local t = 3.5
	for _ = 1, 60 * 120 do
		t += 1 / 60
		FishingSession.reel(s, policy(s))
		local event, c = FishingSession.update(s, t)
		if event and event ~= "tick" then return event, c, t end
	end
	error("kéo mãi không xong")
end

return {
	["cast: từ chối và báo lý do khi không quăng được"] = function()
		local cases = {
			{ { holdingRod = false }, "Cast_EquipRod" },
			{ { distance = 81 }, "Cast_TooFar" },
			{ { zone = false }, "Cast_NotWater" }, -- false: zoneAt found no ZoneId,
			{ { bait = baits.corn, baitLeft = 0 }, "Cast_OutOfBait", "Corn" },
			{ { zone = "sea" }, "Cast_NoBite", "Worm" },
		}
		for _, c in cases do
			local s = FishingSession.new(Catch, Tension, content)
			local ok, msg, args = FishingSession.cast(s, request(c[1]), 0, fixed(0.1, 0, 0))
			assert(not ok and msg == c[2], `muốn "{c[2]}", ra {ok} "{msg}"`)
			assert(c[3] == nil or (args and args.bait == c[3]), `{c[2]}: thiếu tên Bait`)
			assert(s.state == "idle", "từ chối thì vẫn idle")
		end
	end,

	["cast: hợp lệ thì sang waiting, đã chọn cá và thời điểm cắn"] = function()
		local s = FishingSession.new(Catch, Tension, content)
		local ok = FishingSession.cast(s, request(), 100, fixed(0.1, 0, 0))
		assert(ok == true and s.state == "waiting", `ra {s.state}`)
		assert(s.fish.id == "perch" and s.zone == "lake", "cá sai")
		assert(s.biteAt == 103, `biteAt {s.biteAt}`)
	end,

	["cast: req.fish ép loài và cân (lượt câu hướng dẫn), không roll"] = function()
		local s = FishingSession.new(Catch, Tension, content)
		local roach = content.species[2]
		assert(FishingSession.cast(s, request({ fish = roach, kg = 0.1 }), 0, fixed(0)), "chỉ còn rng cho thời gian cắn")
		assert(s.fish == roach and s.kg == 0.1, "phải đúng cá ép")
	end,

	["cast: mỗi người chơi chỉ một lượt câu"] = function()
		local s = waiting()
		local ok, msg = FishingSession.cast(s, request(), 1, fixed(0.1, 0, 0))
		assert(not ok and msg == "Cast_AlreadyFishing", msg)
	end,

	["update: cá cắn đúng lúc, giật trong hookWindow thì sang reeling"] = function()
		local s = waiting()
		assert(FishingSession.update(s, 2.9) == nil and s.state == "waiting", "chưa tới lúc cắn")
		assert(FishingSession.update(s, 3) == "bite" and s.state == "bite", "phải cắn lúc 3 s")
		assert(FishingSession.update(s, 3.5) == nil, "chỉ báo cắn một lần")
		assert(FishingSession.hook(s, 4.5, math.random) and s.state == "reeling", "giật trong 1.5 s phải dính")
	end,

	["hook: giật trước khi cá cắn thì không dính"] = function()
		local s = waiting()
		assert(not FishingSession.hook(s, 1) and s.state == "waiting", "chưa cắn")
	end,

	["update: giật chậm thì cá thoát, về idle"] = function()
		local s = waiting()
		FishingSession.update(s, 3)
		assert(FishingSession.update(s, 4.6) == "missed" and s.state == "idle", `ra {s.state}`)
		assert(not FishingSession.hook(s, 4.6), "cá đã thoát")
	end,

	["reel: giữ hợp lý thì kéo được cá lên, trả Catch và về idle"] = function()
		local s = reeling()
		local event, c = play(s, function(x) return x.reel.tension < 0.4 end)
		assert(event == "landed", `ra {event}`)
		assert(c and c.fish.id == "perch" and c.zone == "lake" and c.kg == 0.1, "Catch sai") -- rng 0: Perch nhẹ nhất 0.1 kg
		assert(s.state == "idle", "phải về idle")
	end,

	["reel: giữ mãi với Line quá yếu thì dây đứt, không trả Catch, về idle"] = function()
		local s = FishingSession.new(Catch, Tension, content)
		assert(FishingSession.cast(s, request({ line = { maxTension = 1 } }), 0, fixed(0.1, 0, 0)))
		FishingSession.update(s, 3)
		assert(FishingSession.hook(s, 3.5, function() return 0.5 end))
		local event, c = play(s, function() return true end)
		assert(event == "snapped" and c == nil and s.state == "idle", `ra {event}`)
	end,

	["reel: không giữ thì cá chạy xa rồi thoát, về idle"] = function()
		local s = reeling()
		local event, c = play(s, function() return false end)
		assert(event == "escaped" and c == nil and s.state == "idle", `ra {event}`)
	end,

	["reel: server bước Tension theo nhịp cố định 0.1 s, không theo khung hình"] = function()
		local s = reeling()
		FishingSession.reel(s, true)
		assert(FishingSession.update(s, 3.55) == nil and s.reel.distance == 30, "chưa đủ một nhịp thì chưa kéo")
		assert(FishingSession.update(s, 3.6) == "tick", "đủ một nhịp")
		local d = s.reel.distance
		assert(FishingSession.update(s, 3.85) == "tick", "khung hình chậm")
		assert(math.abs(d - s.reel.distance - 2 * (30 - d)) < 1e-9, "khung hình chậm 0.25 s phải bù đủ hai nhịp")
	end,

	["cancel: thu cần giữa chừng về idle, quăng lại được"] = function()
		local s = waiting()
		FishingSession.cancel(s)
		assert(s.state == "idle" and FishingSession.update(s, 10) == nil, "phải hủy hẳn")
		assert(FishingSession.cast(s, request(), 10, fixed(0.1, 0, 0)), "quăng lại được")
	end,

	["allow: giới hạn tần suất sự kiện từ client"] = function()
		local s = FishingSession.new(Catch, Tension, content)
		local n = 0
		for _ = 1, 20 do
			if FishingSession.allow(s, 0) then n += 1 end
		end
		assert(n == 10, `burst 10, ra {n}`)
		assert(not FishingSession.allow(s, 0.1), "chưa hồi đủ 1 lượt")
		assert(FishingSession.allow(s, 0.2), "5 lượt/s: sau 0.2 s có lại 1 lượt")
	end,
}
