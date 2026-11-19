# Content Spec: Misty Fishing

Danh mục **toàn bộ content** của game: map, cảnh vật, điểm câu, loài cá, Tackle, NPC, tiến trình. Từ danh mục này rút ra danh sách feature ở mục 10.

- **Người chốt:** Content Designer. Bản này là **nháp v1**: số liệu (cân nặng, giá, chỉ số) là đề xuất, sẽ cân bằng khi playtest.
- **Quy ước:** tên hiển thị tiếng Anh (game ra mắt tiếng Anh trước), mô tả tiếng Việt. `id` là **Content ID**, đặt một lần và không bao giờ đổi ([ADR 0003](adr/0003-stable-content-ids.md)).
- **Ký hiệu giai đoạn:** **MVP** = đã có trong code; **GĐ2** = trước ra mắt; **Sau** = cập nhật sau ra mắt.
- Thuật ngữ in đậm theo [GLOSSARY.md](../GLOSSARY.md).

## 1. Bối cảnh

Thung lũng **Misty Vale**: một vùng hồ, sông, đầm lầy và bờ biển quanh năm phủ sương. Sương dày lúc bình minh và ban đêm, mỏng vào giữa trưa. Người dân kể rằng trong sương có những con cá "chỉ hiện ra khi sương dày nhất". Đó là nhóm cá **huyền thoại** (Legendary) của game.

Giọng điệu: yên tĩnh, hơi bí ẩn, chân thật. Cá thường là cá có thật; chỉ cá Legendary mới mang màu sắc huyền thoại.

## 2. Map (Zone)

Mỗi map là một **Zone**: một vùng nước có loài cá riêng. Người chơi mở map mới bằng **Level**.

| id | Tên hiển thị | Loại nước | Level mở | Phong cách | Giai đoạn |
|---|---|---|---|---|---|
| `lake` | Mistmere Lake | Nước ngọt, nước đứng | 1 | Hồ rừng thông, sương sớm, bến gỗ | MVP |
| `river` | Willowrun River | Nước ngọt, nước chảy | 5 | Sông uốn quanh rặng liễu, ghềnh đá, cầu đá cũ | GĐ2 |
| `swamp` | Fogmarsh | Nước ngọt, đầm lầy | 10 | Đầm sương dày, cây bách đầm, đèn lồng, nhà sàn | GĐ2 |
| `coast` | Greywater Coast | Nước mặn, ven bờ | 15 | Bờ đá xám, cầu tàu dài, ngọn hải đăng | GĐ2 |
| `deep_sea` | Abyssal Shelf | Nước mặn, nước sâu | 25 | Giàn câu ngoài khơi, sóng lớn, sương biển | GĐ2 |

Thay đổi so với plan cũ: từ 3 map (Lake, River, Sea) lên **5 map**. `sea` cũ được tách thành `coast` và `deep_sea`.

### 2.1. Cảnh vật từng map (cho Builder)

| Map | Cây và thực vật | Địa hình, công trình | Ánh sáng, không khí |
|---|---|---|---|
| Mistmere Lake | Thông, bạch dương, lau sậy ven bờ, bèo súng | Bến gỗ (điểm xuất phát), chòi bán cá, quầy đồ câu, xuồng gỗ neo bờ | Sương sớm xanh xám, nắng xiên qua tán thông |
| Willowrun River | Liễu rủ, dương xỉ, rêu trên đá | Ghềnh đá, bãi sỏi, cầu đá cũ, cối xay nước | Sáng hơn hồ, sương mỏng trên mặt nước chảy |
| Fogmarsh | Bách đầm (cây có rễ nhô), cỏ lác, nấm phát sáng | Lối ván gỗ, nhà sàn, đèn lồng treo | Sương rất dày, tông xanh lục, ban đêm có đom đóm |
| Greywater Coast | Cỏ biển, thông biển lùn | Vách đá, cầu tàu dài, hải đăng, nhà thuyền | Gió, sóng vỗ, sương mặn màu xám bạc |
| Abyssal Shelf | Không có cây | Giàn câu nổi ngoài khơi, tàu chở khách từ Coast ra | Trời u ám, nước xanh đen, sương biển dày |

### 2.2. Công trình bắt buộc mỗi map

Builder gắn tag cho các phần này. Code đã đọc các tag MVP.

| Công trình | Tag / attribute | Ghi chú | Giai đoạn |
|---|---|---|---|
| Điểm xuất phát | `SpawnDock` | Chỗ người chơi xuất hiện | MVP |
| Vùng nước câu được | `FishingZone` + `ZoneId` | Một map có thể có nhiều part nước cùng `ZoneId` | MVP |
| Chỗ bán cá | `SellNPC` | | MVP |
| Cửa hàng Rod / Line / Bait | `RodShop` + `RodId`, `LineShop` + `LineId`, `BaitShop` + `BaitId` | Mỗi món là một quầy | MVP |
| Cửa hàng Float | `FloatShop` + `FloatId` | Mới | GĐ2 |
| Điểm câu (Spot) | `FishingZone` + `ZoneId` + `SpotId` | Xem mục 3 | GĐ2 |
| Cổng di chuyển nhanh | `TravelPoint` + `ZoneId` | Biển chỉ đường hoặc thuyền | GĐ2 |

## 3. Điểm câu (Spot), đề xuất

Một Zone có nhiều **điểm câu** khác nhau. Cùng một hồ, câu ở bãi sậy ra loài khác câu ở hố sâu. Spot là một phần của vùng nước, gắn `SpotId`, và **tăng tỉ lệ** một số loài. Nó không mở thêm loài mới.

| Zone | Spot | Đặc điểm | Tăng tỉ lệ |
|---|---|---|---|
| lake | `reeds` (Bãi sậy) | Nước nông có cây | Perch, Rudd, Tench |
| lake | `deep_hole` (Hố sâu) | Giữa hồ | Carp, Wels Catfish |
| lake | `dock` (Quanh bến) | Gần chỗ xuất phát | Roach, Bream |
| river | `rapids` (Ghềnh) | Nước chảy xiết | Grayling, Brown Trout, Asp |
| river | `pool` (Vực nước) | Nước chậm, sâu | Barbel, Zander, Chub |
| swamp | `lily_pads` (Bèo súng) | Mặt nước phủ bèo | Snakehead, Crucian Carp |
| swamp | `sunken_trees` (Cây chìm) | Gốc cây dưới nước | European Eel, Lantern Eel |
| coast | `pier` (Cầu tàu) | Nước sâu vừa | Mackerel, Herring, Garfish |
| coast | `rocks` (Bờ đá) | Đá ngầm | Sea Bass, Conger Eel |
| deep_sea | `shelf_edge` (Mép thềm) | Rất sâu | Ling, Monkfish, Abyss Lantern |

Quyết định cần chốt khi làm: Spot có hiện tên trên màn hình khi người chơi đứng gần không (đề xuất: có).

## 4. Loài cá (Species)

### 4.1. Họ cá (chủng loại)

| Họ | Ví dụ | Kiểu kéo |
|---|---|---|
| Cá chép (Cyprinidae) | Roach, Bream, Carp, Tench | Kéo đều, khỏe dần theo cân nặng |
| Cá rô (Percidae) | Perch, Zander | Giật ngắn, dễ |
| Cá chó (Esocidae) | Pike | Lao mạnh từng đợt, ăn mồi giả |
| Cá trê, cá nheo (Siluridae) | Wels Catfish | Rất nặng, kéo lâu, chủ yếu ban đêm |
| Cá hồi (Salmonidae) | Brown Trout, Grayling | Nhanh, hay vùng vẫy |
| Cá lóc (Channidae) | Snakehead | Lao mạnh gần mặt nước |
| Cá chình (Anguillidae, Congridae) | European Eel, Conger Eel | Vặn mình, kéo về đáy |
| Cá biển ven bờ | Mackerel, Sea Bass, Flounder, Cod | Đa dạng |
| Cá biển sâu | Tuna, Swordfish, Ling, Monkfish | Rất khỏe, cần Tackle cao cấp |
| **Huyền thoại** | Golden Koi, Mist Sturgeon, Lantern Eel, Pearl Bream, Abyss Lantern | Mỗi con một kiểu riêng, chỉ ra khi có sương dày hoặc ban đêm |

### 4.2. Tầng nước

Mỗi loài sống ở một tầng: **mặt** (surface), **giữa** (mid) hoặc **đáy** (bottom). **Float** quyết định mồi nằm ở tầng nào (xem 5.3). Đây là lý do có ô Float.

### 4.3. Danh sách loài

Cột: Hiếm (C = Common, U = Uncommon, R = Rare, E = Epic, L = Legendary), cân nặng (kg), giá mỗi kg (Coins), độ khó kéo (1–5), giờ (Ngày / Đêm / Cả ngày), mồi ưa thích.

**Mistmere Lake** (10 loài)

| id | Tên | Họ | Hiếm | kg | Giá/kg | Tầng | Mồi | Giờ | Khó | GĐ |
|---|---|---|---|---|---|---|---|---|---|---|
| `perch` | Perch | Cá rô | C | 0.1–0.8 | 10 | giữa | worm, maggot | Ngày | 1 | MVP |
| `roach` | Roach | Cá chép | C | 0.1–0.5 | 12 | giữa | worm, corn, bread | Cả ngày | 1 | MVP |
| `rudd` | Rudd | Cá chép | C | 0.1–0.6 | 12 | mặt | bread, maggot | Ngày | 1 | GĐ2 |
| `bream` | Bream | Cá chép | U | 0.5–4 | 14 | đáy | worm, corn | Cả ngày | 2 | MVP |
| `tench` | Tench | Cá chép | U | 0.5–3 | 18 | đáy | worm, corn | Cả ngày | 2 | MVP |
| `crucian_carp` | Crucian Carp | Cá chép | U | 0.2–1.5 | 16 | đáy | bread, corn | Ngày | 2 | GĐ2 |
| `carp` | Carp | Cá chép | R | 2–20 | 15 | đáy | corn, boilie | Cả ngày | 3 | MVP |
| `pike` | Pike | Cá chó | R | 1–15 | 20 | giữa | lure, minnow | Ngày | 3 | MVP |
| `wels_catfish` | Wels Catfish | Cá nheo | E | 10–120 | 12 | đáy | worm, minnow | Đêm | 5 | MVP |
| `golden_koi` | Golden Koi | Huyền thoại | L | 3–15 | 250 | giữa | corn | Bình minh có sương | 4 | MVP |

**Willowrun River** (9 loài)

| id | Tên | Họ | Hiếm | kg | Giá/kg | Tầng | Mồi | Giờ | Khó |
|---|---|---|---|---|---|---|---|---|---|
| `chub` | Chub | Cá chép | C | 0.3–3 | 14 | giữa | bread, maggot | Ngày | 2 |
| `ide` | Ide | Cá chép | C | 0.3–2.5 | 15 | giữa | worm, maggot | Ngày | 2 |
| `grayling` | Grayling | Cá hồi | U | 0.2–1.5 | 30 | mặt | maggot, fly_lure | Ngày | 2 |
| `barbel` | Barbel | Cá chép | U | 1–8 | 18 | đáy | worm, boilie | Cả ngày | 3 |
| `asp` | Asp | Cá chép | R | 1–7 | 24 | mặt | spinner | Ngày | 3 |
| `brown_trout` | Brown Trout | Cá hồi | R | 0.5–6 | 35 | giữa | worm, spinner | Bình minh, hoàng hôn | 3 |
| `zander` | Zander | Cá rô | R | 1–10 | 26 | đáy | minnow, lure | Đêm | 3 |
| `burbot` | Burbot | Cá tuyết sông | E | 1–12 | 30 | đáy | minnow, worm | Đêm | 4 |
| `mist_sturgeon` | Mist Sturgeon | Huyền thoại | L | 20–90 | 60 | đáy | worm | Đêm có sương | 5 |

**Fogmarsh** (7 loài)

| id | Tên | Họ | Hiếm | kg | Giá/kg | Tầng | Mồi | Giờ | Khó |
|---|---|---|---|---|---|---|---|---|---|
| `weatherfish` | Weatherfish | Cá chạch | C | 0.05–0.3 | 25 | đáy | worm, maggot | Cả ngày | 1 |
| `crucian_carp` | (dùng chung với Lake) | | | | | | | | |
| `european_eel` | European Eel | Cá chình | U | 0.5–4 | 28 | đáy | worm, minnow | Đêm | 3 |
| `snakehead` | Snakehead | Cá lóc | R | 1–8 | 26 | mặt | frog_lure, minnow | Ngày | 4 |
| `grass_carp` | Grass Carp | Cá chép | R | 3–30 | 14 | giữa | bread, corn | Ngày | 3 |
| `bighead_carp` | Bighead Carp | Cá chép | E | 10–50 | 12 | giữa | bread, boilie | Cả ngày | 4 |
| `lantern_eel` | Lantern Eel | Huyền thoại | L | 2–10 | 220 | đáy | minnow | Đêm | 5 |

**Greywater Coast** (8 loài)

| id | Tên | Họ | Hiếm | kg | Giá/kg | Tầng | Mồi | Giờ | Khó |
|---|---|---|---|---|---|---|---|---|---|
| `herring` | Herring | Cá biển | C | 0.1–0.5 | 14 | giữa | sandworm, shrimp | Ngày | 1 |
| `mackerel` | Mackerel | Cá biển | C | 0.3–1.5 | 16 | giữa | shrimp, spinner | Ngày | 2 |
| `flounder` | Flounder | Cá biển | U | 0.3–3 | 22 | đáy | sandworm | Cả ngày | 2 |
| `garfish` | Garfish | Cá biển | U | 0.3–1.5 | 26 | mặt | shrimp, spinner | Ngày | 3 |
| `sea_bass` | Sea Bass | Cá biển | R | 1–9 | 30 | giữa | shrimp, lure | Bình minh, hoàng hôn | 3 |
| `cod` | Cod | Cá biển | R | 2–25 | 20 | đáy | squid, sandworm | Cả ngày | 3 |
| `conger_eel` | Conger Eel | Cá chình | E | 5–60 | 18 | đáy | squid | Đêm | 5 |
| `pearl_bream` | Pearl Bream | Huyền thoại | L | 2–8 | 260 | giữa | shrimp | Bình minh có sương | 4 |

**Abyssal Shelf** (7 loài)

| id | Tên | Họ | Hiếm | kg | Giá/kg | Tầng | Mồi | Giờ | Khó |
|---|---|---|---|---|---|---|---|---|---|
| `pollock` | Pollock | Cá biển sâu | C | 1–8 | 16 | giữa | squid, jig | Cả ngày | 2 |
| `ling` | Ling | Cá biển sâu | U | 3–30 | 18 | đáy | squid | Cả ngày | 3 |
| `monkfish` | Monkfish | Cá biển sâu | R | 3–40 | 22 | đáy | squid, live_bait | Đêm | 4 |
| `halibut` | Halibut | Cá biển sâu | R | 5–100 | 20 | đáy | squid, jig | Cả ngày | 4 |
| `bluefin_tuna` | Bluefin Tuna | Cá biển sâu | E | 30–300 | 20 | giữa | live_bait | Ngày | 5 |
| `swordfish` | Swordfish | Cá biển sâu | E | 40–250 | 22 | mặt | live_bait, squid | Đêm | 5 |
| `abyss_lantern` | Abyss Lantern | Huyền thoại | L | 10–60 | 120 | đáy | live_bait | Đêm có sương | 5 |

**Tổng:** 40 loài (10 + 9 + 6 riêng + 1 dùng chung + 8 + 7). Plan cũ ghi "khoảng 25", spec này nâng lên 40 vì có 5 map.

### 4.4. Quy tắc cân bằng loài

- Mỗi map có khoảng 40% Common, 25% Uncommon, 20% Rare, 10% Epic và 1 Legendary.
- Cá Legendary chỉ cắn khi có **sương dày** (bình minh hoặc đêm). Đây là nét riêng của Misty Fishing.
- Map mở sau thì giá mỗi kg cao hơn, để người chơi có lý do đi tiếp.
- Mỗi loài có ít nhất một mồi **rẻ** câu được, trừ Epic và Legendary.

## 5. Tackle (4 ô trang bị)

Tackle gồm 4 ô: **Rod**, **Line**, **Float**, **Bait**. Thay đổi so với MVP: thêm **Float**. Ticket #37 (Reel là ô thứ tư) cần sửa: nếu làm Reel thì nó thành ô thứ năm.

### 5.1. Rod (Cần câu)

Chỉ số: `power` (tốc độ kéo cá lại gần), `luck` (tăng tỉ lệ cá hiếm), `maxKg` (cá nặng hơn mức này dễ làm gãy nhịp kéo), `pull` (lực kéo mỗi nhịp), `cast` (khoảng quăng, mét).

| id | Tên | Giá | Level | power | luck | maxKg | pull | cast | GĐ |
|---|---|---|---|---|---|---|---|---|---|
| `basic` | Basic Rod | 0 | 1 | 0.25 | 0 | 5 | 6 | 30 | MVP |
| `carbon` | Carbon Rod | 500 | 1 | 0.30 | 1 | 25 | 9 | 40 | MVP |
| `river_spinner` | River Spinner | 1,500 | 5 | 0.35 | 1 | 15 | 9 | 45 | GĐ2 |
| `marsh_reed` | Marsh Reed Rod | 3,500 | 10 | 0.35 | 2 | 50 | 11 | 35 | GĐ2 |
| `surf_caster` | Surf Caster | 7,000 | 15 | 0.40 | 2 | 60 | 12 | 70 | GĐ2 |
| `deep_boat` | Deep Boat Rod | 15,000 | 25 | 0.45 | 3 | 300 | 16 | 40 | GĐ2 |
| `mistwood` | Mistwood Rod | 40,000 | 30 | 0.50 | 5 | 300 | 18 | 60 | GĐ2 |

### 5.2. Line (Dây câu)

Chỉ số: `maxTension` (độ căng tối đa trước khi đứt).

| id | Tên | Giá | Level | maxTension | GĐ |
|---|---|---|---|---|---|
| `basic` | Basic Line | 0 | 1 | 100 | MVP |
| `mono_plus` | Mono Plus | 200 | 3 | 130 | GĐ2 |
| `braided` | Braided Line | 400 | 1 | 160 | MVP |
| `fluorocarbon` | Fluorocarbon | 2,500 | 12 | 220 | GĐ2 |
| `titan_braid` | Titan Braid | 9,000 | 22 | 320 | GĐ2 |

### 5.3. Float (Phao), ô mới

Float quyết định **tầng nước** của mồi (mục 4.2) và **độ nhạy**: phao nhạy thì thời gian giật cần dài hơn một chút.

| id | Tên | Giá | Level | Tầng | Độ nhạy (giây giật cần thêm) | GĐ |
|---|---|---|---|---|---|---|
| `cork` | Cork Float | 0 | 1 | giữa | +0 | GĐ2 |
| `surface_quill` | Surface Quill | 150 | 2 | mặt | +0.2 | GĐ2 |
| `bottom_sinker` | Bottom Sinker | 150 | 2 | đáy | +0 | GĐ2 |
| `sliding_float` | Sliding Float | 1,200 | 8 | chọn được giữa / đáy | +0.3 | GĐ2 |
| `glow_float` | Glow Float | 2,000 | 10 | giữa | +0.5 ban đêm | GĐ2 |

Quy tắc:
- Mồi giả (lure, spinner, jig...) **bỏ qua Float**: tự chạy ở tầng của nó. Đây là cách câu Pike và Asp.
- Trước khi có ô Float (MVP), mọi lượt câu coi như tầng "giữa", và mọi loài cắn được ở mọi tầng.

### 5.4. Bait (Mồi)

Chỉ số: `price` (giá một gói), `pack` (số lượt trong gói), `luck`, `biteSpeed` (cá cắn nhanh hơn), loại (tự nhiên / mồi giả), tầng (chỉ mồi giả).

| id | Tên | Loại | Giá | Gói | luck | biteSpeed | Nước | GĐ |
|---|---|---|---|---|---|---|---|---|
| `worm` | Worm | tự nhiên | 0 | ∞ | 0 | 1.0 | ngọt | MVP |
| `maggot` | Maggot | tự nhiên | 20 | 10 | 0 | 1.2 | ngọt | GĐ2 |
| `bread` | Bread | tự nhiên | 20 | 10 | 0 | 1.1 | ngọt | GĐ2 |
| `corn` | Corn | tự nhiên | 30 | 10 | 0 | 1.2 | ngọt | MVP |
| `boilie` | Boilie | tự nhiên | 120 | 10 | 1 | 1.1 | ngọt | GĐ2 |
| `minnow` | Minnow | tự nhiên | 90 | 10 | 1 | 1.3 | ngọt | GĐ2 |
| `lure` | Lure | mồi giả (giữa) | 150 | 10 | 2 | 1.4 | ngọt | MVP |
| `spinner` | Spinner | mồi giả (giữa) | 200 | 10 | 2 | 1.4 | cả hai | GĐ2 |
| `fly_lure` | Fly Lure | mồi giả (mặt) | 250 | 10 | 2 | 1.3 | ngọt | GĐ2 |
| `frog_lure` | Frog Lure | mồi giả (mặt) | 300 | 10 | 2 | 1.3 | ngọt | GĐ2 |
| `sandworm` | Sandworm | tự nhiên | 40 | 10 | 0 | 1.2 | mặn | GĐ2 |
| `shrimp` | Shrimp | tự nhiên | 60 | 10 | 1 | 1.2 | mặn | GĐ2 |
| `squid` | Squid | tự nhiên | 150 | 10 | 1 | 1.2 | mặn | GĐ2 |
| `jig` | Jig | mồi giả (đáy) | 400 | 10 | 2 | 1.3 | mặn | GĐ2 |
| `live_bait` | Live Bait | tự nhiên | 600 | 5 | 3 | 1.0 | mặn | GĐ2 |

## 6. NPC và cửa hàng

| Map | Bán cá | Rod | Line | Float | Bait |
|---|---|---|---|---|---|
| Mistmere Lake | Chòi cá | basic, carbon | basic, braided, mono_plus | cork, surface_quill, bottom_sinker | worm, maggot, bread, corn, boilie, lure |
| Willowrun River | Cối xay nước | river_spinner | fluorocarbon | sliding_float | minnow, spinner, fly_lure |
| Fogmarsh | Nhà sàn | marsh_reed | | glow_float | frog_lure |
| Greywater Coast | Nhà thuyền | surf_caster | titan_braid | | sandworm, shrimp, squid |
| Abyssal Shelf | Giàn câu | deep_boat, mistwood | | | jig, live_bait |

Đồ đã mua dùng được ở mọi map. Cửa hàng ở map nào thì bán đồ hợp với map đó.

## 7. Tiến trình

- **Level:** nhận kinh nghiệm theo độ hiếm (C 5, U 12, R 30, E 80, L 250) cộng thưởng lần đầu bắt một loài. Level mở map theo bảng ở mục 2.
- **Túi cá:** 30 con (MVP), Gamepass lên 60.
- **Collection:** 40 loài, chia theo map; hoàn thành một map thì nhận một danh hiệu (Sau).

## 8. Thời gian và sương

- 1 ngày trong game bằng 12 phút thật (MVP đã có).
- Các mốc: Bình minh (05:00–07:00, **sương dày**), Ngày, Hoàng hôn (18:00–20:00), Đêm (**sương dày** từ 0:00 đến 04:00).
- Thời tiết đầy đủ (mưa, gió) để sau ra mắt (#34).

## 9. Model và hình ảnh cần làm (Builder)

- **Model cá:** ưu tiên Rare trở lên (#24), tổng 40. Cá Common có thể dùng chung model đổi màu theo họ.
- **Model Tackle:** 7 Rod, 5 Float (hiện trên dây khi câu), 4 mồi giả.
- **Cảnh vật:** mục 2.1 cho 5 map.

## 10. Feature tổng hợp từ spec

Danh sách này rút từ các mục trên và đối chiếu với ticket hiện có.

| Feature | Nguồn trong spec | Ticket |
|---|---|---|
| Content 5 map, 40 loài, 7 Rod, 5 Line, 5 Float, 15 Bait | 2, 4, 5 | #23 (sửa: từ 3 map / 25 loài lên 5 map / 40 loài) |
| Dựng map River, Swamp, Coast, Deep Sea | 2.1, 2.2 | #24 (sửa: thêm Swamp và Deep Sea) |
| **Ô Float và tầng nước của cá** | 4.2, 5.3 | **Mới** |
| **Điểm câu (Spot) tăng tỉ lệ theo vị trí** | 3 | **Mới** |
| **Nước ngọt / nước mặn cho Bait** | 5.4 | **Mới** (nhỏ, có thể gộp với ô Float) |
| **Cá Legendary chỉ ra khi có sương dày** | 4.4, 8 | **Mới** (gộp với #20 ngày đêm) |
| Level và mở khóa map, di chuyển nhanh | 2, 7 | #19 |
| Chu kỳ ngày đêm, cá theo giờ | 8 | #20 |
| Collection theo map | 7 | #21 |
| Model cá khi kéo lên | 9 | #25 |
| Reel (máy câu) | 5 | #37 (sửa: thành ô thứ năm) |
