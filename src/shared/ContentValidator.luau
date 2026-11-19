-- Content Validator (spec #1): kiểm tra toàn bộ content, không phụ thuộc Roblox để chạy được cả trong Lune/CI.
-- validate(content, published) -> { errors = {string}, warnings = {string} }
--   content: { species, zones, rods, lines, baits = {records}, balance = { rarities = {records} } }
--   published: { [kind] = {Content ID} } — content/published.luau, chỉ được thêm vào (ADR 0003)
local ContentValidator = {}

local KINDS = { "species", "zones", "rods", "lines", "baits", "rarities" }

function ContentValidator.validate(content, published)
	local errors, warnings = {}, {}
	local function err(msg) table.insert(errors, msg) end

	local lists = table.clone(content)
	lists.rarities = content.balance.rarities

	-- index theo Content ID; báo ID trùng
	local byId = {}
	for _, kind in KINDS do
		byId[kind] = {}
		for _, r in lists[kind] do
			if byId[kind][r.id] then err(`{kind}: Content ID '{r.id}' bị trùng`) end
			byId[kind][r.id] = r
		end
	end

	-- ID đã phát hành phải còn (ẩn thì được, xóa thì không)
	for _, kind in KINDS do
		for _, id in published[kind] or {} do
			if not byId[kind][id] then err(`{kind}: Content ID '{id}' đã phát hành nhưng bị mất (chỉ được ẩn, không được xóa/đổi tên)`) end
		end
	end

	for kind, label in { species = "Species", rods = "Rod", lines = "Line", baits = "Bait" } do
		for _, r in lists[kind] do
			if r.price < 0 then err(`{label} '{r.id}' có giá âm ({r.price})`) end
		end
	end

	for _, s in lists.species do
		local who = `Species '{s.id}'`
		local min, max = s.kg[1], s.kg[2]
		if min <= 0 or max <= 0 then err(`{who} có cân nặng ≤ 0 ({min}–{max} kg)`) end
		if min > max then err(`{who} có cân nặng min ({min}) lớn hơn max ({max})`) end
		if not byId.rarities[s.rarity] then err(`{who} có độ hiếm '{s.rarity}' không hợp lệ`) end
		for _, z in s.zones do
			if not byId.zones[z] then err(`{who} tham chiếu Zone '{z}' không tồn tại`) end
		end
		for _, b in s.baits do
			if not byId.baits[b] then err(`{who} tham chiếu Bait '{b}' không tồn tại`) end
		end
	end

	-- eats[zone][bait] = true khi có Species không ẩn ăn Bait đó ở Zone đó
	-- dayEats: như eats nhưng chỉ tính loài ăn ban ngày
	local eats, dayEats = {}, {}
	for _, s in lists.species do
		if s.hidden then continue end
		for _, z in s.zones do
			eats[z], dayEats[z] = eats[z] or {}, dayEats[z] or {}
			for _, b in s.baits do
				eats[z][b] = true
				if not s.night then dayEats[z][b] = true end
			end
		end
	end
	for _, s in lists.species do
		if s.hidden then continue end
		if not s.model then table.insert(warnings, `Species '{s.id}' chưa có model`) end
		if not s.night then continue end
		for _, z in s.zones do
			for _, b in s.baits do
				if not (dayEats[z] or {})[b] then
					table.insert(warnings, `Species '{s.id}' chỉ ăn ban đêm, nhưng ban ngày ở Zone '{z}' không có loài nào ăn Bait '{b}'`)
				end
			end
		end
	end
	for _, z in lists.zones do
		if z.hidden then continue end
		if not eats[z.id] then
			err(`Zone '{z.id}' không có Species nào`)
			continue -- khỏi báo thêm từng Bait của Zone trống
		end
		for _, b in lists.baits do
			if not b.hidden and not eats[z.id][b.id] then
				err(`Zone '{z.id}' + Bait '{b.id}': không có Species nào ăn`)
			end
		end
	end

	return { errors = errors, warnings = warnings }
end

-- checkMap(zones, waters) -> {string}: đối chiếu map với content (#13, ADR 0001).
--   zones: content/zones.luau; waters: { { name = tên part, zoneId = attribute ZoneId (có thể nil) } }
function ContentValidator.checkMap(zones, waters)
	local errors = {}
	local known, used = {}, {}
	for _, z in zones do known[z.id] = true end
	for _, w in waters do
		if known[w.zoneId] then
			used[w.zoneId] = true
		elseif w.zoneId == nil then
			table.insert(errors, `Vùng nước '{w.name}' chưa có attribute ZoneId`)
		else
			table.insert(errors, `Vùng nước '{w.name}' có ZoneId '{w.zoneId}' không tồn tại trong content`)
		end
	end
	for _, z in zones do
		if not z.hidden and not used[z.id] then
			table.insert(errors, `Zone '{z.id}' chưa có vùng nước nào trong map`)
		end
	end
	return errors
end

return ContentValidator
