USE QLBH_3_5_12
-- Cursor
-- 4a
CREATE PROC sp_CauA 
AS
	BEGIN
		DECLARE @MAKH VARCHAR(10), @TenKH NVARCHAR(50), @DoanhThu MONEY
		DECLARE cur_CauA cursor for (	SELECT K.MAKH, TENKH, SUM(THANHTOAN)
										FROM KHACHHG K, HOADON H
										WHERE K.MAKH = H.MAKH
										GROUP BY K.MAKH, TENKH	)
		OPEN cur_CauA
		PRINT N'Mã khách hàng' + SPACE(10) + N'Tên khách hàng' + SPACE(50) + N'Doanh thu'
		FETCH NEXT FROM cur_CauA into @MAKH, @TENKH, @DOANHTHU
		WHILE(@@FETCH_STATUS = 0)
			BEGIN
				PRINT @MAKH + SPACE(10) + @TenKH + SPACE(50) + CONVERT(VARCHAR(20),@DoanhThu)
				FETCH NEXT FROM cur_CauA into @MAKH, @TENKH, @DOANHTHU
			END
	END
EXEC sp_CauA
-- 4b
CREATE PROC sp_CauB @TuNgay DATE, @DenNgay DATE
AS
	BEGIN
	    DECLARE cur_TKHang CURSOR FOR
        SELECT MAHG, TENHG FROM HANG
            
        DECLARE @MAHG_C CHAR(10), @TENHG_C NVARCHAR(50)
        DECLARE @TONGNHAP INT, @TONGBAN INT
        
        OPEN cur_TKHang
        FETCH NEXT FROM cur_TKHang INTO @MAHG_C, @TENHG_C
        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            SELECT @TONGNHAP = ISNULL(SUM(c.SOLUONG), 0)
            FROM CHITIETPN c, PHIEUNHAP p
            WHERE c.MAPN = p.MAPN AND c.MAHG = @MAHG_C AND p.NGAYNHAP BETWEEN @TuNgay AND @DenNgay
            
            SELECT @TONGBAN = ISNULL(SUM(c.SOLUONG), 0)
            FROM CHITIETHD c, HOADON h
            WHERE c.MAHD = h.MAHD AND c.MAHG = @MAHG_C AND h.NGAYBAN BETWEEN @TuNgay AND @DenNgay
            
            PRINT N'Mã hàng: ' + @MAHG_C + N', Tên: ' + @TENHG_C + N', Tổng nhập: ' + CONVERT(NVARCHAR(10),@TONGNHAP) + N', Tổng bán: ' + CONVERT(NVARCHAR(10),@TONGBAN)
            
            FETCH NEXT FROM cur_TKHang INTO @MAHG_C, @TENHG_C
        END
        CLOSE cur_TKHang
        DEALLOCATE cur_TKHang
	END
EXEC sp_CauB '2025-09-01','2025-09-17'
-- 4c
CREATE PROC sp_CauC @MAHD VARCHAR(10)
AS
	BEGIN
		DECLARE @MAHG VARCHAR(10), @TENHG NVARCHAR(50), @SLBan INT, @GiaBan MONEY, @ThanhTien MONEY
		DECLARE cur_CauC cursor for (	SELECT H.MAHG, TENHG, SOLUONG, GIA, (SOLUONG * GIA)
										FROM CHITIETHD C, HANG H, DONGIA D
										WHERE C.MAHD = @MAHD 
											AND C.MAHG = H.MAHG AND H.MAHG = D.MAHG )
		OPEN cur_CauC
		PRINT N'Mã hàng' + Space(10) + N'Tên hàng' + Space(50) + N'số lượng' + Space(10) + N'Gía bán' + Space(20) + N'Thành tiền'
		FETCH NEXT FROM cur_CauC into @MAHG, @TENHG, @SLBAN, @GIABAN, @THANHTIEN
		WHILE(@@FETCH_STATUS = 0)
			BEGIN
				PRINT @MAHG + Space(10) + @TENHG + Space(50) + CONVERT(NVARCHAR(10),@SLBAN) + Space(10) + CONVERT(NVARCHAR(20),@GIABAN) + Space(20) + CONVERT(NVARCHAR(10),@THANHTIEN)
				FETCH NEXT FROM cur_CauC into @MAHG, @TENHG, @SLBAN, @GIABAN, @THANHTIEN
			END
		CLOSE cur_CauC
		DEALLOCATE cur_CauC
	END
EXEC sp_CauC 'HD001'