-- Đối chiếu ZoneId trong map với content (#13). Map chỉ gặp content qua ZoneId (ADR 0001).
local Validator = require("../src/shared/ContentValidator")

local zones = { { id = "lake", name = "Lake", level = 1 } }

-- Mỗi vùng nước trong map: tên đầy đủ của part + attribute ZoneId (có thể nil).
local function water(zoneId, name)
	return { name = name or "Workspace.Water", zoneId = zoneId }
end

local function expectOne(list, needle)
	assert(#list == 1, `cần đúng 1, có {#list}: {table.concat(list, " | ")}`)
	assert(list[1]:find(needle, 1, true), `"{list[1]}" không chứa "{needle}"`)
end

return {
	["map khớp content thì không có lỗi"] = function()
		local errors = Validator.checkMap(zones, { water("lake") })
		assert(#errors == 0, table.concat(errors, " | "))
	end,

	["vùng nước có ZoneId không tồn tại trong content là lỗi"] = function()
		local errors = Validator.checkMap(zones, { water("lake"), water("sea", "Workspace.Sea") })
		expectOne(errors, "Vùng nước 'Workspace.Sea' có ZoneId 'sea' không tồn tại trong content")
	end,

	["Zone không ẩn chưa có vùng nước nào trong map là lỗi"] = function()
		local errors = Validator.checkMap({ zones[1], { id = "river", name = "River", level = 5 } }, { water("lake") })
		expectOne(errors, "Zone 'river' chưa có vùng nước nào trong map")
	end,

	["Zone bị ẩn không cần vùng nước"] = function()
		local errors = Validator.checkMap({ zones[1], { id = "river", name = "River", level = 5, hidden = true } }, { water("lake") })
		assert(#errors == 0, table.concat(errors, " | "))
	end,

	["vùng nước thiếu ZoneId là lỗi"] = function()
		local errors = Validator.checkMap(zones, { water("lake"), water(nil, "Workspace.Pond") })
		expectOne(errors, "Vùng nước 'Workspace.Pond' chưa có attribute ZoneId")
	end,
}
