# Content viết bằng file Luau, không dùng bảng tính

Species, Zone, Rod, Line, Bait và nhiệm vụ là các bảng `.luau` thuần trong thư mục `content/`, do Content Designer chỉnh sửa và được review qua Pull Request như code. Chúng tôi chọn cách này thay vì Google Sheets để bỏ bước xuất dữ liệu và để mọi thay đổi content đều được review trong Git; game kiểm tra content khi khởi động và trong CI để bắt lỗi trước khi người chơi thấy.
