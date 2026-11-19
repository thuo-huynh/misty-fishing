-- Content ID đã phát hành tới người chơi. CHỈ ĐƯỢC THÊM VÀO, không xóa/sửa (ADR 0003):
-- dữ liệu lưu của người chơi tham chiếu các ID này. Muốn gỡ nội dung thì đặt `hidden = true` trong bản ghi.
-- Content Validator báo lỗi khi một ID ở đây không còn trong content.
return {
	species = { "perch", "roach", "bream", "tench", "carp", "pike", "wels_catfish", "golden_koi" },
	zones = { "lake" },
	rods = { "basic", "carbon" },
	lines = { "basic", "braided" },
	baits = { "worm", "corn", "lure" },
	rarities = { "common", "uncommon", "rare", "epic", "legendary" },
}
