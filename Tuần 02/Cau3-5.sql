CREATE DATABASE Cau35
USE Cau35

CREATE TABLE KHACHHG (
    MAKH CHAR(10),
    TENKH NVARCHAR(50),
    DCHI NVARCHAR(100),
    DTHOAI VARCHAR(15),
    CONSTRAINT PK_KHACHHG PRIMARY KEY (MAKH)
)

CREATE TABLE NHASX (
    MANSX CHAR(10),
    TENNSX NVARCHAR(50),
    DCHI NVARCHAR(100),
    DTHOAI VARCHAR(15),
    CONSTRAINT PK_NHASX PRIMARY KEY (MANSX)
)

CREATE TABLE NHACC (
    MANCC CHAR(10),
    TENNCC NVARCHAR(50),
    DCHI NVARCHAR(100),
    DTHOAI VARCHAR(15),
    CONSTRAINT PK_NHACC PRIMARY KEY (MANCC)
)

CREATE TABLE HANG (
    MAHG CHAR(10),
    TENHG NVARCHAR(50),
    DVT NVARCHAR(20),
    SOLUONGTON INT,
    MANSX CHAR(10),
    TINHTRANG NVARCHAR(20),
    CONSTRAINT PK_HANG PRIMARY KEY (MAHG),
    CONSTRAINT FK_HANG_NHASX FOREIGN KEY (MANSX) REFERENCES NHASX(MANSX)
)

CREATE TABLE PHIEUNHAP (
    MAPN CHAR(10),
    NGAYNHAP DATE,
    MANCC CHAR(10),
    TIENNHAP FLOAT,
    CONSTRAINT PK_PHIEUNHAP PRIMARY KEY (MAPN),
    CONSTRAINT FK_PHIEUNHAP_NHACC FOREIGN KEY (MANCC) REFERENCES NHACC(MANCC)
)

CREATE TABLE CHITIETPN (
    MAPN CHAR(10),
    MAHG CHAR(10),
    SOLUONG INT,
    GIANHAP FLOAT,
    THANHTIEN FLOAT,
    PRIMARY KEY (MAPN, MAHG),
    CONSTRAINT FK_CTPN_PHIEUNHAP FOREIGN KEY (MAPN) REFERENCES PHIEUNHAP(MAPN),
    CONSTRAINT FK_CTPN_HANG FOREIGN KEY (MAHG) REFERENCES HANG(MAHG)
)

CREATE TABLE HOADON (
    MAHD CHAR(10),
    NGAYBAN DATE,
    MAKH CHAR(10),
    TIENBAN FLOAT,
    GIAMGIA FLOAT, 
    THANHTOAN FLOAT,
    CONSTRAINT PK_HOADON PRIMARY KEY (MAHD),
    CONSTRAINT FK_HOADON_KHACHHG FOREIGN KEY (MAKH) REFERENCES KHACHHG(MAKH)
)

CREATE TABLE CHITIETHD (
    MAHD CHAR(10),
    MAHG CHAR(10),
    SOLUONG INT,
    GIABAN FLOAT,
    THANHTIEN FLOAT,
    PRIMARY KEY (MAHD, MAHG),
    CONSTRAINT FK_CTHD_HOADON FOREIGN KEY (MAHD) REFERENCES HOADON(MAHD),
    CONSTRAINT FK_CTHD_HANG FOREIGN KEY (MAHG) REFERENCES HANG(MAHG)
)

CREATE TABLE DONGIA (
    MAHG CHAR(10),
    NGAYCN DATE,
    GIA FLOAT,
    PRIMARY KEY (MAHG, NGAYCN),
    CONSTRAINT FK_DONGIA_HANG FOREIGN KEY (MAHG) REFERENCES HANG(MAHG)
)


--
-- a) Mỗi khi thêm dữ liệu vào bảng PHIEUNHAP thì NGAYNHAP là ngày hiện hành
CREATE TRIGGER trg_PhieuNhap_NgayHienHanh ON PHIEUNHAP
AFTER INSERT
AS
    BEGIN
        UPDATE PHIEUNHAP
        SET NGAYNHAP = GETDATE()
        WHERE MAPN IN (SELECT MAPN FROM inserted)
    END

-- b) Mỗi khi thêm dữ liệu vào bảng HOADON thì NGAYBAN là ngày hiện hành
CREATE TRIGGER trg_HoaDon_NgayHienHanh ON HOADON
AFTER INSERT
AS
    BEGIN
        UPDATE HOADON
        SET NGAYBAN = GETDATE()
        WHERE MAHD IN (SELECT MAHD FROM inserted)
    END

-- c) Mỗi khi nhập hàng (bảng CHITIETPN)
CREATE TRIGGER trg_NhapHang ON CHITIETPN
AFTER INSERT
AS
    BEGIN
        -- Cập nhật cột THANHTIEN
        UPDATE CHITIETPN
        SET THANHTIEN = SOLUONG * GIANHAP
        WHERE MAPN IN (SELECT MAPN FROM inserted) AND MAHG IN (SELECT MAHG FROM inserted)

        -- Cập nhật cột TIENNHAP của phiếu nhập
        UPDATE PHIEUNHAP
        SET TIENNHAP = (SELECT SUM(THANHTIEN) FROM CHITIETPN WHERE CHITIETPN.MAPN = PHIEUNHAP.MAPN)
        WHERE MAPN IN (SELECT MAPN FROM inserted)

        -- Tăng số lượng tồn của mặt hàng nhập
        UPDATE HANG
        SET SOLUONGTON = ISNULL(SOLUONGTON, 0) + (SELECT SUM(SOLUONG) FROM inserted WHERE inserted.MAHG = HANG.MAHG)
        WHERE MAHG IN (SELECT MAHG FROM inserted)
    END

-- d) Mỗi khi bán hàng (bảng CHITIETHD)
CREATE TRIGGER trg_BanHang ON CHITIETHD
AFTER INSERT
AS
    BEGIN
        -- Kiểm tra số lượng tồn
        IF EXISTS (
            SELECT i.MAHG
            FROM inserted i, HANG h
            WHERE i.MAHG = h.MAHG AND h.SOLUONGTON < i.SOLUONG
        )
        BEGIN
            PRINT(N'Không đủ hàng để bán.')
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Lấy giá mới nhất từ DONGIA cập nhật vào GIABAN
        UPDATE CHITIETHD
        SET GIABAN = (
            SELECT TOP 1 GIA 
            FROM DONGIA 
            WHERE DONGIA.MAHG = CHITIETHD.MAHG 
            ORDER BY NGAYCN DESC
        )
        WHERE MAHD IN (SELECT MAHD FROM inserted) AND MAHG IN (SELECT MAHG FROM inserted)

        -- Cập nhật THANHTIEN = SOLUONG * GIABAN
        UPDATE CHITIETHD
        SET THANHTIEN = SOLUONG * GIABAN
        WHERE MAHD IN (SELECT MAHD FROM inserted) AND MAHG IN (SELECT MAHG FROM inserted)

        -- Cập nhật TIENBAN của hóa đơn
        UPDATE HOADON
        SET TIENBAN = (SELECT SUM(THANHTIEN) FROM CHITIETHD WHERE CHITIETHD.MAHD = HOADON.MAHD)
        WHERE MAHD IN (SELECT MAHD FROM inserted)

        -- Giảm số lượng tồn của mặt hàng
        UPDATE HANG
        SET SOLUONGTON = SOLUONGTON - (SELECT SUM(SOLUONG) FROM inserted WHERE inserted.MAHG = HANG.MAHG)
        WHERE MAHG IN (SELECT MAHG FROM inserted)

        -- Nếu số lượng tồn = 0 thì chuyển tình trạng
        UPDATE HANG
        SET TINHTRANG = N'Hết hàng'
        WHERE SOLUONGTON <= 0 AND MAHG IN (SELECT MAHG FROM inserted)

        -- Cập nhật GIAMGIA và THANHTOAN cho HOADON
        UPDATE HOADON
        SET GIAMGIA = 
            CASE 
                WHEN TIENBAN < 200000 THEN 0
                WHEN TIENBAN >= 200000 AND TIENBAN < 500000 THEN 0.05
                WHEN TIENBAN >= 500000 THEN 0.1
            END
        WHERE MAHD IN (SELECT MAHD FROM inserted)

        UPDATE HOADON
        SET THANHTOAN = TIENBAN - (TIENBAN * GIAMGIA)
        WHERE MAHD IN (SELECT MAHD FROM inserted)
    END


--
-- a) Truyền mã khách hàng, in ra danh sách các hóa đơn của khách hàng đó
CREATE PROC sp_DSHoaDonKH @MAKH CHAR(10)
AS
    BEGIN
        SELECT MAHD, NGAYBAN, TIENBAN, THANHTOAN
        FROM HOADON
        WHERE MAKH = @MAKH
    END

-- b) Truyền mã hóa đơn, trả về ngày lập và trị giá của hóa đơn đó
CREATE PROC sp_ThongTinHoaDon @MAHD CHAR(10), @NGAYLAP DATE OUTPUT, @TRIGIA FLOAT OUTPUT
AS
    BEGIN
        SELECT @NGAYLAP = NGAYBAN, @TRIGIA = THANHTOAN
        FROM HOADON
        WHERE MAHD = @MAHD
    END

-- c) Truyền mã hàng, trả về tên hàng, số lượng tồn và tên NSX tương ứng
CREATE PROC sp_ThongTinHang @MAHG CHAR(10), @TENHG NVARCHAR(50) OUTPUT, @SOLUONGTON INT OUTPUT, @TENNSX NVARCHAR(50) OUTPUT
AS
    BEGIN
        SELECT @TENHG = h.TENHG, @SOLUONGTON = h.SOLUONGTON, @TENNSX = n.TENNSX
        FROM HANG h, NHASX n
        WHERE h.MANSX = n.MANSX AND h.MAHG = @MAHG
    END

-- d) Truyền mã nhà sản xuất, in ra danh sách các mặt hàng của NSX đó
CREATE PROC sp_DSHangCuaNSX @MANSX CHAR(10)
AS
    BEGIN
        SELECT MAHG, TENHG, DVT
        FROM HANG
        WHERE MANSX = @MANSX
    END

-- e) Truyền mã hóa đơn, trả về thông tin khách hàng đã mua hóa đơn đó
CREATE PROC sp_KhachHangCuaHD @MAHD CHAR(10), @TENKH NVARCHAR(50) OUTPUT, @DCHI NVARCHAR(100) OUTPUT, @DTHOAI VARCHAR(15) OUTPUT
AS
    BEGIN
        SELECT @TENKH = k.TENKH, @DCHI = k.DCHI, @DTHOAI = k.DTHOAI
        FROM KHACHHG k, HOADON h
        WHERE k.MAKH = h.MAKH AND h.MAHD = @MAHD
    END

-- f) Truyền mã khách hàng, trả về phân loại khách hàng dựa trên doanh số
CREATE PROC sp_PhanLoaiKhachHang @MAKH CHAR(10), @LOAIKH NVARCHAR(30) OUTPUT
AS
    BEGIN
        DECLARE @DOANHSO FLOAT
        SELECT @DOANHSO = SUM(THANHTOAN)
        FROM HOADON
        WHERE MAKH = @MAKH

        IF @DOANHSO >= 10000000
            SET @LOAIKH = N'VIP'
        ELSE IF @DOANHSO >= 6000000 AND @DOANHSO < 10000000
            SET @LOAIKH = N'KH thành viên'
        ELSE
            SET @LOAIKH = N'KH thân thiết'
    END

-- g) Truyền mã hàng sẽ trả về đơn giá mới nhất
CREATE PROC sp_DonGiaMoiNhat @MAHG CHAR(10), @GIAMOINHAT FLOAT OUTPUT
AS
    BEGIN
        SELECT TOP 1 @GIAMOINHAT = GIA
        FROM DONGIA
        WHERE MAHG = @MAHG
        ORDER BY NGAYCN DESC
    END


--
-- a) Truyền mã KH, trả về số lượng hóa đơn đã mua
CREATE FUNCTION fn_SoLuongHD (@MAKH CHAR(10)) RETURNS INT
AS
    BEGIN
        DECLARE @SL INT
        SELECT @SL = COUNT(MAHD) 
        FROM HOADON 
        WHERE MAKH = @MAKH
        RETURN ISNULL(@SL, 0)
    END

-- b) Truyền mã hóa đơn, trả về trị giá của hóa đơn
CREATE FUNCTION fn_TriGiaHD (@MAHD CHAR(10)) RETURNS FLOAT
AS
    BEGIN
        DECLARE @TRIGIA FLOAT
        SELECT @TRIGIA = THANHTOAN 
        FROM HOADON 
        WHERE MAHD = @MAHD
        RETURN ISNULL(@TRIGIA, 0)
    END

-- c) Truyền mã hàng và ngày bán, trả về tổng số lượng đã bán ra
CREATE FUNCTION fn_TongSLBan (@MAHG CHAR(10), @NGAYBAN DATE) RETURNS INT
AS
    BEGIN
        DECLARE @TONG INT
        SELECT @TONG = SUM(c.SOLUONG)
        FROM CHITIETHD c, HOADON h
        WHERE c.MAHD = h.MAHD AND c.MAHG = @MAHG AND h.NGAYBAN = @NGAYBAN
        RETURN ISNULL(@TONG, 0)
    END

-- d) Truyền mã KH, trả về doanh số của khách hàng đó
CREATE FUNCTION fn_DoanhSoKH (@MAKH CHAR(10)) RETURNS FLOAT
AS
    BEGIN
        DECLARE @DS FLOAT
        SELECT @DS = SUM(THANHTOAN) 
        FROM HOADON 
        WHERE MAKH = @MAKH
        RETURN ISNULL(@DS, 0)
    END

-- e) Truyền mã NCC, trả về bảng các mặt hàng đã nhập
CREATE FUNCTION fn_DSHangNhapTuNCC (@MANCC CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT h.MAHG, h.TENHG, SUM(c.SOLUONG) AS TONGSL
        FROM HANG h, CHITIETPN c, PHIEUNHAP p
        WHERE h.MAHG = c.MAHG AND c.MAPN = p.MAPN AND p.MANCC = @MANCC
        GROUP BY h.MAHG, h.TENHG
    )

-- f) Truyền mã hóa đơn, trả về chi tiết các mặt hàng đã mua
CREATE FUNCTION fn_ChiTietHoaDonBan (@MAHD CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT h.MAHG, h.TENHG, c.SOLUONG, c.GIABAN, c.THANHTIEN
        FROM HANG h, CHITIETHD c
        WHERE h.MAHG = c.MAHG AND c.MAHD = @MAHD
    )

-- g) Truyền mã hàng, trả về thông tin SL nhập, SL xuất, SL còn lại
CREATE FUNCTION fn_ThongKeHangHoa (@MAHG CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT h.MAHG, h.TENHG, 
               ISNULL((SELECT SUM(SOLUONG) FROM CHITIETPN WHERE MAHG = h.MAHG), 0) AS SL_NHAP,
               ISNULL((SELECT SUM(SOLUONG) FROM CHITIETHD WHERE MAHG = h.MAHG), 0) AS SL_XUAT,
               h.SOLUONGTON AS SL_CONLAI
        FROM HANG h
        WHERE h.MAHG = @MAHG
    )


--
-- a) SP kết hợp cursor hiển thị mã KH, tên KH và doanh số
CREATE PROC sp_Cursor_DoanhSoKhachHang
AS
    BEGIN
        DECLARE cur_DSKhachHang CURSOR FOR
            SELECT k.MAKH, k.TENKH, ISNULL(SUM(h.THANHTOAN), 0)
            FROM KHACHHG k, HOADON h
            WHERE k.MAKH = h.MAKH
            GROUP BY k.MAKH, k.TENKH
            
        DECLARE @MA_C CHAR(10), @TEN_C NVARCHAR(50), @DOANHSO_C FLOAT
        OPEN cur_DSKhachHang
        FETCH NEXT FROM cur_DSKhachHang INTO @MA_C, @TEN_C, @DOANHSO_C
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT N'Mã KH: ' + @MA_C + N', Tên: ' + @TEN_C + N', Doanh số: ' + CAST(@DOANHSO_C AS VARCHAR)
            FETCH NEXT FROM cur_DSKhachHang INTO @MA_C, @TEN_C, @DOANHSO_C
        END
        CLOSE cur_DSKhachHang
        DEALLOCATE cur_DSKhachHang
    END

-- b) SP kết hợp cursor hiển thị mã hàng, tên hàng, tổng nhập, tổng bán trong khoảng thời gian
CREATE PROC sp_Cursor_ThongKeXuatNhap @TuNgay DATE, @DenNgay DATE
AS
    BEGIN
        DECLARE cur_TKHang CURSOR FOR
            SELECT MAHG, TENHG FROM HANG
            
        DECLARE @MAHG_C CHAR(10), @TENHG_C NVARCHAR(50)
        DECLARE @TONGNHAP INT, @TONGBAN INT
        
        OPEN cur_TKHang
        FETCH NEXT FROM cur_TKHang INTO @MAHG_C, @TENHG_C
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tính tổng nhập trong khoảng thời gian
            SELECT @TONGNHAP = ISNULL(SUM(c.SOLUONG), 0)
            FROM CHITIETPN c, PHIEUNHAP p
            WHERE c.MAPN = p.MAPN AND c.MAHG = @MAHG_C AND p.NGAYNHAP BETWEEN @TuNgay AND @DenNgay
            
            -- Tính tổng bán trong khoảng thời gian
            SELECT @TONGBAN = ISNULL(SUM(c.SOLUONG), 0)
            FROM CHITIETHD c, HOADON h
            WHERE c.MAHD = h.MAHD AND c.MAHG = @MAHG_C AND h.NGAYBAN BETWEEN @TuNgay AND @DenNgay
            
            PRINT N'Mã hàng: ' + @MAHG_C + N', Tên: ' + @TENHG_C + N', Tổng nhập: ' + CAST(@TONGNHAP AS VARCHAR) + N', Tổng bán: ' + CAST(@TONGBAN AS VARCHAR)
            
            FETCH NEXT FROM cur_TKHang INTO @MAHG_C, @TENHG_C
        END
        CLOSE cur_TKHang
        DEALLOCATE cur_TKHang
    END

-- c) SP kết hợp cursor hiển thị thông tin hóa đơn (mã hàng, tên, số lượng, giá bán mới nhất, thành tiền)
CREATE PROC sp_Cursor_ChiTietHD @MAHD CHAR(10)
AS
    BEGIN
        DECLARE cur_CTHD CURSOR FOR
            SELECT h.MAHG, h.TENHG, c.SOLUONG, c.THANHTIEN
            FROM HANG h, CHITIETHD c
            WHERE h.MAHG = c.MAHG AND c.MAHD = @MAHD

        DECLARE @MA_HG_C CHAR(10), @TEN_HG_C NVARCHAR(50), @SL_C INT, @TT_C FLOAT
        DECLARE @GIA_MOI_NHAT FLOAT
        
        OPEN cur_CTHD
        FETCH NEXT FROM cur_CTHD INTO @MA_HG_C, @TEN_HG_C, @SL_C, @TT_C
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lấy giá mới nhất từ bảng đơn giá
            SELECT TOP 1 @GIA_MOI_NHAT = GIA 
            FROM DONGIA 
            WHERE MAHG = @MA_HG_C 
            ORDER BY NGAYCN DESC

            PRINT N'Mã HG: ' + @MA_HG_C + N', Tên: ' + @TEN_HG_C + 
                  N', SL bán: ' + CAST(@SL_C AS VARCHAR) + 
                  N', Giá mới nhất: ' + CAST(ISNULL(@GIA_MOI_NHAT, 0) AS VARCHAR) + 
                  N', Thành tiền: ' + CAST(@TT_C AS VARCHAR)
                  
            FETCH NEXT FROM cur_CTHD INTO @MA_HG_C, @TEN_HG_C, @SL_C, @TT_C
        END
        CLOSE cur_CTHD
        DEALLOCATE cur_CTHD
    END