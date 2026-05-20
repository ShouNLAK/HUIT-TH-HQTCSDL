CREATE DATABASE CAU33
USE CAU33
--
CREATE TABLE LOP (
    MALOP CHAR(10),
    TENLOP NVARCHAR(50),
    SISO INT,
    CONSTRAINT PK_LOP PRIMARY KEY (MALOP)
)

CREATE TABLE SINHVIEN (
    MASV CHAR(10) ,
    HOTEN NVARCHAR(50),
    NGSINH DATE,
    GIOITINH NVARCHAR(3),
    QUEQUAN NVARCHAR(50),
    MALOP CHAR(10),
    DIEMTB FLOAT,
    XEPLOAI NVARCHAR(20),
    CONSTRAINT PK_SINHVIEN PRIMARY KEY (MASV),
    CONSTRAINT FK_SINHVIEN_LOP FOREIGN KEY (MALOP) REFERENCES LOP(MALOP)
)

CREATE TABLE MONHOC (
    MAMH CHAR(10),
    TENMH NVARCHAR(50),
    SOTC INT,
    BATBUOC INT,
    CONSTRAINT PK_MONHOC PRIMARY KEY (MAMH)
)

CREATE TABLE KETQUA (
    MASV CHAR(10),
    MAMH CHAR(10),
    HOCKY INT,
    DIEMTHI FLOAT,
    PRIMARY KEY (MASV, MAMH, HOCKY),
    CONSTRAINT FK_KETQUA_SINHVIEN FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    CONSTRAINT FK_KETQUA_MONHOC FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH)
)

SELECT * FROM LOP
SELECT * FROM SINHVIEN
SELECT * FROM MONHOC
SELECT * FROM KETQUA
--
-- a) Cập nhật sĩ số bảng LOP khi thêm, xóa, sửa trên bảng SINHVIEN
CREATE TRIGGER trg_CapNhatSiSo ON SINHVIEN
AFTER INSERT, UPDATE, DELETE
AS
    BEGIN
        UPDATE LOP
        SET SISO = (    SELECT COUNT(MASV) 
                        FROM SINHVIEN 
                        WHERE SINHVIEN.MALOP = LOP.MALOP)
        WHERE MALOP IN (SELECT MALOP FROM inserted)
           OR MALOP IN (SELECT MALOP FROM deleted)
    END

-- b) Mỗi sinh viên đăng ký tối đa 5 môn trong mỗi học kỳ
CREATE TRIGGER trg_ToiDa5Mon ON KETQUA
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT MASV, HOCKY
            FROM KETQUA
            WHERE MASV IN (SELECT MASV FROM inserted)
            GROUP BY MASV, HOCKY
            HAVING COUNT(MAMH) > 5
        )
        BEGIN
            PRINT(N'Mỗi sinh viên chỉ được đăng ký tối đa 5 môn trong mỗi học kỳ.')
            ROLLBACK TRANSACTION
        END
    END

-- c) Mỗi sinh viên đăng ký tối đa 10 tín chỉ môn bắt buộc trong mỗi học kỳ
CREATE TRIGGER trg_ToiDa10TinChiBatBuoc ON KETQUA
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT k.MASV, k.HOCKY
            FROM KETQUA k, MONHOC m
            WHERE k.MAMH = m.MAMH
              AND m.BATBUOC = 1 
              AND k.MASV IN (SELECT MASV FROM inserted)
            GROUP BY k.MASV, k.HOCKY
            HAVING SUM(m.SOTC) > 10
        )
        BEGIN
            PRINT(N'Sinh viên chỉ đăng ký tối đa 10 tín chỉ bắt buộc mỗi học kỳ.')
            ROLLBACK TRANSACTION
        END
    END

-- d) Cập nhật DIEMTB và XEPLOAI khi điểm thi được cập nhật (lấy điểm cao nhất nếu học nhiều lần)
CREATE TRIGGER trg_CapNhatDiemTB_XepLoai ON KETQUA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE SINHVIEN
    SET DIEMTB = ( SELECT SUM (DIEMTHI * SOTC) / SUM(SOTC)
                   FROM KETQUA k, MONHOC m
                   WHERE k.MASV = SINHVIEN.MASV
                     AND k.MAMH = m.MAMH )
    WHERE MASV IN (SELECT MASV FROM inserted)
       OR MASV IN (SELECT MASV FROM deleted)

    UPDATE SINHVIEN
    SET XEPLOAI = 
        CASE
            WHEN DIEMTB < 5 THEN N'Yếu'
            WHEN DIEMTB >= 5 AND DIEMTB < 7 THEN N'Trung bình'
            WHEN DIEMTB >= 7 AND DIEMTB < 8 THEN N'Khá'
            WHEN DIEMTB >= 8 THEN N'Giỏi'
        END
    WHERE MASV IN (SELECT MASV FROM inserted)
       OR MASV IN (SELECT MASV FROM deleted)
END

--
-- a) Thêm một lớp (SISO mặc định 0)
CREATE PROC sp_ThemLop @MALOP VARCHAR(10), @TENLOP NVARCHAR(50)
AS
    BEGIN
        INSERT INTO LOP(MALOP, TENLOP, SISO) VALUES (@MALOP, @TENLOP, 0)
    END

-- b) Thêm một sinh viên (DIEMTB và XEPLOAI là NULL)
CREATE PROC sp_ThemSinhVien @MASV VARCHAR(10), @HOTEN NVARCHAR(50), @NGSINH DATE, @GIOITINH NVARCHAR(10), @QUEQUAN NVARCHAR(100), @MALOP VARCHAR(10)
AS
    BEGIN
        INSERT INTO SINHVIEN(MASV, HOTEN, NGSINH, GIOITINH, QUEQUAN, MALOP, DIEMTB, XEPLOAI) 
        VALUES (@MASV, @HOTEN, @NGSINH, @GIOITINH, @QUEQUAN, @MALOP, NULL, NULL)
    END

-- c) Cập nhật lại SISO của lớp theo MALOP
CREATE PROC sp_CapNhatSiso_MaLop @MALOP VARCHAR(10)
AS
    BEGIN
        UPDATE LOP 
        SET SISO = (SELECT COUNT(*) FROM SINHVIEN WHERE MALOP = @MALOP)
        WHERE MALOP = @MALOP
    END

-- d) Cộng 1 điểm cho sinh viên
CREATE PROC sp_Cong1Diem @MASV VARCHAR(10), @MAMH VARCHAR(10), @HOCKY INT
AS
    BEGIN
        UPDATE KETQUA 
        SET DIEMTHI = DIEMTHI + 1
        WHERE MASV = @MASV AND MAMH = @MAMH AND HOCKY = @HOCKY
    END

-- e) Truyền MASV, trả về hoten, ngsinh, gioitinh, tenlop
CREATE PROC sp_ThongTinSinhVien @MASV VARCHAR(10),
                                @HOTEN NVARCHAR(50) OUTPUT, @NGSINH DATE OUTPUT, @GIOITINH NVARCHAR(10) OUTPUT, @TENLOP NVARCHAR(50) OUTPUT
AS
    BEGIN
        SELECT @HOTEN = s.HOTEN, @NGSINH = s.NGSINH, @GIOITINH = s.GIOITINH, @TENLOP = l.TENLOP
        FROM SINHVIEN s, LOP l
        WHERE s.MALOP = l.MALOP AND s.MASV = @MASV
    END

-- f) Truyền MASV, trả về diemtb, xeploai
CREATE PROC sp_DiemVaXepLoai    @MASV VARCHAR(10),
                                @DIEMTB FLOAT OUTPUT, @XEPLOAI NVARCHAR(20) OUTPUT
AS
    BEGIN
        SELECT @DIEMTB = DIEMTB, @XEPLOAI = XEPLOAI 
        FROM SINHVIEN 
        WHERE MASV = @MASV
    END

-- g) Trả về danh sách sinh viên của lớp đó (Lưu ý: SP dùng SELECT trả thẳng về Result Set)
CREATE PROC sp_DSSinhVienLop @MALOP VARCHAR(10)
AS
    BEGIN
        SELECT * 
        FROM SINHVIEN 
        WHERE MALOP = @MALOP
    END

-- h) Trả về tổng số sinh viên học môn học trong học kỳ đó
CREATE PROC sp_TongSVHocMon @MAMH VARCHAR(10), @HOCKY INT,
                            @TONGSV INT OUTPUT
AS
    BEGIN
        SELECT @TONGSV = COUNT(MASV) 
        FROM KETQUA 
        WHERE MAMH = @MAMH AND HOCKY = @HOCKY
    END

-- i) Truyền 3 tham số và trả về trạng thái
CREATE PROC sp_KiemTraTrangThaiMonHoc   @MASV VARCHAR(10), @MAMH VARCHAR(10), @HOCKY INT,
                                        @TRANGTHAI NVARCHAR(50) OUTPUT
AS
    BEGIN
        IF NOT EXISTS (SELECT * FROM KETQUA WHERE MASV = @MASV AND MAMH = @MAMH AND HOCKY = @HOCKY)
            SET @TRANGTHAI = N'chưa đăng ký'
        ELSE
            BEGIN
                DECLARE @DIEM FLOAT
                SELECT @DIEM = DIEMTHI 
                FROM KETQUA 
                WHERE MASV = @MASV AND MAMH = @MAMH AND HOCKY = @HOCKY
        
                IF @DIEM IS NULL
                    SET @TRANGTHAI = N'chưa có điểm'
                ELSE IF @DIEM >= 5
                    SET @TRANGTHAI = N'đạt'
                ELSE
                    SET @TRANGTHAI = N'không đạt'
            END
    END

-- j) Truyền MASV, HOCKY trả về trạng thái Khen thưởng
CREATE PROC sp_KhenThuong   @MASV VARCHAR(10), @HOCKY INT,
                            @KHENTHUONG NVARCHAR(50) OUTPUT
AS
    BEGIN
        DECLARE @DTB_HK FLOAT
        SELECT @DTB_HK = SUM(k.DIEMTHI * m.SOTC) / SUM(m.SOTC)
        FROM KETQUA k, MONHOC m
        WHERE k.MAMH = m.MAMH AND k.MASV = @MASV AND k.HOCKY = @HOCKY
        GROUP BY k.MASV

        IF @DTB_HK >= 8
            SET @KHENTHUONG = N'Khen thưởng'
        ELSE
            SET @KHENTHUONG = N'Không khen thưởng'
    END

--
-- a) Trả về số tín chỉ
CREATE FUNCTION fn_SoTinChi (@MAMH CHAR(10)) RETURNS INT
AS
    BEGIN
        DECLARE @SOTC INT
        SELECT @SOTC = SOTC 
        FROM MONHOC 
        WHERE MAMH = @MAMH
        
        RETURN @SOTC
    END

-- b) Trả về điểm trung bình
CREATE FUNCTION fn_DiemTB (@MASV CHAR(10)) RETURNS FLOAT
AS
    BEGIN
        DECLARE @DTB FLOAT
        SELECT @DTB = DIEMTB 
        FROM SINHVIEN 
        WHERE MASV = @MASV
        RETURN @DTB
    END

-- c) Trả về tổng số sv học môn học trong học kỳ
CREATE FUNCTION fn_TongSVHocMon (@MAMH CHAR(10), @HOCKY INT) RETURNS INT
AS
    BEGIN
        DECLARE @TSV INT
        SELECT @TSV = COUNT(MASV) 
        FROM KETQUA 
        WHERE MAMH = @MAMH AND HOCKY = @HOCKY
        RETURN @TSV
    END

-- d) Trả về điểm thi
CREATE FUNCTION fn_DiemThi (@MASV CHAR(10), @MAMH CHAR(10), @HOCKY INT) RETURNS FLOAT
AS
    BEGIN
        DECLARE @DIEM FLOAT
        SELECT @DIEM = DIEMTHI 
        FROM KETQUA
        WHERE MASV = @MASV AND MAMH = @MAMH AND HOCKY = @HOCKY
        RETURN @DIEM
    END

-- e) Tổng số tín chỉ đã đạt của sinh viên đó trong học kỳ (điểm >= 5)
CREATE FUNCTION fn_TongTCDat (@MASV CHAR(10), @HOCKY INT) RETURNS INT
AS
    BEGIN
        DECLARE @TONGTC INT
        SELECT @TONGTC = ISNULL(SUM(m.SOTC), 0)
        FROM KETQUA k, MONHOC m
        WHERE k.MAMH = m.MAMH AND k.MASV = @MASV AND k.HOCKY = @HOCKY AND k.DIEMTHI >= 5
        RETURN @TONGTC
    END

-- f) Trả về bảng danh sách sinh viên học lớp đó
CREATE FUNCTION fn_DSSVLop (@MALOP CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT MASV, HOTEN, NGSINH 
        FROM SINHVIEN 
        WHERE MALOP = @MALOP
    )


-- g) Trả về bảng những sinh viên có điểm < 5 môn học đó trong học kỳ
CREATE FUNCTION fn_DSSVYeu (@MAMH CHAR(10), @HOCKY INT) RETURNS TABLE
AS
    RETURN (
        SELECT s.MASV, s.HOTEN, s.NGSINH, l.TENLOP
        FROM SINHVIEN s, LOP l, KETQUA k
        WHERE s.MALOP = l.MALOP AND s.MASV = k.MASV AND k.MAMH = @MAMH AND k.HOCKY = @HOCKY AND k.DIEMTHI < 5
    )

-- h) Bảng những sinh viên chưa học môn đó
CREATE FUNCTION fn_SVChuaHocMon (@MAMH CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT MASV, HOTEN, NGSINH 
        FROM SINHVIEN
        WHERE MASV NOT IN ( SELECT MASV 
                            FROM KETQUA 
                            WHERE MAMH = @MAMH)
    )

-- i) Bảng những môn sinh viên đã học (lấy điểm cao nhất)
CREATE FUNCTION fn_MonSVDaHoc (@MASV CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT m.MAMH, m.TENMH, MAX(k.DIEMTHI) N'Điểm cao nhất'
        FROM KETQUA k, MONHOC m
        WHERE k.MAMH = m.MAMH AND k.MASV = @MASV
        GROUP BY m.MAMH, m.TENMH
    )