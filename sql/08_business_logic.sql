/* Module 04 - nghiep vu, ham va trigger cua 3K Store.
   Chay sau 01_database_init.sql va file nang cap schema web.
   File chi tao/cap nhat doi tuong SQL, khong chay cac vi du sua du lieu. */ 
 use PhoneStore
 go

 --1.STORED PROCEDURE

 --Nghiep vu 1: Ban hang

CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder
    @CustomerId INT,
    @EmployeeId INT,
    @ProductId INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Stock INT;
    DECLARE @SalePrice DECIMAL(18,2);
    DECLARE @CostPrice DECIMAL(18,2);
    DECLARE @OrderId INT;

    -- Kiem tra so luong
    IF @Quantity IS NULL OR @Quantity <= 0
        THROW 51040, N'So luong phai lon hon 0.', 1;

    -- Kiem tra khach hang
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Customers
        WHERE CustomerId = @CustomerId
    )
        THROW 51041, N'Khong tim thay khach hang.', 1;

    -- Kiem tra nhan vien
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Employees
        WHERE EmployeeId = @EmployeeId
          AND IsActive = 1
    )
        THROW 51042, N'Nhan vien khong ton tai hoac da ngung hoat dong.', 1;

    -- Lay thong tin san pham
    SELECT
        @Stock = StockQuantity,
        @SalePrice = SalePrice,
        @CostPrice = CostPrice
    FROM dbo.Products
    WHERE ProductId = @ProductId
      AND IsActive = 1;

    IF @Stock IS NULL
        THROW 51043, N'San pham khong ton tai hoac da ngung ban.', 1;

    -- Kiem tra ton kho
    IF @Stock < @Quantity
        THROW 51044, N'Ton kho khong du.', 1;

    -- Tao don hang
    INSERT INTO dbo.Orders
        (CustomerId, CreatedByEmployeeId)
    VALUES
        (@CustomerId, @EmployeeId);

    SET @OrderId = CONVERT(INT, SCOPE_IDENTITY());

    -- Them chi tiet don hang
    INSERT INTO dbo.OrderItems
        (OrderId, ProductId, Quantity, UnitPrice, UnitCost)
    VALUES
        (@OrderId, @ProductId, @Quantity, @SalePrice, @CostPrice);

    -- Tru ton kho
    UPDATE dbo.Products
    SET StockQuantity = StockQuantity - @Quantity
    WHERE ProductId = @ProductId;

    -- Cap nhat trang thai va tong tien
    UPDATE dbo.Orders
    SET Status = 'completed',
        CompletedAt = SYSDATETIME(),
        TotalAmount = (
            SELECT SUM(LineTotal)
            FROM dbo.OrderItems
            WHERE OrderId = @OrderId
        )
    WHERE OrderId = @OrderId;

    -- Tra ket qua
    SELECT
        @OrderId AS OrderId,
        N'Ban hang thanh cong' AS ResultMessage;
END;
GO

--Nghiep vu 2: Nhap kho

-- Nghiep vu 2: Nhap kho
CREATE OR ALTER PROCEDURE dbo.usp_ProcessStockReceipt
    @SupplierId INT,
    @ReceivedByEmployeeId INT,
    @ProductId INT,
    @Quantity INT,
    @UnitCost DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStock INT;
    DECLARE @ReceiptId INT;

    -- Kiem tra so luong va gia nhap
    IF @Quantity IS NULL OR @Quantity <= 0
        THROW 52001, N'So luong nhap phai lon hon 0.', 1;

    IF @UnitCost IS NULL OR @UnitCost < 0
        THROW 52002, N'Gia nhap khong duoc am.', 1;

    -- Kiem tra san pham
    SELECT @CurrentStock = StockQuantity
    FROM dbo.Products
    WHERE ProductId = @ProductId;

    IF @CurrentStock IS NULL
        THROW 52003, N'San pham khong ton tai.', 1;

    -- Kiem tra nha cung cap
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Suppliers
        WHERE SupplierId = @SupplierId
    )
        THROW 52004, N'Nha cung cap khong ton tai.', 1;

    -- Kiem tra nhan vien
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Employees
        WHERE EmployeeId = @ReceivedByEmployeeId
          AND IsActive = 1
    )
        THROW 52005, N'Nhan vien khong ton tai hoac da ngung hoat dong.', 1;

    -- Tao phieu nhap kho
    INSERT INTO dbo.StockReceipts
        (SupplierId, ReceivedByEmployeeId, ReceivedAt)
    VALUES
        (@SupplierId, @ReceivedByEmployeeId, SYSDATETIME());

    SET @ReceiptId = CONVERT(INT, SCOPE_IDENTITY());

    -- Them chi tiet phieu nhap
    INSERT INTO dbo.StockReceiptItems
        (ReceiptId, ProductId, Quantity, UnitCost)
    VALUES
        (@ReceiptId, @ProductId, @Quantity, @UnitCost);

    -- Cap nhat ton kho va gia von
    UPDATE dbo.Products
    SET StockQuantity = StockQuantity + @Quantity,
        CostPrice = @UnitCost
    WHERE ProductId = @ProductId;

    -- Tra ket qua
    SELECT
        @ReceiptId AS ReceiptId,
        @ProductId AS ProductId,
        @Quantity AS QuantityReceived,
        @CurrentStock + @Quantity AS StockAfterReceipt,
        N'Nhap kho thanh cong' AS ResultMessage;
END;
GO

--Nghiep vu 3: Huy don hang va hoan lai kho

CREATE OR ALTER PROCEDURE dbo.usp_CancelAndRestock
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status VARCHAR(20);

    -- Kiem tra don hang
    SELECT @Status = Status
    FROM dbo.Orders
    WHERE OrderId = @OrderId;

    IF @Status IS NULL
        THROW 53001, N'Don hang khong ton tai.', 1;

    -- Kiem tra don hang da bi huy
    IF @Status = 'cancelled'
        THROW 53002, N'Don hang da bi huy truoc do.', 1;

    -- Neu don hang da hoan tat thi hoan lai hang vao kho
    IF @Status = 'completed'
    BEGIN
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + oi.Quantity
        FROM dbo.Products p
        INNER JOIN dbo.OrderItems oi
            ON p.ProductId = oi.ProductId
        WHERE oi.OrderId = @OrderId;
    END;

    -- Cap nhat trang thai don hang
    UPDATE dbo.Orders
    SET Status = 'cancelled',
        CompletedAt = NULL
    WHERE OrderId = @OrderId;

    -- Tra ket qua
    SELECT
        @OrderId AS OrderId,
        N'Huy don hang thanh cong' AS ResultMessage;
END;
GO

--2.FUNCTIONS

--Nghiep vu 1:Tính số tiền giảm giá cho khách hàng
/*Quy tắc: Khách mua trên 20 triệu giảm 2%, trên 50 triệu giảm 5%, tối đa 3 triệu */
CREATE OR ALTER  FUNCTION dbo.VOUCHER(
    @CustomerId INT,
    @LineTotal DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Discount DECIMAL(18,2) = 0;
    -- Nếu là khách vãng lai (CustomerId IS NULL) hoặc tổng tiền <= 0 -> không giảm
    IF @CustomerId IS NULL 
       OR EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerId = @CustomerId AND UserId IS NULL) 
       OR @LineTotal <= 0
        RETURN 0;

    IF  @LineTotal >= 50000000
        SET @Discount = @LineTotal * 0.05;
    ELSE IF  @LineTotal >= 20000000
        SET @Discount = @LineTotal * 0.02;

    -- Giới hạn mức giảm tối đa là 3.000.000 VNĐ
    IF @Discount > 3000000.00
        SET @Discount = 3000000;

    RETURN @Discount;
END;
GO
--Nghiep vu 2:Phục vụ cho chức năng tìm kiếm sản phẩm trên web/giao diện bán hàng.
/* Người dùng truyền vào Hãng (BrandId), giá tối thiểu (MinPrice), Giá tối đa (MaxPrice) để lấy danh sách máy tương ứng*/
 CREATE OR ALTER FUNCTION dbo.Timkiemsanpham
(
    @BrandId  INT,
    @MinPrice DECIMAL(18,2),
    @MaxPrice DECIMAL(18,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT p.ProductId,p.SKU,p.ProductName,b.BrandName,b.BrandId,c.CategoryName,p.SalePrice,p.StockQuantity,p.WarrantyMonths
    FROM dbo.Products p
    JOIN dbo.Brands b ON p.BrandId = b.BrandId
    JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE (p.BrandId = @BrandId OR @BrandId IS NULL)
      AND p.SalePrice BETWEEN @MinPrice AND @MaxPrice
      AND p.IsActive = 1
);
GO

--Nghiep vu 3: Tính tổng số tiền mà khách hàng đã thanh toán thành công 

CREATE OR ALTER FUNCTION dbo.Tinhtong
(
    @CustomerId INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalSpent DECIMAL(18,2) = 0;
    -- Tính tổng LineTotal từ các đơn hàng có trạng thái completed
    SELECT @TotalSpent = ISNULL(SUM(oi.LineTotal), 0)
    FROM dbo.Orders o
    JOIN dbo.OrderItems oi ON o.OrderId = oi.OrderId
    WHERE o.CustomerId = @CustomerId
      AND o.Status = 'completed';

    RETURN @TotalSpent;
END;
GO


--chay thu
select dbo.Tinhtong(1) 

-- 2. Kết hợp vào câu truy vấn danh sách khách hàng để xếp hạng thành viên
SELECT c.CustomerId,c.FullName,dbo.Tinhtong(c.CustomerId) AS TongChiTieu,
    CASE 
        WHEN dbo.Tinhtong(c.CustomerId) >= 50000000 THEN N'VIP / Kim Cương'
        WHEN dbo.Tinhtong(c.CustomerId) >= 20000000 THEN N'Thân thiết / Vàng'
        ELSE N'Tiêu chuẩn'
    END AS HangThanhVien FROM dbo.Customers c;

select *from dbo.Customers