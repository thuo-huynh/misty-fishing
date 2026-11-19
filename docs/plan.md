# Kế hoạch phát triển Misty Fishing

Tài liệu này tổng hợp mọi quyết định đã thống nhất và chia công việc theo giai đoạn cho team 3 người. Thuật ngữ in đậm (như **Species**, **Catch**, **Tension**) được định nghĩa trong [GLOSSARY.md](../GLOSSARY.md).

## 1. Tầm nhìn

Một game câu cá trên Roblox lấy cảm hứng từ Russian Fishing 4: có chiều sâu (dây có thể đứt, mồi quyết định loài cá, cá theo giờ trong ngày) nhưng điều khiển đơn giản, chơi tốt trên điện thoại. Không gian mang tông **"rừng hồ huyền ảo"**: xanh lam, sương mờ, nắng xuyên tán cây.

**Nguyên tắc:**
- Con cá đầu tiên phải tới trong 1 phút.
- Không pay-to-win. Robux chỉ mua tiện ích và đồ trang trí.
- Làm gameplay cho vui trước, đầu tư đồ họa sau.

## 2. Đội ngũ (3 người, khoảng 10 giờ/tuần mỗi người)

| Vai trò | Phụ trách | Làm việc trong |
|---|---|---|
| **Content Designer** (bạn) | Species, Zone, Tackle, nhiệm vụ, giá cả, cân bằng game, điều phối playtest | `content/`, `docs/` |
| **Programmer** | Logic game, UI, lưu dữ liệu, kiểm tra content, review Pull Request | `src/` |
| **Builder** | Map (Terrain, cây, nhà), model cá và cần câu, ánh sáng | Studio (Team Create), `art/`, `models/` |

## 3. Công nghệ

| Phần | Lựa chọn |
|---|---|
| Ngôn ngữ | Luau (ngôn ngữ duy nhất của Roblox) |
| Vật lý | Engine có sẵn của Roblox: `RopeConstraint` hoặc `Beam` cho dây câu, Terrain water cho phao. Độ căng dây là công thức Luau. Không dùng thư viện ngoài. |
| Nước, địa hình | Terrain |
| Ánh sáng | Lighting Future, Atmosphere, ColorCorrection, Bloom, SunRays, DepthOfField |
| Model 3D | Blender, xuất FBX rồi import. Dùng AI gen cho bản mẫu và đồ phụ. |
| UI | Fusion |
| Lưu dữ liệu | ProfileStore |
| Đồng bộ code | Rojo (cài qua Rokit), thư viện cài qua Wally |
| Quản lý code | GitHub private repo, Git LFS cho file 3D |
| Quản lý công việc | GitHub Projects |

## 4. Quyết định đã chốt

1. **Map trên cloud Roblox, code và content trong Git.** Xem [ADR 0001](adr/0001-map-in-cloud-code-in-git.md).
2. **Content là file `.luau`.** Xem [ADR 0002](adr/0002-content-as-luau-files.md).
3. **Mọi nội dung có Content ID cố định.** ID không bao giờ đổi hay xóa. Xem [ADR 0003](adr/0003-stable-content-ids.md).
4. **Game đứng tên một Roblox Group**, không đứng tên tài khoản cá nhân.
5. **Hai place:** **Dev** để cả team test, **Live** cho người chơi thật.
6. **Nhánh `main` được khóa.** Mọi thay đổi đi qua Pull Request và cần 1 người duyệt.
7. **Giao diện game bằng tiếng Anh trước**, thiết kế sẵn để thêm tiếng Việt.
8. **Phát hành trên Roblox toàn cầu.**

## 5. Cấu trúc repository

```
game/
├── content/          ← Content Designer: species, zones, rods, lines, baits, quests (.luau)
├── src/
│   ├── server/       ← Programmer: logic phía server
│   ├── client/       ← Programmer: UI, điều khiển, minigame
│   └── shared/       ← Programmer: code dùng chung, kiểm tra content
├── art/              ← Builder: file .blend, texture (Git LFS)
├── models/           ← Builder: model .rbxm dùng chung (cá, cần câu)
├── docs/
│   ├── adr/          ← Các quyết định lớn
│   ├── plan.md       ← Tài liệu này
│   └── content-guide.md  ← Hướng dẫn thêm nội dung
├── GLOSSARY.md
└── default.project.json
```

## 6. Thiết kế lối chơi

### 6.1. 5 phút đầu tiên
Người chơi xuất hiện ở bến hồ. Hướng dẫn dạy lần lượt: quăng cần, bắt con cá đầu tiên (chắc chắn thành công), bán cá, mua mồi mới, rồi bắt một loài khác.

### 6.2. Vòng lặp chính
Quăng cần → chờ cá cắn → giật cần → kéo cá (giữ **Tension** trong ngưỡng an toàn) → bỏ cá vào túi → bán lấy **Coins** → mua **Tackle** tốt hơn → mở vùng câu mới.

### 6.3. Kéo cá bằng độ căng dây
- Giữ nút thì kéo cá lại gần, nhưng **Tension** tăng dần.
- Cá vùng vẫy làm **Tension** tăng vọt.
- Vượt giới hạn của **Line** thì dây đứt và mất cá.
- Thả nút thì dây chùng, nhưng cá bơi ra xa.
- Chỉ dùng một nút: chuột, chạm màn hình hoặc phím Space.

### 6.4. Tackle (3 ô trang bị)
- **Rod:** độ bền và may mắn (tăng tỉ lệ ra cá hiếm).
- **Line:** độ căng tối đa.
- **Bait:** quyết định loài nào cắn câu.

### 6.5. Tiến trình
- **Level** tăng nhờ câu được cá và dùng để mở vùng mới: Lake ở level 1, River level 5, Sea level 12. Các con số sẽ chốt khi cân bằng game.
- **Coins** dùng mua Tackle. Muốn câu ở vùng mới cần cả Level đủ cao lẫn Tackle đủ tốt.

### 6.6. Kinh tế
- Chỉ có một loại tiền là **Coins**. Giá bán cố định = giá mỗi kg của loài × cân nặng.
- **Gamepass** (Robux): túi lớn hơn, x2 Coins, skin cần. Không đổi Robux thành Coins.

### 6.7. Giữ chân người chơi
- **Daily Quest**, ví dụ "bắt 3 con Perch" hoặc "bắt 1 con Rare".
- **Collection**: các loài đã bắt và kỷ lục cân nặng.
- **Bảng xếp hạng tuần**: con nặng nhất của mỗi loài.
- **Thông báo toàn server** khi có người bắt được cá Epic hoặc Legendary. Người chơi có thể cầm cá lên khoe.

### 6.8. Thời gian và thời tiết
- Chu kỳ ngày đêm: 1 ngày trong game bằng 12 phút thật. Một số loài chỉ cắn câu ban đêm.
- Thời tiết (mưa, sương mù) để bản cập nhật sau khi ra mắt.

### 6.9. Thông tin của một Species
`id`, tên hiển thị, mô tả, độ hiếm (Common, Uncommon, Rare, Epic, Legendary), khoảng cân nặng, giá mỗi kg, các Zone sống, các Bait ưa thích, giờ hoạt động, độ khó khi kéo, model 3D (asset ID). Thời tiết ưa thích sẽ thêm khi có hệ thống thời tiết.

### 6.10. Zone
Content Designer định nghĩa Zone trong `content/zones.luau` (`id`, tên, loại nước, Level yêu cầu). Builder đặt vùng nước trong map và gắn thuộc tính `ZoneId` trùng với id đó. Game báo lỗi nếu map có ZoneId không tồn tại trong content.

## 7. Nội dung lúc ra mắt

| Loại | Số lượng |
|---|---|
| Zone | 3: Lake, River, Sea |
| Species | khoảng 25 |
| Rod | 4 |
| Line | 3 |
| Bait | 5 |

## 8. Quy trình làm việc

### 8.1. Thêm một Species mới (Content Designer)
1. Tạo nhánh Git mới, ví dụ `content/add-golden-carp`.
2. Thêm loài vào `content/species.luau`.
3. Mở Studio và bấm Play. Game tự kiểm tra và báo lỗi nếu có, ví dụ Zone không tồn tại hay cân nặng min lớn hơn max.
4. Tạo Pull Request. GitHub tự kiểm tra lại.
5. Programmer duyệt và gộp vào `main`, rồi đưa lên place Dev để test.

Chi tiết từng bước có hình minh họa sẽ nằm trong `docs/content-guide.md`.

### 8.2. Quy ước Git
- Mỗi việc một nhánh, đặt tên theo người làm: `content/...`, `feature/...` hoặc `fix/...`.
- Mỗi Pull Request làm một việc và cần 1 người duyệt.
- Không ai đẩy thẳng lên `main`.

### 8.3. Playtest hằng tuần
Cuối tuần, cả team và vài người bạn chơi bản Dev khoảng 30 phút rồi điền form góp ý ngắn. Content Designer tổng hợp góp ý và chỉnh cân bằng game.

### 8.4. Model 3D
- **Cá và cần câu:** Builder làm trong Blender để giữ phong cách thống nhất.
- **Đồ phụ và bản mẫu:** được dùng AI gen.
- Mọi model phải được kiểm tra số đa giác trước khi đưa vào game, để không lag trên điện thoại.
- File gốc lưu trong `art/` (Git LFS). Content tham chiếu model bằng asset ID.

## 9. Lộ trình

Tổng thời gian khoảng 3 tháng. Mỗi giai đoạn chỉ kết thúc khi đạt "Điều kiện xong".

### Giai đoạn 0: Chuẩn bị (1 tuần)
| Ai | Việc |
|---|---|
| Cả team | **Xác nhận ít nhất 1 người đăng nhập được Roblox Studio** (rủi ro số 1) |
| Content Designer | Tạo Roblox Group, mời 2 thành viên và phân quyền; tạo bảng GitHub Projects |
| Programmer | Tạo GitHub repo, khóa nhánh `main`, cài Rojo, Wally, Fusion, ProfileStore; dựng cấu trúc thư mục; thiết lập CI kiểm tra code |
| Builder | Tạo experience cùng 2 place Dev và Live trong Group; bật Team Create; cài Blender |

**Điều kiện xong:** cả 3 người clone được repo, chạy Rojo và thấy code đồng bộ vào place Dev.

### Giai đoạn 1: MVP (3–4 tuần)
| Ai | Việc |
|---|---|
| Content Designer | Viết content cho Lake: 8 Species, 2 Rod, 2 Line, 3 Bait; đặt giá và độ hiếm; viết `docs/content-guide.md` cùng Programmer |
| Programmer | Chuyển content sang `content/` dùng Content ID; bộ kiểm tra content; minigame **Tension** có đứt dây; bán cá, Coins; lưu dữ liệu bằng ProfileStore; hướng dẫn 5 phút đầu |
| Builder | Dựng khu hồ đầu tiên (bến, cửa hàng, chỗ bán cá); gắn `ZoneId`; ánh sáng tông "rừng hồ huyền ảo" bản đầu |

**Điều kiện xong:** người chơi mới tự chơi được từ lúc vào game tới khi mua được mồi thứ hai, và **phần lớn người playtest thấy kéo cá vui**. Nếu chưa vui thì chỉnh minigame trước khi sang giai đoạn 2.

### Giai đoạn 2: Mở rộng nội dung (3–4 tuần)
| Ai | Việc |
|---|---|
| Content Designer | Thêm Zone River và Sea, nâng tổng lên khoảng 25 Species, 4 Rod, 3 Line, 5 Bait; cân bằng Level |
| Programmer | Hệ thống Level và mở khóa Zone; giao diện Collection; cá theo giờ ngày đêm |
| Builder | Dựng khu River và Sea; model cá cho các loài Rare trở lên |

**Điều kiện xong:** có đủ 3 Zone, người chơi có mục tiêu khoảng 5–10 giờ chơi.

### Giai đoạn 3: Giữ chân người chơi (2–3 tuần)
| Ai | Việc |
|---|---|
| Content Designer | Thiết kế danh sách Daily Quest và phần thưởng; chọn Gamepass và giá |
| Programmer | Daily Quest; bảng xếp hạng tuần; thông báo cá Epic và Legendary; cầm cá khoe; Gamepass |
| Builder | Bảng xếp hạng trong map; hiệu ứng khi bắt cá hiếm; skin cần cho Gamepass |

**Điều kiện xong:** người playtest có lý do quay lại vào ngày hôm sau.

### Giai đoạn 4: Hoàn thiện và ra mắt (2 tuần)
| Ai | Việc |
|---|---|
| Content Designer | Kiểm tra tên "Misty Fishing" không trùng trên Roblox; viết mô tả game, chuẩn bị ảnh và icon; cân bằng lần cuối |
| Programmer | Tối ưu cho điện thoại (StreamingEnabled, giảm lag); sửa lỗi; đưa bản cuối lên place Live |
| Builder | Hoàn thiện đồ họa và ánh sáng; giảm chi tiết cho máy yếu |

**Điều kiện xong:** game chạy mượt trên điện thoại tầm trung và được công khai trên Roblox.

## 10. Rủi ro

| Rủi ro | Mức độ | Cách xử lý |
|---|---|---|
| Nhà mạng Việt Nam chặn www.roblox.com, không đăng nhập được Studio | **Cao** | Giải quyết đầu tiên ở Giai đoạn 0; ít nhất 1 thành viên phải đăng nhập được để publish |
| Minigame kéo cá không vui | Cao | MVP chỉ tập trung vào điều này; playtest hằng tuần |
| Đồ họa nặng gây lag điện thoại | Trung bình | Kiểm tra số đa giác, dùng StreamingEnabled, test trên điện thoại thật mỗi tuần |
| Đổi hoặc xóa Content ID làm mất dữ liệu người chơi | Trung bình | Quy tắc ID cố định (ADR 0003), bộ kiểm tra content |
| Team 3 người bán thời gian bị chậm tiến độ | Trung bình | Mỗi giai đoạn có "Điều kiện xong" rõ ràng; cắt bớt nội dung thay vì kéo dài thời gian |

## 11. Để sau khi ra mắt
- Hệ thống thời tiết (mưa, sương mù) ảnh hưởng tới Species
- Giải đấu và câu theo nhóm
- Máy câu (ô Tackle thứ 4)
- Giao diện tiếng Việt
- Vùng câu mới
