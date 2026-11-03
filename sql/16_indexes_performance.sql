use PhoneStore

USE PhoneStore;
GO

-- MODULE 08: 16_indexes_performance.sql
-- Mục tiêu: Tối ưu hóa truy vấn Module 3 và Module 4 bằng Non-Clustered Index
-- 

-- Bật thống kê số lượt đọc I/O trên bộ nhớ đệm và thời gian CPU thực thi
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO


--1. KIỂM THỬ TRƯỚC KHI TẠO INDEX (GIAI ĐOẠN BASELINE)
--truy van 1
SELECT ProductId, SKU, ProductName, BrandId, SalePrice, StockQuantity
FROM dbo.Products
WHERE SalePrice BETWEEN 5000000 AND 20000000;

--truy van 2
SELECT OrderId, CustomerId, OrderDate, Status
FROM dbo.Orders
WHERE CustomerId = 1 AND Status = 'completed';

--truy van 3
SELECT OrderId, ProductId, Quantity, UnitPrice
FROM dbo.OrderItems
WHERE OrderId = 1;
GO


--2. TẠO CÁC COVERING NON-CLUSTERED INDEX

-- 1. Index trên bảng Products: Tối ưu tìm kiếm theo khoảng giá bán
DROP INDEX IF EXISTS IX_timkiemkhoanggia ON dbo.Products
CREATE NONCLUSTERED INDEX IX_timkiemkhoanggia
ON dbo.Products (SalePrice)
INCLUDE (SKU, ProductName, BrandId, StockQuantity, IsActive);
GO

-- 2. Index trên bảng Orders: Tối ưu lọc đơn theo khách hàng và trạng thái
DROP INDEX IF  EXISTS IX_locdon ON dbo.Orders
CREATE NONCLUSTERED INDEX IX_locdon
ON dbo.Orders (CustomerId, Status)
INCLUDE (OrderDate);
GO

-- 3. Index trên bảng OrderItems: Tối ưu tìm kiếm chi tiết theo mã đơn
DROP INDEX IF EXISTS IX_timkiemmadon ON dbo.OrderItems
CREATE NONCLUSTERED INDEX IX_timkiemmadon
ON dbo.OrderItems (OrderId)
INCLUDE (ProductId, Quantity, UnitPrice);
GO


--3. KIỂM THỬ SAU KHI CÓ INDEX (GIAI ĐOẠN VERIFICATION)

-- Chạy lại Truy vấn 1: Chuyển từ Table/Clustered Index Scan sang Index Seek
SELECT ProductId, SKU, ProductName, BrandId, SalePrice, StockQuantity
FROM dbo.Products
WHERE SalePrice BETWEEN 5000000 AND 20000000;

-- Chạy lại Truy vấn 2: Truy xuất thẳng bằng Index Seek trên (CustomerId, Status)
SELECT OrderId, CustomerId, OrderDate, Status
FROM dbo.Orders
WHERE CustomerId = 1 AND Status = 'completed';

-- Chạy lại Truy vấn 3: Index Seek trực tiếp theo OrderId
SELECT OrderId, ProductId, Quantity, UnitPrice
FROM dbo.OrderItems
WHERE OrderId = 1;
GO

-- Tắt thống kê sau khi hoàn tất kiểm thử
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO