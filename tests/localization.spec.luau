-- Bảng dịch localization/UI.csv (Rojo biến thành LocalizationTable "UI"): mọi key dùng trong src phải có bản tiếng Anh.
local fs = require("@lune/fs")

-- shortcut: tách CSV theo dấu phẩy, không hỗ trợ ô có ngoặc kép; test dưới bắt dòng lệch cột
local function rows()
	local out, header = {}, nil
	for line in string.gmatch(fs.readFile("localization/UI.csv"), "[^\r\n]+") do
		local cells = string.split(line, ",")
		if not header then
			header = cells
		else
			assert(#cells == #header, `dòng lệch cột (có dấu phẩy trong chữ?): {line}`)
			local r = {}
			for i, h in header do r[h] = cells[i] end
			table.insert(out, r)
		end
	end
	return out
end

local function srcFiles(dir, out)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then srcFiles(path, out) elseif path:match("%.luau?$") then table.insert(out, path) end
	end
	return out
end

return {
	["mỗi dòng có Key không trùng và chữ tiếng Anh"] = function()
		local seen = {}
		for _, r in rows() do
			assert(r.Key ~= "" and not seen[r.Key], `Key trống hoặc trùng: {r.Key}`)
			assert(r.en ~= "" and r.Source ~= "", `{r.Key}: thiếu Source/en`)
			seen[r.Key] = true
		end
	end,

	["mọi key dạng Nhom_Ten viết trong src đều có trong bảng"] = function()
		local keys = {}
		for _, r in rows() do keys[r.Key] = true end
		local found = 0
		for _, path in srcFiles("src", {}) do
			for key in string.gmatch(fs.readFile(path), "\"(%u%a+_%u%w*)\"") do
				found += 1
				assert(keys[key], `{path}: key "{key}" chưa có trong localization/UI.csv`)
			end
		end
		assert(found > 20, `chỉ thấy {found} key trong src`)
	end,
}
