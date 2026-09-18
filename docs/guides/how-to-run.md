# Cách chạy lại dự án

## Trạng thái cần biết trước

Tại thời điểm viết tài liệu này, dự án đang ở Giai đoạn 1. Repository có Docker Compose, script SQL, migration, module ML và DAG dưới dạng khung chuẩn bị đón dữ liệu thật.

Các bước dưới đây là trình tự tái lập toàn bộ pipeline theo đúng thiết kế End-to-End.

## 1. Cài các công cụ cần thiết

1. Cài Docker Desktop và bật WSL 2. Docker cần có tối thiểu 6 GB RAM cho SQL Server và Airflow; 8 GB trở lên là mức khuyến nghị.
2. Cài một công cụ SQL: Azure Data Studio, SSMS hoặc `sqlcmd`.
3. Cài Python (≥3.10) với các thư viện: `pandas`, `scikit-learn`, `lightgbm`, `pyodbc`.
4. Cài Power BI Desktop để mở dashboard khi Giai đoạn 8 hoàn tất.

## 2. Chuẩn bị dữ liệu thô

1. Tải 2 bộ dữ liệu:
   - Brazilian Insurance Market Data (SUSEP, ~8.3M dòng).
   - Porto Seguro's Safe Driver Prediction (Kaggle, ~1.5M dòng).
2. Đặt các file CSV vào `data/raw/`. Thư mục này không được commit dữ liệu lớn theo `.gitignore`.
3. Mở và chạy `notebooks/01-eda.ipynb`; điền kết quả cột, kiểu dữ liệu và vấn đề chất lượng vào `docs/architecture/data-dictionary.md`.
4. Cập nhật tên file CSV trong `sql/01_load_staging.sql` để khớp file đã tải.

## 3. Khởi động SQL Server và Airflow

Từ thư mục gốc repository, chạy:

```powershell
docker-compose up -d
docker-compose ps
```

Cấu hình nằm tại `docker-compose.yml`:
- SQL Server: `localhost,1433`, container `insurance_sqlserver`.
- Airflow: `http://localhost:8080`, container `insurance_airflow_webserver` và `insurance_airflow_scheduler`.
- Dữ liệu thô được mount từ `data/raw/` vào container SQL Server.

## 4. Tạo staging và nạp CSV

1. Kết nối SQL Server bằng Azure Data Studio/SSMS đến `localhost,1433` với tài khoản `sa`.
2. Mở và chạy `sql/01_load_staging.sql`.
3. Đối chiếu số dòng staging với số dòng từng CSV gốc.

## 5. Chạy schema migration

1. Áp dụng migration tại `migrations/V1__create_dwh_schema.sql` (bằng Flyway hoặc DbUp) để tạo database `DWH_Insurance` cùng 8 bảng Fact/Dim:
   - `Dim_Date`, `Dim_Region`, `Dim_Policy`, `Dim_Customer` (SCD2).
   - `Fact_Premium`, `Fact_Claims`, `Fact_Customer_Risk_Prediction`.

## 6. Bật CDC và chạy ETL

Theo thứ tự, chạy các file sau trên SQL Server:
1. `sql/02_enable_cdc.sql` để bật CDC và tạo `ETL_Watermark`.
2. `sql/03_sp_dim_customer_scd2.sql` để tạo thủ tục nạp khách hàng có lịch sử.
3. `sql/04_sp_dim_others.sql` để tạo thủ tục nạp các Dimension khác.
4. `sql/05_sp_fact_premium.sql` và `sql/06_sp_fact_claims.sql` để tạo thủ tục nạp Fact.
5. `sql/07_data_quality_checks.sql` để tạo bảng log và thủ tục kiểm tra chất lượng.
6. `sql/08_sp_load_risk_predictions.sql` để tạo thủ tục nạp điểm rủi ro ML.

## 7. Huấn luyện mô hình Machine Learning

1. Chạy script huấn luyện baseline model:
   ```powershell
   python ml/train_risk_model.py
   ```
2. Model artifact sẽ được lưu tại `ml/risk_model.pkl`.

## 8. Chạy DAG Airflow

1. Mở Airflow Webserver tại `http://localhost:8080`.
2. Bật DAG `insurance_dwh_pipeline` và kích hoạt chạy thủ công.
3. Xác nhận chuỗi task thực thi:
   `load_staging` → các Dimension (song song) → các Fact → `run_data_quality_checks` → `predict_customer_risk` → `load_risk_predictions` → `notify`.

## 9. Mở Power BI

1. Mở `powerbi/insurance-dashboard.pbix` bằng Power BI Desktop.
2. Kết nối tới `DWH_Insurance`, làm mới dữ liệu và kiểm tra các báo cáo Loss Ratio, xu hướng phí và rủi ro dự đoán.
