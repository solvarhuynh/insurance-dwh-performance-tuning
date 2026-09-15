# Progress Log

Muc dich: ghi lai toan bo tien do du an theo thoi gian thuc, de bat ky AI hoac nguoi nao tiep tuc cong viec deu co the doc file nay va biet chinh xac da lam gi, tao file nao, o dau, con thieu gi.

## Cach dung
- Sau moi buoc hoan thanh (tao file, sua file, chay thanh cong mot script, hoan tat mot Definition of Done), them mot dong moi vao bang ben duoi.
- Khong xoa dong cu. Neu mot viec bi lam lai, ghi dong moi voi trang thai "Redo" va ly do.
- Truoc khi bat dau phien lam viec moi, doc toan bo bang nay truoc, uu tien doc tu duoi len de biet trang thai moi nhat.

## Bang tien do

| Thoi gian | Giai doan | Viec da lam | File da tao/sua | Duong dan | Trang thai | Ghi chu |
|---|---|---|---|---|---|---|
| 2026-09-15 13:15 | Scaffold | Khoi tao file nhat ky tien do du an | progress-log.md | log/progress-log.md | Done | Tao khung file log theo quy dinh |
| 2026-09-15 13:15 | Scaffold | Tao file cau hinh bo qua git | .gitignore | .gitignore | Done | Loai tru data/raw/*, credentials, pycache, notebook checkpoints |
| 2026-09-15 13:16 | Giai doan 1 | Tao file giu cho thu muc du lieu tho | .gitkeep | data/raw/.gitkeep | Done | Thu muc luu CSV tho SUSEP va Prudential (khong commit du lieu lon) |
| 2026-09-15 13:16 | Giai doan 1 | Tao file giu cho thu muc tai lieu | .gitkeep | docs/.gitkeep | Done | Thu muc luu tai lieu du an (data-dictionary, erd, insights) |
| 2026-09-15 13:16 | Giai doan 1 | Tao notebook EDA khao sat du lieu | 01-eda.ipynb | notebooks/01-eda.ipynb | Done | San sang cac section: Load data, Shape & dtypes, Null check, Duplicate check, DQ issues |
| 2026-09-15 13:16 | Giai doan 2 | Tao docker-compose khoi tao ha tang | docker-compose.yml | docker-compose.yml | Done | Cau hinh 2 service: SQL Server 2022 va Airflow (webserver + scheduler), RAM >= 6GB |
| 2026-09-15 13:16 | Giai doan 2 | Tao script nap staging bang BULK INSERT | 01_load_staging.sql | sql/01_load_staging.sql | Done | Stub DDL staging SUSEP/Prudential va BULK INSERT |
| 2026-09-15 13:17 | Giai doan 3 | Tao migration khoi tao schema DWH | V1__create_dwh_schema.sql | migrations/V1__create_dwh_schema.sql | Done | DDL Star Schema: Fact_Premium, Fact_Claims, Dim_Customer (SCD2), Dim_Policy, Dim_Date, Dim_Region |
| 2026-09-15 13:17 | Giai doan 4 | Tao script bat CDC va tao bang Watermark | 02_enable_cdc.sql | sql/02_enable_cdc.sql | Done | Bat CDC tren staging DB/table, tao bang ETL_Watermark luu LSN |
| 2026-09-15 13:17 | Giai doan 4 | Tao SP xu ly Dim_Customer theo SCD Type 2 | 03_sp_dim_customer_scd2.sql | sql/03_sp_dim_customer_scd2.sql | Done | DDL ETL_Audit_Log va stub sp_Load_DimCustomer voi MERGE SCD2, TRY...CATCH |
| 2026-09-15 13:17 | Giai doan 4 | Tao SP xu ly cac Dimension con lai | 04_sp_dim_others.sql | sql/04_sp_dim_others.sql | Done | Stubs cho sp_Load_DimPolicy, sp_Load_DimDate, sp_Load_DimRegion kem Audit Log |
| 2026-09-15 13:17 | Giai doan 4 | Tao SP xu ly Fact_Premium | 05_sp_fact_premium.sql | sql/05_sp_fact_premium.sql | Done | Stub sp_Load_FactPremium lookup Dim keys, MERGE UPSERT, Audit Log |
| 2026-09-15 13:17 | Giai doan 4 | Tao SP xu ly Fact_Claims | 06_sp_fact_claims.sql | sql/06_sp_fact_claims.sql | Done | Stub sp_Load_FactClaims lookup Dim keys, MERGE UPSERT, Audit Log |
| 2026-09-15 13:17 | Giai doan 5 | Tao script kiem dinh chat luong du lieu | 07_data_quality_checks.sql | sql/07_data_quality_checks.sql | Done | DDL DQ_Check_Log, procedure sp_Run_DataQualityChecks voi cac rule DQ va ngat pipeline |
| 2026-09-15 13:17 | Giai doan 6 | Tao Airflow DAG dieu phoi pipeline | insurance_dwh_pipeline.py | dags/insurance_dwh_pipeline.py | Done | Dinh nghia cac task load_staging, dim (parallel), fact, DQ, notify, retries=3 |
| 2026-09-15 13:17 | Giai doan 7 | Tao tai lieu README tong quan du an | README.md | README.md | Done | Day du 9 muc bat buoc, mo ta du an, kien truc, cong nghe, khong icon |
| 2026-09-15 13:18 | Giai doan 8 | Tao file giu cho thu muc Power BI | .gitkeep | powerbi/.gitkeep | Done | Thu muc luu dashboard Power BI (.pbix) o Giai doan 8 |
| 2026-09-15 13:18 | Scaffold | Hoan thanh dung suon toan bo repo | Toan bo 17 files | / | Done | Hoan tat scaffold 17 files theo dung 8 giai doan trong implementation-guide.md |
| 2026-09-15 13:20 | Tai lieu | Tao bo tai lieu giai thich du an, thuat ngu, khung data dictionary, huong dan chay, insight va tuning theo tien do thuc te | architecture-explained.md; glossary.md; data-dictionary.md; how-to-run.md; insights.md; performance-tuning-summary.md | docs/architecture-explained.md; docs/glossary.md; docs/data-dictionary.md; docs/how-to-run.md; docs/insights.md; docs/performance-tuning-summary.md | Done | Phan chua co du lieu/ket qua xac minh duoc ghi ro la da len ke hoach, chua trien khai |
| 2026-09-15 13:24 | Review | Duyet tinh toan bo repo, doi chieu tai lieu nguon, sua sai lech cau truc README va Docker Compose | review-report-2026-09-15.md; README.md; docker-compose.yml; how-to-run.md | log/review-report-2026-09-15.md; README.md; docker-compose.yml; docs/how-to-run.md | Done | Khong chay Docker/SQL Server/Airflow; con .cursor/rules/ can nguoi dung xac nhan vi nam ngoai cau truc tai lieu nguon |
| 2026-09-15 13:25 | Review | Hoan tat kiem tra tinh sau sua va loai bo thuoc tinh Docker Compose da loi thoi | review-report-2026-09-15.md; docker-compose.yml | log/review-report-2026-09-15.md; docker-compose.yml | Done | PASS: parse YAML/Compose, cu phap AST DAG, JSON notebook, can bang block comment SQL va kiem tra whitespace |
| 2026-09-15 13:25 | Review | Dong bo huong dan chay voi service Airflow standalone sau khi chuan hoa Docker Compose | how-to-run.md | docs/how-to-run.md | Done | Ghi ro Airflow khoi tao metadata database/tai khoan khi khoi dong; chua chay xac minh container |
| 2026-09-15 13:29 | Tai lieu | Tao tai lieu giai thich cau truc thu muc hien tai va chuc nang tung khu vuc/file | repository-structure.md; README.md | docs/repository-structure.md; README.md | Done | Ghi ro vai tro va trang thai cua tung thu muc/file; phan con la khung duoc danh dau |

## Giai doan hien tai
Giai doan 1 — Khao sat & chuan bi du lieu that

## Viec tiep theo can lam
1. Hoan thanh Giai doan 1 trong implementation-guide.md: tai 2 bo du lieu SUSEP va Prudential ve data/raw/.
2. Chay khao sat EDA trong notebooks/01-eda.ipynb: kiem tra shape, dtypes, null check, duplicate check.
3. Dien du lieu that vao docs/data-dictionary.md va tong hop danh sach van de chat luong du lieu can xu ly.
