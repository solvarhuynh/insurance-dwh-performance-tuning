# Insurance DWH & Performance Tuning

Dự án cá nhân — Data Engineering trên nền tảng Microsoft SQL Server, ứng dụng dữ liệu bảo hiểm thật, kèm lớp phân tích Power BI. Trọng tâm của dự án là chứng minh năng lực thiết kế Data Warehouse chuẩn mực, viết ETL bằng T-SQL, và đặc biệt là Performance Tuning — phân tích Execution Plan, indexing, tối ưu truy vấn trên dữ liệu lớn thật.

## Mục tiêu dự án

- Thiết kế và xây dựng hệ thống Data Warehouse chuyên nghiệp phục vụ ngành Bảo hiểm nhân thọ và phi nhân thọ, bám sát các yêu cầu thực tế của hệ sinh thái Microsoft (SQL Server, T-SQL, SSIS).
- Xây dựng luồng ETL bằng T-SQL với khả năng Incremental Load dựa trên Change Data Capture (CDC) và cơ chế lưu vết Watermark, giúp tiết kiệm tài nguyên so với full reload.
- Thiết kế cơ chế Audit Log đầy đủ và tính idempotent, đảm bảo chạy lại cùng batch không gây trùng lặp hoặc sai lệch dữ liệu.
- Áp dụng SCD Type 2 cho bảng chiều khách hàng (Dim_Customer) để theo dõi lịch sử thay đổi thông tin theo thời gian.
- Xây dựng framework Data Quality tự động kiểm định toàn vẹn dữ liệu (Not Null, Unique, Referential Integrity, Business Rules) và chủ động ngắt pipeline khi phát hiện lỗi critical.
- Điều phối toàn bộ pipeline qua Apache Airflow trên môi trường Docker hóa.
- Chứng minh năng lực Performance Tuning bằng cách đo lường, so sánh Execution Plan và chỉ số STATISTICS IO/TIME trước và sau khi tối ưu hóa bằng Indexing.
- Xây dựng dashboard Power BI trực quan hóa chỉ số nghiệp vụ (Loss Ratio, xu hướng phí bảo hiểm) và đưa ra insight giá trị.

## Nguồn dữ liệu

| Bộ dữ liệu | Nguồn | Quy mô | Vai trò trong dự án |
|---|---|---|---|
| Brazilian Insurance Market Data (SUSEP) | Kaggle / susep.gov.br — dataset công khai do cơ quan quản lý bảo hiểm Brazil (SUSEP) công bố | ~8.3 triệu dòng, dữ liệu thật từ 2003, cập nhật theo quý | Nguồn chính cho Fact_Premium / Fact_Claims — phí, bồi thường theo công ty, sản phẩm, bang, tháng |
| Prudential Life Insurance Assessment | Kaggle competition — dữ liệu underwriting thật | ~60 nghìn dòng | Nguồn cho Dim_Customer — đặc điểm nghiệp vụ thật (tuổi, BMI, tiền sử y tế đã mã hoá, mức rủi ro) |

Hai bộ dữ liệu được kết hợp: SUSEP cung cấp khối lượng giao dịch đủ lớn để tuning thật, Prudential cung cấp chiều khách hàng có ý nghĩa nghiệp vụ thật (không phải random).

## Kiến trúc tổng quan

Luồng dữ liệu tổng thể chạy qua các tầng kiến trúc:
Staging -> DWH Star Schema -> Incremental Load/CDC -> Data Quality -> Orchestration Airflow -> Performance Tuning -> Power BI.

1. Staging: Nạp file CSV thô vào database Staging_InsuranceRaw bằng lệnh BULK INSERT, giữ nguyên cấu trúc ban đầu để đối chiếu toàn vẹn.
2. DWH Star Schema: Fact_Premium, Fact_Claims (bảng sự kiện); Dim_Customer (SCD Type 2), Dim_Policy, Dim_Date, Dim_Region (bảng chiều).
3. Incremental Load / CDC: T-SQL Stored Procedures dùng lệnh MERGE để UPSERT; bật SQL Server Change Data Capture (CDC) trên Staging để chỉ nạp phần dữ liệu mới/thay đổi, không reload toàn bộ mỗi lần.
4. Data Quality: Bộ kiểm định tự động (not null, unique, referential integrity) chạy như một bước trong pipeline, ghi log vào DQ_Check_Log, làm pipeline dừng và cảnh báo nếu không đạt.
5. Orchestration Airflow: Apache Airflow điều phối toàn bộ DAG: Load Staging -> Load Dim (song song) -> Load Fact -> Data Quality Check -> Notify; có cơ chế retry và cảnh báo khi lỗi.
6. Performance Tuning: Đo trước và sau bằng Execution Plan + STATISTICS IO/TIME, thêm Non-Clustered/Covering Index, cân nhắc partitioning theo tháng.
7. Power BI: Kết nối trực tiếp DWH, xây dashboard loss ratio, xu hướng phí, phát hiện outlier theo bang/sản phẩm bảo hiểm.

## Công nghệ sử dụng

| Hạng mục | Công cụ |
|---|---|
| Cơ sở dữ liệu | Microsoft SQL Server (Docker trên WSL) |
| Ngôn ngữ chính | T-SQL (ETL, tuning), Python (nạp dữ liệu, DAG Airflow) |
| Incremental Load | SQL Server Change Data Capture (CDC) |
| Orchestration | Apache Airflow (chạy trong Docker) |
| Schema Migration | Flyway hoặc DbUp — quản lý schema theo version |
| Data Quality | dbt tests / Great Expectations — kiểm định tự động trong pipeline |
| Công cụ quản trị DB | Azure Data Studio / SSMS |
| Trực quan hoá | Power BI Desktop |
| Quản lý mã nguồn & tài liệu | Git/GitHub, README có ảnh chụp Execution Plan |

## Cấu trúc repo

```
insurance-dwh-project/
├── .cursor/
│   └── rules/
├── .gitignore
├── data/raw/
│   └── .gitkeep
├── docs/
│   ├── architecture/
│   │   ├── architecture-explained.md
│   │   ├── data-dictionary.md
│   │   └── repository-structure.md
│   ├── guides/
│   │   ├── glossary.md
│   │   └── how-to-run.md
│   ├── reports/
│   │   ├── insights.md
│   │   └── performance-tuning-summary.md
│   └── specs/
│       ├── implementation-guide.md
│       └── insurance-dwh-overview.pdf
├── dags/
│   └── insurance_dwh_pipeline.py
├── log/
│   ├── progress-log.md
│   └── review-report-2026-09-15.md
├── migrations/
│   └── V1__create_dwh_schema.sql
├── notebooks/
│   └── 01-eda.ipynb
├── powerbi/
│   └── .gitkeep
├── sql/
│   ├── 01_load_staging.sql
│   ├── 02_enable_cdc.sql
│   ├── 03_sp_dim_customer_scd2.sql
│   ├── 04_sp_dim_others.sql
│   ├── 05_sp_fact_premium.sql
│   ├── 06_sp_fact_claims.sql
│   └── 07_data_quality_checks.sql
├── docker-compose.yml
└── README.md
```

## Cách chạy dự án

### Bước 1: Thiết lập hạ tầng Docker
- Khởi chạy container SQL Server và Airflow:
  ```bash
  docker-compose up -d
  ```
- TODO: Cập nhật hướng dẫn cấu hình chi tiết khi hoàn thành Giai đoạn 2.

### Bước 2: Chạy Schema Migrations
- Khởi tạo DWH schema qua Flyway hoặc DbUp:
  ```bash
  # TODO: Chạy migration V1__create_dwh_schema.sql
  ```
- TODO: Cập nhật khi hoàn thành Giai đoạn 3.

### Bước 3: Nạp dữ liệu và Kích hoạt CDC
- Chạy script nạp staging và bật CDC:
  ```bash
  # TODO: Chạy sql/01_load_staging.sql và sql/02_enable_cdc.sql
  ```
- TODO: Cập nhật khi hoàn thành Giai đoạn 4.

### Bước 4: Chạy pipeline trên Airflow
- Kích hoạt DAG `insurance_dwh_pipeline` trên Airflow Webserver (`http://localhost:8080`).
- TODO: Cập nhật khi hoàn thành Giai đoạn 6.

## Trạng thái hiện tại của dự án

Xem chi tiết tiến độ thực hiện, danh sách việc đã làm và kế hoạch tiếp theo tại [log/progress-log.md](log/progress-log.md).

## Ghi chú về Performance Tuning

Chứng minh năng lực tối ưu hóa bằng ảnh chụp Execution Plan trước và sau khi tạo Index, bảng so sánh chỉ số STATISTICS IO/TIME (logical reads, elapsed time) sẽ được trình bày chi tiết tại mục này sau khi hoàn thành Giai đoạn 7.
