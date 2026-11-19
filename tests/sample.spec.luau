-- Test mẫu: mỗi file tests/**/*.spec.luau trả về bảng { ["tên test"] = function() ... end }.
-- Test hỏng khi hàm ném lỗi (assert/error).
return {
	["string.split tách theo dấu phẩy"] = function()
		local parts = string.split("Worm,Corn", ",")
		assert(#parts == 2 and parts[1] == "Worm" and parts[2] == "Corn", "split sai")
	end,
}
