# Data Dictionary — Từ điển Dữ liệu Nguồn và Đích

Trạng thái: Khung cấu trúc từ điển dữ liệu. Hai bộ dữ liệu gốc (SUSEP ~8.3M dòng và Porto Seguro ~1.5M dòng) sẽ được tải vào `data/raw/` trong Giai đoạn 1 để điền đầy đủ thông tin chi tiết qua notebook `notebooks/01-eda.ipynb`.

## 1. Nguồn dữ liệu: SUSEP — Brazilian Insurance Market Data (~8.3M dòng)

| Tên cột mẫu | Kiểu dữ liệu | Ý nghĩa | Bảng nguồn | Ghi chú chất lượng dữ liệu |
|---|---|---|---|---|
| id_empresa / company_id | INT / NVARCHAR | Mã công ty bảo hiểm | Báo cáo tháng SUSEP | Kiểm tra mã hoá và bảng danh mục công ty |
| id_ramo / product_code | INT / NVARCHAR | Nhóm nghiệp vụ bảo hiểm | Báo cáo tháng SUSEP | Phân loại theo bảo hiểm tài sản, con người, xe |
| id_regiao / region_code | NVARCHAR(10) | Mã bang / khu vực Brazil | Báo cáo tháng SUSEP | Chuẩn hoá mã bang (SP, RJ, MG, etc.) |
| dt_ref / date_ref | DATE | Tháng năm ghi nhận giao dịch | Báo cáo tháng SUSEP | Định dạng ngày tháng, kiểm tra khoảng thời gian từ 2003 |
| vl_premio / premium_amt | DECIMAL(18,2) | Doanh thu phí bảo hiểm phát sinh | Báo cáo tháng SUSEP | Đơn vị BRL, kiểm tra giá trị không âm |
| vl_sinistro / claims_amt | DECIMAL(18,2) | Giá trị bồi thường phát sinh | Báo cáo tháng SUSEP | Đơn vị BRL, kiểm tra giá trị không âm |

## 2. Nguồn dữ liệu: Porto Seguro's Safe Driver Prediction (~1.5M dòng)

| Nhóm cột | Kiểu dữ liệu | Ý nghĩa | Vai trò trong DWH / ML |
|---|---|---|---|
| id | INT | Mã định danh khách hàng / hợp đồng | Khóa nghiệp vụ (Business Key) cho Dim_Customer |
| target | INT (0/1) | Khách hàng có phát sinh bồi thường hay không | Biến mục tiêu (Target Label) cho mô hình Machine Learning |
| ps_ind_* | INT / FLOAT | Đặc trưng nhân khẩu học cá nhân (tuổi, giới tính, khu vực) | Thuộc tính cho Dim_Customer và Feature cho ML |
| ps_reg_* | FLOAT | Đặc trưng khu vực địa lý nơi đăng ký bảo hiểm | Thuộc tính phân nhóm vùng rủi ro |
| ps_car_* | INT / FLOAT | Đặc trưng phương tiện xe cơ giới (loại xe, độ tuổi xe) | Thuộc tính hợp đồng/phương tiện |
| ps_calc_* | FLOAT | Các chỉ số rủi ro tính toán nội bộ | Feature đầu vào cho mô hình dự đoán |

## 3. Bảng đích DWH: Fact_Customer_Risk_Prediction (Kết quả Machine Learning)

| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| PredictionFactKey | BIGINT | PRIMARY KEY IDENTITY | Khóa thay thế (Surrogate Key) của bảng sự kiện dự đoán |
| CustomerKey | INT | FOREIGN KEY | Liên kết tới Dim_Customer(CustomerKey) |
| DateKey | INT | FOREIGN KEY | Ngày thực hiện dự đoán, liên kết tới Dim_Date(DateKey) |
| PredictedClaimProbability | DECIMAL(6,4) | NOT NULL | Xác suất dự đoán phát sinh tổn thất (0.0000 - 1.0000) |
| RiskCategory | NVARCHAR(20) | NOT NULL | Phân loại mức độ rủi ro ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') |
| ModelVersion | NVARCHAR(50) | NOT NULL | Phiên bản mô hình ML được sử dụng (VD: 'LightGBM_v1.0') |
| CreatedDate | DATETIME2 | DEFAULT UTC | Thời điểm ghi nhận bản ghi |
