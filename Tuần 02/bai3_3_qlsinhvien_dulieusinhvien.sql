CREATE DATABASE QLSV_3_3_12;
USE QLSV_3_3_12;
CREATE TABLE LOP (
    MALOP VARCHAR(10) PRIMARY KEY,
    TENLOP NVARCHAR(50),
    SISO INT
);

CREATE TABLE SINHVIEN (
    MASV VARCHAR(10) PRIMARY KEY,
    HOTEN NVARCHAR(50),
    NGSINH DATE,
    GIOITINH NVARCHAR(10),
    QUEQUAN NVARCHAR(50),
    MALOP VARCHAR(10),
    DIEMTB DECIMAL(4, 2),
    XEPLOAI NVARCHAR(20),
    FOREIGN KEY (MALOP) REFERENCES LOP(MALOP)
);

CREATE TABLE MONHOC (
    MAMH VARCHAR(10) PRIMARY KEY,
    TENMH NVARCHAR(50),
    SOTC INT,
    BATBUOC BIT
);

CREATE TABLE KETQUA (
    MASV VARCHAR(10),
    MAMH VARCHAR(10),
    HOCKY INT,
    DIEMTHI DECIMAL(4, 2),
    PRIMARY KEY (MASV, MAMH, HOCKY),
    FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH)
);

-- Dữ liệu cho bảng LOP
INSERT INTO LOP (MALOP, TENLOP, SISO) VALUES
('CNTT01', 'Công nghệ thông tin 01', 50),
('CNTT02', 'Công nghệ thông tin 02', 45),
('KT01', 'Kế toán 01', 55),
('KT02', 'Kế toán 02', 60),
('TMDT01', 'Thương mại điện tử 01', 48),
('TMDT02', 'Thương mại điện tử 02', 52),
('XD01', 'Xây dựng 01', 40),
('XD02', 'Xây dựng 02', 38),
('DL01', 'Du lịch 01', 35),
('QTKD01', 'Quản trị kinh doanh 01', 50);

-- Dữ liệu cho bảng SINHVIEN
INSERT INTO SINHVIEN (MASV, HOTEN, NGSINH, GIOITINH, QUEQUAN, MALOP, DIEMTB, XEPLOAI) VALUES
('SV001', N'Nguyễn Văn A', '2004-01-15', N'Nam', N'Hà Nội', 'CNTT01', 8.5, N'Giỏi'),
('SV002', N'Trần Thị B', '2004-02-20', N'Nữ', N'TP. Hồ Chí Minh', 'CNTT01', 7.8, N'Khá'),
('SV003', N'Lê Văn C', '2003-11-10', N'Nam', N'Đà Nẵng', 'KT01', 9.0, N'Xuất sắc'),
('SV004', N'Phạm Thị D', '2004-05-05', N'Nữ', N'Hải Phòng', 'KT01', 7.2, N'Khá'),
('SV005', N'Hoàng Văn E', '2003-08-25', N'Nam', N'Nghệ An', 'TMDT01', 6.5, N'Trung bình'),
('SV006', N'Đinh Thị F', '2004-03-30', N'Nữ', N'Hà Tĩnh', 'TMDT01', 8.9, N'Giỏi'),
('SV007', N'Vũ Văn G', '2004-06-18', N'Nam', N'Thanh Hóa', 'XD01', 7.5, N'Khá'),
('SV008', N'Mai Thị H', '2003-12-01', N'Nữ', N'Quảng Ninh', 'XD01', 6.8, N'Khá'),
('SV009', N'Ngô Văn I', '2004-04-12', N'Nam', N'Huế', 'CNTT02', 8.0, N'Giỏi'),
('SV010', N'Bùi Thị K', '2003-10-22', N'Nữ', N'Cần Thơ', 'QTKD01', 9.2, N'Xuất sắc');

-- Dữ liệu cho bảng MONHOC
INSERT INTO MONHOC (MAMH, TENMH, SOTC, BATBUOC) VALUES
('MH01', N'Cơ sở dữ liệu', 3, 1),
('MH02', N'Lập trình C++', 4, 1),
('MH03', N'Mạng máy tính', 3, 1),
('MH04', N'Kinh tế vi mô', 2, 0),
('MH05', N'Kế toán tài chính', 3, 1),
('MH06', N'Thống kê ứng dụng', 3, 0),
('MH07', N'Quản trị Marketing', 3, 1),
('MH08', N'Kiến trúc máy tính', 3, 1),
('MH09', N'An toàn thông tin', 2, 0),
('MH10', N'Pháp luật đại cương', 2, 0);

-- Dữ liệu cho bảng KETQUA
INSERT INTO KETQUA (MASV, MAMH, HOCKY, DIEMTHI) VALUES
('SV001', 'MH01', 1, 8.5),
('SV001', 'MH02', 1, 7.5),
('SV002', 'MH01', 1, 8.0),
('SV002', 'MH03', 1, 7.0),
('SV003', 'MH04', 2, 9.5),
('SV003', 'MH05', 2, 8.8),
('SV004', 'MH05', 2, 7.0),
('SV004', 'MH06', 2, 7.5),
('SV005', 'MH07', 3, 6.5),
('SV005', 'MH08', 3, 5.0);