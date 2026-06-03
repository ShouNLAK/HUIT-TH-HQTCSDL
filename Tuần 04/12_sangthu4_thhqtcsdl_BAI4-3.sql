CREATE DATABASE Bai4_3_QLHV
USE Bai4_3_QLHV
--
CREATE TABLE LOPHOC
(
	MaLH varchar(10),
	TenLH nvarchar(50),
	NgayBD date,
	NgayKT date,
	MaKH varchar(10)
)
INSERT INTO LOPHOC
VALUES
	('LH1',N'Tiếng Anh 1','2024-02-11','2024-04-11','KH01'),
	('LH2',N'Tiếng Anh 2','2024-03-15','2024-05-15','KH01')
--
BACKUP DATABASE Bai4_3_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLHV_Full.bak'
with init
INSERT INTO LOPHOC
VALUES 
	('LH3',N'Tiếng Anh 3','2024-03-15','2024-05-15','KH01')
--
BACKUP LOG Bai4_3_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLHV_Tran_t2.trn'
INSERT INTO LOPHOC
VALUES 
	('LH4',N'Tiếng Anh 4','2024-03-15','2024-05-15','KH01')
--
BACKUP LOG Bai4_3_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLHV_Tran_t3.trn'
INSERT INTO LOPHOC
VALUES 
	('LH5',N'Tiếng Anh 5','2024-03-15','2024-05-15','KH01')
--
BACKUP DATABASE Bai4_3_QLHV
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLHV_Diff.bak'
with init, differential
INSERT INTO LOPHOC
VALUES 
	('LH6',N'Tiếng Anh 6','2024-03-15','2024-05-15','KH01')
--
RESTORE DATABASE Bai4_3_QLHV
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLHV_Full.bak'
with norecovery

RESTORE DATABASE Bai4_3_QLHV
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLHV_Diff.bak'
with recovery
