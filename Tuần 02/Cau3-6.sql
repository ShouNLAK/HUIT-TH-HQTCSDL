CREATE DATABASE Cau36
USE Cau36

CREATE TABLE NHACUNGCAP (
    MANCC CHAR(10),
    TENNCC NVARCHAR(50),
    DCHI NVARCHAR(100),
    DTHOAI VARCHAR(15),
    CONSTRAINT PK_NHACUNGCAP PRIMARY KEY (MANCC)
)

CREATE TABLE MATHANG (
    MAMH CHAR(10),
    TENMH NVARCHAR(50),
    DVT NVARCHAR(20),
    QUYCACH NVARCHAR(20),
    SLTON INT,
    DG FLOAT,
    CONSTRAINT PK_MATHANG PRIMARY KEY (MAMH)
)

CREATE TABLE CUNGUNG (
    MANCC CHAR(10),
    MAMH CHAR(10),
    PRIMARY KEY (MANCC, MAMH),
    CONSTRAINT FK_CU_NCC FOREIGN KEY (MANCC) REFERENCES NHACUNGCAP(MANCC),
    CONSTRAINT FK_CU_MH FOREIGN KEY (MAMH) REFERENCES MATHANG(MAMH)
)

CREATE TABLE DATHANG (
    SODH CHAR(10),
    NGAYDH DATE,
    MANCC CHAR(10),
    SL_MATHANG INT,
    GHICHU NVARCHAR(100),
    THANHTIEN FLOAT,
    CONSTRAINT PK_DATHANG PRIMARY KEY (SODH),
    CONSTRAINT FK_DH_NCC FOREIGN KEY (MANCC) REFERENCES NHACUNGCAP(MANCC)
)

CREATE TABLE CTDH (
    SODH CHAR(10),
    MAMH CHAR(10),
    SLDAT INT,
    DGDAT FLOAT,
    PRIMARY KEY (SODH, MAMH),
    CONSTRAINT FK_CTDH_DH FOREIGN KEY (SODH) REFERENCES DATHANG(SODH),
    CONSTRAINT FK_CTDH_MH FOREIGN KEY (MAMH) REFERENCES MATHANG(MAMH)
)

CREATE TABLE GIAOHANG (
    SOGH CHAR(10),
    NGAYGH DATE,
    SODH CHAR(10),
    CONSTRAINT PK_GIAOHANG PRIMARY KEY (SOGH),
    CONSTRAINT FK_GH_DH FOREIGN KEY (SODH) REFERENCES DATHANG(SODH)
)

CREATE TABLE CTGH (
    SOGH CHAR(10),
    MAMH CHAR(10),
    SLGIAO INT,
    PRIMARY KEY (SOGH, MAMH),
    CONSTRAINT FK_CTGH_GH FOREIGN KEY (SOGH) REFERENCES GIAOHANG(SOGH),
    CONSTRAINT FK_CTGH_MH FOREIGN KEY (MAMH) REFERENCES MATHANG(MAMH)
)


--
-- a) Số lượng tồn luôn > 0
ALTER TABLE MATHANG 
ADD CONSTRAINT CHK_SLTON CHECK (SLTON > 0)

-- b) Đơn vị tính thuộc các giá trị quy định
ALTER TABLE MATHANG 
ADD CONSTRAINT CHK_DVT CHECK (DVT IN (N'lốc', N'chai', N'thùng', N'túi', N'bao', N'bình', N'hộp', N'hũ', N'gói', N'kg'))

-- c) Quy cách đóng gói thuộc các giá trị quy định
ALTER TABLE MATHANG 
ADD CONSTRAINT CHK_QUYCACH CHECK (QUYCACH IN (N'chai', N'gói', N'hộp', N'thùng'))

-- d) Tối đa 3 lần giao hàng cho 1 lần đặt hàng
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

-- e) Không được giao trễ hơn 1 tuần so với ngày đặt hàng
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

-- f) Chỉ có thể đặt các mặt hàng nhà cung cấp đó cung ứng
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

-- g) Chỉ được giao các mặt hàng khách hàng có đặt
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

-- h) Tổng số lượng giao <= Số lượng đặt
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

-- i) Tự động cập nhật SL_MATHANG = số mặt hàng trong CTDH
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

-- j) Tự động cập nhật SLTON khi giao hàng (Lưu ý: nhập kho làm TĂNG số lượng tồn)
CREATE TRIGGER trg_CapNhatTonGiaoHang ON CTGH
AFTER INSERT
AS
    BEGIN
        UPDATE MATHANG
        SET SLTON = SLTON + (SELECT SUM(SLGIAO) FROM inserted WHERE inserted.MAMH = MATHANG.MAMH)
        WHERE MAMH IN (SELECT MAMH FROM inserted)
    END

-- k) Tự động cập nhật THANHTIEN khi thêm mặt hàng vào đơn
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


--
-- a) Truyền SODH, trả về TENNCC và DCHI
CREATE PROC sp_ThongTinNCC_DonHang @SODH CHAR(10), @TENNCC NVARCHAR(50) OUTPUT, @DCHI NVARCHAR(100) OUTPUT
AS
    BEGIN
        SELECT @TENNCC = n.TENNCC, @DCHI = n.DCHI
        FROM NHACUNGCAP n, DATHANG d
        WHERE n.MANCC = d.MANCC AND d.SODH = @SODH
    END

-- b) Truyền MANCC, in ra danh sách đơn đặt hàng
CREATE PROC sp_DSDonHangCuaNCC @MANCC CHAR(10)
AS
    BEGIN
        SELECT SODH, NGAYDH, SL_MATHANG, THANHTIEN
        FROM DATHANG
        WHERE MANCC = @MANCC
    END

-- c) Truyền SOGH, trả về thành tiền (DGDAT lấy từ CTDH)
CREATE PROC sp_ThanhTienGiaoHang @SOGH CHAR(10), @THANHTIEN FLOAT OUTPUT
AS
    BEGIN
        SELECT @THANHTIEN = SUM(c.SLGIAO * ct.DGDAT)
        FROM CTGH c, GIAOHANG g, CTDH ct
        WHERE c.SOGH = g.SOGH 
          AND g.SODH = ct.SODH 
          AND c.MAMH = ct.MAMH
          AND c.SOGH = @SOGH
    END

-- d) Truyền MANCC, trả về danh sách mặt hàng cung ứng
CREATE PROC sp_DSMatHangCungUng @MANCC CHAR(10)
AS
    BEGIN
        SELECT m.MAMH, m.TENMH, m.DVT, m.QUYCACH
        FROM MATHANG m, CUNGUNG c
        WHERE m.MAMH = c.MAMH AND c.MANCC = @MANCC
    END


--
-- a) Trả về mã mặt hàng, số lượng đặt, đơn giá đặt
CREATE FUNCTION fn_ChiTietDonDatHang (@SODH CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT MAMH, SLDAT, DGDAT
        FROM CTDH
        WHERE SODH = @SODH
    )

-- b) Truyền tháng và năm, trả về DS đơn đặt hàng
CREATE FUNCTION fn_DSDonHangTheoThangNam (@THANG INT, @NAM INT) RETURNS TABLE
AS
    RETURN (
        SELECT SODH, NGAYDH, MANCC, SL_MATHANG, GHICHU, THANHTIEN
        FROM DATHANG
        WHERE MONTH(NGAYDH) = @THANG AND YEAR(NGAYDH) = @NAM
    )

-- c) Trả về số lượng CHƯA GIAO của một đơn (SL_CHUA_GIAO = SLDAT - Tổng SLGIAO)
CREATE FUNCTION fn_SLChuaGiao (@SODH CHAR(10)) RETURNS TABLE
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

-- d) Thống kê số lượng từng mặt hàng ĐÃ ĐẶT trong khoảng thời gian
CREATE FUNCTION fn_ThongKeDatHang (@TuNgay DATE, @DenNgay DATE) RETURNS TABLE
AS
    RETURN (
        SELECT c.MAMH, m.TENMH, SUM(c.SLDAT) AS TONG_SLDAT
        FROM CTDH c, DATHANG d, MATHANG m
        WHERE c.SODH = d.SODH AND c.MAMH = m.MAMH 
          AND d.NGAYDH BETWEEN @TuNgay AND @DenNgay
        GROUP BY c.MAMH, m.TENMH
    )


--
-- a) Thêm cột THANHTIEN vào GIAOHANG và viết cursor cập nhật
ALTER TABLE GIAOHANG ADD THANHTIEN FLOAT

DECLARE cur_CapNhatTTGH CURSOR FOR
    SELECT SOGH FROM GIAOHANG

DECLARE @SOGH_C CHAR(10), @TT_C FLOAT
OPEN cur_CapNhatTTGH
FETCH NEXT FROM cur_CapNhatTTGH INTO @SOGH_C
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @TT_C = SUM(c.SLGIAO * ct.DGDAT)
    FROM CTGH c, GIAOHANG g, CTDH ct
    WHERE c.SOGH = g.SOGH AND g.SODH = ct.SODH AND c.MAMH = ct.MAMH
      AND c.SOGH = @SOGH_C

    UPDATE GIAOHANG SET THANHTIEN = ISNULL(@TT_C, 0) WHERE SOGH = @SOGH_C

    FETCH NEXT FROM cur_CapNhatTTGH INTO @SOGH_C
END
CLOSE cur_CapNhatTTGH
DEALLOCATE cur_CapNhatTTGH

-- b) Thủ tục kết hợp cursor hiển thị danh sách nhập của một NCC
CREATE PROC sp_Cursor_ThongKeNhapTheoNCC @MANCC CHAR(10)
AS
    BEGIN
        DECLARE cur_TKNhap CURSOR FOR
            SELECT m.MAMH, m.TENMH
            FROM MATHANG m, CUNGUNG c
            WHERE m.MAMH = c.MAMH AND c.MANCC = @MANCC

        DECLARE @MA_C CHAR(10), @TEN_C NVARCHAR(50), @TONG_C INT
        OPEN cur_TKNhap
        FETCH NEXT FROM cur_TKNhap INTO @MA_C, @TEN_C
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tính tổng số lượng mặt hàng này do NCC này cung cấp đã được giao
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