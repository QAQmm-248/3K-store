# 3K Store — hướng dẫn cài đặt và chạy toàn bộ hệ thống

3K Store là hệ thống quản lý cửa hàng thiết bị điện tử. Website dùng FastAPI/Uvicorn, giao diện HTML/CSS/JavaScript và SQL Server làm nguồn dữ liệu chính. Tên thương hiệu hiển thị là **3K Store**; các định danh kỹ thuật hiện có như database `PhoneStore`, login SQL `phone_app` và container Docker được giữ nguyên để không làm hỏng kết nối đã cấu hình.

## 1. Thành phần cần có

- Windows 10/11.
- Docker Desktop đang chạy.
- SQL Server/SQL Server Express và SSMS. Máy hiện tại dùng `QAQMM\SQLEXPRESS`.
- Quyền kết nối SQL Server bằng tài khoản quản trị khi cài schema và phân quyền.
- Thư mục dự án: `C:\Users\DELL\Dropbox\PC\Downloads\HQT`.

Không đưa mật khẩu thật vào GitHub. File `admin.env` chỉ dùng trên máy chạy dịch vụ và đã được loại khỏi nội dung cần chia sẻ.

## 2. Cấu trúc chính

```text
HQT/
├─ main.py                         # API FastAPI và các endpoint web
├─ store.html                      # giao diện cửa hàng
├─ admin.html                      # giao diện quản trị
├─ static/                         # CSS, JavaScript, biểu tượng
├─ data/                           # CSV và ảnh sản phẩm
├─ sql/                            # toàn bộ script SQL theo thứ tự chạy
├─ docker-compose.yml              # web, n8n và QA runner
├─ docker/                         # Dockerfile của web và QA runner
└─ admin.env                       # cấu hình kết nối SQL (không commit)
```

## 3. Cấu hình kết nối SQL cho web

Tạo hoặc kiểm tra file `admin.env` ở thư mục gốc. Các khóa mà `main.py` sử dụng là:

```env
DB_SERVER=host.docker.internal,1433
DB_NAME=PhoneStore
DB_USER=phone_app
DB_PASSWORD=<mật-khẩu-phone_app>
APP_SECRET=<chuỗi-bí-mật-dài>
ADMIN_INITIAL_PASSWORD=<mật-khẩu-admin>
```

Nếu SQL Server đang nghe cổng khác, thay giá trị `DB_SERVER`. Khi web chạy trong Docker trên Windows, `host.docker.internal` trỏ về SQL Server trên máy host. Không dùng `localhost` trong biến `DB_SERVER` của container web.

## 4. Chạy SQL theo đúng thứ tự

### 4.1. Trường hợp đang có database và muốn giữ đơn hàng

Đây là cách khuyến nghị cho hệ thống hiện tại.

1. Mở SSMS, kết nối tới SQL Server bằng tài khoản quản trị.
2. Mở `sql/master_run.sql`.
3. Chọn **Query → SQLCMD Mode**.
4. Đảm bảo dòng sau vẫn được comment:

   ```sql
   -- :r .\01_database_init.sql
   ```

5. Chạy toàn bộ file bằng **Execute**.

`master_run.sql` sẽ chạy theo chuỗi (thứ tự này là bắt buộc vì procedure đặt hàng web dùng hàm `dbo.VOUCHER` được tạo ở Module 8):

```text
02_schema_upgrade.sql
03_catalog_seed.sql
04_catalog_expand.sql
05_hide_base_samples.sql
06_product_filters.sql
08_business_logic.sql
07_checkout.sql
Module05_Transactions/10_transactions.sql
Module06_ErrorHandling/12_error_handling.sql
Module06_ErrorHandling/13_test_cases.sql
11_security_roles.sql
09_module3_queries_views.sql
10_report_queries.sql
12_security_tests.sql
13_order_sync_check.sql
16_indexes_performance.sql
```

Các script trên được thiết kế theo hướng bổ sung/nâng cấp và không tự xóa đơn hàng hiện có.

### 4.2. Trường hợp tạo database thử nghiệm mới

`01_database_init.sql` có thể tạo lại database `PhoneStore` và xóa dữ liệu cũ. Chỉ dùng trên máy/database thử nghiệm:

1. Sao lưu database trước khi thực hiện.
2. Mở `sql/master_run.sql` ở SQLCMD Mode.
3. Bỏ comment dòng `-- :r .\01_database_init.sql` thành `:r .\01_database_init.sql`.
4. Chạy file một lần.
5. Sau khi kiểm tra xong, không chạy lại bước này trên database đang sử dụng thật.

## 5. Các nhóm script

| Nhóm | File | Chức năng |
|---|---|---|
| Khởi tạo/nâng cấp | `01_database_init.sql`, `02_schema_upgrade.sql` | Tạo database, bảng, khóa, cột mở rộng, view, function và procedure nền. |
| Dữ liệu catalog | `03_catalog_seed.sql`, `04_catalog_expand.sql`, `05_hide_base_samples.sql` | Nạp danh mục, thương hiệu, sản phẩm và ngừng bán dữ liệu mẫu nền mà không xóa lịch sử. |
| Lọc sản phẩm | `06_product_filters.sql` | Lọc theo danh mục, thương hiệu và từ khóa. |
| Nghiệp vụ cửa hàng/khuyến mãi | `08_business_logic.sql` | Tạo `usp_CreateOrder`, `usp_ProcessStockReceipt`, `usp_CancelAndRestock`, hàm `VOUCHER`, `Timkiemsanpham`, `Tinhtong`. Hàm `VOUCHER` được procedure web sử dụng để tính giảm giá. |
| Đặt hàng web | `07_checkout.sql` | Tạo `dbo.usp_CreateOrder_Web`; giữ giá gốc ở `OrderItems`, lưu số phải thanh toán sau giảm ở `Orders.TotalAmount`. |
| Module 03 | `09_module3_queries_views.sql`, `10_report_queries.sql` | Truy vấn nghiệp vụ và view báo cáo. |
| Phân quyền | `11_security_roles.sql`, `12_security_tests.sql` | Role/login/user, quyền tối thiểu và kiểm thử. |
| Đối soát | `13_order_sync_check.sql` | Kiểm tra đơn web, dòng hàng và tồn kho. |
| Tối ưu | `16_indexes_performance.sql` | Chỉ mục và kiểm tra hiệu năng. |
| Module 05 | `Module05_Transactions/10_transactions.sql`, `11_concurrency_tests.sql` | Giao dịch, khóa và đồng thời. |
| Module 06 | `Module06_ErrorHandling/12_error_handling.sql`, `13_test_cases.sql` | Xử lý lỗi, rollback và ca kiểm thử. |

`90_demo_accounts.sql` chỉ tạo tài khoản mẫu và đang để comment trong master. Chạy riêng khi cần. `91_cleanup_legacy.sql` là script dọn SKU cũ; chỉ chạy sau khi duyệt danh sách.

## 6. Kiểm thử riêng

Sau master, chạy thủ công:

- `Module05_Transactions/11_concurrency_tests.sql`: hai cửa sổ SSMS.
- `Module05_Transactions/session_A.sql` và `session_B.sql`: hai session riêng.
- `Module06_ErrorHandling/13_test_cases.sql`: lỗi dữ liệu và rollback.
- `sql/12_security_tests.sql`: thao tác được phép/bị từ chối.

Không đưa các session đồng thời vào chuỗi tự động vì chúng có thể giữ khóa hoặc thay đổi dữ liệu kiểm thử.

## 7. Khởi động website

Mở PowerShell tại thư mục HQT:

```powershell
cd C:\Users\DELL\Dropbox\PC\Downloads\HQT
docker compose up -d --build web
```

Muốn chạy cả n8n và QA runner:

```powershell
docker compose up -d --build
```

Kiểm tra:

```powershell
docker compose ps
docker compose logs -f web
```

Mở:

- Cửa hàng: [http://localhost:8000/](http://localhost:8000/)
- Quản trị: [http://localhost:8000/admin](http://localhost:8000/admin)
- Sức khỏe: [http://localhost:8000/health](http://localhost:8000/health)
- n8n: [http://localhost:5678/](http://localhost:5678/)

Sau khi sửa mã, chạy lại `docker compose up -d --build web`.

## 8. Luồng web → SQL

1. Cửa hàng đọc sản phẩm từ `dbo.vw_ProductInventory`.
2. Bộ lọc dùng `Categories`, `Brands`, `Products` và procedure trong `06_product_filters.sql`.
3. Xác nhận đơn gọi `dbo.usp_CreateOrder_Web`.
4. Procedure kiểm tra tồn, gọi `dbo.VOUCHER` (20 triệu giảm 2%, từ 50 triệu giảm 5%, tối đa 3 triệu), tạo `Orders`/`OrderItems` và giảm `Products.StockQuantity` trong transaction.
5. Quản trị đọc `dbo.vw_AdminDashboard`, `dbo.vw_MonthlyRevenue`, `dbo.vw_OrderDetails`.
6. CSV/ảnh là nguồn nạp catalog ban đầu; mua hàng cập nhật SQL, không cập nhật ngược CSV.

## 9. Kiểm tra sau khi đặt hàng

Trong SSMS, chọn database `PhoneStore`:

```sql
SELECT COUNT(*) AS ActiveProducts
FROM dbo.Products
WHERE IsActive = 1;

SELECT TOP (20) *
FROM dbo.vw_OrderDetails
ORDER BY OrderDate DESC, OrderId DESC;

SELECT OrderId, OrderDate, Status, TotalAmount
FROM dbo.Orders
WHERE Status = N'completed'
ORDER BY OrderDate DESC, OrderId DESC;

SELECT O.OrderId,
       O.TotalAmount,
       SUM(OI.LineTotal) AS DetailTotal
FROM dbo.Orders AS O
JOIN dbo.OrderItems AS OI ON OI.OrderId = O.OrderId
GROUP BY O.OrderId, O.TotalAmount
ORDER BY O.OrderId DESC;

-- Đối chiếu giảm giá: tổng giá gốc, số phải trả và mức giảm
SELECT O.OrderId,
       SUM(OI.LineTotal) AS GrossTotal,
       O.TotalAmount AS PayableTotal,
       SUM(OI.LineTotal) - O.TotalAmount AS DiscountAmount
FROM dbo.Orders AS O
JOIN dbo.OrderItems AS OI ON OI.OrderId = O.OrderId
GROUP BY O.OrderId, O.TotalAmount
ORDER BY O.OrderId DESC;
```

Sau đó chạy `sql/13_order_sync_check.sql`. Nếu đặt hàng thành công nhưng không có `Orders`, xem log web và kiểm tra `DB_SERVER`, `DB_USER`, `DB_PASSWORD`.

## 10. Tài khoản và phân quyền

`sql/11_security_roles.sql` tạo/cấp quyền cho quản trị, nhân viên, người xem báo cáo và tài khoản ứng dụng `phone_app`. `sql/90_demo_accounts.sql` là dữ liệu demo tùy chọn. Không dùng mật khẩu demo cho môi trường thật và không đưa mật khẩu vào README/GitHub.

## 11. Xử lý lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| `localhost:8000` không mở | `docker compose ps`, rồi `docker compose logs web`. |
| API lỗi SQL | Kiểm tra SQL Server, TCP/IP/cổng và `admin.env`; trong Docker dùng `host.docker.internal`. |
| Thiếu view/procedure | Chạy lại `02_schema_upgrade.sql`, `06_product_filters.sql`, `07_checkout.sql`. |
| Đặt hàng lỗi tồn kho | Kiểm tra `Products.StockQuantity` và chạy `13_order_sync_check.sql`. |
| Giao diện chưa đổi | `docker compose up -d --build web`, rồi Ctrl+F5. |
| `:r` không chạy | Bật **Query → SQLCMD Mode** trong SSMS. |

## 12. Sao lưu

Trước `01_database_init.sql` hoặc `91_cleanup_legacy.sql`, hãy backup database. Không chạy script hủy/tạo database trên database đang có đơn hàng cần giữ.

## 13. Trạng thái

- Endpoint `/health` và API catalog đã được kiểm tra ở local.
- Catalog web lấy từ SQL; danh mục/thương hiệu/sản phẩm không phải dữ liệu hard-code riêng của giao diện.
- Chuỗi script chính nằm trong `sql/master_run.sql`.
- Module 05 concurrency vẫn cần chạy thủ công theo mục 6.
- Không chạy `01_database_init.sql` trên database hiện tại trong hướng dẫn này để tránh mất dữ liệu.

