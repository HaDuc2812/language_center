# Language Center Management System

Ứng dụng Flutter quản lý hoạt động trung tâm ngoại ngữ. Source hiện dùng MVVM đơn giản:

```text
View → Riverpod ViewModel → Repository → DatabaseHelper → SQLite
                           └→ Firebase Auth/Firestore chỉ cho hồ sơ users/{uid}
```

## Database và xác thực

- Firebase Authentication xác thực tài khoản.
- Firestore chỉ đọc `users/{Firebase Auth UID}` để xác nhận profile tồn tại,
  `status == "active"` và `role` là `admin` hoặc `staff`.
- `students`, `teachers`, `course`, `classrooms`, `classes`, `sessions`,
  `enrollments`, `attendance` và `learning_results` lưu trong SQLite local.
- Mỗi thiết bị có database riêng. Không đồng bộ nghiệp vụ lên Firestore;
  đăng nhập cùng tài khoản ở thiết bị khác không chia sẻ dữ liệu local.
- SQLite dùng `language_center.db`, foreign keys bật cho mỗi kết nối và schema
  được quản lý bằng `DatabaseHelper.databaseVersion`. Không xóa database để
  cập nhật schema; tăng version và thêm migration trong `_upgradeSchema`.
- Seed được thêm khi tạo database và dùng mã nghiệp vụ unique cùng
  `ConflictAlgorithm.ignore`, nên không thêm trùng mỗi lần mở app.
- Không commit database SQLite đang chạy. Các mẫu `*.db`, `*.db-shm`,
  `*.db-wal` đã được ignore trong `.gitignore`.

> SRS trong workspace mô tả Firestore là kho dữ liệu dùng chung, trong khi yêu
> cầu triển khai hiện tại chọn SQLite local cho dữ liệu nghiệp vụ. Hai cách này
> khác nhau; nhóm cần cập nhật SRS trước khi coi SQLite local là quyết định
> triển khai chính thức. Các Business Rules mẫu về cafeteria/giao đồ ăn trong
> phụ lục SRS không được xem là nghiệp vụ LCMS.

## Chạy ứng dụng

Hiện cấu hình `sqflite` ưu tiên Android. Chạy trên Android emulator/thiết bị:

```powershell
flutter pub get
dart run build_runner build
flutter run
```

Nếu Firebase project chưa bật Email/Password, bật tại Firebase Console.
Tạo user trong Firebase Authentication và tạo Firestore document:

```text
users/{Firebase Auth UID}
  role: "admin" | "staff"
  status: "active"
  fullName: string
  email: string
```

Firestore Rules cần cho phép user đã đăng nhập đọc đúng hồ sơ của mình.
Không mở Rules công khai. Quyền nghiệp vụ trên SQLite là kiểm soát ở ứng dụng
local, không phải cơ chế bảo mật phía server.

## Dữ liệu demo

Database mới tự tạo các dữ liệu mẫu:

- Học viên: `STU0001`, `STU0002` đang học; `STU0003` đã ngừng.
- Giáo viên: `TEA0001`.
- Khóa học: `IELTS_5.0`; phòng `Room 302`.
- Lớp: `IELTS50_OPEN` đang mở, `IELTS50_01` đang diễn ra/còn chỗ,
  `IELTS50_FULL` đã đủ chỗ, `IELTS50_DONE` đã hoàn thành.
- Buổi học đã bắt đầu và buổi học tương lai.
- Có đăng ký, điểm danh và kết quả mẫu cho luồng tra cứu.

Dữ liệu nghiệp vụ Firestore trước đây không tự migrate sang SQLite. Không xóa
dữ liệu Firestore cũ; database local chỉ được seed khi tạo mới.

## Phần quá trình học

Các màn hình:

1. **Tổng quan:** số lượt đang học/đã hủy, lớp đang nhận học viên, đăng ký gần đây.
2. **Lớp học:** tìm theo mã/tên và lọc trạng thái.
3. **Chi tiết lớp:** danh sách enrollment, lọc trạng thái, chọn học viên từ danh
   sách, hủy đăng ký có lý do, mở điểm danh/kết quả.
4. **Điểm danh:** tạo buổi học cho lớp đang diễn ra, chọn buổi, xem trạng thái
   hiện tại, ghi/sửa/xóa có lý do. Buổi học tự lấy phòng theo lớp và đánh số tiếp
   theo các buổi đã có.
5. **Kết quả lớp:** nhập/sửa điểm 0–10, nhận xét và trạng thái Đạt/Chưa đạt.
6. **Tra cứu học viên:** tìm theo mã/tên, xem đăng ký, điểm, điểm danh và lịch sử hủy.

Quy tắc chính:

- Đăng ký chấp nhận học viên `studying`/`active`, lớp `open`/`ongoing` còn chỗ.
- Một học viên chỉ có một enrollment cho mỗi lớp; enrollment đã hủy không tự
  đăng ký lại trong bản đầu.
- Tạo/hủy enrollment và cập nhật sĩ số chạy trong cùng SQLite transaction.
- Attendance duy nhất theo enrollment–session; chỉ ghi cho lớp ongoing, buổi
  không hủy đã bắt đầu và enrollment hợp lệ tại thời điểm buổi học.
- Chỉ admin/staff tạo buổi học cho lớp ongoing; thời gian kết thúc phải sau bắt
  đầu, tên buổi bắt buộc và phòng học được lấy theo phòng của lớp.
- Kết quả duy nhất mỗi enrollment, điểm 0–10, tối đa hai chữ số thập phân;
  điểm 0 khác với chưa có kết quả.
- Lớp completed: chỉ admin được sửa dữ liệu đã có và phải nhập lý do.
- Xóa attendance là soft delete có lưu lý do; hồ sơ học tập và quan hệ không
  xóa cascade.
- Xóa kết quả là soft delete; chỉ admin được xóa và phải nhập lý do. Nhập lại
  kết quả sẽ khôi phục bản ghi hiện có, không tạo bản ghi trùng.

Riverpod dùng `ref.watch` cho truy vấn. Sau khi mutation transaction thành công,
ViewModel invalidate các provider liên quan để màn hình lớp, đăng ký, điểm danh,
kết quả và tra cứu tải lại dữ liệu. Mutation thất bại không refresh hay báo thành công.

## Kiểm thử và code generation

```powershell
dart format lib test
dart run build_runner build
flutter analyze
flutter test
```

Repository tests dùng SQLite FFI trong bộ nhớ để kiểm tra đăng ký trùng, lớp đầy,
tranh chỗ cuối, hủy enrollment, điểm danh sai lớp/trùng/xóa mềm, điểm ngoài thang,
sửa kết quả sau khi lớp hoàn thành và xóa/khôi phục kết quả. File `.g.dart` là
generated output, không sửa tay.
