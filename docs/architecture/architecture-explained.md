# Kiến trúc dự án, giải thích theo luồng dữ liệu

## Dự án này giải quyết việc gì?

Dự án xây dựng một **Data Warehouse** kết hợp **Machine Learning Batch Pipeline**: kho dữ liệu được tổ chức chuẩn mực theo mô hình Star Schema trên Microsoft SQL Server để phục vụ báo cáo phân tích và dự đoán rủi ro. Bài toán là tổng hợp dữ liệu phí bảo hiểm và bồi thường từ thị trường bảo hiểm Brazil (SUSEP ~8.3M dòng), kết hợp với dữ liệu khách hàng và lịch sử tổn thất xe cơ giới từ Porto Seguro (~1.5M dòng), từ đó phân tích doanh thu, bồi thường và dự đoán xác suất phát sinh tổn thất bằng mô hình học máy.

Mục tiêu là xây dựng một hệ thống End-to-End trọn vẹn: quy trình ETL tự động, chịu lỗi, có kiểm tra chất lượng dữ liệu, có đo lường tối ưu hiệu năng (Performance Tuning), và có luồng dự đoán rủi ro (Batch Inference) phục vụ trực tiếp cho Power BI.

## Dữ liệu đi từ đâu đến đâu?

```text
CSV SUSEP (~8.3M rows) + CSV Porto Seguro (~1.5M rows)
                    |
                    v
    Staging_InsuranceRaw trong SQL Server
                    |
                    v
            DWH_Insurance:
   (Fact_Premium, Fact_Claims, Dim_Customer SCD2,
        Dim_Policy, Dim_Date, Dim_Region)
                    |
                    +------------------------------------------+
                    |                                          |
                    v                                          v
      Kiểm tra chất lượng dữ liệu (DQ Check)           ML Feature View (SQL)
                    |                                          |
                    v                                          v
      Airflow điều phối toàn bộ pipeline               Batch Model Scoring
                    |                              (ml/predict_risk_batch.py)
                    |                                          |
                    +<-----------------------------------------+
                    | (Lưu kết quả dự đoán)
                    v
      Fact_Customer_Risk_Prediction
                    |
                    +--> Đo và tối ưu truy vấn SQL (Tuning)
                    |
                    v
      Power BI: Dashboard tổn thất, xu hướng & rủi ro dự đoán
```

1. **Dữ liệu nguồn**: Gồm SUSEP (~8.3 triệu dòng phí và bồi thường theo công ty, sản phẩm, bang, tháng) và Porto Seguro (~1.5 triệu dòng thông tin khách hàng, đặc trưng xe và lịch sử claim). Cả hai đều xuất phát từ thị trường bảo hiểm Brazil, đạt tổng dung lượng thô ~2.0 — 2.5 GB.
2. **Staging**: File CSV được nạp nguyên trạng vào `Staging_InsuranceRaw` bằng `BULK INSERT` qua script `sql/01_load_staging.sql`.
3. **DWH Star Schema**: Các Stored Procedure T-SQL chuyển dữ liệu từ staging vào kho `DWH_Insurance`, lấy dữ liệu mới/thay đổi qua CDC và nạp vào các bảng Fact/Dimension.
4. **Data Quality**: Pipeline tự động kiểm tra các quy tắc toàn vẹn (Not Null, Unique, Referential Integrity, Range check) và ghi log vào `DQ_Check_Log`.
5. **Machine Learning Batch Inference**: Task Airflow gọi `ml/predict_risk_batch.py` trích xuất feature từ DWH, tính toán điểm rủi ro (`PredictedClaimProbability`, `RiskCategory`) và gọi `sql/08_sp_load_risk_predictions.sql` để lưu kết quả vào `Fact_Customer_Risk_Prediction`.
6. **Analytics & Performance Tuning**: Dữ liệu trong DWH được tối ưu truy vấn bằng Indexing/Partitioning, và trực quan hóa toàn diện trên Power BI Desktop.

## Các quyết định thiết kế

### Star Schema
- Dùng **Star Schema** với các bảng sự kiện (`Fact_Premium`, `Fact_Claims`, `Fact_Customer_Risk_Prediction`) và các bảng chiều (`Dim_Customer`, `Dim_Policy`, `Dim_Date`, `Dim_Region`). Mô hình này tối ưu cho việc truy vấn tổng hợp đa chiều và tích hợp trực tiếp vào Power BI.

### Dim_Customer dùng SCD Type 2
- Khách hàng từ tập dữ liệu Porto Seguro (~1.5 triệu dòng) áp dụng **SCD Type 2** (`Start_Date`, `End_Date`, `Is_Current`) để lưu vết lịch sử biến động thông tin theo thời gian, đảm bảo tính chính xác cho các giao dịch trong quá khứ.

### CDC (Change Data Capture) thay vì nạp lại toàn bộ
- Nguồn dữ liệu lên tới hàng triệu dòng. Dùng **CDC** và bảng `ETL_Watermark` giúp chỉ nạp phần dữ liệu thay đổi, tiết kiệm tài nguyên và rút ngắn thời gian chạy batch.

### Machine Learning Batch Inference tích hợp vào Airflow
- Thay vì tách rời mô hình ML như một bài toán nghiên cứu độc lập, dự án xem DWH như một **Feature Store**. Airflow điều phối việc chạy model scoring định kỳ và ghi ngược kết quả vào DWH để Power BI có thể so sánh giữa *Rủi ro dự đoán* và *Tổn thất thực tế (Loss Ratio)*.

### Audit Log và Idempotency
- Mọi Stored Procedure đều được bọc trong `TRY...CATCH`, ghi nhận nhật ký vào `ETL_Audit_Log` và sử dụng lệnh `MERGE` để đảm bảo khi chạy lại cùng một batch sẽ không làm nhân đôi hoặc sai lệch dữ liệu.

### Tối ưu truy vấn bằng Index dựa trên đo đạc thực tế
- Trên Fact Table quy mô 8-10 triệu dòng, việc đo lường Execution Plan và `STATISTICS IO, TIME` trước và sau khi tạo Non-Clustered/Covering Index giúp chứng minh rõ ràng năng lực Performance Tuning.
