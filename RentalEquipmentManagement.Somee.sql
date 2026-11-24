SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Category.Icon và SubCategory.ImageUrl lấy ảnh từ WebApi/wwwroot/categories.
-- Equipment.ImageUrl lấy ảnh từ WebApi/wwwroot/equipment.

--DROP TABLE Equipment;
--DROP TABLE SubCategory;
--DROP TABLE Category;


IF OBJECT_ID(N'dbo.Category', N'U') IS NULL
CREATE TABLE Category(
    CategoryId SMALLINT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    CategoryName NVARCHAR(64) NOT NULL,
    Title NVARCHAR(128) NOT NULL,
    Description NVARCHAR(1024) NOT NULL,
    Icon VARCHAR(16) NOT NULL
);
GO


IF NOT EXISTS (SELECT 1 FROM Category)
BEGIN
    SET IDENTITY_INSERT Category ON;

    INSERT INTO Category (CategoryId, CategoryName, Title, Description, Icon) VALUES
        (1, N'Thiết bị văn phòng', N'Thiết bị văn phòng cho thuê', N'Các thiết bị văn phòng phục vụ công việc, hội họp, đào tạo và hoạt động hàng ngày của các đơn vị.', 'office.png'),
        (2, N'Thiết bị công nghệ', N'Thiết bị công nghệ cho thuê', N'Các thiết bị công nghệ phục vụ công việc, học tập, trình chiếu và các hoạt động chuyên môn.', 'technology.png'),
        (3, N'Thiết bị sự kiện', N'Thiết bị sự kiện cho thuê', N'Các thiết bị phục vụ hội nghị, hội thảo, sự kiện và các chương trình được tổ chức tại các đơn vị.', 'event.png'),
        (4, N'Thiết bị quay phim', N'Thiết bị quay phim và chụp ảnh', N'Các thiết bị quay phim, chụp ảnh phục vụ truyền thông, sự kiện và sản xuất nội dung.', 'camera.png'),
        (5, N'Thiết bị âm thanh', N'Thiết bị âm thanh cho thuê', N'Các thiết bị âm thanh phục vụ hội nghị, hội thảo, sự kiện và các hoạt động của đơn vị.', 'audio.png');

    SET IDENTITY_INSERT Category OFF;
END
GO


--DROP TABLE SubCategory;
GO

IF OBJECT_ID(N'dbo.SubCategory', N'U') IS NULL
CREATE TABLE SubCategory(
    SubCategoryId SMALLINT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    CategoryId SMALLINT NOT NULL REFERENCES Category(CategoryId),
    SubCategoryName NVARCHAR(64) NOT NULL,
    Title NVARCHAR(128) NOT NULL,
    Description NVARCHAR(1024) NOT NULL,
    ImageUrl NVARCHAR(32) NOT NULL
);
GO


IF NOT EXISTS (SELECT 1 FROM SubCategory)
BEGIN
    SET IDENTITY_INSERT SubCategory ON;

    INSERT INTO SubCategory (SubCategoryId, CategoryId, SubCategoryName, Title, Description, ImageUrl) VALUES
        (1, 1, N'Máy chiếu', N'Máy chiếu văn phòng', N'Máy chiếu phục vụ trình chiếu trong phòng họp, lớp học, đào tạo và hội nghị.', 'projector.png'),
        (2, 1, N'Màn chiếu', N'Màn chiếu văn phòng', N'Màn chiếu phục vụ trình chiếu, hội họp, đào tạo và tổ chức sự kiện.', 'screen.png'),
        (3, 1, N'Máy in', N'Máy in văn phòng', N'Máy in phục vụ công việc văn phòng, in tài liệu và hồ sơ.', 'printer.png'),

        (4, 2, N'Laptop', N'Laptop cho thuê', N'Laptop phục vụ công việc, đào tạo, hội nghị và các hoạt động chuyên môn.', 'laptop.png'),
        (5, 2, N'Máy tính để bàn', N'Máy tính để bàn cho thuê', N'Máy tính để bàn phục vụ công việc văn phòng và các hoạt động tại đơn vị.', 'desktop.png'),
        (6, 2, N'Máy tính bảng', N'Máy tính bảng cho thuê', N'Máy tính bảng phục vụ trình diễn, khảo sát, đào tạo và công việc.', 'tablet.png'),

        (7, 3, N'Đèn sự kiện', N'Đèn phục vụ sự kiện', N'Các loại đèn phục vụ sân khấu, hội nghị và các chương trình sự kiện.', 'event-light.png'),
        (8, 3, N'Backdrop', N'Backdrop sự kiện', N'Thiết bị và vật dụng phục vụ trang trí hội nghị, hội thảo và sự kiện.', 'backdrop.png'),

        (9, 4, N'Camera', N'Camera quay phim', N'Camera phục vụ quay phim, ghi hình các chương trình và hoạt động của đơn vị.', 'camera.png'),
        (10, 4, N'Máy ảnh', N'Máy ảnh chuyên nghiệp', N'Máy ảnh phục vụ chụp ảnh sự kiện, truyền thông và sản xuất nội dung.', 'camera-photo.png'),

        (11, 5, N'Loa', N'Loa sự kiện', N'Loa phục vụ hội nghị, hội thảo, sân khấu và các chương trình sự kiện.', 'speaker.png'),
        (12, 5, N'Micro', N'Micro không dây', N'Micro phục vụ hội họp, hội nghị, hội thảo và các chương trình sự kiện.', 'microphone.png');

    SET IDENTITY_INSERT SubCategory OFF;
END
GO


--DROP TABLE Equipment;
GO

IF OBJECT_ID(N'dbo.Equipment', N'U') IS NULL
CREATE TABLE Equipment(
    EquipmentId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    SubCategoryId SMALLINT NOT NULL REFERENCES SubCategory(SubCategoryId),
    EquipmentName NVARCHAR(128) NOT NULL,
    ImageUrl VARCHAR(32) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Brand NVARCHAR(64),
    Model NVARCHAR(128),
    Specifications NVARCHAR(256),
    Unit NVARCHAR(128),
    Status NVARCHAR(64)
);
GO


IF NOT EXISTS (SELECT 1 FROM Equipment)
BEGIN
    SET IDENTITY_INSERT Equipment ON;

    INSERT INTO Equipment (EquipmentId, SubCategoryId, EquipmentName, Price, ImageUrl, Brand, Model, Specifications, Unit, Status) VALUES

        -- MÁY CHIẾU

        (1001, 1, N'Máy chiếu Epson EB-X06', 300000, 'epson-eb-x06.png', N'Epson', N'EB-X06', N'3600 Lumens, XGA, HDMI', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1002, 1, N'Máy chiếu Epson EB-E01', 250000, 'epson-eb-e01.png', N'Epson', N'EB-E01', N'3300 Lumens, XGA, HDMI', N'Đơn vị Bình Dương', N'Sẵn sàng'),
        (1003, 1, N'Máy chiếu BenQ MS550', 280000, 'benq-ms550.png', N'BenQ', N'MS550', N'3600 Lumens, SVGA, HDMI', N'Đơn vị Đồng Nai', N'Đang cho thuê'),
        (1004, 1, N'Máy chiếu ViewSonic PA503W', 320000, 'viewsonic-pa503w.png', N'ViewSonic', N'PA503W', N'3800 Lumens, WXGA, HDMI', N'Đơn vị Cần Thơ', N'Sẵn sàng'),

        -- MÀN CHIẾU

        (1005, 2, N'Màn chiếu 120 inch', 150000, 'screen-120.png', N'Vertex', N'120 inch', N'Màn chiếu kéo tay 120 inch', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1006, 2, N'Màn chiếu 150 inch', 200000, 'screen-150.png', N'Vertex', N'150 inch', N'Màn chiếu kéo tay 150 inch', N'Đơn vị Bình Dương', N'Sẵn sàng'),
        (1007, 2, N'Màn chiếu điện 120 inch', 250000, 'electric-screen-120.png', N'Grandview', N'120 inch', N'Màn chiếu điện điều khiển từ xa', N'Đơn vị Đồng Nai', N'Đang bảo trì'),

        -- MÁY IN

        (1008, 3, N'Máy in Canon LBP 623', 200000, 'canon-lbp623.png', N'Canon', N'LBP 623', N'Laser, A4, USB, WiFi', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1009, 3, N'Máy in HP LaserJet Pro M404', 220000, 'hp-m404.png', N'HP', N'LaserJet Pro M404', N'Laser, A4, USB, WiFi', N'Đơn vị Bình Dương', N'Sẵn sàng'),

        -- LAPTOP

        (1010, 4, N'Laptop Dell Latitude 5420', 400000, 'dell-latitude-5420.png', N'Dell', N'Latitude 5420', N'Core i5, RAM 16GB, SSD 512GB', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1011, 4, N'Laptop Lenovo ThinkPad T14', 450000, 'lenovo-t14.png', N'Lenovo', N'ThinkPad T14', N'Core i5, RAM 16GB, SSD 512GB', N'Đơn vị Bình Dương', N'Sẵn sàng'),
        (1012, 4, N'Laptop HP ProBook 450', 350000, 'hp-probook-450.png', N'HP', N'ProBook 450', N'Core i5, RAM 16GB, SSD 512GB', N'Đơn vị Đồng Nai', N'Đang cho thuê'),
        (1013, 4, N'Laptop Asus ExpertBook', 380000, 'asus-expertbook.png', N'Asus', N'ExpertBook', N'Core i5, RAM 16GB, SSD 512GB', N'Đơn vị Cần Thơ', N'Sẵn sàng'),

        -- MÁY TÍNH ĐỂ BÀN

        (1014, 5, N'Máy tính Dell OptiPlex', 300000, 'dell-optiplex.png', N'Dell', N'OptiPlex 7090', N'Core i5, RAM 16GB, SSD 512GB', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1015, 5, N'Máy tính HP ProDesk', 280000, 'hp-prodesk.png', N'HP', N'ProDesk 400', N'Core i5, RAM 16GB, SSD 512GB', N'Đơn vị Bình Dương', N'Sẵn sàng'),

        -- MÁY TÍNH BẢNG

        (1016, 6, N'iPad Air', 250000, 'ipad-air.png', N'Apple', N'iPad Air', N'10.9 inch, WiFi, 64GB', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1017, 6, N'Samsung Galaxy Tab S9', 280000, 'galaxy-tab-s9.png', N'Samsung', N'Galaxy Tab S9', N'11 inch, WiFi, 128GB', N'Đơn vị Bình Dương', N'Sẵn sàng'),

        -- ĐÈN SỰ KIỆN

        (1018, 7, N'Đèn LED Studio', 300000, 'led-studio.png', N'Godox', N'SL60W', N'60W, ánh sáng LED', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1019, 7, N'Đèn LED sân khấu', 350000, 'led-stage.png', N'Beam', N'LED Stage 200', N'200W, RGB', N'Đơn vị Đồng Nai', N'Sẵn sàng'),

        -- BACKDROP

        (1020, 8, N'Backdrop hội nghị 3x5m', 300000, 'backdrop-3x5.png', N'EventPro', N'3x5m', N'Khung nhôm, kích thước 3x5m', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1021, 8, N'Backdrop sự kiện 4x6m', 450000, 'backdrop-4x6.png', N'EventPro', N'4x6m', N'Khung nhôm, kích thước 4x6m', N'Đơn vị Bình Dương', N'Sẵn sàng'),

        -- CAMERA

        (1022, 9, N'Sony Alpha A7 III', 700000, 'sony-a7iii.png', N'Sony', N'Alpha A7 III', N'Full Frame, 24MP, 4K', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1023, 9, N'Canon EOS R6', 800000, 'canon-eos-r6.png', N'Canon', N'EOS R6', N'Full Frame, 20MP, 4K', N'Đơn vị Đồng Nai', N'Đang cho thuê'),
        (1024, 9, N'Sony FX30', 750000, 'sony-fx30.png', N'Sony', N'FX30', N'APS-C, 4K, Cinema Camera', N'Đơn vị Cần Thơ', N'Sẵn sàng'),

        -- MÁY ẢNH

        (1025, 10, N'Canon EOS R8', 650000, 'canon-eos-r8.png', N'Canon', N'EOS R8', N'Full Frame, 24MP, 4K', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1026, 10, N'Sony Alpha A7 IV', 850000, 'sony-a7iv.png', N'Sony', N'Alpha A7 IV', N'Full Frame, 33MP, 4K', N'Đơn vị Bình Dương', N'Sẵn sàng'),

        -- LOA

        (1027, 11, N'Loa JBL PartyBox 310', 600000, 'jbl-partybox.png', N'JBL', N'PartyBox 310', N'Công suất lớn, Bluetooth', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1028, 11, N'Loa JBL EON 715', 500000, 'jbl-eon.png', N'JBL', N'EON 715', N'1300W, Bluetooth', N'Đơn vị Bình Dương', N'Sẵn sàng'),
        (1029, 11, N'Loa Yamaha DBR12', 450000, 'yamaha-dbr12.png', N'Yamaha', N'DBR12', N'1000W, 12 inch', N'Đơn vị Đồng Nai', N'Đang cho thuê'),

        -- MICRO

        (1030, 12, N'Micro không dây Shure SM58', 250000, 'shure-sm58.png', N'Shure', N'SM58', N'Micro không dây UHF', N'Đơn vị TP. Hồ Chí Minh', N'Sẵn sàng'),
        (1031, 12, N'Micro không dây Sennheiser', 300000, 'sennheiser-micro.png', N'Sennheiser', N'XSW 1-825', N'Micro không dây UHF', N'Đơn vị Bình Dương', N'Sẵn sàng');

    SET IDENTITY_INSERT Equipment OFF;
END
GO
IF OBJECT_ID(N'dbo.Member', N'U') IS NULL
CREATE TABLE Member(
    MemberId VARCHAR(32) NOT NULL PRIMARY KEY,
    GivenName NVARCHAR(16) NOT NULL,
    Surname NVARCHAR(16),
    Email VARCHAR(64) NOT NULL UNIQUE,
    Password NVARCHAR(128) NOT NULL,
    Role SMALLINT NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Member_IsActive DEFAULT 1
);
GO

IF COL_LENGTH('dbo.Member', 'IsActive') IS NULL
    ALTER TABLE dbo.Member ADD IsActive BIT NOT NULL CONSTRAINT DF_Member_IsActive DEFAULT 1;
GO

IF COL_LENGTH('dbo.Member', 'EmailVerified') IS NULL
    ALTER TABLE dbo.Member ADD EmailVerified BIT NOT NULL CONSTRAINT DF_Member_EmailVerified DEFAULT 0;
IF COL_LENGTH('dbo.Member', 'SecurityVersion') IS NULL
    ALTER TABLE dbo.Member ADD SecurityVersion INT NOT NULL CONSTRAINT DF_Member_SecurityVersion DEFAULT 0;
GO

IF OBJECT_ID(N'dbo.EmailCode', N'U') IS NULL
CREATE TABLE dbo.EmailCode(
    MemberId VARCHAR(32) NOT NULL REFERENCES dbo.Member(MemberId),
    Purpose VARCHAR(10) NOT NULL,
    CodeHash VARCHAR(64) NOT NULL,
    SentAt DATETIME2 NOT NULL,
    Attempts INT NOT NULL,
    PRIMARY KEY (MemberId, Purpose)
);
GO

IF OBJECT_ID(N'dbo.Cart', N'U') IS NULL
CREATE TABLE Cart(
    CartId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    MemberId VARCHAR(32) NOT NULL REFERENCES Member(MemberId),
    EquipmentId INT NOT NULL REFERENCES Equipment(EquipmentId),
    Quantity SMALLINT NOT NULL CHECK (Quantity BETWEEN 1 AND 365),
    UNIQUE (MemberId, EquipmentId)
);
GO

IF OBJECT_ID(N'dbo.Status', N'U') IS NULL
CREATE TABLE Status(
    StatusId INT NOT NULL PRIMARY KEY,
    StatusName NVARCHAR(64) NOT NULL UNIQUE
);
GO

IF NOT EXISTS (SELECT 1 FROM Status)
INSERT INTO Status (StatusId, StatusName) VALUES
    (1, N'Đã hủy'),
    (2, N'Chờ xác nhận'),
    (3, N'Đã xác nhận'),
    (4, N'Đã bàn giao'),
    (5, N'Đã trả');
GO

IF OBJECT_ID(N'dbo.Rental', N'U') IS NULL
CREATE TABLE Rental(
    RentalId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    MemberId VARCHAR(32) NOT NULL REFERENCES Member(MemberId),
    StatusId INT NOT NULL REFERENCES Status(StatusId),
    RentalDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

IF OBJECT_ID(N'dbo.RentalDetail', N'U') IS NULL
CREATE TABLE RentalDetail(
    RentalId INT NOT NULL REFERENCES Rental(RentalId),
    EquipmentId INT NOT NULL REFERENCES Equipment(EquipmentId),
    Quantity SMALLINT NOT NULL CHECK (Quantity BETWEEN 1 AND 365),
    Price DECIMAL(10, 2) NOT NULL,
    Unit NVARCHAR(128),
    PRIMARY KEY (RentalId, EquipmentId)
);
GO

IF OBJECT_ID(N'dbo.RentalPayment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RentalPayment(
        PaymentId BIGINT NOT NULL PRIMARY KEY IDENTITY(1000000000, 1),
        RentalId INT NOT NULL REFERENCES dbo.Rental(RentalId),
        Method VARCHAR(10) NOT NULL,
        Amount BIGINT NOT NULL CHECK (Amount > 0),
        State INT NOT NULL CHECK (State IN (0, 1, 2)),
        CreatedAt DATETIME2 NOT NULL,
        CheckoutUrl NVARCHAR(1024),
        PaidAt DATETIME2
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.RentalPayment') AND name = N'UX_RentalPayment_Open')
    CREATE UNIQUE INDEX UX_RentalPayment_Open ON dbo.RentalPayment(RentalId) WHERE State < 2;
GO

CREATE OR ALTER PROC AddCart
    @MemberId VARCHAR(32),
    @EquipmentId INT,
    @Quantity SMALLINT
AS
BEGIN
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    -- Serialize changes to this member's cart with checkout.
    DECLARE @Member VARCHAR(32);
    SELECT @Member = MemberId FROM Member WITH (UPDLOCK, HOLDLOCK) WHERE MemberId = @MemberId;

    IF @Member IS NULL OR @Quantity NOT BETWEEN 1 AND 365 OR NOT EXISTS (
        SELECT 1 FROM Equipment WHERE EquipmentId = @EquipmentId AND Status = N'Sẵn sàng'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE Cart SET Quantity = @Quantity WHERE MemberId = @MemberId AND EquipmentId = @EquipmentId;
    IF @@ROWCOUNT = 0
        INSERT INTO Cart (MemberId, EquipmentId, Quantity) VALUES (@MemberId, @EquipmentId, @Quantity);

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROC AddRental
    @MemberId VARCHAR(32),
    @RentalId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @RentalId = 0;
    BEGIN TRANSACTION;

    DECLARE @Member VARCHAR(32);
    SELECT @Member = MemberId FROM Member WITH (UPDLOCK, HOLDLOCK) WHERE MemberId = @MemberId;

    DECLARE @Items INT;
    SELECT @Items = COUNT(*) FROM Cart WITH (UPDLOCK, HOLDLOCK) WHERE MemberId = @MemberId;

    IF @Member IS NULL OR @Items = 0
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE e SET Status = N'Đang cho thuê'
        FROM Equipment e JOIN Cart c ON c.EquipmentId = e.EquipmentId
        WHERE c.MemberId = @MemberId AND e.Status = N'Sẵn sàng';

    IF @@ROWCOUNT <> @Items
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    INSERT INTO Rental (MemberId, StatusId) VALUES (@MemberId, 2);
    SET @RentalId = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO RentalDetail (RentalId, EquipmentId, Quantity, Price, Unit)
        SELECT @RentalId, c.EquipmentId, c.Quantity, e.Price, e.Unit
        FROM Cart c JOIN Equipment e ON e.EquipmentId = c.EquipmentId
        WHERE c.MemberId = @MemberId;

    DELETE FROM Cart WHERE MemberId = @MemberId;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROC UpdateRentalStatus
    @RentalId INT,
    @StatusId INT,
    @MemberId VARCHAR(32),
    @IsAdmin BIT,
    @Changed INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Changed = 0;
    BEGIN TRANSACTION;

    UPDATE Rental SET StatusId = @StatusId
        WHERE RentalId = @RentalId AND
            (@StatusId <> 1 OR NOT EXISTS (
                SELECT 1 FROM RentalPayment WHERE RentalId = @RentalId AND State < 2
            )) AND (
            (@IsAdmin = 1 AND (
                (StatusId = 2 AND @StatusId IN (1, 3)) OR
                (StatusId = 3 AND @StatusId IN (1, 4)) OR
                (StatusId = 4 AND @StatusId = 5)
            )) OR
            (@IsAdmin = 0 AND MemberId = @MemberId AND StatusId = 2 AND @StatusId = 1)
        );

    SET @Changed = @@ROWCOUNT;
    IF @Changed = 1 AND @StatusId IN (1, 5)
        UPDATE e SET Status = N'Sẵn sàng'
            FROM Equipment e JOIN RentalDetail d ON d.EquipmentId = e.EquipmentId
            WHERE d.RentalId = @RentalId AND e.Status = N'Đang cho thuê';

    COMMIT TRANSACTION;
END;
GO
