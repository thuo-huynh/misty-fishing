-- Tutorial (src/shared/Tutorial.luau): các bước hướng dẫn 5 phút đầu, sự kiện vào -> bước tiếp theo trong Player Profile.
local Tutorial = require("../src/shared/Tutorial")
local ProfileData = require("../src/server/ProfileData")

local function byId(list)
	local t = {}
	for _, r in list do t[r.id] = r end
	return t
end

local function content()
	local c = { list = {}, balance = require("../content/balance") }
	for _, kind in { "species", "zones", "rods", "lines", "baits" } do
		c.list[kind] = require(`../content/{kind}`)
		c[kind] = byId(c.list[kind])
	end
	return c
end

-- chạy một chuỗi sự kiện từ người chơi mới; trả profile data
local function play(c, events)
	local d = ProfileData.new(c)
	for _, e in events do
		if e.kind == "landed" then ProfileData.addCatch(d, c, { species = e.species, kg = 0.1, zone = "lake", time = 0 }) end
		if e.kind == "sold" then ProfileData.sellBag(d, c, function() return 1 end) end
		Tutorial.advance(d, c, e)
	end
	return d
end

local CAST, SELL, BUY = { kind = "cast" }, { kind = "sold" }, { kind = "bought", item = "baits" }
local function landed(species) return { kind = "landed", species = species } end

return {
	["người chơi mới bắt đầu ở bước quăng, có lời nhắc chỉ về bến"] = function()
		local d = ProfileData.new(content())
		local h = Tutorial.hint(d.tutorialStep)
		assert(h and h.text == "Tut_Cast" and h.target == "SpawnDock", "bước đầu phải là quăng ở bến")
	end,

	["đi đủ các bước: quăng, câu, bán, mua Bait, câu loài khác thì xong và không còn lời nhắc"] = function()
		local c = content()
		local d = play(c, { CAST, landed("perch"), SELL, BUY, landed("roach") })
		assert(Tutorial.done(d), `phải xong, đang ở bước {d.tutorialStep}`)
		assert(Tutorial.hint(d.tutorialStep) == nil, "xong rồi thì không hiện")
	end,

	["lời nhắc chỉ về chợ khi bán và về tiệm Bait khi mua"] = function()
		local c = content()
		assert(Tutorial.hint(play(c, { CAST, landed("perch") }).tutorialStep).target == "SellNPC")
		assert(Tutorial.hint(play(c, { CAST, landed("perch"), SELL }).tutorialStep).target == "BaitShop")
	end,

	["sự kiện sai bước thì không đổi bước"] = function()
		local c = content()
		local d = play(c, { SELL, BUY, landed("perch") })
		assert(d.tutorialStep == 0, `ra {d.tutorialStep}`)
		d = play(c, { CAST, landed("perch"), SELL, { kind = "bought", item = "rods" } })
		assert(Tutorial.hint(d.tutorialStep).target == "BaitShop", "mua Rod không tính là mua Bait")
	end,

	["câu lại cùng loài cá đầu thì chưa xong"] = function()
		local c = content()
		local d = play(c, { CAST, landed("perch"), SELL, BUY, landed("perch") })
		assert(not Tutorial.done(d), "phải là loài khác")
	end,

	["bán xong được bù đủ Coins mua gói Bait rẻ nhất"] = function()
		local c = content()
		local d = play(c, { CAST, landed("perch"), SELL })
		assert(d.coins == 30, `Corn giá 30, ra {d.coins}`)
		assert(ProfileData.buy(d, c, "baits", "corn"), "phải mua được Corn")
	end,

	["chỉ bù Coins lúc vừa vào bước mua Bait, không bù lại mỗi sự kiện sau đó"] = function()
		local c = content()
		local d = play(c, { CAST, landed("perch"), SELL })
		d.coins = 0
		Tutorial.advance(d, c, { kind = "bought", item = "rods" })
		assert(d.coins == 0, `không được bù lại, ra {d.coins}`)
	end,

	["bỏ qua ở bất kỳ bước nào thì xong luôn"] = function()
		local c = content()
		assert(Tutorial.done(play(c, { { kind = "skip" } })))
		assert(Tutorial.done(play(c, { CAST, landed("perch"), { kind = "skip" } })))
	end,

	["advance trả true chỉ khi bước đổi"] = function()
		local c = content()
		local d = ProfileData.new(c)
		assert(Tutorial.advance(d, c, CAST) == true)
		assert(Tutorial.advance(d, c, CAST) == false)
	end,

	["lượt câu đầu chắc chắn: loài Common ăn Bait đó ở Zone đó, cân nhẹ nhất"] = function()
		local c = content()
		local d = ProfileData.new(c)
		local fish, kg = Tutorial.forcedCatch(d, c, "lake", c.baits.worm)
		assert(fish and fish.id == "perch" and kg == 0.1, "Worm ở Lake: Perch 0.1 kg")
		assert(Tutorial.forcedCatch(d, c, "sea", c.baits.worm) == nil, "không có loài hợp thì câu bình thường")
		d = play(c, { CAST, landed("perch") })
		assert(Tutorial.forcedCatch(d, c, "lake", c.baits.worm) == nil, "chỉ lượt câu đầu")
	end,
}
