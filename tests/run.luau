-- Chạy mọi tests/**/*.spec.luau; thoát mã 1 nếu có test hỏng (hoặc không tìm thấy test nào).
local fs = require("@lune/fs")
local process = require("@lune/process")

local failed, passed = 0, 0

local function runDir(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			runDir(path)
		elseif name:match("%.spec%.luau$") then
			-- require tương đối với file này (tests/run.luau)
			local modulePath = "./" .. path:sub(#"tests/" + 1):gsub("%.luau$", "")
			local ok, cases = pcall(require, modulePath)
			if not ok then
				failed += 1
				print(`FAIL {path} (không load được): {cases}`)
				continue
			end
			for caseName, fn in cases do
				local caseOk, err = pcall(fn)
				if caseOk then
					passed += 1
					print(`ok   {path} > {caseName}`)
				else
					failed += 1
					print(`FAIL {path} > {caseName}\n     {err}`)
				end
			end
		end
	end
end

runDir("tests")
print(`\n{passed} passed, {failed} failed`)
process.exit(if failed > 0 or passed == 0 then 1 else 0)
