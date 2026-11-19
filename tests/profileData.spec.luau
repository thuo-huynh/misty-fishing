-- ProfileData: hình dạng Player Profile và các thao tác có tên, kiểm tra với content thật.
local ProfileData = require("../src/server/ProfileData")

local function byId(list)
	local t = {}
	for _, r in list do t[r.id] = r end
	return t
end

-- Giống Content.luau nhưng không cần Roblox.
local function content()
	local c = { list = {}, balance = require("../content/balance") }
	for _, kind in { "species", "zones", "rods", "lines", "baits" } do
		c.list[kind] = require(`../content/{kind}`)
		c[kind] = byId(c.list[kind])
	end
	return c
end

return {
	["người chơi mới có Basic Rod, Basic Line và trang bị Worm"] = function()
		local d = ProfileData.new(content())
		assert(type(d.version) == "number", "thiếu version")
		assert(d.coins == 0 and d.xp == 0)
		assert(table.find(d.ownedRods, "basic") and table.find(d.ownedLines, "basic"))
		assert(d.equipped.rod == "basic" and d.equipped.line == "basic" and d.equipped.bait == "worm")
		assert(#d.bag == 0 and next(d.collection) == nil and d.tutorialStep == 0)
	end,

	["khi tải: Tackle trang bị đã mất khỏi content về Tackle miễn phí, ID lạ vẫn giữ trong save"] = function()
		local c = content()
		local d = ProfileData.new(c)
		table.insert(d.ownedRods, "gold")
		d.equipped = { rod = "gold", line = "carbon_line", bait = "glow" }
		d.baits.glow = 5
		ProfileData.reconcile(d, c)
		assert(d.equipped.rod == "basic" and d.equipped.line == "basic" and d.equipped.bait == "worm")
		assert(table.find(d.ownedRods, "gold") and d.baits.glow == 5, "ID lạ bị xóa")
	end,

	["khi tải: trang bị Rod chưa sở hữu hoặc Bait đã hết thì về miễn phí"] = function()
		local c = content()
		local d = ProfileData.new(c)
		d.equipped.rod, d.equipped.bait = "carbon", "corn"
		ProfileData.reconcile(d, c)
		assert(d.equipped.rod == "basic" and d.equipped.bait == "worm")
	end,

	["khi tải: save cũ thiếu trường thì được bổ sung, không đụng giá trị đã có"] = function()
		local c = content()
		local d = { version = 1, coins = 42, equipped = { rod = "basic" } }
		ProfileData.reconcile(d, c)
		assert(d.coins == 42 and d.xp == 0 and d.equipped.line == "basic" and d.dailyQuests.day == 0)
	end,

	["mua Rod: trừ Coins, sở hữu và trang bị; thiếu Coins thì không đổi gì"] = function()
		local c = content()
		local d = ProfileData.new(c)
		d.coins = 499
		assert(ProfileData.buy(d, c, "rods", "carbon") == false and d.coins == 499 and d.equipped.rod == "basic")
		d.coins = 600
		assert(ProfileData.buy(d, c, "rods", "carbon") == true)
		assert(d.coins == 100 and ProfileData.owns(d, c, "rods", "carbon") and d.equipped.rod == "carbon")
		-- đã sở hữu thì chỉ trang bị, không trừ thêm
		ProfileData.equip(d, c, "rods", "basic")
		assert(ProfileData.buy(d, c, "rods", "carbon") == true and d.coins == 100 and d.equipped.rod == "carbon")
	end,

	["mua Bait: trừ Coins, cộng một gói và trang bị"] = function()
		local c = content()
		local d = ProfileData.new(c)
		d.coins = 40
		assert(ProfileData.buy(d, c, "baits", "corn") == true)
		assert(d.coins == 10 and d.baits.corn == 10 and d.equipped.bait == "corn")
		assert(ProfileData.buy(d, c, "baits", "worm") == false, "Bait miễn phí không bán")
	end,

	["không trang bị được Tackle chưa sở hữu hay Bait đã hết"] = function()
		local c = content()
		local d = ProfileData.new(c)
		assert(ProfileData.equip(d, c, "lines", "braided") == false and d.equipped.line == "basic")
		assert(ProfileData.equip(d, c, "baits", "lure") == false and d.equipped.bait == "worm")
		d.baits.lure = 1
		assert(ProfileData.equip(d, c, "baits", "lure") == true and d.equipped.bait == "lure")
	end,

	["quăng cần dùng một Bait trả phí; hết thì tự về Worm"] = function()
		local c = content()
		local d = ProfileData.new(c)
		d.baits.corn, d.equipped.bait = 1, "corn"
		assert(ProfileData.takeBait(d, c).id == "corn" and d.baits.corn == 0 and d.equipped.bait == "worm")
		assert(ProfileData.takeBait(d, c).id == "worm" and d.baits.worm == nil)
	end,

	["Catch vào túi và Collection; kỷ lục khi nặng hơn; túi đầy thì từ chối"] = function()
		local c = content()
		local d = ProfileData.new(c)
		local sp = c.list.species[1].id
		local ok, record = ProfileData.addCatch(d, c, { species = sp, kg = 2, zone = "lake", time = 100 })
		assert(ok and record and #d.bag == 1 and d.bag[1].kept == false)
		ok, record = ProfileData.addCatch(d, c, { species = sp, kg = 1, zone = "lake", time = 101 })
		assert(ok and not record and d.collection[sp].count == 2 and d.collection[sp].bestKg == 2)
		for _ = 3, c.balance.bagSize do ProfileData.addCatch(d, c, { species = sp, kg = 1, zone = "lake", time = 1 }) end
		assert(ProfileData.addCatch(d, c, { species = sp, kg = 9, zone = "lake", time = 1 }) == false)
		assert(#d.bag == c.balance.bagSize and d.collection[sp].bestKg == 2)
	end,

	["bán túi: cộng Coins (giá/kg × kg, làm tròn xuống, tối thiểu 1), giữ lại cá khoe và cá của loài đã mất"] = function()
		local c = content()
		local d = ProfileData.new(c)
		local sp = c.list.species[1]
		d.bag = {
			{ species = sp.id, kg = 2.5, zone = "lake", time = 1, kept = false },
			{ species = sp.id, kg = 0.001, zone = "lake", time = 1, kept = false },
			{ species = sp.id, kg = 3, zone = "lake", time = 1, kept = true },
			{ species = "ghost_fish", kg = 3, zone = "lake", time = 1, kept = false },
		}
		local total = ProfileData.sellBag(d, c)
		assert(total == math.floor(2.5 * sp.price) + 1 and d.coins == total, `bán được {total}`)
		assert(#d.bag == 2 and d.bag[1].kept and d.bag[2].species == "ghost_fish")
	end,
}
