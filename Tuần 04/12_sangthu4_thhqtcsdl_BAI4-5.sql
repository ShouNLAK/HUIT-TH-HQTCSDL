CREATE DATABASE Bai4_5_QLDH
USE Bai4_5_QLDH
--
CREATE TABLE DONHANG
(
	MaDH varchar(10),
	ThanhTien money,
	TrangThai nvarchar(50)
)
INSERT INTO DONHANG
VALUES
	('DH001',120000,N'Đang chờ'),
	('DH002',120000,N'Đã thanh toán')
--
BACKUP DATABASE Bai4_5_QLDH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Full.bak'
with init
INSERT INTO DONHANG
VALUES
	('DH003',120000,'Đang vận chuyển')
--
BACKUP LOG Bai4_5_QLDH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Tran_t2.trn'
UPDATE DONHANG
SET TrangThai = N'Đã hủy'
WHERE MaDH = 'DH001'
--
BACKUP DATABASE Bai4_5_QLDH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Diff.bak'
with init, differential
UPDATE DONHANG
SET TrangThai = N'Đã vận chuyển'
WHERE MaDH = 'DH003'
--
BACKUP LOG Bai4_5_QLDH
TO DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Tran_t4.trn'
DELETE FROM DONHANG WHERE MaDH = 'DH001'
--
RESTORE DATABASE Bai4_5_QLDH
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Full.bak'
with norecovery

RESTORE DATABASE Bai4_5_QLDH
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Diff.bak'
with norecovery

RESTORE DATABASE Bai4_5_QLDH
FROM DISK = 'E:\LuuDuLieuSinhVien\sangthu4_thhqtcsdl\12_sangthu4_thhqtcsdl\QLDH_Tran_t4.trn'
with recovery