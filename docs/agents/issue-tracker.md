# Issue tracker: GitHub

Issue và spec của repo này nằm trên GitHub Issues. Dùng `gh` CLI cho mọi thao tác.

Repo: https://github.com/thuo-huynh/misty-fishing

## Quy ước

- **Tạo issue**: `gh issue create --title "..." --body "..."`. Dùng heredoc cho nội dung nhiều dòng.
- **Đọc issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **Liệt kê issue**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` kèm bộ lọc `--label` và `--state` phù hợp.
- **Gắn issue con vào issue cha**: `gh issue create --parent <parent> ...`, hoặc `gh issue edit <parent> --add-sub-issue <child>` sau đó (`gh` 2.94+). Với `gh` cũ hơn: `gh api --method POST repos/<owner>/<repo>/issues/<parent>/sub_issues -F sub_issue_id=<child-db-id>` (database id, như mục **Chặn** bên dưới). Nếu không dùng được sub-issue, ghi `Part of #<parent>` ở đầu nội dung issue con.
- **Bình luận**: `gh issue comment <number> --body "..."`
- **Gắn / gỡ nhãn**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Đóng**: `gh issue close <number> --comment "..."`

Repo được suy ra từ `git remote -v`; `gh` tự làm việc này khi chạy trong thư mục clone.

## Pull request như một nguồn yêu cầu

**PR là nguồn yêu cầu: không.** _(Đổi thành `có` nếu repo coi PR từ người ngoài là yêu cầu tính năng; `/triage` đọc cờ này.)_

Khi đặt là `có`, PR đi qua cùng các nhãn và trạng thái như issue, dùng các lệnh `gh pr` tương ứng:

- **Đọc PR**: `gh pr view <number> --comments` và `gh pr diff <number>` để xem thay đổi.
- **Liệt kê PR từ người ngoài để phân loại**: `gh api --paginate 'repos/{owner}/{repo}/pulls?state=open' --jq '.[] | select(.author_association | IN("OWNER","MEMBER","COLLABORATOR") | not) | {number, title, author: .user.login, author_association, labels: [.labels[].name]}'`.
- **Bình luận / gắn nhãn / đóng**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub dùng chung một dãy số cho issue và PR, nên `#42` có thể là một trong hai: thử `gh pr view 42` trước, không được thì `gh issue view 42`.

## Khi một skill nói "đăng lên issue tracker"

Tạo một GitHub issue.

## Khi một skill nói "lấy ticket liên quan"

Đọc như mục **Đọc issue** ở trên.

## Thao tác cho Wayfinding

Dùng bởi `/wayfinder`. **Map** là một issue duy nhất, các **ticket con** là issue con của nó.

- **Map**: một issue gắn nhãn `wayfinder:map`, chứa phần Notes / Decisions-so-far / Fog. `gh issue create --label wayfinder:map`.
- **Ticket con**: issue được gắn vào map dưới dạng sub-issue của GitHub (xem **Gắn issue con vào issue cha**). Nếu không bật sub-issue, thêm ticket vào danh sách task trong nội dung map và ghi `Part of #<map>` ở đầu ticket con. Nhãn: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Khi đã nhận, ticket được gán cho người đang làm.
- **Chặn**: dùng **issue dependencies có sẵn của GitHub**, cách biểu diễn chuẩn và hiện trên giao diện. Thêm quan hệ bằng `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, trong đó `<blocker-db-id>` là **database id** dạng số của issue chặn (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _không phải_ `#number` hay `node_id`). GitHub báo `issue_dependencies_summary.blocked_by` (chỉ tính issue chặn còn mở). Nếu không có dependencies, ghi dòng `Blocked by: #<n>, #<n>` ở đầu ticket con. Ticket hết bị chặn khi mọi issue chặn đã đóng.
- **Tìm việc tiếp theo**: liệt kê các ticket con còn mở của map (`gh issue list --state open`, trong phạm vi sub-issue / danh sách task của map), bỏ những ticket còn bị chặn (`issue_dependencies_summary.blocked_by > 0`, hoặc có issue còn mở trong dòng `Blocked by`) hoặc đã có người nhận; ticket đứng đầu theo thứ tự trong map được chọn.
- **Nhận việc**: `gh issue edit <n> --add-assignee @me`, thao tác ghi đầu tiên của phiên làm việc.
- **Hoàn tất**: `gh issue comment <n> --body "<kết quả>"`, rồi `gh issue close <n>`, rồi thêm một dòng tóm tắt kèm link vào phần Decisions-so-far của map.
