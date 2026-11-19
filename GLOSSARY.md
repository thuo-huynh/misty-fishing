# Misty Fishing

Game câu cá trên Roblox lấy cảm hứng từ các game mô phỏng câu cá: người chơi câu cá ở nhiều vùng nước, bán cá và nâng cấp đồ câu.

Thuật ngữ in đậm là tên chính thức, dùng thống nhất trong trò chuyện, tài liệu và code. Các từ trong _Tránh dùng_ không nên dùng để chỉ cùng khái niệm.

## Thuật ngữ

### Nội dung

**Content** (Nội dung):
Mọi thứ Content Designer định nghĩa để tạo nên thế giới game, như loài cá, vùng câu, cần, dây, mồi, được tách riêng khỏi logic game.
_Tránh dùng_: Data, config, settings

**Content ID**:
Tên cố định của một nội dung mà tiến trình người chơi tham chiếu tới; không bao giờ đổi kể cả khi tên hiển thị thay đổi.
_Tránh dùng_: Key, name, slug

**Species** (Loài cá):
Một loài cá được định nghĩa trong content, gồm độ hiếm, khoảng cân nặng, nơi sống và mồi ưa thích.
_Tránh dùng_: Fish type, "cá" (khi muốn nói về loài)

**Zone** (Vùng câu):
Một vùng nước được định nghĩa trong content, quyết định loài nào có thể câu được ở đó; map đánh dấu vị trí của từng vùng.
_Tránh dùng_: Area, region, fishing spot

**Tackle** (Bộ đồ câu):
Bốn món đồ người chơi dùng để câu: một Rod, một Line, một Float và một Bait.
_Tránh dùng_: Equipment, loadout, gear set

**Rod** (Cần câu):
Món đồ câu quyết định độ bền và may mắn khi câu.
_Tránh dùng_: Pole, fishing rod (trong code)

**Line** (Dây câu):
Món đồ câu quyết định độ căng tối đa trước khi dây đứt.
_Tránh dùng_: String, fishing line

**Float** (Phao):
Món đồ câu quyết định mồi nằm ở tầng nước nào (mặt, giữa, đáy) và độ nhạy khi cá cắn.
_Tránh dùng_: Bobber, phao câu (trong code)

**Bait** (Mồi):
Món đồ câu quyết định loài nào sẽ cắn câu; mồi giả (lure) cũng là một loại Bait.
_Tránh dùng_: Lure (như một ô trang bị riêng), hook

### Đội ngũ

**Content Designer**:
Thành viên tạo và cân bằng content.
_Tránh dùng_: Game designer, người làm data

**Builder**:
Thành viên dựng map và model 3D.
_Tránh dùng_: Mapper, artist

### Lối chơi

**Catch** (Con cá bắt được):
Một con cá cụ thể người chơi đã câu lên, có cân nặng, thời điểm và nơi bắt riêng.
_Tránh dùng_: "cá" (khi muốn nói về một con cụ thể), item, loot

**Tension** (Độ căng dây):
Mức dây đang bị kéo khi người chơi kéo cá vào; căng quá thì dây đứt.
_Tránh dùng_: Pressure, stress, strain

**Level** (Cấp độ):
Cấp kinh nghiệm câu cá của người chơi, tăng nhờ câu được cá, dùng để mở khóa vùng câu mới.
_Tránh dùng_: Rank, tier, XP level

**Coins** (Xu):
Loại tiền duy nhất trong game, kiếm được khi bán cá và dùng để mua đồ câu.
_Tránh dùng_: Money, cash, gold

**Collection** (Bộ sưu tập):
Ghi chép mọi loài người chơi đã câu được, kèm con nặng nhất của từng loài.
_Tránh dùng_: Fishdex, album, journal

**Daily Quest** (Nhiệm vụ hằng ngày):
Một mục tiêu câu cá nhỏ, đặt lại mỗi ngày, thưởng Coins khi hoàn thành.
_Tránh dùng_: Mission, task, challenge
