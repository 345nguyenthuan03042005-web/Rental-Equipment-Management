# Rental-Equipment-Management
Ứng dụng hỗ trợ quản lý thiết bị cho thuê của công ty tại các đơn vị. Người dùng có thể tra cứu thiết bị, xem tình trạng và gửi yêu cầu thuê. Quản trị viên có thể quản lý danh mục, thiết bị và theo dõi các yêu cầu thuê.


## Triển khai web

1. Tạo cơ sở dữ liệu trên SQL Server bằng `RentalEquipmentManagement.sql`. Chạy script với tài khoản có quyền tạo cơ sở dữ liệu.
2. Triển khai dự án `WebApi/WebApi.csproj` trên máy chủ hỗ trợ ASP.NET Core 10. Khai báo biến môi trường `ConnectionStrings__RentalEquipmentManagement` và `Jwt__SecretKey` (khóa ngẫu nhiên tối thiểu 32 byte) trên máy chủ.
3. Trong thư mục `rental_equipment_app`, chạy `flutter pub get`, rồi chạy `flutter build web --dart-define=API_URL=https://api.example.com`. Thay URL bằng địa chỉ HTTPS của Web API và đưa nội dung `build/web` lên dịch vụ lưu trữ web.

File `rental_equipment_app/.env` chỉ chứa URL API mặc định dùng trên máy phát triển. Flutter Web dùng API trực tiếp, còn bộ nhớ đệm SQLite dành cho nền tảng được hỗ trợ.

Nếu bật đăng nhập qua Google, Facebook hoặc Zalo, đặt các biến `Social__<provider>__ClientId`, `Social__<provider>__ClientSecret` và `Social__<provider>__Callback` trên máy chạy Web API. Đăng ký URL callback `https://api.example.com/api/social/<provider>/callback` với nhà cung cấp và dùng đúng URL đó trên máy chủ.
