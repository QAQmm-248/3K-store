/* Tài khoản kiểm tra cho PhoneStore. Chạy bằng Windows Authentication trên PhoneStore. */
USE PhoneStore;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

/* admin / 123456 — chỉ dùng cho môi trường demo cục bộ */
IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'admin')
    UPDATE dbo.Users
    SET PasswordHash = N'pbkdf2_sha256$310000$oY4OKD61zQLX1tpzoZgqTw$8vKX0x_TeX8AhO4zJbKeqosgQQ2yJ6s7eVRv_4SFrkg',
        RoleName = 'admin', IsActive = 1
    WHERE Username = N'admin';
ELSE
    INSERT dbo.Users (Username, PasswordHash, RoleName, IsActive)
    VALUES (N'admin', N'pbkdf2_sha256$310000$oY4OKD61zQLX1tpzoZgqTw$8vKX0x_TeX8AhO4zJbKeqosgQQ2yJ6s7eVRv_4SFrkg', 'admin', 1);
GO

/* user_demo / 123456 — chỉ dùng cho môi trường demo cục bộ */
IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'user_demo')
    UPDATE dbo.Users
    SET PasswordHash = N'pbkdf2_sha256$310000$oY4OKD61zQLX1tpzoZgqTw$8vKX0x_TeX8AhO4zJbKeqosgQQ2yJ6s7eVRv_4SFrkg',
        RoleName = 'user', IsActive = 1
    WHERE Username = N'user_demo';
ELSE
    INSERT dbo.Users (Username, PasswordHash, RoleName, IsActive)
    VALUES (N'user_demo', N'pbkdf2_sha256$310000$oY4OKD61zQLX1tpzoZgqTw$8vKX0x_TeX8AhO4zJbKeqosgQQ2yJ6s7eVRv_4SFrkg', 'user', 1);
GO

DECLARE @UserId INT = (SELECT UserId FROM dbo.Users WHERE Username = N'user_demo');
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE UserId = @UserId)
    INSERT dbo.Customers (FullName, Phone, Email, Address, UserId)
    VALUES (N'Khách hàng dùng thử', '0900000000', N'user_demo@3kstore.local', N'Hà Nội', @UserId);
GO
