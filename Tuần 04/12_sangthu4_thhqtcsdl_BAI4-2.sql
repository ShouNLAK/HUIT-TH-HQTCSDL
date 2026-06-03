CREATE DATABASE Bai4_2_QLHV
USE Bai4_2_QLHV
--
CREATE TABLE KHOAHOC
(
	MaKH varchar(10),
	TenKH nvarchar(50),
	ThoiLuong int,
	CONSTRAINT FK_KHOAHOC primary key (MaKH)
)
INSERT INTO KHOAHOC
VALUES
	('KH01',N'Tiếng Anh',3)
--
BACKUP DATABASE Bai4_2_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\FullQLHV.bak'
with init
INSERT INTO KHOAHOC
VALUES
	('KH02',N'Tiếng Trung',6)
--
BACKUP DATABASE Bai4_2_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\DiffQLHV.bak'
with init,differential
INSERT INTO KHOAHOC
VALUES
	('KH03',N'Tiếng Hàn',12)
--
BACKUP LOG Bai4_2_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\LogQLHV.trn'
INSERT INTO KHOAHOC
VALUES
	('KH04',N'Tiếng Nhật',6)
--
BACKUP LOG Bai4_2_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\LogQLHV.trn'
--
RESTORE DATABASE Bai4_2_QLHV
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\FullQLHV.bak'
with norecovery

RESTORE DATABASE Bai4_2_QLHV
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\DiffQLHV.bak'
with norecovery

RESTORE DATABASE Bai4_2_QLHV
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\LogQLHV.trn'
with recovery