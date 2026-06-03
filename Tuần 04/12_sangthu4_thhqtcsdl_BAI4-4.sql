CREATE DATABASE Bai4_4_QLBH
USE Bai4_4_QLBH
--
CREATE TABLE HOADON
(
	MaHD varchar(10),
	ThanhTien money
)
INSERT INTO HOADON
VALUES
	('HD001',120000),
	('HD002',120000)
--
BACKUP DATABASE Bai4_4_QLBH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Full.bak'
with init
INSERT INTO HOADON
VALUES
	('HD003',120000)
--
BACKUP LOG Bai4_4_QLBH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Tran_t2.trn'
INSERT INTO HOADON
VALUES
	('HD004',120000)
--
BACKUP DATABASE Bai4_4_QLBH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Diff.bak'
with init, differential
INSERT INTO HOADON
VALUES
	('HD005',120000)
--
BACKUP LOG Bai4_4_QLBH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Tran_t4.trn'
INSERT INTO HOADON
VALUES
	('HD006',120000)
--
RESTORE DATABASE Bai4_4_QLBH
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Full.bak'
with norecovery

RESTORE DATABASE Bai4_4_QLBH
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Diff.bak'
with norecovery

RESTORE DATABASE Bai4_4_QLBH
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLBH_Tran_t4.trn'
with recovery