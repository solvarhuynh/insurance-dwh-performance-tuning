# Cấu trúc thư mục hiện tại

Tài liệu này giải thích repository đang được chia thành những khu vực nào, mỗi khu vực dùng để làm gì và phần nào đã có thật hoặc mới là khung. Cây bên dưới bỏ qua `.git/` và `.venv/` vì đó là dữ liệu quản lý phiên bản và môi trường Python cục bộ, không phải đầu ra của dự án.

## Cây thư mục

```text
insurance-dwh-project/
├── .cursor/rules/              # Quy tắc làm việc và kiểm tra trong môi trường phát triển
├── data/raw/                   # CSV dữ liệu gốc (SUSEP + Porto Seguro); hiện chỉ có .gitkeep
├── docs/                       # Hệ thống tài liệu phân theo nhóm chuyên biệt
│   ├── architecture/           # Kiến trúc và mô hình dữ liệu
│   ├── guides/                 # Hướng dẫn thực hành và thuật ngữ
│   ├── reports/                # Báo cáo insight và performance tuning
│   └── specs/                  # Tài liệu đặc tả và định hướng gốc
├── ml/                         # Machine learning training và batch prediction
│   ├── train_risk_model.py     # Script huấn luyện baseline model
│   └── predict_risk_batch.py   # Script batch scoring gọi bởi Airflow
├── dags/                       # DAG Airflow điều phối pipeline
│   └── insurance_dwh_pipeline.py
├── log/                        # Nhật ký tiến độ và báo cáo review
│   ├── progress-log.md
│   └── review-report-2026-09-15.md
├── migrations/                 # Script thay đổi schema theo version
│   └── V1__create_dwh_schema.sql
├── notebooks/                  # Notebook khảo sát dữ liệu (EDA)
│   └── 01-eda.ipynb
├── powerbi/                    # File dashboard Power BI; hiện chỉ có .gitkeep
├── sql/                        # Script staging, CDC, ETL, data quality và ML load
│   ├── 01_load_staging.sql
│   ├── 02_enable_cdc.sql
│   ├── 03_sp_dim_customer_scd2.sql
│   ├── 04_sp_dim_others.sql
│   ├── 05_sp_fact_premium.sql
│   ├── 06_sp_fact_claims.sql
│   ├── 07_data_quality_checks.sql
│   └── 08_sp_load_risk_predictions.sql
├── .gitignore                  # Quy tắc không đưa dữ liệu lớn và secret vào Git
├── docker-compose.yml          # Cấu hình các service SQL Server và Airflow
└── README.md                   # Trang giới thiệu tổng quan của repository
```

## Chức năng từng thư mục và file

| Đường dẫn | Chức năng | Trạng thái hiện tại |
|---|---|---|
| `.cursor/rules/` | Chứa quy tắc hỗ trợ quy trình làm việc, quản lý file/log, review Git, Python và bàn giao. | Đang có sẵn trong môi trường phát triển. |
| `data/raw/` | Nơi đặt các CSV nguyên bản tải từ SUSEP (~8.3M dòng) và Porto Seguro (~1.5M dòng). Dữ liệu ở đây được giữ nguyên để đối chiếu. | Chưa có CSV; có `.gitkeep` để giữ thư mục trong Git. |
| `docs/` | Nơi chứa tài liệu kiến trúc, thuật ngữ, data dictionary, cách chạy, insight, tuning và đặc tả nguồn. | Đã cấu trúc thành 4 nhóm (`architecture/`, `guides/`, `reports/`, `specs/`). |
| `ml/` | Chứa mã huấn luyện mô hình dự đoán rủi ro và mã batch scoring phục vụ pipeline tự động. | Đã có `train_risk_model.py` và `predict_risk_batch.py`. |
| `dags/` | Chứa mã DAG Airflow điều phối toàn bộ luồng ETL, DQ check và ML scoring. | `insurance_dwh_pipeline.py` đã có đầy đủ task và dependency. |
| `log/` | Lưu lịch sử công việc, trạng thái giai đoạn và các báo cáo kiểm tra. | Có `progress-log.md` và `review-report-2026-09-15.md`. |
| `migrations/` | Lưu các thay đổi cấu trúc Data Warehouse theo version (Flyway/DbUp). | Có `V1__create_dwh_schema.sql` (gồm 8 bảng Fact/Dim). |
| `notebooks/` | Dùng cho phân tích khám phá dữ liệu (EDA): xem shape, kiểu dữ liệu, null, duplicate. | Có `01-eda.ipynb` với 5 section chuẩn. |
| `powerbi/` | Nơi lưu dashboard Power BI kết nối đến `DWH_Insurance`. | Có `.gitkeep`, sẵn sàng cho file `.pbix`. |
| `sql/` | Chứa SQL theo thứ tự pipeline: nạp staging, bật CDC, nạp Dim/Fact, DQ checks và nạp kết quả ML. | Đủ 8 file theo thiết kế chuẩn. |
| `.gitignore` | Ngăn dữ liệu thô lớn, secret, cache Python và file tạm bị đưa vào Git. | Đã có. |
| `docker-compose.yml` | Mô tả môi trường chạy cục bộ gồm SQL Server và Airflow. | Đã có cấu hình chuẩn. |
| `README.md` | Điểm bắt đầu cho người mới: mục tiêu, dữ liệu, kiến trúc, công nghệ, cây repo, cách chạy và trạng thái. | Đã chuẩn hoá tiếng Việt có dấu đầy đủ. |

## Quan hệ giữa các khu vực

Luồng dữ liệu đi từ `data/raw/` vào `sql/01_load_staging.sql`, qua các Stored Procedure `sql/02_...` đến `sql/07_...` để nạp vào Star Schema trong `migrations/`. DAG trong `dags/` điều phối các bước, kích hoạt module `ml/` để dự đoán rủi ro và nạp kết quả qua `sql/08_sp_load_risk_predictions.sql`. `powerbi/` là lớp tiêu thụ dữ liệu cuối cùng hiển thị báo cáo phân tích và đối chiếu rủi ro dự đoán.
