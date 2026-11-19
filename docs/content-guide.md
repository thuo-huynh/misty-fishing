# Hướng dẫn thêm Content

Tài liệu này dành cho **Content Designer**: người thêm và cân bằng Species, Zone, Rod, Line, Bait mà không cần biết lập trình. Bạn chỉ sửa các file trong thư mục `content/`, mọi thứ còn lại do Programmer lo.

Thuật ngữ (Species, Zone, Content ID, ...) theo `GLOSSARY.md`. Vì sao content là file `.luau` thay vì bảng tính: xem `docs/adr/0002-content-as-luau-files.md`.

## 1. Cài công cụ (làm một lần)

1. **VS Code** (trình sửa file): tải ở https://code.visualstudio.com và cài. Nên cài thêm extension **Luau Language Server** để file `.luau` có màu.
2. **Git**: tải ở https://git-scm.com và cài với lựa chọn mặc định. Bạn cũng cần một tài khoản GitHub có quyền vào repo `misty-fishing`.
3. **Roblox Studio**: cài từ https://create.roblox.com.
4. **Rokit** (cài Rojo và Lune cho bạn): làm theo https://github.com/rojo-rbx/rokit.
5. Lấy repo về máy. Mở VS Code, chọn **Terminal → New Terminal**, rồi gõ:

   ```
   git clone https://github.com/thuo-huynh/misty-fishing.git
   cd misty-fishing
   rokit install
   rojo plugin install
   ```

   `rokit install` cài đúng phiên bản Rojo và Lune ghi trong `rokit.toml`. `rojo plugin install` cài plugin Rojo vào Studio.
6. Trong VS Code chọn **File → Open Folder** và mở thư mục `misty-fishing`.

## 2. Mở game để làm việc (mỗi lần)

1. Trong terminal của VS Code, gõ:

   ```
   rojo serve
   ```

   Để cửa sổ này chạy suốt lúc làm việc. Nó đồng bộ file trên máy vào Studio.
2. Mở Roblox Studio, mở place Dev của team.
3. Mở tab **Plugins**, bấm **Rojo**, rồi bấm **Connect**. Từ giờ mỗi lần bạn lưu file trong VS Code, Studio tự cập nhật.

Muốn dừng: bấm **Disconnect** trong Studio và nhấn `Ctrl+C` trong terminal.

## 3. Tạo nhánh mới

Mỗi việc làm trên một nhánh riêng, không bao giờ sửa thẳng `main`. Mở một terminal mới (giữ `rojo serve` chạy) và gõ:

```
git checkout main
git pull
git checkout -b content/add-golden-carp
```

Đặt tên nhánh bắt đầu bằng `content/` rồi mô tả ngắn việc bạn làm.

## 4. Thêm một Species

Mở `content/species.luau`. Mỗi dòng `{ ... },` là một Species. Thêm một dòng mới **ở cuối danh sách**, trước dấu `}` cuối file. Ví dụ:

```lua
	{ id = "golden_carp", name = "Golden Carp", rarity = "epic", zones = { "lake" }, kg = { 1, 12 }, price = 30, difficulty = 4, baits = { "corn", "lure" }, night = true },
```

Giải thích từng trường:

| Trường | Ví dụ | Ý nghĩa |
|---|---|---|
| `id` | `"golden_carp"` | **Content ID**. Chữ thường, không dấu, dùng `_` thay dấu cách. Không được trùng với Species khác. Sau khi phát hành thì **không bao giờ đổi** (xem mục 5). |
| `name` | `"Golden Carp"` | Tên hiển thị cho người chơi. Đổi thoải mái bất cứ lúc nào. |
| `rarity` | `"epic"` | Độ hiếm. Một trong các `id` ở `rarities` trong `content/balance.luau`: `common`, `uncommon`, `rare`, `epic`, `legendary`. |
| `zones` | `{ "lake" }` | Các Zone loài này sống. Mỗi giá trị là một `id` trong `content/zones.luau`. |
| `kg` | `{ 1, 12 }` | Cân nặng `{ nhỏ nhất, lớn nhất }`, tính bằng kg. Cả hai phải lớn hơn 0 và số đầu không lớn hơn số sau. |
| `price` | `30` | Giá bán, tính bằng Coins **mỗi kg**. Con 5 kg giá 150 Coins. Không được âm. |
| `difficulty` | `4` | Độ khó khi kéo, từ 1 (dễ) đến 5 (rất khó). Càng khó cá càng kéo mạnh và giật nhiều. |
| `baits` | `{ "corn", "lure" }` | Các Bait loài này cắn. Mỗi giá trị là một `id` trong `content/baits.luau`. |
| `night` | `true` | *Không bắt buộc.* `true` = chỉ cắn câu ban đêm (18:00–06:00 giờ trong game). Bỏ trường này đi = cắn cả ngày. |
| `hidden` | `true` | *Không bắt buộc.* `true` = ẩn loài khỏi game (không ai câu được nữa). Dùng thay cho việc xóa. |
| `model` | | *Không bắt buộc, chưa dùng.* Asset ID của model 3D. Khi chưa có, game chỉ hiện cảnh báo "chưa có model". |

Lưu ý khi gõ:
- Chữ phải nằm trong dấu ngoặc kép `"..."`, số thì không.
- Các trường cách nhau bằng dấu phẩy, cuối dòng có `},`.
- Danh sách nhiều giá trị đặt trong `{ }`, ví dụ `{ "worm", "corn" }`.
- Cách dễ nhất: copy một dòng có sẵn rồi sửa giá trị.

## 5. File published.luau: không bao giờ đổi tên hay xóa

`content/published.luau` ghi lại mọi Content ID **đã đến tay người chơi**. Dữ liệu lưu của người chơi chỉ nhớ các ID này, nên nếu một ID biến mất, món đồ đó âm thầm mất khỏi tài khoản của mọi người (`docs/adr/0003-stable-content-ids.md`).

Quy tắc:
- **Không đổi `id`** của thứ đã có trong `published.luau`. Muốn đổi tên thì chỉ sửa `name`.
- **Không xóa** dòng của thứ đã có trong `published.luau`. Muốn gỡ khỏi game thì thêm `hidden = true` vào dòng đó.
- **Không xóa hay sửa** gì trong `published.luau`, chỉ được **thêm vào**.

Khi thêm Species mới, bạn **chưa cần** thêm vào `published.luau`. ID chỉ được thêm vào đó lúc nội dung được đưa lên bản chính thức cho người chơi (Programmer sẽ nhắc). Trước lúc đó bạn vẫn được đổi `id` thoải mái.

Nếu lỡ xóa hay đổi tên, game sẽ báo lỗi kiểu:

```
species: Content ID 'pike' đã phát hành nhưng bị mất (chỉ được ẩn, không được xóa/đổi tên)
```

## 6. Zone, Rod, Line, Bait (tóm tắt)

Cách làm giống Species: copy một dòng có sẵn, sửa giá trị, thêm vào cuối file. `id` luôn theo quy tắc ở mục 5.

**Zone**: `content/zones.luau`
- `id`, `name`: như Species.
- `level`: Level người chơi cần để câu ở đây.
- Builder phải đặt vùng nước trong map với thuộc tính trùng `id` này. Báo Builder khi bạn thêm Zone.

**Rod**: `content/rods.luau`
- `price`: giá Coins; `0` = có sẵn từ đầu.
- `power`: độ rộng vùng xanh khi kéo (0 đến 1, càng lớn càng dễ).
- `luck`: tăng tỉ lệ ra cá hiếm.
- `maxKg`: cân nặng cá mà cần kéo thoải mái.
- `pull`: tốc độ kéo cá vào khi giữ nút.

**Line**: `content/lines.luau`
- `price`: giá Coins; `0` = có sẵn từ đầu.
- `maxTension`: Tension tối đa trước khi dây đứt. Càng lớn càng khó đứt.

**Bait**: `content/baits.luau`
- `price`: giá một gói; `0` = miễn phí, dùng không giới hạn.
- `pack`: số mồi trong một gói.
- `luck`: tăng tỉ lệ ra cá hiếm.
- `biteSpeed`: cá cắn nhanh hơn bao nhiêu lần (1.0 = bình thường).
- Khi thêm Bait mới, **mọi Zone** đều phải có ít nhất một Species ăn Bait đó, nếu không game báo lỗi.

Các con số cân bằng chung (độ hiếm, kích thước túi, độ dài một ngày, ...) nằm trong `content/balance.luau`, mỗi số có chú thích bên cạnh.

## 7. Bấm Play và đọc thông báo

1. Lưu file (`Ctrl+S`). Kiểm tra Rojo vẫn đang Connect.
2. Trong Studio bấm **Play**.
3. Mở cửa sổ **Output** (tab **View → Output**) và tìm các dòng bắt đầu bằng `[Content]`.

Có hai loại thông báo:
- `[Content] Cảnh báo: ...` (vàng): nên xem, nhưng game vẫn chạy.
- `[Content] LỖI: ...` (cũng vàng, có chữ LỖI): **phải sửa**. Khi còn lỗi, game từ chối mọi lượt câu và in thêm dòng "Có N lỗi content".

Không thấy dòng `[Content]` nào nghĩa là content ổn.

Các lỗi hay gặp và cách sửa:

| Thông báo | Nghĩa là | Cách sửa |
|---|---|---|
| `species: Content ID 'x' bị trùng` | Hai dòng cùng `id` | Đổi `id` của dòng mới |
| `species: Content ID 'x' đã phát hành nhưng bị mất ...` | Đã xóa hoặc đổi `id` của thứ đã phát hành | Trả lại dòng cũ; muốn gỡ thì dùng `hidden = true` |
| `Species 'x' có giá âm (-5)` | `price` nhỏ hơn 0 | Sửa thành số ≥ 0 |
| `Species 'x' có cân nặng ≤ 0 (0–3 kg)` | Một số trong `kg` bằng 0 hoặc âm | Dùng số lớn hơn 0, ví dụ `0.1` |
| `Species 'x' có cân nặng min (5) lớn hơn max (2)` | `kg` bị đảo | Đổi thành `{ 2, 5 }` |
| `Species 'x' có độ hiếm 'y' không hợp lệ` | `rarity` gõ sai | Dùng một trong `common`, `uncommon`, `rare`, `epic`, `legendary` |
| `Species 'x' tham chiếu Zone 'y' không tồn tại` | `zones` có id sai | Kiểm tra chính tả với `content/zones.luau` |
| `Species 'x' tham chiếu Bait 'y' không tồn tại` | `baits` có id sai | Kiểm tra chính tả với `content/baits.luau` |
| `Zone 'x' không có Species nào` | Zone chưa có loài nào sống | Thêm `"x"` vào `zones` của ít nhất một Species |
| `Zone 'x' + Bait 'y': không có Species nào ăn` | Người chơi dùng Bait `y` ở Zone `x` sẽ không bao giờ có cá | Thêm `"y"` vào `baits` của một Species sống ở Zone `x` |
| Cảnh báo `Species 'x' chưa có model` | Chưa gắn model 3D | Không cần làm gì cho tới khi có model |
| Cảnh báo `Species 'x' chỉ ăn ban đêm, nhưng ban ngày ...` | Ban ngày dùng Bait đó ở Zone đó sẽ không có cá | Nên thêm một loài ăn ban ngày dùng Bait đó |

Lỗi có chữ đỏ và không có `[Content]` (ví dụ `Expected '}'`) thường là lỗi gõ: thiếu dấu phẩy, thiếu ngoặc kép hoặc ngoặc `{ }`. Xem số dòng trong thông báo và so với dòng bên cạnh.

Bấm **Stop** để thoát Play, sửa file, lưu, rồi Play lại.

## 8. Chạy kiểm tra tự động

Trước khi gửi, chạy bộ test trong terminal:

```
lune run tests/run
```

Lệnh này kiểm tra lại toàn bộ file trong `content/`. Cuối cùng nó in `N passed, 0 failed` là ổn. Dòng bắt đầu bằng `FAIL` là test hỏng, kèm lý do bên dưới; đọc tương tự mục 7, hoặc nhờ Programmer xem. GitHub cũng tự chạy lệnh này khi bạn tạo Pull Request.

## 9. Lưu thay đổi (commit) và tạo Pull Request

1. Xem bạn đã sửa những file nào:

   ```
   git status
   ```

2. Lưu thay đổi vào Git kèm một câu mô tả ngắn:

   ```
   git add content
   git commit -m "Thêm Species Golden Carp"
   ```

3. Đẩy nhánh lên GitHub:

   ```
   git push -u origin content/add-golden-carp
   ```

4. Mở trang repo trên GitHub. Sẽ có thanh vàng **Compare & pull request**; bấm vào đó.
5. Chọn đích là `main`, viết ngắn bạn đã thêm gì và vì sao (ví dụ "Thêm cá hiếm ban đêm cho Lake"), rồi bấm **Create pull request**.
6. Chờ dấu tích xanh của GitHub (bước kiểm tra tự động). Dấu X đỏ nghĩa là có lỗi: bấm vào để xem, sửa trên máy, rồi `git add`, `git commit`, `git push` lại. Pull Request tự cập nhật.
7. Programmer sẽ duyệt và gộp vào `main`, rồi đưa lên `Misty Fishing [DEV]` để cả team test.

Xong một việc thì quay lại mục 3 để bắt đầu nhánh mới.
