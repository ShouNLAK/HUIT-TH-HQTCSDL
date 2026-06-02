USE QLDH_3_6_12

-- Constraint
-- 1a
ALTER TABLE MATHANG 
ADD CONSTRAINT CHK_SLTON CHECK (SLTON > 0)

-- 1b
ALTER TABLE MATHANG 
ADD CONSTRAINT CHK_DVT CHECK (DVT IN (N'lốc', N'chai', N'thùng', N'túi', N'bao', N'bình', N'hộp', N'hũ', N'gói', N'kg'))

-- 1c
ALTER TABLE MATHANG 
ADD CONSTRAINT CHK_QUYCACH CHECK (QUYCACH IN (N'chai', N'gói', N'hộp', N'thùng'))

-- Trigger
-- 1d
CREATE TRIGGER trg_ToiDa3LanGiao ON GIAOHANG
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT SODH
            FROM GIAOHANG
            WHERE SODH IN (SELECT SODH FROM inserted)
            GROUP BY SODH
            HAVING COUNT(SOGH) > 3
        )
        BEGIN
            PRINT(N'Trong một lần đặt hàng, nhà cung cấp có thể giao hàng tối đa 3 lần.')
            ROLLBACK TRANSACTION
        END
    END

-- 1e
CREATE TRIGGER trg_KhongGiaoTre ON GIAOHANG
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT i.SOGH
            FROM inserted i, DATHANG d
            WHERE i.SODH = d.SODH AND DATEDIFF(DAY, d.NGAYDH, i.NGAYGH) > 7
        )
        BEGIN
            PRINT(N'Không được phép giao hàng trễ hơn 1 tuần so với ngày đặt hàng.')
            ROLLBACK TRANSACTION
        END
    END

-- 1f
CREATE TRIGGER trg_DatHangTheoCungUng ON CTDH
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT i.MAMH
            FROM inserted i, DATHANG d
            WHERE i.SODH = d.SODH
              AND i.MAMH NOT IN (
                  SELECT c.MAMH 
                  FROM CUNGUNG c 
                  WHERE c.MANCC = d.MANCC
              )
        )
        BEGIN
            PRINT(N'Chỉ có thể đặt các mặt hàng mà nhà cung cấp đó cung ứng.')
            ROLLBACK TRANSACTION
        END
    END

-- 1g
CREATE TRIGGER trg_GiaoHangDungMatHang ON CTGH
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT i.MAMH
            FROM inserted i, GIAOHANG g
            WHERE i.SOGH = g.SOGH
              AND i.MAMH NOT IN (
                  SELECT c.MAMH
                  FROM CTDH c
                  WHERE c.SODH = g.SODH
              )
        )
        BEGIN
            PRINT(N'Chỉ được giao các mặt hàng mà khách hàng có đặt.')
            ROLLBACK TRANSACTION
        END
    END

-- 1h
CREATE TRIGGER trg_KiemTraSoLuongGiao ON CTGH
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT g.SODH, c.MAMH
            FROM GIAOHANG g, CTGH c
            WHERE g.SOGH = c.SOGH 
              AND c.MAMH IN (SELECT MAMH FROM inserted)
              AND g.SODH IN (SELECT SODH FROM GIAOHANG WHERE SOGH IN (SELECT SOGH FROM inserted))
            GROUP BY g.SODH, c.MAMH
            HAVING SUM(c.SLGIAO) > (
                SELECT ct.SLDAT 
                FROM CTDH ct 
                WHERE ct.SODH = g.SODH AND ct.MAMH = c.MAMH
            )
        )
        BEGIN
            PRINT(N'Tổng số lượng giao của một mặt hàng phải <= số lượng đặt.')
            ROLLBACK TRANSACTION
        END
    END

-- 1i
CREATE TRIGGER trg_CapNhatSLMatHang ON CTDH
AFTER INSERT, UPDATE, DELETE
AS
    BEGIN
        UPDATE DATHANG
        SET SL_MATHANG = (
            SELECT COUNT(MAMH) 
            FROM CTDH 
            WHERE CTDH.SODH = DATHANG.SODH
        )
        WHERE SODH IN (SELECT SODH FROM inserted) 
           OR SODH IN (SELECT SODH FROM deleted)
    END

-- 1j
CREATE TRIGGER trg_CapNhatTonGiaoHang ON CTGH
AFTER INSERT
AS
    BEGIN
        UPDATE MATHANG
        SET SLTON = SLTON + (SELECT SUM(SLGIAO) FROM inserted WHERE inserted.MAMH = MATHANG.MAMH)
        WHERE MAMH IN (SELECT MAMH FROM inserted)
    END

-- 1k
CREATE TRIGGER trg_CapNhatThanhTienDH ON CTDH
AFTER INSERT, UPDATE, DELETE
AS
    BEGIN
        UPDATE DATHANG
        SET THANHTIEN = (
            SELECT SUM(SLDAT * DGDAT)
            FROM CTDH
            WHERE CTDH.SODH = DATHANG.SODH
        )
        WHERE SODH IN (SELECT SODH FROM inserted)
           OR SODH IN (SELECT SODH FROM deleted)
    END

-- Procedure
-- 2a
CREATE PROC sp_ThongTinNCC_DonHang @SODH VARCHAR(10), @TENNCC NVARCHAR(50) OUTPUT, @DCHI NVARCHAR(100) OUTPUT
AS
    BEGIN
        SELECT @TENNCC = n.TENNCC, @DCHI = n.DCHI
        FROM NHACUNGCAP n, DATHANG d
        WHERE n.MANCC = d.MANCC AND d.SODH = @SODH
    END
DECLARE @TenNCC NVARCHAR(50), @DChi NVARCHAR(100)
EXEC sp_ThongTinNCC_DonHang 'DH001', @TenNCC OUTPUT, @DChi OUTPUT
PRINT N'Tên NCC: ' + ISNULL(@TenNCC, '') + N' - Địa chỉ: ' + ISNULL(@DChi, '')

-- 2b
CREATE PROC sp_DSDonHangCuaNCC @MANCC VARCHAR(10)
AS
    BEGIN
        SELECT SODH, NGAYDH, SL_MATHANG, THANHTIEN
        FROM DATHANG
        WHERE MANCC = @MANCC
    END
EXEC sp_DSDonHangCuaNCC 'NCC01'

-- 2c
CREATE PROC sp_ThanhTienGiaoHang @SOGH VARCHAR(10), @THANHTIEN MONEY OUTPUT
AS
    BEGIN
        SELECT @THANHTIEN = SUM(c.SLGIAO * ct.DGDAT)
        FROM CTGH c, GIAOHANG g, CTDH ct
        WHERE c.SOGH = g.SOGH 
          AND g.SODH = ct.SODH 
          AND c.MAMH = ct.MAMH
          AND c.SOGH = @SOGH
    END
DECLARE @TT MONEY
EXEC sp_ThanhTienGiaoHang 'GH001', @TT OUTPUT
PRINT N'Thành tiền giao hàng: ' + CONVERT(VARCHAR(20), ISNULL(@TT, 0))

-- 2d
CREATE PROC sp_DSMatHangCungUng @MANCC VARCHAR(10)
AS
    BEGIN
        SELECT m.MAMH, m.TENMH, m.DVT, m.QUYCACH
        FROM MATHANG m, CUNGUNG c
        WHERE m.MAMH = c.MAMH AND c.MANCC = @MANCC
    END
EXEC sp_DSMatHangCungUng 'NCC01'

-- Function
-- 3a
CREATE FUNCTION fn_ChiTietDonDatHang (@SODH VARCHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT MAMH, SLDAT, DGDAT
        FROM CTDH
        WHERE SODH = @SODH
    )
SELECT * FROM dbo.fn_ChiTietDonDatHang('DH001')

-- 3b
CREATE FUNCTION fn_DSDonHangTheoThangNam (@THANG INT, @NAM INT) RETURNS TABLE
AS
    RETURN (
        SELECT SODH, NGAYDH, MANCC, SL_MATHANG, GHICHU, THANHTIEN
        FROM DATHANG
        WHERE MONTH(NGAYDH) = @THANG AND YEAR(NGAYDH) = @NAM
    )
SELECT * FROM dbo.fn_DSDonHangTheoThangNam(10, 2023)

-- 3c
CREATE FUNCTION fn_SLChuaGiao (@SODH VARCHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT m.MAMH, m.TENMH, 
               c.SLDAT - ISNULL((
                   SELECT SUM(cg.SLGIAO)
                   FROM CTGH cg, GIAOHANG g
                   WHERE cg.SOGH = g.SOGH AND g.SODH = @SODH AND cg.MAMH = c.MAMH
               ), 0) AS SL_CHUA_GIAO
        FROM MATHANG m, CTDH c
        WHERE m.MAMH = c.MAMH AND c.SODH = @SODH
    )
SELECT * FROM dbo.fn_SLChuaGiao('DH001')

-- 3d
CREATE FUNCTION fn_ThongKeDatHang (@TuNgay DATE, @DenNgay DATE) RETURNS TABLE
AS
    RETURN (
        SELECT c.MAMH, m.TENMH, SUM(c.SLDAT) AS TONG_SLDAT
        FROM CTDH c, DATHANG d, MATHANG m
        WHERE c.SODH = d.SODH AND c.MAMH = m.MAMH 
          AND d.NGAYDH BETWEEN @TuNgay AND @DenNgay
        GROUP BY c.MAMH, m.TENMH
    )
SELECT * FROM dbo.fn_ThongKeDatHang('2023-10-01', '2023-11-30')

-- Cursor
-- 4a
CREATE PROC sp_CauA
AS
    BEGIN
        DECLARE cur_CapNhatTTGH CURSOR FOR
            SELECT SOGH FROM GIAOHANG

        DECLARE @SOGH_C VARCHAR(10), @TT_C MONEY
        OPEN cur_CapNhatTTGH
        FETCH NEXT FROM cur_CapNhatTTGH INTO @SOGH_C
        PRINT N'Mã giao hàng' + Space(10) + N'Thành tiền'
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @TT_C = SUM(c.SLGIAO * ct.DGDAT)
            FROM CTGH c, GIAOHANG g, CTDH ct
            WHERE c.SOGH = g.SOGH AND g.SODH = ct.SODH AND c.MAMH = ct.MAMH
              AND c.SOGH = @SOGH_C

            UPDATE GIAOHANG SET THANHTIEN = ISNULL(@TT_C, 0) WHERE SOGH = @SOGH_C
            PRINT @SOGH_C + Space(10) + CONVERT(VARCHAR(20), ISNULL(@TT_C, 0))

            FETCH NEXT FROM cur_CapNhatTTGH INTO @SOGH_C
        END
        CLOSE cur_CapNhatTTGH
        DEALLOCATE cur_CapNhatTTGH
    END
EXEC sp_CauA
SELECT * FROM GIAOHANG

-- 4b
CREATE PROC sp_CauB @MANCC VARCHAR(10)
AS
    BEGIN
        DECLARE cur_TKNhap CURSOR FOR
            SELECT m.MAMH, m.TENMH
            FROM MATHANG m, CUNGUNG c
            WHERE m.MAMH = c.MAMH AND c.MANCC = @MANCC

        DECLARE @MA_C VARCHAR(10), @TEN_C NVARCHAR(50), @TONG_C INT
        OPEN cur_TKNhap
        FETCH NEXT FROM cur_TKNhap INTO @MA_C, @TEN_C
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @TONG_C = ISNULL(SUM(cg.SLGIAO), 0)
            FROM CTGH cg, GIAOHANG g, DATHANG d
            WHERE cg.SOGH = g.SOGH AND g.SODH = d.SODH
              AND d.MANCC = @MANCC AND cg.MAMH = @MA_C

            PRINT N'Mã hàng: ' + @MA_C + N', Tên hàng: ' + @TEN_C + N', Tổng đã nhập: ' + CAST(@TONG_C AS VARCHAR)
            
            FETCH NEXT FROM cur_TKNhap INTO @MA_C, @TEN_C
        END
        CLOSE cur_TKNhap
        DEALLOCATE cur_TKNhap
    END
EXEC sp_CauB 'NCC01'