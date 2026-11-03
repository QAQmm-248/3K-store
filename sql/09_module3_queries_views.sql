USE PhoneStore
GO

--TRUY VẤN
--1. Hiển thị danh sách sản phẩm kèm thương hiệu và danh mục
SELECT
    P.ProductId,
    P.SKU,
    P.ProductName,
    B.BrandName,
    C.CategoryName,
    P.SalePrice,
    P.StockQuantity
FROM dbo.Products P
JOIN dbo.Brands B ON P.BrandId = B.BrandId
JOIN dbo.Categories C ON P.CategoryId = C.CategoryId
WHERE P.IsActive = 1
ORDER BY P.ProductName, P.SKU;

--2. Tìm kiếm sản phẩm theo tên ( VD: Tìm các sản phẩm có tên chứa từ Samsung)
SELECT
    ProductId,
    ProductName,
    SalePrice,
    StockQuantity
FROM dbo.Products
WHERE ProductName LIKE N'%Samsung%';

--3. Tìm sản phẩm có giá bán trong khoảng từ 5 triệu đến 20 triệu đồng
SELECT
    ProductId,
    ProductName,
    SalePrice
FROM dbo.Products
WHERE SalePrice BETWEEN 5000000 AND 20000000
ORDER BY SalePrice ASC;

--4. Thống kê doanh thu của từng đơn hàng đã hoàn thành
SELECT
    O.OrderId,
    O.OrderDate,
    C.FullName AS CustomerName,
    SUM(OI.LineTotal) AS TotalRevenue
FROM Orders O
JOIN OrderItems OI ON O.OrderId = OI.OrderId
LEFT JOIN Customers C ON O.CustomerId = C.CustomerId
WHERE O.Status = 'completed'
GROUP BY
    O.OrderId,
    O.OrderDate,
    C.FullName
ORDER BY TotalRevenue DESC;

--5. Thống kê số lượng sản phẩm bán ra theo từng thương hiệu, chỉ lấy thương hiệu bán được từ 5 sản phẩm trở lên
SELECT
    B.BrandName,
    SUM(OI.Quantity) AS TotalQuantitySold
FROM Brands B
JOIN Products P ON B.BrandId = P.BrandId
JOIN OrderItems OI ON P.ProductId = OI.ProductId
JOIN Orders O ON OI.OrderId = O.OrderId
WHERE O.Status = 'completed'
GROUP BY B.BrandName
HAVING SUM(OI.Quantity) >= 5
ORDER BY TotalQuantitySold DESC;

--6. Tìm 10 sản phẩm bán chạy nhất
SELECT TOP 10
    P.ProductId,
    P.ProductName,
    SUM(OI.Quantity) AS TotalSold
FROM Products P
JOIN OrderItems OI ON P.ProductId = OI.ProductId
JOIN Orders O ON OI.OrderId = O.OrderId
WHERE O.Status = 'completed'
GROUP BY
    P.ProductId,
    P.ProductName
ORDER BY TotalSold DESC;

--7. Tìm sản phẩm có giá bán cao hơn giá bán trung bình của toàn bộ sản phẩm
SELECT
    ProductId,
    ProductName,
    SalePrice
FROM Products
WHERE SalePrice > (
    SELECT AVG(SalePrice)
    FROM dbo.Products
    WHERE IsActive = 1
)
ORDER BY SalePrice DESC;

--8. Tìm khách hàng chưa từng có đơn hàng hoàn thành
SELECT
    CustomerId,
    FullName
FROM Customers
EXCEPT
SELECT
    C.CustomerId,
    C.FullName
FROM Customers C
JOIN Orders O ON C.CustomerId = O.CustomerId
WHERE O.Status = 'completed';

--9. Lấy 10% sản phẩm có giá bán cao nhất
SELECT TOP 10 PERCENT
    ProductId,
    ProductName,
    SalePrice
FROM Products
ORDER BY SalePrice DESC;

--10. Thống kê doanh thu theo từng tháng
SELECT
    YEAR(O.OrderDate) AS Nam,
    MONTH(O.OrderDate) AS Thang,
    COUNT(DISTINCT O.OrderId) AS SoDonHang,
    SUM(OI.LineTotal) AS TongDoanhThu
FROM Orders O
JOIN OrderItems OI ON O.OrderId = OI.OrderId
WHERE O.Status = 'completed'
GROUP BY
    YEAR(O.OrderDate),
    MONTH(O.OrderDate)
ORDER BY Nam, Thang;

--11. Tìm khách hàng có tổng giá trị mua hàng cao nhất
SELECT TOP 5
    C.CustomerId,
    C.FullName,
    COUNT(DISTINCT O.OrderId) AS SoDonHang,
    SUM(OI.LineTotal) AS TongTienMua
FROM Customers C
JOIN Orders O ON C.CustomerId = O.CustomerId
JOIN OrderItems OI ON O.OrderId = OI.OrderId
WHERE O.Status = 'completed'
GROUP BY
    C.CustomerId,
    C.FullName
ORDER BY TongTienMua DESC;

--12. Thống kê số lượng hàng đã nhập theo nhà cung cấp
SELECT
    S.SupplierId,
    S.SupplierName,
    COUNT(DISTINCT SR.ReceiptId) AS SoPhieuNhap,
    SUM(SRI.Quantity) AS TongSoLuongNhap
FROM Suppliers S
JOIN StockReceipts SR ON S.SupplierId = SR.SupplierId
JOIN StockReceiptItems SRI ON SR.ReceiptId = SRI.ReceiptId
GROUP BY
    S.SupplierId,
    S.SupplierName
ORDER BY TongSoLuongNhap DESC;

--VIEW
--1. Danh sách sản phẩm đầy đủ thông tin
CREATE OR ALTER VIEW dbo.vw_ProductCatalog
AS
SELECT
    P.ProductId,
    P.SKU,
    P.ProductName,
    B.BrandName,
    C.CategoryName,
    P.SalePrice,
    P.CostPrice,
    P.StockQuantity,
    P.WarrantyMonths
FROM dbo.Products P
JOIN dbo.Brands B ON P.BrandId = B.BrandId
JOIN dbo.Categories C ON P.CategoryId = C.CategoryId
WHERE P.IsActive = 1;

GO
SELECT * FROM dbo.vw_ProductCatalog;

--2. Báo cáo doanh thu theo đơn hàng
CREATE OR ALTER VIEW dbo.vw_OrderRevenue
AS
SELECT
    O.OrderId,
    O.OrderDate,
    O.Status,
    C.FullName AS CustomerName,
    E.FullName AS EmployeeName,
    SUM(OI.LineTotal) AS TotalRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI ON O.OrderId = OI.OrderId
LEFT JOIN dbo.Customers C ON O.CustomerId = C.CustomerId
LEFT JOIN dbo.Employees E ON O.CreatedByEmployeeId = E.EmployeeId
WHERE O.Status = 'completed'
GROUP BY
    O.OrderId,
    O.OrderDate,
    O.Status,
    C.FullName,
    E.FullName;

GO
SELECT * FROM dbo.vw_OrderRevenue
ORDER BY TotalRevenue DESC;


--3. Báo cáo số lượng sản phẩm đã bán
CREATE OR ALTER VIEW dbo.vw_ProductSalesSummary
AS
SELECT
    P.ProductId,
    P.ProductName,
    B.BrandName,
    SUM(OI.Quantity) AS TotalQuantitySold,
    SUM(OI.LineTotal) AS TotalRevenue
FROM dbo.Products P
JOIN dbo.Brands B ON P.BrandId = B.BrandId
JOIN dbo.OrderItems OI ON P.ProductId = OI.ProductId
JOIN dbo.Orders O ON OI.OrderId = O.OrderId
WHERE O.Status = 'completed'
GROUP BY
    P.ProductId,
    P.ProductName,
    B.BrandName;

GO
SELECT * FROM dbo.vw_ProductSalesSummary
ORDER BY TotalQuantitySold DESC;

--4. Báo cáo tồn kho
CREATE OR ALTER VIEW dbo.vw_InventoryReport
AS
SELECT
    P.ProductId,
    P.SKU,
    P.ProductName,
    P.StockQuantity,
    P.CostPrice,
    P.StockQuantity * P.CostPrice AS InventoryValue,
    CASE
        WHEN P.StockQuantity <= 5 THEN N'Sắp hết hàng'
        WHEN P.StockQuantity <= 10 THEN N'Tồn kho thấp'
        ELSE N'Còn hàng'
    END AS StockStatus
FROM dbo.Products P
WHERE P.IsActive = 1;

GO
SELECT * FROM dbo.vw_InventoryReport;

--5. Thống kê nhập hàng theo nhà cung cấp
CREATE OR ALTER VIEW dbo.vw_SupplierImportSummary
AS
SELECT
    S.SupplierId,
    S.SupplierName,
    COUNT(DISTINCT SR.ReceiptId) AS SoPhieuNhap,
    SUM(SRI.Quantity) AS TongSoLuongNhap,
    SUM(SRI.Quantity * SRI.UnitCost) AS TongGiaTriNhap
FROM dbo.Suppliers S
JOIN dbo.StockReceipts SR ON S.SupplierId = SR.SupplierId
JOIN dbo.StockReceiptItems SRI ON SR.ReceiptId = SRI.ReceiptId
GROUP BY
    S.SupplierId,
    S.SupplierName;

GO
SELECT * FROM dbo.vw_SupplierImportSummary
ORDER BY TongGiaTriNhap DESC;

