
/*
MODULE 05 - TRANSACTIONS
Database: PhoneStore

  - Su dung lai cac stored procedure da tao o Module 04.

Cac stored procedure Module 04 duoc su dung:
  1. dbo.usp_CreateOrder
  2. dbo.usp_ProcessStockReceipt
  3. dbo.usp_CancelAndRestock

Cac wrapper Module 05:
  1. dbo.usp_CreateOrder_Transaction
  2. dbo.usp_ProcessStockReceipt_Transaction
  3. dbo.usp_CancelAndRestock_Transaction

Luu y:
  - Khong DROP DATABASE, khong xoa du lieu mau.
  - Chay file nay de tao/cap nhat cac wrapper cua Module 05.
*/

USE PhoneStore;
GO

/* =========================================================
   1. TRANSACTION BAN HANG
   Goi stored procedure usp_CreateOrder 
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder_Transaction
    @CustomerId INT,
    @EmployeeId INT,
    @ProductId INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
        Khoa dong san pham trong suot transaction.
        Tranh hai phien cung ban mot san pham
        va doc cung mot muc ton kho.
        */

        DECLARE @Stock INT;

        SELECT @Stock = StockQuantity
        FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId;

        /*
        Goi nghiep vu ban hang cua Module 04.
        Module 04 tu kiem tra san pham, so luong,
        khach hang, nhan vien va cap nhat ton kho.
        */

        EXEC dbo.usp_CreateOrder
            @CustomerId = @CustomerId,
            @EmployeeId = @EmployeeId,
            @ProductId = @ProductId,
            @Quantity = @Quantity;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


/* =========================================================
   2. TRANSACTION NHAP KHO
   Goi stored procedure usp_ProcessStockReceipt 
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_ProcessStockReceipt_Transaction
    @SupplierId INT,
    @ReceivedByEmployeeId INT,
    @ProductId INT,
    @Quantity INT,
    @UnitCost DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
        Khoa dong san pham de cac giao dich nhap kho
        va ban hang tren cung san pham duoc tuan tu hoa.
        */

        DECLARE @CurrentStock INT;

        SELECT @CurrentStock = StockQuantity
        FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId;

        /*
        Goi nghiep vu nhap kho cua Module 04.
        */

        EXEC dbo.usp_ProcessStockReceipt
            @SupplierId = @SupplierId,
            @ReceivedByEmployeeId = @ReceivedByEmployeeId,
            @ProductId = @ProductId,
            @Quantity = @Quantity,
            @UnitCost = @UnitCost;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


/* =========================================================
   3. TRANSACTION HUY DON HANG VA HOAN KHO
   Goi stored procedure usp_CancelAndRestock 
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_CancelAndRestock_Transaction
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
        Khoa dong don hang de tranh hai phien
        cung huy mot don va hoan kho hai lan.
        */

        DECLARE @Status VARCHAR(20);

        SELECT @Status = Status
        FROM dbo.Orders WITH (UPDLOCK, HOLDLOCK)
        WHERE OrderId = @OrderId;

        /*
        Goi nghiep vu huy don va hoan kho cua Module 04.
        */

        EXEC dbo.usp_CancelAndRestock
            @OrderId = @OrderId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


/* =========================================================
   4. KIEM THU BAN HANG - THANH CONG
   Giao dich duoc ROLLBACK ben ngoai de hoan nguyen du lieu.
   ========================================================= */

--BEGIN TRANSACTION;

--SELECT
--    ProductId,
--    StockQuantity AS StockBefore
--FROM dbo.Products
--WHERE ProductId = 1;


--EXEC dbo.usp_CreateOrder_Transaction
--    @CustomerId = 1,
--    @EmployeeId = 1,
--    @ProductId = 1,
--    @Quantity = 2;

--SELECT
--    ProductId,
--    StockQuantity AS StockAfter
--FROM dbo.Products
--WHERE ProductId = 1;

--SELECT TOP (1) *
--FROM dbo.Orders
--ORDER BY OrderId DESC;

--SELECT TOP (1) *
--FROM dbo.OrderItems
--ORDER BY OrderId DESC;

--ROLLBACK TRANSACTION;
--GO

/* =========================================================
   5. KIEM THU BAN HANG - THAT BAI
   Du kien loi 51044 neu ton kho khong du.
   ========================================================= */

-- BEGIN TRY
--     EXEC dbo.usp_CreateOrder_Transaction
--         @CustomerId = 1,
--         @EmployeeId = 1,
--         @ProductId = 1,
--         @Quantity = 999999;
-- END TRY
-- BEGIN CATCH
--     SELECT
--         ERROR_NUMBER() AS ErrorNumber,
--         ERROR_MESSAGE() AS ErrorMessage;
-- END CATCH;
-- GO


/* =========================================================
   6. KIEM THU NHAP KHO - THANH CONG
   Giao dich duoc ROLLBACK ben ngoai de hoan nguyen du lieu.
   ========================================================= */
--BEGIN TRANSACTION;

--SELECT
--    ProductId,
--    StockQuantity AS StockBefore
--FROM dbo.Products
--WHERE ProductId = 1;

--EXEC dbo.usp_ProcessStockReceipt_Transaction
--    @SupplierId = 1,
--    @ReceivedByEmployeeId = 1,
--    @ProductId = 1,
--    @Quantity = 5,
--    @UnitCost = 23800000;

--SELECT
--    ProductId,
--    StockQuantity AS StockAfter,
--    CostPrice
--FROM dbo.Products
--WHERE ProductId = 1;

--SELECT TOP (1) *
--FROM dbo.StockReceipts
--ORDER BY ReceiptId DESC;

--SELECT TOP (1) *
--FROM dbo.StockReceiptItems
--ORDER BY ReceiptId DESC;

--ROLLBACK TRANSACTION;
--GO

/* =========================================================
   7. KIEM THU NHAP KHO - THAT BAI
   Du kien loi 52003 tu Module 04.
   ========================================================= */

-- BEGIN TRY
--     EXEC dbo.usp_ProcessStockReceipt_Transaction
--         @SupplierId = 1,
--         @ReceivedByEmployeeId = 1,
--         @ProductId = -999999,
--         @Quantity = 5,
--         @UnitCost = 23800000;
-- END TRY
-- BEGIN CATCH
--     SELECT
--         ERROR_NUMBER() AS ErrorNumber,
--         ERROR_MESSAGE() AS ErrorMessage;
-- END CATCH;
-- GO


/* =========================================================
   8. KIEM THU HUY DON HANG - THANH CONG
   Chi chay khi co OrderId hop le.
   Nen chon don completed de kiem tra hoan kho.
   ========================================================= */

-- BEGIN TRANSACTION;

-- EXEC dbo.usp_CancelAndRestock_Transaction
--     @OrderId = 1;

-- SELECT OrderId, Status
-- FROM dbo.Orders
-- WHERE OrderId = 1;

-- SELECT p.ProductId, p.StockQuantity
-- FROM dbo.Products p
-- INNER JOIN dbo.OrderItems oi
--     ON p.ProductId = oi.ProductId
-- WHERE oi.OrderId = 1;

-- ROLLBACK TRANSACTION;
-- GO

--/* =========================================================
--   9. KIEM THU HUY DON HANG - THAT BAI
--   Du kien loi 53001 neu don hang khong ton tai.
--   ========================================================= */

-- BEGIN TRY
--     EXEC dbo.usp_CancelAndRestock_Transaction
--         @OrderId = -999999;
-- END TRY
-- BEGIN CATCH
--     SELECT
--         ERROR_NUMBER() AS ErrorNumber,
--         ERROR_MESSAGE() AS ErrorMessage;
-- END CATCH;
-- GO


