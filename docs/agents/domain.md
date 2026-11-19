# Tài liệu domain

Cách các skill kỹ thuật dùng tài liệu domain của repo khi tìm hiểu code.

## Trước khi tìm hiểu, đọc các file sau

- **`GLOSSARY.md`** ở thư mục gốc, hoặc
- **`GLOSSARY-MAP.md`** ở thư mục gốc nếu có: file này trỏ tới một `GLOSSARY.md` cho mỗi context. Đọc những file liên quan tới chủ đề đang làm.
- **`docs/adr/`**: đọc các ADR liên quan tới phần sắp làm. Trong repo nhiều context, kiểm tra thêm `src/<context>/docs/adr/` cho các quyết định riêng của từng context.

Nếu các file này chưa có, **cứ tiếp tục, không cần nhắc**. Đừng báo thiếu, đừng đề xuất tạo trước. Skill `/domain-modeling` (gọi qua `/grill-with-docs` và `/improve-codebase-architecture`) sẽ tạo chúng khi thuật ngữ hoặc quyết định thực sự được chốt.

## Cấu trúc file

Repo này là **single-context**:

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-map-in-cloud-code-in-git.md
│   └── 0002-content-as-luau-files.md
└── src/
```

Repo nhiều context (có `GLOSSARY-MAP.md` ở gốc):

```
/
├── GLOSSARY-MAP.md
├── docs/adr/                          ← quyết định toàn hệ thống
└── src/
    ├── ordering/
    │   ├── GLOSSARY.md
    │   └── docs/adr/                  ← quyết định riêng của context
    └── billing/
        ├── GLOSSARY.md
        └── docs/adr/
```

## Dùng đúng thuật ngữ trong glossary

Khi kết quả của bạn nhắc tới một khái niệm domain (trong tiêu đề issue, đề xuất refactor, giả thuyết, tên test), dùng đúng thuật ngữ như định nghĩa trong `GLOSSARY.md`. Không dùng các từ đồng nghĩa mà glossary đã ghi là _Tránh dùng_.

Nếu khái niệm cần dùng chưa có trong glossary, đó là một tín hiệu: hoặc bạn đang tự đặt ra từ mà dự án không dùng (cân nhắc lại), hoặc glossary thực sự còn thiếu (ghi chú lại cho `/domain-modeling`).

## Báo khi trái với ADR

Nếu kết quả của bạn đi ngược một ADR đã có, hãy nói rõ thay vì lặng lẽ làm khác:

> _Trái với ADR-0002 (content là file Luau), nhưng nên xem xét lại vì…_
