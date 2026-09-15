# Cách chạy lại dự án

## Trạng thái cần biết trước

Tại thời điểm viết tài liệu này, dự án đang ở Giai đoạn 1. Repository có Docker Compose, script SQL, migration và DAG dưới dạng khung, nhưng chưa có hai file dữ liệu thật, chưa có kết quả EDA, chưa xác nhận container chạy, và migration `migrations/V1__create_dwh_schema.sql` vẫn đang được comment. Vì vậy chưa thể chạy end-to-end thành công chỉ bằng repository hiện tại.

Các bước dưới đây là trình tự tái lập đúng thiết kế. Những mục được ghi “Đã lên kế hoạch, chưa triển khai” cần hoàn thiện trước khi có thể đi đến Power BI.

## 1. Cài các công cụ cần thiết

1. Cài Docker Desktop và bật WSL 2. Docker cần có tối thiểu 6 GB RAM cho SQL Server và Airflow; 8 GB trở lên là mức khuyến nghị.
2. Cài một công cụ SQL: Azure Data Studio, SSMS hoặc `sqlcmd`.
3. Cài Power BI Desktop để mở dashboard khi Giai đoạn 8 hoàn tất.
4. Cài Python nếu muốn chạy notebook khảo sát `notebooks/01-eda.ipynb`.

## 2. Chuẩn bị dữ liệu thô

1. Tải Brazilian Insurance Market Data (SUSEP) và Prudential Life Insurance Assessment từ các nguồn được nêu trong `docs/specs/implementation-guide.md`.
2. Đặt các file CSV vào `data/raw/`. Thư mục này không được commit dữ liệu lớn theo `.gitignore`.
3. Mở và chạy `notebooks/01-eda.ipynb`; điền kết quả cột, kiểu dữ liệu và vấn đề chất lượng vào `docs/architecture/data-dictionary.md`.
4. Cập nhật tên file CSV trong `sql/01_load_staging.sql` để khớp file đã tải.

Trạng thái: đây là Giai đoạn 1, chưa hoàn thành.

## 3. Khởi động SQL Server và Airflow

Từ thư mục gốc repository, chạy:

```powershell
docker-compose up -d
docker-compose ps
```

Cấu hình nằm tại `docker-compose.yml`:

- SQL Server: `localhost,1433`, container `insurance_sqlserver`.
- Airflow: `http://localhost:8080`, container `insurance_airflow`. Lệnh `standalone` khởi tạo metadata database và chạy cả webserver lẫn scheduler trong cùng service.
- Dữ liệu thô được mount từ `data/raw/` vào `/var/opt/mssql/raw_data` trong SQL Server.

Mật khẩu `SA_PASSWORD` hiện là giá trị mẫu trong `docker-compose.yml`; thay bằng secret mạnh trước khi chạy thật và không commit secret. Lệnh `airflow standalone` đã được cấu hình để khởi tạo metadata database và tài khoản Airflow khi container khởi động lần đầu; kiểm tra thông tin đăng nhập sinh ra trong log của service `airflow`. Cấu hình này chưa được chạy xác minh trong Giai đoạn 2.

## 4. Tạo staging và nạp CSV

1. Kết nối SQL Server bằng Azure Data Studio/SSMS đến `localhost,1433` với tài khoản `sa`.
2. Mở và chạy `sql/01_load_staging.sql`.
3. Đối chiếu số dòng staging với số dòng từng CSV. Ghi lại kết quả trong progress log.

Script hiện là stub DDL/BULK INSERT. Cần thay tên bảng, cột và đường dẫn theo kết quả EDA trước khi chạy. Đã lên kế hoạch, chưa triển khai/xác minh.

## 5. Chạy schema migration

Migration được version hoá tại `migrations/V1__create_dwh_schema.sql`; mục tiêu là tạo `DWH_Insurance` cùng các bảng Dimension và Fact.

1. Chọn Flyway hoặc DbUp như thiết kế trong `implementation-guide.md`.
2. Bỏ comment và hoàn thiện DDL trong `migrations/V1__create_dwh_schema.sql` theo data dictionary và công cụ migration đã chọn.
3. Cấu hình kết nối tới SQL Server, rồi chạy migration từ thư mục `migrations/`.
4. Xác minh các bảng `Dim_Date`, `Dim_Region`, `Dim_Policy`, `Dim_Customer`, `Fact_Premium`, `Fact_Claims` đã tồn tại.

Đã lên kế hoạch, chưa triển khai/xác minh: hiện không có cấu hình Flyway/DbUp trong repo và toàn bộ DDL V1 đang được comment.

## 6. Bật CDC và chạy ETL

Theo thứ tự, chạy các file sau trên SQL Server sau khi staging và schema đã hoàn thiện:

1. `sql/02_enable_cdc.sql` để bật CDC và tạo `ETL_Watermark`.
2. `sql/03_sp_dim_customer_scd2.sql` để tạo thủ tục nạp khách hàng có lịch sử.
3. `sql/04_sp_dim_others.sql` để tạo thủ tục nạp các Dimension khác.
4. `sql/05_sp_fact_premium.sql` và `sql/06_sp_fact_claims.sql` để tạo thủ tục nạp Fact.
5. `sql/07_data_quality_checks.sql` để tạo bảng log và thủ tục kiểm tra chất lượng.

Sau đó chạy các thủ tục theo chuỗi Dimension → Fact → data quality. Kiểm tra `ETL_Audit_Log`, `ETL_Watermark` và `DQ_Check_Log`; chạy lại cùng batch để chứng minh idempotency. Đã lên kế hoạch, chưa triển khai/xác minh.

## 7. Chạy DAG Airflow

1. Khi Airflow đã khởi tạo đúng, mở `http://localhost:8080`.
2. Kiểm tra DAG từ `dags/insurance_dwh_pipeline.py` đã xuất hiện với tên `insurance_dwh_pipeline`.
3. Cấu hình SQL Server connection mà DAG sử dụng, bật DAG và bấm chạy thủ công.
4. Xác nhận thứ tự: `load_staging` → các task Dimension chạy song song → các task Fact → `run_data_quality_checks` → `notify`.
5. Kiểm tra retry và log task nếu có lỗi.

DAG hiện là khung, chưa được chạy/xác minh trên UI; chi tiết kết nối SQL Server và callback cảnh báo cần hoàn thiện ở Giai đoạn 6.

## 8. Mở Power BI

1. Sau khi DWH đã có dữ liệu đã qua kiểm tra, mở `powerbi/insurance-dashboard.pbix` bằng Power BI Desktop.
2. Nếu chưa có file này, tạo kết nối SQL Server đến `DWH_Insurance`, xác nhận quan hệ Star Schema, rồi xây các báo cáo phí, bồi thường và Loss Ratio.
3. Làm mới dữ liệu, đối chiếu tổng số với SQL, và lưu file tại đúng đường dẫn `powerbi/insurance-dashboard.pbix`.

Đã lên kế hoạch, chưa triển khai: thư mục `powerbi/` hiện chỉ có `.gitkeep`; chưa có dashboard hoặc insight thật.
