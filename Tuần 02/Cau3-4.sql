CREATE DATABASE Cau34
USE Cau34
--
CREATE TABLE SACH (
    MASH CHAR(10),
    TENSH NVARCHAR(50),
    TACGIA NVARCHAR(50),
    LOAI NVARCHAR(50),
    TINHTRANG NVARCHAR(20),
    CONSTRAINT PK_SACH PRIMARY KEY (MASH)
)

CREATE TABLE DOCGIA (
    MADG CHAR(10),
    TENDG NVARCHAR(50),
    NGSINH DATE,
    PHAI NVARCHAR(3),
    DIACHI NVARCHAR(100),
    CONSTRAINT PK_DOCGIA PRIMARY KEY (MADG)
)

CREATE TABLE MUONSACH (
    MADG CHAR(10),
    MASH CHAR(10),
    NGAYMUON DATE,
    NGAYTRA DATE,
    PRIMARY KEY (MADG, MASH, NGAYMUON),
    CONSTRAINT FK_MUONSACH_DOCGIA FOREIGN KEY (MADG) REFERENCES DOCGIA(MADG),
    CONSTRAINT FK_MUONSACH_SACH FOREIGN KEY (MASH) REFERENCES SACH(MASH)
)

SELECT * FROM SACH
SELECT * FROM DOCGIA
SELECT * FROM MUONSACH

--
-- a) Viết trigger kiểm tra tuổi của độc giả phải >= 15
CREATE TRIGGER trg_KiemTraTuoi ON DOCGIA
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT * FROM inserted
            WHERE YEAR(GETDATE()) - YEAR(NGSINH) < 15
        )
        BEGIN
            PRINT(N'Tuổi của độc giả phải >= 15.')
            ROLLBACK TRANSACTION
        END
    END

-- b) Viết trigger kiểm tra phái của độc giả phải là 'Nam' hay 'Nữ'
CREATE TRIGGER trg_KiemTraPhai ON DOCGIA
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT * FROM inserted
            WHERE PHAI NOT IN (N'Nam', N'Nữ')
        )
        BEGIN
            PRINT(N'Phái của độc giả phải là Nam hoặc Nữ.')
            ROLLBACK TRANSACTION
        END
    END

-- c) Viết trigger kiểm tra loại sách phải thuộc các loại chỉ định
CREATE TRIGGER trg_KiemTraLoaiSach ON SACH
AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS (
            SELECT * FROM inserted
            WHERE LOAI NOT IN (N'Khoa học tự nhiên', N'Xã hội', N'Kinh tế', N'Truyện')
        )
        BEGIN
            PRINT(N'Loại sách không hợp lệ.')
            ROLLBACK TRANSACTION
        END
    END

-- d) Viết trigger kiểm tra khi mượn sách: chặn nếu sách chưa trả >= 3, ngược lại cập nhật 'Đã mượn'
CREATE TRIGGER trg_MuonSach ON MUONSACH
AFTER INSERT
AS
    BEGIN
        -- Nếu số lượng sách đang mượn (bao gồm cả cuốn vừa mượn) lớn hơn 3
        IF EXISTS (
            SELECT i.MADG
            FROM inserted i, MUONSACH m
            WHERE i.MADG = m.MADG AND m.NGAYTRA IS NULL
            GROUP BY i.MADG
            HAVING COUNT(m.MASH) > 3 
        )
        BEGIN
            PRINT(N'Độc giả đã mượn tối đa 3 cuốn sách chưa trả, không được mượn tiếp.')
            ROLLBACK TRANSACTION
        END
        ELSE
        BEGIN
            UPDATE SACH
            SET TINHTRANG = N'Đã mượn'
            WHERE MASH IN (SELECT MASH FROM inserted)
        END
    END

-- e) Viết trigger kiểm tra khi trả sách: cập nhật cuốn sách trở thành 'Chưa mượn'
CREATE TRIGGER trg_TraSach ON MUONSACH
AFTER UPDATE
AS
    BEGIN
        IF UPDATE(NGAYTRA)
        BEGIN
            UPDATE SACH
            SET TINHTRANG = N'Chưa mượn'
            WHERE MASH IN (
                SELECT i.MASH 
                FROM inserted i, deleted d 
                WHERE i.MASH = d.MASH AND i.MADG = d.MADG AND i.NGAYMUON = d.NGAYMUON 
                  AND d.NGAYTRA IS NULL AND i.NGAYTRA IS NOT NULL
            )
        END
    END

--
-- a) Truyền tham số mã độc giả, trả về tên và địa chỉ
CREATE PROC sp_ThongTinDocGia @MADG CHAR(10), @TENDG NVARCHAR(50) OUTPUT, @DIACHI NVARCHAR(100) OUTPUT
AS
    BEGIN
        SELECT @TENDG = TENDG, @DIACHI = DIACHI
        FROM DOCGIA
        WHERE MADG = @MADG
    END

-- b) Truyền mã sách, trả về tên sách, tác giả (Bỏ qua Năm XB vì không có trong bảng)
CREATE PROC sp_ThongTinSach @MASH CHAR(10), @TENSH NVARCHAR(50) OUTPUT, @TACGIA NVARCHAR(50) OUTPUT
AS
    BEGIN
        SELECT @TENSH = TENSH, @TACGIA = TACGIA
        FROM SACH
        WHERE MASH = @MASH
    END

-- c) Truyền mã độc giả, trả về số lượng sách đang mượn chưa trả
CREATE PROC sp_SoSachChuaTra @MADG CHAR(10), @SOLUONG INT OUTPUT
AS
    BEGIN
        SELECT @SOLUONG = COUNT(MASH)
        FROM MUONSACH
        WHERE MADG = @MADG AND NGAYTRA IS NULL
    END

-- d) Truyền mã sách, trả về tên độc giả đang mượn cuốn sách đó
CREATE PROC sp_TenDocGiaDangMuon @MASH CHAR(10), @TENDG NVARCHAR(50) OUTPUT
AS
    BEGIN
        SELECT @TENDG = d.TENDG
        FROM DOCGIA d, MUONSACH m
        WHERE d.MADG = m.MADG AND m.MASH = @MASH AND m.NGAYTRA IS NULL
    END

-- e) Truyền mã độc giả và ngày/tháng/năm, trả về số sách mượn trong ngày đó
CREATE PROC sp_SoSachMuonTrongNgay @MADG CHAR(10), @NGAY DATE, @SOLUONG INT OUTPUT
AS
    BEGIN
        SELECT @SOLUONG = COUNT(MASH)
        FROM MUONSACH
        WHERE MADG = @MADG AND NGAYMUON = @NGAY
    END

-- f) Truyền mã sách, trả về ngày mượn gần nhất
CREATE PROC sp_NgayMuonGanNhat @MASH CHAR(10), @NGAYMUON DATE OUTPUT
AS
    BEGIN
        SELECT @NGAYMUON = MAX(NGAYMUON)
        FROM MUONSACH
        WHERE MASH = @MASH
    END

--
-- a) Truyền tham số mã độc giả trả về chuỗi tên độc giả và địa chỉ
CREATE FUNCTION fn_ThongTinDG_Chuoi (@MADG CHAR(10)) RETURNS NVARCHAR(200)
AS
    BEGIN
        DECLARE @KQT NVARCHAR(200)
        SELECT @KQT = N'Độc giả ' + TENDG + N' có địa chỉ ' + DIACHI
        FROM DOCGIA
        WHERE MADG = @MADG
        RETURN @KQT
    END

-- b) Truyền mã độc giả trả về bảng sách chưa trả
CREATE FUNCTION fn_DSChuaTra (@MADG CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT s.MASH, s.TENSH
        FROM SACH s, MUONSACH m
        WHERE s.MASH = m.MASH AND m.MADG = @MADG AND m.NGAYTRA IS NULL
    )

-- c) Truyền mã sách trả về bảng những độc giả đã từng mượn
CREATE FUNCTION fn_DSDocGiaTungMuon (@MASH CHAR(10)) RETURNS TABLE
AS
    RETURN (
        SELECT DISTINCT d.MADG, d.TENDG
        FROM DOCGIA d, MUONSACH m
        WHERE d.MADG = m.MADG AND m.MASH = @MASH
    )

-- d) Truyền mã độc giả và tháng, trả về tổng số sách mượn trong tháng đó
CREATE FUNCTION fn_TongSachMuonThang (@MADG CHAR(10), @THANG INT, @NAM INT) RETURNS INT
AS
    BEGIN
        DECLARE @TONG INT
        SELECT @TONG = COUNT(MASH)
        FROM MUONSACH
        WHERE MADG = @MADG AND MONTH(NGAYMUON) = @THANG AND YEAR(NGAYMUON) = @NAM
        RETURN @TONG
    END

--
-- a) Cursor hiển thị mã độc giả, tên độc giả và số lượng sách mượn trong ngày 12/03/2022
DECLARE cur_DGMuonSach CURSOR FOR
    SELECT d.MADG, d.TENDG, COUNT(m.MASH)
    FROM DOCGIA d, MUONSACH m
    WHERE d.MADG = m.MADG AND m.NGAYMUON = '2022-03-12'
    GROUP BY d.MADG, d.TENDG

DECLARE @MADG_C CHAR(10), @TENDG_C NVARCHAR(50), @SL_C INT
OPEN cur_DGMuonSach
FETCH NEXT FROM cur_DGMuonSach INTO @MADG_C, @TENDG_C, @SL_C
WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Mã ĐG: ' + @MADG_C + N', Tên ĐG: ' + @TENDG_C + N', Số lượng: ' + CAST(@SL_C AS VARCHAR)
        FETCH NEXT FROM cur_DGMuonSach INTO @MADG_C, @TENDG_C, @SL_C
    END
CLOSE cur_DGMuonSach
DEALLOCATE cur_DGMuonSach

-- b) Cursor hiển thị mã sách, tên sách có trạng thái là chưa mượn
DECLARE cur_SachChuaMuon CURSOR FOR
    SELECT MASH, TENSH
    FROM SACH
    WHERE TINHTRANG = N'Chưa mượn' OR TINHTRANG IS NULL

DECLARE @MASH_C CHAR(10), @TENSH_C NVARCHAR(50)
OPEN cur_SachChuaMuon
FETCH NEXT FROM cur_SachChuaMuon INTO @MASH_C, @TENSH_C
WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Mã Sách: ' + @MASH_C + N', Tên Sách: ' + @TENSH_C
        FETCH NEXT FROM cur_SachChuaMuon INTO @MASH_C, @TENSH_C
    END
CLOSE cur_SachChuaMuon
DEALLOCATE cur_SachChuaMuon

-- c) Thêm cột SoLanMuon và viết thủ tục kết hợp cursor cập nhật
ALTER TABLE DOCGIA ADD SoLanMuon INT

CREATE PROC sp_CapNhatSoLanMuon
AS
    BEGIN
        DECLARE cur_SoLanMuon CURSOR FOR
            SELECT MADG
            FROM DOCGIA

        DECLARE @MADG_CUR CHAR(10), @SOLAN INT
        OPEN cur_SoLanMuon
        FETCH NEXT FROM cur_SoLanMuon INTO @MADG_CUR
        WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Mỗi ngày mượn khác nhau được tính là 1 lần mượn (dùng DISTINCT NGAYMUON)
                SELECT @SOLAN = COUNT(DISTINCT NGAYMUON)
                FROM MUONSACH
                WHERE MADG = @MADG_CUR

                UPDATE DOCGIA 
                SET SoLanMuon = ISNULL(@SOLAN, 0) 
                WHERE MADG = @MADG_CUR

                FETCH NEXT FROM cur_SoLanMuon INTO @MADG_CUR
            END
        CLOSE cur_SoLanMuon
        DEALLOCATE cur_SoLanMuon
    END

-- d) Thêm cột QuaHan và viết cursor cập nhật nếu > 60 ngày
ALTER TABLE MUONSACH 
ADD QuaHan NVARCHAR(20)

DECLARE cur_QuaHan CURSOR FOR
    SELECT MADG, MASH, NGAYMUON
    FROM MUONSACH
    WHERE NGAYTRA IS NULL AND DATEDIFF(DAY, NGAYMUON, GETDATE()) > 60

DECLARE @MADG_Q CHAR(10), @MASH_Q CHAR(10), @NGAYMUON_Q DATE
OPEN cur_QuaHan
FETCH NEXT FROM cur_QuaHan INTO @MADG_Q, @MASH_Q, @NGAYMUON_Q
WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE MUONSACH 
        SET QuaHan = N'Quá hạn'
        WHERE MADG = @MADG_Q AND MASH = @MASH_Q AND NGAYMUON = @NGAYMUON_Q

        FETCH NEXT FROM cur_QuaHan INTO @MADG_Q, @MASH_Q, @NGAYMUON_Q
    END
CLOSE cur_QuaHan
DEALLOCATE cur_QuaHan