-- Tạo CSDL
CREATE DATABASE QLTV_3_4;
GO
USE QLTV;
GO

-- Tạo bảng SACH
CREATE TABLE SACH (
    MASH VARCHAR(10) PRIMARY KEY,
    TENSH NVARCHAR(100),
    TACGIA NVARCHAR(100),
    LOAI NVARCHAR(50),
    TINHTRANG NVARCHAR(20)
);

-- Tạo bảng DOCGIA
CREATE TABLE DOCGIA (
    MADG VARCHAR(10) PRIMARY KEY,
    TENDG NVARCHAR(100),
    NGAYSINH DATE,
    PHAI NVARCHAR(5)
);

-- Thêm cột DIACHI vào bảng DOCGIA
ALTER TABLE DOCGIA
ADD DIACHI NVARCHAR(200);

-- Thêm cột SoLanMuon vào bảng DOCGIA
ALTER TABLE DOCGIA
ADD SoLanMuon INT DEFAULT 0;

-- Tạo bảng MUONSACH
CREATE TABLE MUONSACH (
    MADG VARCHAR(10),
    MASH VARCHAR(10),
    NGAYMUON DATE,
    NGAYTRA DATE,
    PRIMARY KEY (MADG, MASH, NGAYMUON),
    FOREIGN KEY (MADG) REFERENCES DOCGIA(MADG),
    FOREIGN KEY (MASH) REFERENCES SACH(MASH)
);

-- Thêm cột QuaHan vào bảng MUONSACH
ALTER TABLE MUONSACH
ADD QuaHan NVARCHAR(20);


-- Dữ liệu cho bảng SACH
INSERT INTO SACH (MASH, TENSH, TACGIA, LOAI, TINHTRANG) VALUES
('S001', N'Nhà giả kim', N'Paulo Coelho', N'Truyện', N'Chưa mượn'),
('S002', N'Đắc nhân tâm', N'Dale Carnegie', N'Xã hội', N'Đã mượn'),
('S003', N'Vật lý đại cương', N'GS. Trần Văn A', N'Khoa học tự nhiên', N'Chưa mượn'),
('S004', N'Sài Gòn một thời vang bóng', N'Nguyễn Nhật Ánh', N'Truyện', N'Chưa mượn'),
('S005', N'Kinh tế vĩ mô', N'ThS. Lê Thị B', N'Kinh tế', N'Đã mượn'),
('S006', N'Hạt giống tâm hồn', N'Jack Canfield', N'Xã hội', N'Chưa mượn'),
('S007', N'Toán cao cấp', N'TS. Nguyễn Văn C', N'Khoa học tự nhiên', N'Chưa mượn'),
('S008', N'Làm giàu không khó', N'Robert Kiyosaki', N'Kinh tế', N'Chưa mượn'),
('S009', N'Những người khốn khổ', N'Victor Hugo', N'Truyện', N'Chưa mượn'),
('S010', N'Thiên nga đen', N'Nassim Nicholas Taleb', N'Kinh tế', N'Chưa mượn');

-- Dữ liệu cho bảng DOCGIA
INSERT INTO DOCGIA (MADG, TENDG, NGAYSINH, PHAI, DIACHI) VALUES
('DG001', N'Nguyễn Thanh Nam', '2000-05-10', N'Nam', N'TP. Hồ Chí Minh'),
('DG002', N'Trần Thị Mai', '1999-08-22', N'Nữ', N'Hà Nội'),
('DG003', N'Lê Văn Tùng', '2001-03-15', N'Nam', N'Đà Nẵng'),
('DG004', N'Phạm Thị Hoài', '2002-11-30', N'Nữ', N'Cần Thơ'),
('DG005', N'Hoàng Văn Việt', '1998-01-20', N'Nam', N'Hải Phòng'),
('DG006', N'Đinh Thị Thu', '2003-07-07', N'Nữ', N'Nghệ An'),
('DG007', N'Vũ Văn An', '2000-09-01', N'Nam', N'Hà Tĩnh'),
('DG008', N'Mai Thị Yến', '2001-04-18', N'Nữ', N'Quảng Ninh'),
('DG009', N'Bùi Văn Hùng', '1997-12-25', N'Nam', N'Huế'),
('DG010', N'Ngô Thị Hương', '2002-02-14', N'Nữ', N'TP. Hồ Chí Minh');

-- Dữ liệu cho bảng MUONSACH
INSERT INTO MUONSACH (MADG, MASH, NGAYMUON, NGAYTRA) VALUES
('DG001', 'S002', '2023-10-25', NULL),
('DG001', 'S005', '2023-10-26', NULL),
('DG002', 'S001', '2023-10-27', '2023-11-05'),
('DG002', 'S003', '2023-10-28', NULL),
('DG003', 'S004', '2023-10-29', '2023-11-10'),
('DG004', 'S006', '2023-10-30', '2023-11-15'),
('DG005', 'S007', '2023-11-01', NULL),
('DG006', 'S008', '2023-11-02', NULL),
('DG007', 'S009', '2023-11-03', '2023-11-03'),
('DG008', 'S010', '2023-11-04', '2023-11-04');