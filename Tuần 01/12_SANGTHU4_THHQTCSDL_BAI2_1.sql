CREATE DATABASE DB1
ON PRIMARY
(
	NAME = DB1_PRIMARY,
	FILENAME= 'E:\LuuDuLieuSinhVien\SANGTHU4_THHQTCSDL\db1_primary.mdf',
	SIZE=30MB,
	MAXSIZE=100MB,
	FILEGROWTH=5MB
),
(
	NAME = DB1_SECOND,
	FILENAME= 'E:\LuuDuLieuSinhVien\SANGTHU4_THHQTCSDL\db1_second.ndf',
	SIZE=10MB,
	MAXSIZE=20MB,
	FILEGROWTH=15%
)
LOG ON
(
	NAME = DB1_Log,
	FILENAME= 'E:\LuuDuLieuSinhVien\SANGTHU4_THHQTCSDL\db1_log.ldf',
	SIZE=20MB,
	MAXSIZE=50MB,
	FILEGROWTH=15%
)

-- Thêm một tập tin dữ liệu phụ
ALTER DATABASE DB1
ADD FILE
(
	NAME = DB1_SECOND2,
	FILENAME= 'E:\LuuDuLieuSinhVien\SANGTHU4_THHQTCSDL\db1_second2.ndf',
	SIZE=10MB,
	MAXSIZE=20MB,
	FILEGROWTH=10%
)

-- Tăng dung lượng của file trên tăng 5MB
ALTER DATABASE DB1
MODIFY FILE
(
	NAME = 'DB1_SECOND2',
	SIZE = 15MB
)

-- Sử dụng DBCC để cắt giảm mdf
USE DB1
DBCC ShrinkFile
(
	DB1_PRIMARY, 20
)