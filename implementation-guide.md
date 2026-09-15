# Implementation Guide — Insurance DWH & Performance Tuning

> File này dùng để bạn (hoặc một AI coding assistant như Claude Code) đi theo từng bước, checklist rõ ràng, có tiêu chí hoàn thành (Definition of Done) cho mỗi giai đoạn. Đọc kèm file `insurance-dwh-overview.pdf` để hiểu bức tranh tổng thể.

## Mục tiêu dự án
Xây một Data Warehouse ngành bảo hiểm dùng **dữ liệu thật**, trên **Microsoft SQL Server**, có luồng ETL bằng **T-SQL** với **incremental load (CDC)**, được điều phối bởi **Airflow**, có **audit log/idempotency** và **data quality tự động**, chứng minh khả năng **Performance Tuning**, và một lớp **Power BI** với insight phân tích thật.

> So với bản DE "cơ bản", bản này thêm hẳn lớp *pipeline engineering* — thứ phân biệt Data Engineer với Analytics Engineer: dữ liệu chảy vào hệ thống một cách tự động, chịu lỗi, không load lại toàn bộ mỗi lần, và được giám sát.

## Nguồn dữ liệu
| Bộ dữ liệu | Nguồn | Dùng cho |
|---|---|---|
| Brazilian Insurance Market Data (SUSEP) | Kaggle — dataset công khai do cơ quan quản lý bảo hiểm Brazil (SUSEP) công bố; ~8.3 triệu dòng, premium/claims theo công ty, sản phẩm, bang, tháng, từ 2003 | Fact_Premium, Fact_Claims |
| Prudential Life Insurance Assessment | Kaggle competition — dữ liệu underwriting thật, ~60 nghìn dòng | Dim_Customer |

> Lưu ý: tự tìm và tải 2 bộ này trên Kaggle (cần tài khoản Kaggle, dùng Kaggle API `kaggle datasets download` hoặc tải thủ công), kiểm tra license trước khi public repo. Nếu SUSEP không còn khả dụng đúng tên, tìm bằng từ khoá "SUSEP insurance data premiums claims Brazil" — đây là dữ liệu regulatory công khai nên luôn có nguồn thay thế tương đương (trang chính thức SUSEP: susep.gov.br).

---

## Giai đoạn 1 — Khảo sát & chuẩn bị dữ liệu thật

**Việc cần làm:**
1. Tải 2 bộ dữ liệu về `data/raw/`.
2. Dùng Python (pandas) đọc và khảo sát nhanh: số dòng, số cột, kiểu dữ liệu, tỷ lệ null, giá trị trùng lặp, khoảng thời gian dữ liệu bao phủ.
3. Ghi lại data dictionary (mô tả từng cột) cho cả 2 bộ — làm cơ sở thiết kế schema ở Giai đoạn 3.
4. Xác định các vấn đề chất lượng dữ liệu cần xử lý (encoding, định dạng ngày tháng, đơn vị tiền tệ BRL, mã hoá category ở bộ Prudential).

**Definition of Done:**
- [ ] File `docs/data-dictionary.md` mô tả từng cột của 2 bộ dữ liệu gốc.
- [ ] File `notebooks/01-eda.ipynb` (hoặc script) chứa kết quả khảo sát (shape, null %, sample rows).
- [ ] Danh sách vấn đề chất lượng dữ liệu đã ghi nhận.

---

## Giai đoạn 2 — Hạ tầng & Staging

**Việc cần làm:**
1. Viết `docker-compose.yml` dựng **2 service**: SQL Server 2022 (`mcr.microsoft.com/mssql/server`) và Airflow (webserver + scheduler, dùng image `apache/airflow`). Cấp đủ RAM (khuyến nghị ≥6GB tổng cho cả 2 container).
2. Kết nối SQL Server bằng Azure Data Studio hoặc `sqlcmd`/`mssql-cli` từ WSL để xác nhận kết nối OK; kiểm tra Airflow UI truy cập được qua `localhost:8080`.
3. Tạo database `Staging_InsuranceRaw`.
4. Tạo bảng staging khớp cấu trúc CSV gốc (không transform).
5. Nạp dữ liệu bằng `BULK INSERT` (từ file CSV đã convert phù hợp) — **không** insert từng dòng qua Python/pyodbc vì quá chậm với hàng triệu dòng.
6. Kiểm tra số dòng nạp vào khớp với số dòng file gốc.

**Definition of Done:**
- [ ] `docker-compose.yml` chạy được cả SQL Server và Airflow, ổn định.
- [ ] Database `Staging_InsuranceRaw` có đủ bảng staging tương ứng 2 nguồn dữ liệu.
- [ ] Script `sql/01_load_staging.sql` (hoặc `.py` gọi BULK INSERT) chạy thành công, log số dòng nạp.
- [ ] Đối chiếu row count staging = row count file CSV gốc.

---

## Giai đoạn 3 — Thiết kế Data Warehouse & Schema Migration

**Việc cần làm:**
1. Thiết kế ERD cho Star Schema (dùng draw.io / dbdiagram.io), gồm:
   - **Fact_Premium**: khoá ngoại tới Dim_Customer, Dim_Policy, Dim_Date, Dim_Region; số đo: giá trị phí, số hợp đồng.
   - **Fact_Claims**: khoá ngoại tương tự; số đo: giá trị bồi thường, số vụ claim.
   - **Dim_Customer**: áp dụng **SCD Type 2** (cột `Start_Date`, `End_Date`, `Is_Current`) — nếu thuộc tính khách hàng thay đổi, thêm dòng mới thay vì ghi đè.
   - **Dim_Policy**: loại sản phẩm bảo hiểm, đặc điểm hợp đồng.
   - **Dim_Date**: bảng ngày chuẩn (ngày, tháng, quý, năm) để dễ phân tích theo thời gian.
   - **Dim_Region**: bang/khu vực (từ dữ liệu SUSEP).
2. Cài đặt công cụ **Schema Migration** (Flyway hoặc DbUp) — mọi script tạo/sửa bảng đều là 1 file migration đánh version tăng dần (`V1__create_dwh_schema.sql`, `V2__add_dim_region.sql`...), không chạy tay ALTER TABLE.
3. Viết migration đầu tiên tạo database `DWH_Insurance` và toàn bộ bảng Fact/Dim với khoá chính, khoá ngoại rõ ràng.
4. Xác định business key vs surrogate key cho từng Dim.

**Definition of Done:**
- [ ] File ERD (ảnh hoặc link draw.io) lưu trong `docs/erd.png`.
- [ ] Thư mục `migrations/` chứa các file `.sql` đánh version, chạy được qua Flyway/DbUp từ trạng thái rỗng.
- [ ] Mỗi bảng Dim có surrogate key (identity) + business key gốc.
- [ ] Dim_Customer có đủ cột SCD Type 2.
- [ ] README trong `migrations/` mô tả cách chạy migration để dựng lại DWH từ đầu.

---

## Giai đoạn 4 — ETL bằng T-SQL với Incremental Load & Audit Log

**Việc cần làm:**

**4a. Incremental Load bằng Change Data Capture (CDC)**
1. Bật CDC trên các bảng Staging liên quan (`EXEC sys.sp_cdc_enable_db`, `EXEC sys.sp_cdc_enable_table`).
2. Tạo bảng control `ETL_Watermark` lưu LSN/timestamp lần chạy gần nhất cho từng bảng.
3. Viết Stored Procedure dùng `cdc.fn_cdc_get_net_changes_<capture_instance>` để lấy đúng phần dữ liệu mới/thay đổi kể từ watermark trước đó, thay vì đọc lại toàn bộ bảng.

**4b. Audit Log & Idempotency**
4. Tạo bảng `ETL_Audit_Log`: `batch_id, procedure_name, start_time, end_time, rows_affected, status, error_message`.
5. Wrap mỗi Stored Procedure bằng `TRY...CATCH`, ghi log kể cả khi lỗi (status = 'FAILED', error_message chi tiết).
6. Thiết kế toàn bộ Stored Procedure UPSERT bằng `MERGE`, đảm bảo chạy lại cùng batch không tạo dòng trùng — test bằng cách chạy 2 lần liên tiếp và so sánh row count.

**4c. Stored Procedures chính**
7. `sp_Load_DimCustomer` — xử lý logic SCD Type 2 dựa trên CDC net changes.
8. Stored Procedure cho các Dim còn lại (đơn giản hơn — UPSERT bằng `MERGE`).
9. `sp_Load_FactPremium`, `sp_Load_FactClaims` — join dữ liệu CDC với các Dim để lấy surrogate key, `MERGE` UPSERT vào Fact.
10. Viết vài query kiểm tra referential integrity: mọi dòng Fact đều join được với Dim tương ứng, không có "unknown member" bất thường.

**Definition of Done:**
- [ ] CDC bật thành công trên bảng Staging, `sql/02_enable_cdc.sql` ghi lại các lệnh setup.
- [ ] `ETL_Watermark` cập nhật đúng sau mỗi lần chạy; chạy incremental chỉ xử lý phần thay đổi (đo và ghi lại thời gian chạy full-load vs incremental-load để so sánh).
- [ ] `ETL_Audit_Log` có dữ liệu đầy đủ sau mỗi lần chạy, kể cả trường hợp lỗi.
- [ ] Chạy lại cùng batch 2 lần liên tiếp → row count Fact/Dim không đổi (chứng minh idempotent).
- [ ] `sql/03_sp_dim_customer_scd2.sql`, `sql/04_sp_dim_others.sql`, `sql/05_sp_fact_premium.sql`, `sql/06_sp_fact_claims.sql`.
- [ ] Query kiểm tra referential integrity không phát hiện bản ghi mồ côi (orphan).

---

## Giai đoạn 5 — Data Quality Framework

**Việc cần làm:**
1. Định nghĩa bộ rule kiểm định chất lượng dữ liệu (không cần công cụ ngoài phức tạp — có thể viết bằng T-SQL thuần hoặc dùng dbt tests nếu muốn chuẩn hoá hơn):
   - Not null trên các cột khoá bắt buộc.
   - Unique trên business key của từng Dim.
   - Referential integrity: mọi FK trong Fact phải tồn tại trong Dim tương ứng.
   - Giá trị hợp lý: số tiền phí/bồi thường không âm, ngày hợp đồng nằm trong khoảng hợp lý.
2. Tạo bảng `DQ_Check_Log`: `check_name, run_time, table_name, rows_checked, rows_failed, status`.
3. Viết Stored Procedure `sp_Run_DataQualityChecks` chạy toàn bộ rule, ghi kết quả vào `DQ_Check_Log`.
4. Nếu có check quan trọng fail (VD: orphan record), procedure trả về status lỗi để bước Airflow phía sau biết dừng pipeline và cảnh báo.

**Definition of Done:**
- [ ] `sql/07_data_quality_checks.sql` chứa toàn bộ rule kiểm định.
- [ ] `DQ_Check_Log` có dữ liệu sau mỗi lần chạy.
- [ ] Test thử bằng cách cố tình đưa 1 dòng dữ liệu lỗi (VD: FK không tồn tại) vào staging, xác nhận check phát hiện đúng và ghi log fail.

---

## Giai đoạn 6 — Orchestration với Airflow

**Việc cần làm:**
1. Viết DAG Airflow (`dags/insurance_dwh_pipeline.py`) mô tả luồng phụ thuộc:
   - Task `load_staging` (BULK INSERT CDC net changes)
   - Task `load_dim_customer`, `load_dim_policy`, `load_dim_date`, `load_dim_region` (chạy song song, đều phụ thuộc `load_staging`)
   - Task `load_fact_premium`, `load_fact_claims` (phụ thuộc các task Dim ở trên)
   - Task `run_data_quality_checks` (phụ thuộc các task Fact)
   - Task `notify` — gửi thông báo kết quả (email/webhook đơn giản, hoặc ghi ra file log rõ ràng nếu không setup SMTP)
2. Mỗi task gọi Stored Procedure tương ứng qua `MsSqlOperator` hoặc `PythonOperator` + pyodbc.
3. Cấu hình `retries=2-3` và `retry_delay` cho từng task.
4. Cấu hình `on_failure_callback` để gửi cảnh báo kèm log chi tiết task nào lỗi.
5. Test chạy DAG thủ công qua Airflow UI, xác nhận thứ tự phụ thuộc đúng, thử cố tình làm 1 task fail để kiểm tra retry + alert hoạt động.

**Definition of Done:**
- [ ] `dags/insurance_dwh_pipeline.py` xuất hiện và chạy được trên Airflow UI (`localhost:8080`).
- [ ] Graph view thể hiện đúng dependency (Dim chạy song song trước Fact, DQ check sau cùng trước Notify).
- [ ] Test retry: cố tình gây lỗi 1 task, xác nhận Airflow tự retry theo cấu hình rồi mới báo fail.
- [ ] Ảnh chụp Graph view + Gantt view của 1 lần chạy thành công, lưu vào `docs/airflow-dag.png`.

---

## Giai đoạn 7 — Performance Tuning & Tài liệu hoá

**Đây là phần quan trọng nhất để đưa vào CV/portfolio.**

**Việc cần làm:**
1. Viết 2-3 câu query phân tích nghiệp vụ thực tế, ví dụ:
   - Tổng phí bảo hiểm thu được theo bang, theo năm, dùng `SUM() OVER`, `GROUP BY`.
   - Top 10 sản phẩm/bang có tỷ lệ bồi thường/phí (loss ratio) cao nhất mỗi quý, dùng CTE + `RANK()`.
2. Chạy các query này trên Fact table **khi chưa có non-clustered index** (ngoài PK). Bật `SET STATISTICS IO, TIME ON`, chụp lại kết quả (logical reads, CPU time, elapsed time).
3. Xem Execution Plan (Azure Data Studio / SSMS) — xác định bước gây chậm (thường là Table Scan hoặc Key Lookup).
4. Tạo Non-Clustered Index trên cột dùng để JOIN (CustomerKey, PolicyKey) và cột lọc/sắp xếp (DateKey). Cân nhắc Covering Index (`INCLUDE`) để tránh Key Lookup.
5. Chạy lại đúng query đó, chụp lại Execution Plan + STATISTICS IO, so sánh trước/sau.
6. (Nâng cao, tuỳ thời gian) Thử partition Fact table theo năm/tháng, đo tác động.
7. Viết `README.md` tổng hợp: mô tả bài toán, ảnh chụp Execution Plan trước/sau, bảng so sánh số liệu (logical reads, thời gian chạy), giải thích *tại sao* chọn index đó.

**Definition of Done:**
- [ ] Ít nhất 2 query nghiệp vụ có kịch bản before/after rõ ràng.
- [ ] Ảnh chụp Execution Plan before và after cho mỗi query.
- [ ] Bảng so sánh số liệu STATISTICS IO/TIME trước và sau khi tối ưu.
- [ ] `README.md` trình bày mạch lạc, có giải thích lý do kỹ thuật (không chỉ liệt kê số liệu).

---

## Giai đoạn 8 — Power BI & Insight

**Việc cần làm:**
1. Kết nối Power BI Desktop trực tiếp tới `DWH_Insurance` (SQL Server connector).
2. Xây model quan hệ trong Power BI khớp với Star Schema đã thiết kế.
3. Xây dashboard gồm:
   - Xu hướng tổng phí thu / tổng bồi thường theo thời gian.
   - Loss ratio (bồi thường/phí) theo bang và theo sản phẩm bảo hiểm — phát hiện điểm bất thường.
   - Top N sản phẩm/khu vực theo doanh thu phí.
4. Viết 3-5 insight bằng văn bản (không chỉ vẽ chart) — ví dụ: "Bang X có loss ratio cao gấp 2 lần trung bình toàn quốc trong 2 năm gần nhất, cần xem lại chính sách định phí ở khu vực này." Đây là chỗ thể hiện tư duy phân tích, không chỉ kỹ thuật.
5. Xuất dashboard dạng `.pbix` và vài ảnh chụp màn hình cho README chính của repo.

**Definition of Done:**
- [ ] File `powerbi/insurance-dashboard.pbix`.
- [ ] Ít nhất 3 visual chính (xu hướng theo thời gian, loss ratio theo chiều, top N).
- [ ] File `docs/insights.md` liệt kê 3-5 insight cụ thể, có số liệu dẫn chứng và đề xuất hành động.
- [ ] Ảnh chụp dashboard gắn vào README chính của repo.

---

## Cấu trúc thư mục đề xuất

```
insurance-dwh-project/
├── data/raw/                  # dữ liệu thô đã tải (không commit lên git nếu lớn — dùng .gitignore)
├── docs/
│   ├── data-dictionary.md
│   ├── erd.png
│   ├── airflow-dag.png
│   └── insights.md
├── notebooks/
│   └── 01-eda.ipynb
├── migrations/                # schema migration (Flyway/DbUp), version hoá
│   ├── V1__create_dwh_schema.sql
│   └── V2__...
├── sql/
│   ├── 01_load_staging.sql
│   ├── 02_enable_cdc.sql
│   ├── 03_sp_dim_customer_scd2.sql
│   ├── 04_sp_dim_others.sql
│   ├── 05_sp_fact_premium.sql
│   ├── 06_sp_fact_claims.sql
│   └── 07_data_quality_checks.sql
├── dags/
│   └── insurance_dwh_pipeline.py    # Airflow DAG
├── powerbi/
│   └── insurance-dashboard.pbix
├── docker-compose.yml         # SQL Server + Airflow
└── README.md
```

## Ghi chú chung cho AI hỗ trợ code
- Ưu tiên T-SQL cho mọi logic transform dữ liệu; Python chỉ dùng để nạp file thô (BULK INSERT), viết DAG Airflow, và các task điều phối — không xử lý logic biến đổi dữ liệu trong Python.
- Không insert dữ liệu triệu dòng theo từng dòng qua pyodbc — luôn dùng BULK INSERT/bcp hoặc batch insert theo lô lớn.
- Mọi thay đổi schema phải đi qua migration file (Flyway/DbUp), không ALTER TABLE tay trực tiếp; kèm cập nhật ERD trong `docs/erd.png`.
- Mọi Stored Procedure ETL phải ghi vào `ETL_Audit_Log` và đảm bảo idempotent (chạy lại không nhân đôi dữ liệu).
- Incremental load luôn dựa trên CDC net changes + watermark, không full reload trừ lần chạy đầu tiên.
- Mỗi giai đoạn hoàn thành nên commit riêng, message rõ ràng, để lịch sử git cũng là minh chứng quá trình làm việc.
