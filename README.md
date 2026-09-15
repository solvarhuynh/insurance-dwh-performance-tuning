# Insurance DWH & Performance Tuning

Du an ca nhan — Data Engineering tren nen tang Microsoft SQL Server, ung dung du lieu bao hiem that, kem lop phan tich Power BI. Trong tam cua du an la chung minh nang luc thiet ke Data Warehouse chuan muc, viet ETL bang T-SQL, va dac biet la Performance Tuning — phan tich execution plan, indexing, toi uu truy van tren du lieu lon that.

## Muc tieu du an

- Thiet ke va xay dung he thong Data Warehouse chuyen nghiep phuc vu nganh Bao hiem nhan tho va phi nhan tho, bam sat cac yeu cau thuc te cua he sinh thai Microsoft (SQL Server, T-SQL, SSIS).
- Xay dung luong ETL bang T-SQL voi kha nang Incremental Load dua tren Change Data Capture (CDC) va co che luu vet Watermark, giup tiet kiem tai nguyen so voi full reload.
- Thiet ke co che Audit Log day du va tinh idempotent, dam bao chay lai cung batch khong gay trung lap hoac sai lech du lieu.
- Ap dung SCD Type 2 cho bang chieu khach hang (Dim_Customer) de theo doi lich su thay doi thong tin theo thoi gian.
- Xay dung framework Data Quality tu dong kiem dinh toan ven du lieu (Not Null, Unique, Referential Integrity, Business Rules) va chu dong ngat pipeline khi phat hien loi critical.
- Dieu phoi toan bo pipeline qua Apache Airflow tren moi truong Docker hoa.
- Chung minh nang luc Performance Tuning bang cach do luong, so sanh Execution Plan va chi so STATISTICS IO/TIME truoc va sau khi toi uu hoa bang Indexing.
- Xay dung dashboard Power BI truc quan hoa chi so nghiep vu (Loss Ratio, xu huong phi bao hiem) va dua ra insight gia tri.

## Nguon du lieu

| Bo du lieu | Nguon | Quy mo | Vai tro trong du an |
|---|---|---|---|
| Brazilian Insurance Market Data (SUSEP) | Kaggle / susep.gov.br — dataset cong khai do co quan quan ly bao hiem Brazil (SUSEP) cong bo | ~8.3 trieu dong, du lieu that tu 2003, cap nhat theo quy | Nguon chinh cho Fact_Premium / Fact_Claims — phi, boi thuong theo cong ty, san pham, bang, thang |
| Prudential Life Insurance Assessment | Kaggle competition — du lieu underwriting that | ~60 nghin dong | Nguon cho Dim_Customer — dac diem nghiep vu that (tuoi, BMI, tien su y te da ma hoa, muc rui ro) |

Hai bo du lieu duoc ket hop: SUSEP cung cap khoi luong giao dich du lon de tuning that, Prudential cung cap chieu khach hang co y nghia nghiep vu that (khong phai random).

## Kien truc tong quan

Luong du lieu tong the chay qua cac tang kien truc:
Staging -> DWH Star Schema -> Incremental Load/CDC -> Data Quality -> Orchestration Airflow -> Performance Tuning -> Power BI.

1. Staging: Nap file CSV tho vao database Staging_InsuranceRaw bang lenh BULK INSERT, giu nguyen cau truc ban dau de doi chieu toan ven.
2. DWH Star Schema: Fact_Premium, Fact_Claims (bang su kien); Dim_Customer (SCD Type 2), Dim_Policy, Dim_Date, Dim_Region (bang chieu).
3. Incremental Load / CDC: T-SQL Stored Procedures dung lenh MERGE de UPSERT; bat SQL Server Change Data Capture (CDC) tren Staging de chi nap phan du lieu moi/thay doi, khong reload toan bo moi lan.
4. Data Quality: Bo kiem dinh tu dong (not null, unique, referential integrity) chay nhu mot buoc trong pipeline, ghi log vao DQ_Check_Log, lam pipeline dung va canh bao neu khong dat.
5. Orchestration Airflow: Apache Airflow dieu phoi toan bo DAG: Load Staging -> Load Dim (song song) -> Load Fact -> Data Quality Check -> Notify; co co che retry va canh bao khi loi.
6. Performance Tuning: Do truoc va sau bang Execution Plan + STATISTICS IO/TIME, them Non-Clustered/Covering Index, can nhac partitioning theo thang.
7. Power BI: Ket noi truc tiep DWH, xay dashboard loss ratio, xu huong phi, phat hien outlier theo bang/san pham bao hiem.

## Cong nghe su dung

| Hang muc | Cong cu |
|---|---|
| Co so du lieu | Microsoft SQL Server (Docker tren WSL) |
| Ngon ngu chinh | T-SQL (ETL, tuning), Python (nap du lieu, DAG Airflow) |
| Incremental Load | SQL Server Change Data Capture (CDC) |
| Orchestration | Apache Airflow (chay trong Docker) |
| Schema Migration | Flyway hoac DbUp — quan ly schema theo version |
| Data Quality | dbt tests / Great Expectations — kiem dinh tu dong trong pipeline |
| Cong cu quan tri DB | Azure Data Studio / SSMS |
| Truc quan hoa | Power BI Desktop |
| Quan ly ma nguon & tai lieu | Git/GitHub, README co anh chup Execution Plan |

## Cau truc repo

```
insurance-dwh-project/
├── .cursor/
│   └── rules/
│       ├── 01-quy-trinh-thuc-hien.mdc
│       ├── 02-quan-ly-file-va-log.mdc
│       ├── 03-kiem-tra-git-va-review.mdc
│       ├── 04-python.mdc
│       └── 05-setup-handoff.mdc
├── .gitignore
├── data/raw/
│   └── .gitkeep
├── docs/
│   ├── .gitkeep
│   ├── architecture-explained.md
│   ├── data-dictionary.md
│   ├── glossary.md
│   ├── how-to-run.md
│   ├── insights.md
│   ├── performance-tuning-summary.md
│   └── repository-structure.md
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
├── implementation-guide.md
├── insurance-dwh-overview.pdf
└── README.md
```

## Cach chay du an

### Buoc 1: Thiet lap ha tang Docker
- Khoi chay container SQL Server va Airflow:
  ```bash
  docker-compose up -d
  ```
- TODO: Cap nhat huong dan cau hinh chi tiet khi hoan thanh Giai doan 2.

### Buoc 2: Chay Schema Migrations
- Khoi tao DWH schema qua Flyway hoac DbUp:
  ```bash
  # TODO: Chay migration V1__create_dwh_schema.sql
  ```
- TODO: Cap nhat khi hoan thanh Giai doan 3.

### Buoc 3: Nap du lieu va Kich hoat CDC
- Chay script nạp staging va bat CDC:
  ```bash
  # TODO: Chay sql/01_load_staging.sql va sql/02_enable_cdc.sql
  ```
- TODO: Cap nhat khi hoan thanh Giai doan 4.

### Buoc 4: Chay pipeline tren Airflow
- Kich hoat DAG `insurance_dwh_pipeline` tren Airflow Webserver (`http://localhost:8080`).
- TODO: Cap nhat khi hoan thanh Giai doan 6.

## Trang thai hien tai cua du an

Xem chi tiet tien do thuc hien, danh sach viec da lam va ke hoach tiep theo tai [log/progress-log.md](log/progress-log.md).

## Ghi chu ve Performance Tuning

Chung minh nang luc toi uu hoa bang anh chup Execution Plan truoc va sau khi tao Index, bang so sanh chi so STATISTICS IO/TIME (logical reads, elapsed time) se duoc trinh bay chi tiet tai muc nay sau khi hoan thanh Giai doan 7.
