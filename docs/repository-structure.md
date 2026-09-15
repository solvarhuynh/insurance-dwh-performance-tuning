# Cấu trúc thư mục hiện tại

Tài liệu này giải thích repository đang được chia thành những khu vực nào, mỗi khu vực dùng để làm gì và phần nào đã có thật hoặc mới là khung. Cây bên dưới bỏ qua `.git/` và `.venv/` vì đó là dữ liệu quản lý phiên bản và môi trường Python cục bộ, không phải đầu ra của dự án.

## Cây thư mục

```text
insurance-dwh-project/
├── .cursor/rules/              # Quy tắc làm việc và kiểm tra trong môi trường phát triển
├── data/raw/                   # CSV dữ liệu gốc; hiện chỉ có .gitkeep
├── docs/                       # Tài liệu kiến trúc, thuật ngữ, hướng dẫn và kết quả
├── dags/                       # DAG Airflow điều phối pipeline
├── log/                        # Nhật ký tiến độ và báo cáo review
├── migrations/                 # Script thay đổi schema theo version
├── notebooks/                  # Notebook khảo sát dữ liệu (EDA)
├── powerbi/                    # File dashboard Power BI; hiện chỉ có .gitkeep
├── sql/                        # Script staging, CDC, ETL và data quality
├── .gitignore                  # Quy tắc không đưa dữ liệu lớn và secret vào Git
├── docker-compose.yml          # Cấu hình các service SQL Server và Airflow
├── implementation-guide.md     # Kế hoạch 8 giai đoạn và Definition of Done
├── insurance-dwh-overview.pdf  # Tài liệu tổng quan và định hướng dự án
└── README.md                   # Trang giới thiệu nhanh của repository
```

## Chức năng từng thư mục và file

| Đường dẫn | Chức năng | Trạng thái hiện tại |
|---|---|---|
| `.cursor/rules/` | Chứa quy tắc hỗ trợ quy trình làm việc, quản lý file/log, review Git, Python và bàn giao. Đây là cấu hình phát triển, không phải thành phần chạy của pipeline. | Đang có; cần xác nhận có giữ làm cấu hình dự án hay không vì không nằm trong cấu trúc của tài liệu nguồn. |
| `data/raw/` | Nơi đặt các CSV nguyên bản tải từ SUSEP và Prudential. Dữ liệu ở đây được giữ nguyên để staging có thể đối chiếu với nguồn. | Chưa có CSV; chỉ có `.gitkeep` để giữ thư mục trong Git. |
| `docs/` | Nơi giải thích kiến trúc, thuật ngữ, data dictionary, cách chạy, insight và performance tuning cho người đọc dự án. | Đã có tài liệu; các insight và số đo tuning vẫn chờ dữ liệu thật. |
| `dags/` | Chứa mã DAG Airflow, tức sơ đồ các task và dependency của pipeline. | `insurance_dwh_pipeline.py` đã có khung task và dependency; các lời gọi stored procedure còn là stub. |
| `log/` | Lưu lịch sử công việc, trạng thái giai đoạn và các báo cáo kiểm tra. | Có `progress-log.md` và `review-report-2026-09-15.md`. |
| `migrations/` | Lưu các thay đổi cấu trúc Data Warehouse theo version, để có thể dựng schema theo cùng một lịch sử. | Có `V1__create_dwh_schema.sql`; DDL hiện còn là khung được comment, chưa chạy xác minh. |
| `notebooks/` | Dùng cho phân tích khám phá dữ liệu (EDA): xem số dòng/cột, kiểu dữ liệu, null và bản ghi trùng trước khi thiết kế schema. | `01-eda.ipynb` đã tạo các phần cần khảo sát; chưa có dữ liệu để điền kết quả. |
| `powerbi/` | Nơi lưu dashboard Power BI kết nối đến `DWH_Insurance`. | Chưa có `.pbix`; chỉ có `.gitkeep`, vì Giai đoạn 8 chưa triển khai. |
| `sql/` | Chứa SQL theo thứ tự pipeline: nạp staging, bật CDC, nạp Dimension/Fact và kiểm tra chất lượng. | Đủ 7 file theo kế hoạch; nhiều phần là stub chờ data dictionary và dữ liệu thật. |
| `.gitignore` | Ngăn dữ liệu thô lớn, secret, cache Python và file tạm bị đưa vào Git. | Đã có. |
| `docker-compose.yml` | Mô tả môi trường chạy cục bộ gồm SQL Server và Airflow; mount mã DAG, SQL và dữ liệu raw vào container. | Đã có cấu hình tĩnh; chưa chạy end-to-end. |
| `implementation-guide.md` | Nguồn kế hoạch chính: mục tiêu, nguồn dữ liệu, 8 giai đoạn, checklist và tiêu chí hoàn thành. | Đã có và dùng để đối chiếu tiến độ. |
| `insurance-dwh-overview.pdf` | Bản tổng quan giải thích bối cảnh, kiến trúc, công nghệ và lộ trình dự án. | Đã có; là tài liệu tham chiếu, không phải file chạy. |
| `README.md` | Điểm bắt đầu cho người mới: mục tiêu, dữ liệu, kiến trúc, công nghệ, cây repo, cách chạy và trạng thái. | Đã có; phần chạy thật vẫn ghi TODO/PENDING theo tiến độ. |

## Quan hệ giữa các khu vực

Luồng dự kiến đi từ `data/raw/` vào `sql/01_load_staging.sql`, sau đó qua các stored procedure trong `sql/02_...` đến `sql/07_...` để tạo và nạp Data Warehouse theo schema trong `migrations/`. DAG trong `dags/` sẽ gọi các bước đó theo thứ tự. `docs/` và `log/` không xử lý dữ liệu; chúng giải thích và ghi lại những gì đã làm. `powerbi/` là lớp tiêu thụ dữ liệu cuối cùng sau khi DWH và kiểm tra chất lượng đã sẵn sàng.

## Đang làm gì tiếp theo?

Theo `log/progress-log.md`, repository đang ở Giai đoạn 1. Việc tiếp theo là tải hai bộ CSV vào `data/raw/`, chạy `notebooks/01-eda.ipynb`, rồi hoàn thiện `docs/data-dictionary.md` và danh sách vấn đề chất lượng dữ liệu. Chỉ sau đó mới nên hoàn thiện các stub SQL và chạy các giai đoạn hạ tầng, ETL, Airflow và Power BI.

