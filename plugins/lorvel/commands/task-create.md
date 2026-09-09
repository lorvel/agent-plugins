---
description: Bước 1 — tạo task Lorvel từ một câu mô tả
argument-hint: [mô tả việc cần làm]
disable-model-invocation: true
---

Tạo một task trên Lorvel từ mô tả: **$ARGUMENTS**

Không có mô tả nào ⇒ hỏi user trước khi làm bất cứ việc gì khác.

File này chỉ mang **trình tự**. **Khuôn nội dung không nằm ở đây** — nó do `task_authoring_guide` trả về lúc chạy. Đừng viết task bằng thứ bạn nhớ về Lorvel.

## 1. Lấy guide, và kiểm đủ tool trước khi làm mất thời gian của user

Gọi `task_authoring_guide`. Giữ `token` **và đọc trọn phần guide nó trả về**.

Guide là nguồn duy nhất cho: task có những field nào và field nào chứa gì, từ vựng status của project này, cú pháp link, và luật của từng field. Nếu bạn thấy mình đang định *nhớ ra* một trong những thứ đó thay vì đọc — dừng và đọc.

Không gọi được tool này ⇒ **dừng ở đây và nói rõ là thiếu nó.** Đừng soạn tiếp: không có guide thì không có khuôn, và một task đúng hình thức mà sai khuôn còn tệ hơn không có task.

Rồi kiểm luôn: `check_similar_tasks`, `create_task`, `log_progress` có mặt không. Thiếu một tool **ghi**, hoặc credential chỉ có quyền đọc ⇒ **nói ngay bây giờ**. Bốn bước dưới toàn là hỏi con người; phát hiện không ghi được ở bước cuối là bắt user trả lời xong rồi mới bảo công cốc.

## 2. Kiểm trùng

Nháp một `title` từ mô tả của user (chưa cần biết loại việc, chưa cần đủ chi tiết) rồi gọi `check_similar_tasks`.

⚠️ **Đọc các match, đừng lọc theo `verdict`.** Một bản gần trùng thật có thể về với `verdict: distinct` và similarity thấp — vì nháp của bạn dài một câu, còn task đang có thì body đã dày, nên hai vector lệch nhau vì một lý do chẳng liên quan gì tới chuyện có cùng việc hay không. Task nào càng được làm kỹ thì càng dễ bị đánh giá thấp ở đây.

Bất cứ match nào **có thể** là cùng một việc:

1. **Nêu nó ra cho user** — ref, link, và cả verdict lẫn similarity mà tool trả về.
2. Hỏi: mở rộng task đó, hay đây thật sự là việc khác?
3. User chưa trả lời thì **chưa tạo gì cả**.

Bước này đứng đầu vì nó rẻ và nó cắt được cả ba bước sau: việc đã có task rồi thì đừng tiêu một lượt hỏi nào của user.

## 3. Phân loại việc

Dùng `AskUserQuestion`, một câu, ba lựa chọn:

- **Bug** — có cái đang chạy sai
- **Thay đổi** — thêm hoặc sửa hành vi có chủ ý
- **Spike** — chưa biết đủ, cần tìm hiểu trước

Loại này **không phải field của Lorvel**. Nó chỉ quyết định bước 4 hỏi gì. User chọn "Other" và tự gọi tên loại của họ thì nhận nguyên, đừng nhét lại vào ba ô trên.

## 4. Hỏi những gì còn thiếu — KHÔNG ĐƯỢC BỎ BƯỚC NÀY

Đây là bước hay bị bỏ nhất, và là bước làm nên khác biệt giữa một task dùng được và một task phải viết lại.

Đối chiếu câu của user với những gì guide đòi. Chỗ nào user chưa nói thì **hỏi**, đừng suy ra rồi viết vào.

Hỏi theo loại đã chọn ở bước 3:

- **Bug** — đang xảy ra gì, đáng ra phải thế nào, thấy ở đâu
- **Thay đổi** — xong thì cái gì khác đi, và làm sao biết là xong
- **Spike** — câu hỏi cần trả lời là gì, và cái gì thì đủ để kết thúc
- **Loại user tự gọi tên** — tự suy ra bộ câu hỏi tương đương cho loại đó. Vẫn phải hỏi, và vẫn không được ép về ba ô trên.

Gộp được thì gộp vào một lượt `AskUserQuestion`, nhưng **thà hỏi còn hơn đoán**.

Session không có `AskUserQuestion` ⇒ hỏi bằng text, và khi đó gộp luôn câu phân loại của bước 3 vào cùng lượt là được. Thiếu công cụ để hỏi **không** phải lý do để bỏ hỏi.

`priority`: user chưa nói thì **không hỏi và không set**. Guide đã nói việc để trống nghĩa là gì — đọc ở đó. Đừng bày ra một danh sách mức để user chọn cho có.

## 5. Kiểm trùng lần hai, rồi trình bản nháp — KHÔNG ĐƯỢC BỎ BƯỚC NÀY

Giờ mới có `title` + `body` đầy đủ. **Gọi `check_similar_tasks` lần nữa với bản đầy đủ đó** — lần ở bước 2 chạy trên nháp mỏng nên nó là phép đo yếu nhất; lần này là phép đo thật. Ra match mới thì xử như bước 2.

Rồi trình cho user xem **toàn văn** những gì sắp ghi: `title`, `body`, loại đã chọn, và mọi field khác bạn định gửi.

Hỏi bằng `AskUserQuestion`: **Tạo / Sửa / Huỷ**.

- **Sửa** ⇒ nhận góp ý và trình lại. Lặp đến khi user đồng ý.
- **Huỷ** ⇒ dừng lệnh, và nói rõ là chưa ghi gì lên Lorvel.
- Chỉ **Tạo** mới được đi sang bước 6.

User nói *"tuỳ bạn"* hoặc *"sao cũng được"*: **đó không phải chấp thuận.** Đưa đề xuất cụ thể của bạn, rồi xin xác nhận tường minh cho chính đề xuất đó.

Bước này tồn tại vì `body` là văn bản **bạn** viết, không phải user viết — và nó là văn bản được đánh chỉ mục, nên một câu sai lọt vào đây sẽ đi tiếp vào mọi lần tìm task sau này. Đây là chỗ duy nhất trong luồng có con người đọc nó.

## 6. Ghi

1. `create_task`, kèm `token` từ bước 1.

   ⚠️ Token chỉ sống khoảng mười lăm phút, mà bước 3–5 là chờ con người trả lời — nên hết hạn ở đây là **chuyện thường, không phải lỗi**. Bị từ chối vì token hết hạn ⇒ gọi lại `task_authoring_guide` lấy token mới rồi thử lại đúng một lần. Đừng bỏ bản nháp user vừa chấp thuận.

2. Rồi **một** `log_progress` lên task vừa tạo, mở đầu bằng đúng dòng này:

   > *Task này do agent soạn qua `/task-create`; nội dung đã được người dùng đọc và chấp thuận trước khi ghi.*

   Phần còn lại của entry nói ngắn gọn task được soạn từ đâu: câu user gõ, loại đã chọn, và task trùng đã cân nếu bước 2 hoặc 5 có match.

   Call này fail ⇒ thử lại một lần, rồi **nói rõ với user là task đã tạo nhưng chưa có entry xuất xứ**. Đừng im lặng: entry đó là chỗ duy nhất ghi lại rằng task này do agent soạn.

3. Báo cho user bằng `[<ref>](<url>)`, lấy `url` từ response — đừng tự dựng URL.

Xong mục 3 là **hết lệnh**. Đừng tự đi tiếp sang lên plan hay triển khai task vừa tạo — đó là việc khác, user sẽ tự gọi khi họ muốn.
