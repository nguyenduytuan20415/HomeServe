# HomeServe API — BẢN NHÁP ĐỂ THẢO LUẬN

> Trạng thái: nháp. Các mục đánh dấu **[CẦN CHỐT]** phải cả nhóm thống nhất trước khi code.
> Sau khi chốt, đặt file này ở `backend/api.md` trên nhánh `backend` (yêu cầu C.3 #10).

Base URL: `https://<ten-app>.onrender.com` (cập nhật sau khi deploy)

---

## 1. Quy ước chung

| Quy ước | Đề xuất | Ghi chú |
|---|---|---|
| Tên trường JSON (gửi lên và trả về) | `snake_case`, trùng tên cột CSDL: `ho_ten`, `gia_tran` | Backend trả thẳng `rows` của `pg`, không phải đổi tên. Android dùng `@SerializedName`, Flutter đọc trong `fromJson`. **[CẦN CHỐT]** nếu nhóm muốn `camelCase` |
| Tham số trên URL (query) | Giữ đúng như đề: `?trangThai=&khuVuc=`, `?tu=&den=` | Để giảng viên đối chiếu với đề dễ dàng |
| Xác thực | Header `Authorization: Bearer <token>` | Token hết hạn sau 7 ngày. App nhận 401 thì đăng xuất và về màn đăng nhập |
| Định dạng lỗi | `{ "loi": "Thông báo cho người dùng" }` | Lỗi kiểm tra dữ liệu có thể thêm `"truong": "email"` để app báo lỗi đúng ô nhập |
| Tiền | Số nguyên, đơn vị VND: `150000` | Không dùng số thập phân |
| Ngày giờ | Chuỗi ISO 8601 có múi giờ: `2026-11-02T14:00:00+07:00` | |
| Danh sách dài | `?trang=1&soLuong=20` (mặc định 1 và 20) | Chỉ áp dụng cho danh sách có thể dài: yêu cầu, đánh giá |

### Mã trạng thái HTTP

| Mã | Khi nào |
|---|---|
| 200 | Thành công (GET, PATCH, DELETE) |
| 201 | Tạo mới thành công (POST) |
| 400 | Dữ liệu gửi lên thiếu hoặc sai |
| 401 | Thiếu token, token sai hoặc hết hạn, sai mật khẩu |
| 403 | Có token nhưng sai vai trò, hoặc không phải chủ của dữ liệu |
| 404 | Không tìm thấy |
| 409 | Xung đột: email đã tồn tại, xóa thứ đang được dùng, chuyển trạng thái không hợp lệ |
| 500 | Lỗi máy chủ |

### Giá trị cố định (viết y hệt ở backend, Android, Flutter)

| Trường | Giá trị |
|---|---|
| `nguoi_dung.vai_tro` | `KHACH`, `THO`, `QUAN_TRI` |
| `ho_so_tho.trang_thai_duyet` | `CHO_DUYET`, `DA_DUYET`, `TU_CHOI` |
| `yeu_cau.trang_thai` | `CHO_NHAN`, `DA_NHAN`, `DANG_LAM`, `HOAN_TAT`, `HUY` |
| `phan_cong.trang_thai` | `CHO_THO_NHAN`, `DA_NHAN`, `TU_CHOI` |
| `khieu_nai.trang_thai` | `MOI`, `DANG_XU_LY`, `DA_XU_LY` |

**[CẦN CHỐT]** Theo đề, đơn có các trạng thái *chờ nhận → đã nhận → đang làm → hoàn tất → hủy*. Nhưng "chờ nhận" đang gộp hai tình huống: quản trị chưa phân công thợ, và đã phân công nhưng thợ chưa bấm nhận. Nếu bàn phân việc cần lọc riêng những yêu cầu chưa ai được gán, có thể thêm trạng thái `CHO_PHAN_CONG`.

**Chuyển trạng thái hợp lệ** (máy chủ kiểm tra; sai thứ tự thì trả 409):
`CHO_NHAN → DA_NHAN → DANG_LAM → HOAN_TAT`. Được chuyển sang `HUY` khi đơn chưa ở `DANG_LAM`.

---

## 2. API của luồng đầu tiên (cho mốc tuần 11) — viết chi tiết

### GET /health
Quyền: công khai · Phụ trách: A
```json
200 { "ok": true }
```

### POST /auth/dang-ky
Quyền: công khai · Phụ trách: A
```json
// Gửi lên
{ "email": "khach1@gmail.com", "mat_khau": "123456", "ho_ten": "Nguyễn Văn A", "sdt": "0901234567" }
// 201
{ "id": 7, "email": "khach1@gmail.com", "ho_ten": "Nguyễn Văn A", "vai_tro": "KHACH" }
```
Lỗi: 400 khi thiếu email hoặc mật khẩu, email sai định dạng, mật khẩu dưới 6 ký tự · 409 khi email đã tồn tại.
Tài khoản đăng ký qua API này **luôn có vai trò `KHACH`**. Máy chủ bỏ qua `vai_tro` nếu app gửi lên.

**[CẦN CHỐT]** Thợ tạo tài khoản bằng cách nào? Có hai phương án:
(a) Thợ tự đăng ký trên app Android, gửi kèm hồ sơ; tài khoản ở trạng thái `CHO_DUYET` cho tới khi quản trị duyệt.
(b) Quản trị tạo tài khoản thợ, thợ chỉ đăng nhập.
Đề có yêu cầu "duyệt hồ sơ thợ", nên phương án (a) sát đề hơn.
Nếu chọn (a), cần chốt thêm: thợ chưa được duyệt mà đăng nhập thì trả 403, hay vẫn cho đăng nhập nhưng không cho nhận việc?

### POST /auth/dang-nhap
Quyền: công khai · Phụ trách: A
```json
// Gửi lên
{ "email": "khach1@gmail.com", "mat_khau": "123456" }
// 200
{ "token": "eyJhbGciOi...", "nguoi_dung": { "id": 7, "ho_ten": "Nguyễn Văn A", "vai_tro": "KHACH" } }
```
Lỗi: 400 khi thiếu trường · 401 với thông báo `"Email hoặc mật khẩu không đúng"`. Dùng cùng một thông báo cho cả hai trường hợp sai email và sai mật khẩu, để người ngoài không dò được email nào đã đăng ký.

### GET /auth/toi
Quyền: đã đăng nhập · Phụ trách: A
Hai app gọi API này khi mở lên để kiểm tra token còn hạn không.
```json
200 { "id": 7, "email": "khach1@gmail.com", "ho_ten": "Nguyễn Văn A", "sdt": "0901234567", "vai_tro": "KHACH" }
```
Lỗi: 401.

### GET /danh-muc-dv
Quyền: công khai · Phụ trách: C
```json
200 [ { "id": 1, "ten": "Điện", "so_dich_vu": 8 }, { "id": 2, "ten": "Nước", "so_dich_vu": 7 } ]
```

### GET /dich-vu?danhMucId=1
Quyền: công khai · Phụ trách: C
```json
200 [ { "id": 12, "danh_muc_id": 1, "ten": "Thay ổ cắm", "gia_san": 80000, "gia_tran": 150000, "don_vi": "cái" } ]
```
Lỗi: 400 khi `danhMucId` không phải số. Không truyền `danhMucId` thì trả tất cả dịch vụ.

### GET /dich-vu/:id/bang-gia
Quyền: công khai · Phụ trách: C
```json
200 { "id": 12, "ten": "Thay ổ cắm", "mo_ta": "Gồm tháo ổ cũ, lắp ổ mới", "gia_san": 80000, "gia_tran": 150000, "don_vi": "cái", "danh_muc": { "id": 1, "ten": "Điện" } }
```
Lỗi: 404.

**[CẦN CHỐT]** Bảng giá ở mức **dịch vụ** (mỗi dịch vụ một cặp giá sàn và giá trần, như bảng `dich_vu` đề gợi ý), hay ở mức **hạng mục nhỏ hơn**? Câu trả lời quyết định cách `bao_gia_chi_tiet` so với giá trần ở mục 3.

### Quản lý danh mục và dịch vụ (chỉ `QUAN_TRI`)
Phụ trách: B

| Phương thức | Đường dẫn | Gửi lên | Thành công | Lỗi riêng |
|---|---|---|---|---|
| POST | /danh-muc-dv | `{ "ten" }` | 201 + bản ghi | 409 khi trùng tên |
| PATCH | /danh-muc-dv/:id | `{ "ten" }` | 200 + bản ghi | 404, 409 |
| DELETE | /danh-muc-dv/:id | | 200 | 409 khi danh mục còn dịch vụ |
| POST | /dich-vu | `{ "danh_muc_id", "ten", "mo_ta", "gia_san", "gia_tran", "don_vi" }` | 201 + bản ghi | 400 khi `gia_san` ≤ 0 hoặc `gia_tran` < `gia_san` |
| PATCH | /dich-vu/:id | các trường cần sửa | 200 + bản ghi | 400, 404 |
| DELETE | /dich-vu/:id | | 200 | 409 khi đã có yêu cầu dùng dịch vụ này |

Mọi đường dẫn trong bảng trên: không có token thì trả **401**; có token nhưng vai trò `KHACH` hoặc `THO` thì trả **403**. Đây là mục giảng viên sẽ thử bằng Postman.

---

## 3. Các API còn lại — chỉ liệt kê, viết chi tiết khi tới lượt làm

| Phương thức + đường dẫn | Quyền | Việc | Phụ trách |
|---|---|---|---|
| POST /tho/ho-so | THO | Gửi hoặc cập nhật hồ sơ thợ (nghề, khu vực, chứng chỉ) | A |
| GET /ho-so-tho?trangThai=CHO_DUYET | QUAN_TRI | Danh sách hồ sơ chờ duyệt | B |
| PATCH /ho-so-tho/:id/duyet | QUAN_TRI | Duyệt hoặc từ chối hồ sơ | B |
| POST /tai-len | đã đăng nhập | Tải ảnh hoặc video ngắn lên Supabase Storage, trả về URL. Máy chủ giới hạn loại tệp và dung lượng | C |
| POST /yeu-cau | KHACH | Tạo yêu cầu: dịch vụ, mô tả, ảnh/video, địa chỉ, khu vực, tọa độ, thời gian mong muốn | C |
| GET /yeu-cau/cua-toi | KHACH | Danh sách đơn của khách | D |
| GET /yeu-cau/:id | chủ đơn, thợ được gán, QUAN_TRI | Chi tiết đơn; thợ được gán (tên, ảnh, số sao, số việc đã làm); thời gian thợ dự kiến tới; báo giá | D |
| PATCH /yeu-cau/:id/huy | KHACH (chủ đơn) | Hủy đơn khi chưa ở `DANG_LAM` | D |
| GET /yeu-cau?trangThai=&khuVuc= | QUAN_TRI | Bàn phân việc | B |
| GET /yeu-cau/:id/tho-phu-hop | QUAN_TRI | **Điểm nhấn ②**: thợ đúng nghề, đúng khu vực, sắp theo số sao | B |
| PATCH /yeu-cau/:id/phan-cong | QUAN_TRI | Gán thợ cho yêu cầu (dùng transaction) | B |
| GET /tho/toi/viec | THO | Việc được giao cho thợ | A |
| PATCH /phan-cong/:id/nhan | THO | Thợ nhận việc (kèm thời gian dự kiến tới) hoặc từ chối | A |
| PATCH /yeu-cau/:id/trang-thai | THO | Chuyển sang `DANG_LAM` | A |
| POST /bao-gia-chi-tiet | THO | **Điểm nhấn ①**: thêm các dòng báo giá; máy chủ so từng dòng với `gia_tran` và đánh dấu dòng vượt trần | A |
| GET /bao-gia-chi-tiet?vuotTran=true&daXemXet=false | QUAN_TRI | Danh sách báo giá vượt trần cần xem lại | B |
| PATCH /bao-gia-chi-tiet/:id/xem-xet | QUAN_TRI | Quản trị đánh dấu đã xem xét | B |
| POST /thanh-toan | KHACH | Xác nhận hoàn tất và thanh toán; tính hoa hồng; chuyển đơn sang `HOAN_TAT` (dùng transaction) | D |
| POST /danh-gia | KHACH, THO | Đánh giá hai chiều; cập nhật `diem_tb` của thợ | D |
| POST /khieu-nai | KHACH | Gửi khiếu nại, ví dụ giá vượt bảng giá | D |
| GET /khieu-nai?trangThai= | QUAN_TRI | Danh sách khiếu nại | B |
| PATCH /khieu-nai/:id/quyet-dinh | QUAN_TRI | Ghi quyết định xử lý | B |
| GET /tho/:id/cong-no | QUAN_TRI | Hoa hồng và công nợ của một thợ | A |
| GET /bao-cao/dich-vu-pho-bien?tu=&den= | QUAN_TRI | Dịch vụ được đặt nhiều nhất | A |
| GET /bao-cao/thoi-gian-phan-hoi?tu=&den= | QUAN_TRI | Thời gian phản hồi trung bình | A |
| GET /bao-cao/tho-bi-khieu-nai?tu=&den= | QUAN_TRI | Thợ bị khiếu nại nhiều | A |

**[CẦN CHỐT]** để làm được điểm nhấn ①:
- Mỗi dòng `bao_gia_chi_tiet` phải liên kết tới dịch vụ hoặc hạng mục nào để máy chủ biết so với `gia_tran` nào? Bảng đề gợi ý chỉ có cột chữ `hang_muc`.
- Lưu dấu "vượt trần" và "đã xem xét" ở đâu?

**[CẦN CHỐT]** Bảng đề gợi ý thiếu một số cột mà chức năng bắt buộc cần:
- `yeu_cau` chưa có cột **khu vực**, trong khi bàn phân việc phải lọc `?khuVuc=` và tìm thợ cùng khu vực. Chỉ có tọa độ thì khó so với `ho_so_tho.khu_vuc`.
- Chưa có chỗ lưu **thời gian thợ dự kiến tới**, mà app Client phải hiển thị.
- `nguoi_dung` chưa có **ảnh đại diện**, mà app Client phải hiện ảnh thợ.
- Chưa rõ **tỉ lệ hoa hồng** lấy từ đâu (một con số chung, hay riêng cho từng dịch vụ hoặc từng thợ).

---

## 4. Câu hỏi cần thảo luận (tổng hợp)

1. JSON dùng `snake_case` hay `camelCase`?
2. Có thêm trạng thái `CHO_PHAN_CONG` không?
3. Thợ tạo tài khoản theo phương án (a) hay (b)?
4. Bảng giá ở mức dịch vụ hay mức hạng mục?
5. Báo giá liên kết với giá trần thế nào, và lưu dấu vượt trần ở đâu?
6. Thợ dùng app Android (vai trò thứ hai của App Admin) đúng không?
7. Thêm các cột còn thiếu: khu vực của yêu cầu, thời gian dự kiến tới, ảnh đại diện, tỉ lệ hoa hồng.
