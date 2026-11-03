# SQL của 3K Store — database PhoneStore

## Chạy trên database thử nghiệm mới

File điều phối là `master_run.sql` ở thư mục gốc. Mở SSMS, bật **Query > SQLCMD Mode**, chọn thư mục `sql` làm thư mục làm việc rồi chạy file. Bước tạo lại database trong file đang được comment để tránh xoá nhầm dữ liệu; chỉ bỏ comment `:r .\01_database_init.sql` khi đã kết nối đúng máy thử nghiệm.

1. `01_database_init.sql`: tạo lại toàn bộ PhoneStore và dữ liệu mẫu. **Có lệnh DROP DATABASE**; chỉ chạy trên database thử nghiệm có thể xóa.
2. `02_schema_upgrade.sql`: nâng cấp schema nền cho web, giữ các role `admin`, `staff`, `customer` và cho phép `user` của web.
3. `03_catalog_seed.sql`, rồi `04_catalog_expand.sql`: nạp catalog tới 500 SKU.
4. `05_hide_base_samples.sql`: ngừng bán 40 sản phẩm mẫu `SKU-001`–`SKU-040` nếu chưa có dòng đơn; giữ nguyên bản ghi. Sau đó chạy `06_product_filters.sql` để tạo thủ tục lọc danh mục, thương hiệu và từ khóa.
5. `08_business_logic.sql`: tạo 2 hàm, 3 thủ tục và hàm `VOUCHER`/`Tinhtong`; file này phải chạy trước `07_checkout.sql` vì procedure web dùng `dbo.VOUCHER`.
6. `07_checkout.sql`: tạo thủ tục đặt hàng web; `Orders.TotalAmount` là số phải trả sau khuyến mãi, còn `OrderItems.LineTotal` là tổng giá gốc.
7. `09_module3_queries_views.sql`: 12 truy vấn và 5 view của Module 3.
8. `10_report_queries.sql`: 11 truy vấn báo cáo nghiệp vụ chỉ đọc.
9. `11_security_roles.sql`: tạo role, cấp quyền và DENY.
10. `12_security_tests.sql`: kiểm thử quyền theo role và `phone_app`.
11. `13_order_sync_check.sql`: đối chiếu dữ liệu sau khi đặt hàng qua web.
12. `16_indexes_performance.sql`: kiểm tra hiệu năng và chỉ mục.

`91_cleanup_legacy.sql` chỉ dùng với các SKU cũ được nêu trong tệp. `90_demo_accounts.sql` tạo/cập nhật tài khoản demo `admin / 123456` và `user_demo / 123456`; chỉ dùng cục bộ cho bài học, không dùng trên hệ thống thật.

Các file trong `Module05_Transactions` và `Module06_ErrorHandling` được gọi trong `master_run.sql` để tạo đối tượng và chạy các test rollback trên database thử nghiệm. Các file `session_A.sql`, `session_B.sql` và `11_concurrency_tests.sql` vẫn phải chạy thủ công ở nhiều cửa sổ SSMS. Thủ tục web dùng tên `usp_CreateOrder_Web`; thủ tục bán hàng tại quầy của Module 8 giữ tên `usp_CreateOrder` để không bị trùng.

## Database đang sử dụng

Sao lưu trước khi nâng cấp. **Không chạy lại `01_database_init.sql`** vì script xóa PhoneStore. Chỉ chạy các tệp cần thiết sau khi kiểm tra schema hiện có. `03_catalog_seed.sql` có nhánh cập nhật theo SKU, nên có thể ghi đè giá hoặc metadata đã chỉnh trong trang quản trị. Không coi việc chạy lại seed là đồng bộ hai chiều. Các thư mục tên `Module05_Transactions` và `Module06_ErrorHandling` là phần bài tập riêng, chưa được thay đổi mã trong đợt sửa này.

Ngày 01/11/2026 đã kiểm tra SQL Server trực tiếp: 500 sản phẩm đang bán khớp 500 SKU CSV; 3 đơn có tổng tiền khớp dòng đơn. `05_hide_base_samples.sql` được lưu để có thể lặp lại bước ngừng bán 40 mẫu nền. Chưa chạy lại toàn bộ thứ tự script trên database thử nghiệm; hãy thử trên bản sao trước khi áp dụng lên dữ liệu thật.

Ngày 01/11/2026 kiểm tra cú pháp bằng `SET PARSEONLY ON`: các file SQL chính không báo lỗi cú pháp. Đã chạy chỉ đọc `09_module3_queries_views.sql`, `12_security_tests.sql`, `13_order_sync_check.sql`: không có lỗi thực thi. Chưa xác nhận chạy liền mạch các script tạo/cập nhật trên database mới vì tài khoản kiểm tra không có quyền tạo database; tuyệt đối không chạy `01_database_init.sql` trên PhoneStore đang dùng vì file này xóa database cũ.

Để chạy lại kiểm thử an toàn trong PowerShell: `.\run_readonly_tests.ps1`. Script này chỉ kiểm tra cú pháp và chạy các truy vấn đọc; không tạo database, không đổi tồn kho và không tạo đơn.
