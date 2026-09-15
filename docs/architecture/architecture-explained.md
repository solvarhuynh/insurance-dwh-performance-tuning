# Kiến trúc dự án, giải thích theo luồng dữ liệu

## Dự án này giải quyết việc gì?

Dự án xây dựng một **Data Warehouse**: kho dữ liệu được tổ chức riêng để phục vụ báo cáo và phân tích, thay vì dùng trực tiếp các file dữ liệu thô. Bài toán là tổng hợp dữ liệu phí bảo hiểm và bồi thường từ thị trường bảo hiểm Brazil, kết hợp với dữ liệu đặc điểm khách hàng Prudential, để có thể phân tích doanh thu phí, bồi thường và rủi ro.

Mục tiêu không chỉ là có dashboard. Dự án còn hướng đến một quy trình có thể chạy lặp lại, theo dõi được lỗi và có thể tối ưu khi dữ liệu lớn.

Trạng thái hiện tại: các thành phần kiến trúc đã được tạo dưới dạng cấu hình hoặc khung mã. Dữ liệu thật chưa được tải và pipeline chưa được chạy xác minh; Giai đoạn 1 vẫn đang thực hiện.

## Dữ liệu đi từ đâu đến đâu?

```text
CSV SUSEP + CSV Prudential
        |
        v
Staging_InsuranceRaw trong SQL Server
        |
        v
DWH_Insurance: các bảng Fact và Dimension theo Star Schema
        |
        +--> kiểm tra chất lượng dữ liệu và ghi audit log
        |
        v
Airflow điều phối các bước chạy
        |
        +--> đo và tối ưu truy vấn SQL
        |
        v
Power BI: dashboard và insight
```

1. Dữ liệu nguồn dự kiến gồm SUSEP (phí và bồi thường theo công ty, sản phẩm, bang, tháng) và Prudential (đặc điểm khách hàng như tuổi, BMI và chỉ dấu rủi ro). Hai bộ này chưa có trong `data/raw/`.
2. File CSV sẽ được nạp nguyên trạng vào vùng **staging**, tức khu vực nhận dữ liệu tạm trước khi biến đổi. Script dự kiến là `sql/01_load_staging.sql`.
3. Các thủ tục T-SQL sẽ chuyển dữ liệu từ staging vào kho `DWH_Insurance`, lấy dữ liệu mới/thay đổi và ghép với các bảng chiều.
4. Trước khi coi một lượt nạp là thành công, pipeline dự kiến kiểm tra các quy tắc chất lượng và ghi lại kết quả.
5. Airflow sẽ điều phối thứ tự chạy. Khi kho dữ liệu đã có dữ liệu đã kiểm chứng, Power BI mới là lớp đọc dữ liệu để làm báo cáo.

## Các quyết định thiết kế

### Star Schema

**Vấn đề.** Báo cáo bảo hiểm thường hỏi cùng một số đo dưới nhiều góc nhìn: tổng phí theo tháng, theo bang, theo sản phẩm hoặc theo khách hàng. Nếu để nguyên các bảng nguồn, mỗi báo cáo phải tự ghép nhiều cột và dễ cho kết quả không nhất quán.

**Giải pháp.** Dùng **Star Schema**, một mô hình có các bảng sự kiện ở giữa và các bảng mô tả bao quanh. `Fact_Premium` lưu sự kiện thu phí, `Fact_Claims` lưu sự kiện bồi thường; `Dim_Customer`, `Dim_Policy`, `Dim_Date`, `Dim_Region` lưu thông tin dùng để phân nhóm.

**Lý do chọn.** Mô hình này dễ đọc cho cả người làm báo cáo lẫn Power BI, giảm độ phức tạp khi truy vấn và phù hợp với các câu hỏi tổng hợp theo thời gian, khu vực, sản phẩm. Schema hiện được phác thảo tại `migrations/V1__create_dwh_schema.sql`, nhưng migration đó còn là khung chưa chạy.

### Dim_Customer dùng SCD Type 2

**Vấn đề.** Thông tin khách hàng, ví dụ mức rủi ro, có thể thay đổi. Ghi đè lên dòng cũ sẽ làm báo cáo lịch sử vô tình dùng thông tin của hiện tại để giải thích một giao dịch trong quá khứ.

**Giải pháp.** Dùng **SCD Type 2** (Slowly Changing Dimension Type 2): mỗi khi thuộc tính quan trọng đổi, đóng bản ghi cũ bằng `End_Date` và tạo bản ghi mới có `Start_Date`, đồng thời đánh dấu `Is_Current`.

**Lý do chọn.** Cách này giữ được lịch sử để biết tại thời điểm phát sinh phí hoặc bồi thường, khách hàng thuộc phiên bản thông tin nào. Thiết kế cột đã có trong `migrations/V1__create_dwh_schema.sql`; logic nạp dự kiến nằm ở `sql/03_sp_dim_customer_scd2.sql`, chưa được kiểm thử với dữ liệu thật.

### CDC thay vì nạp lại toàn bộ

**Vấn đề.** Nguồn SUSEP dự kiến có hàng triệu dòng. Đọc và nạp lại mọi dòng sau mỗi lần chạy vừa chậm vừa tăng rủi ro tạo dữ liệu trùng.

**Giải pháp.** Dùng **CDC (Change Data Capture)**, cơ chế của SQL Server ghi nhận các dòng đã được thêm, sửa hoặc xoá. **Watermark** là mốc LSN hoặc thời gian của lần chạy thành công gần nhất; pipeline dùng mốc này để chỉ lấy phần thay đổi sau đó.

**Lý do chọn.** Incremental load tiết kiệm tài nguyên và rút ngắn thời gian chạy khi chỉ một phần nhỏ dữ liệu thay đổi. Thiết lập dự kiến tại `sql/02_enable_cdc.sql`; chưa có xác nhận CDC đã được bật hoặc watermark đã cập nhật đúng.

### Audit log và Idempotency

**Vấn đề.** Một lượt ETL có thể lỗi giữa chừng hoặc cần chạy lại. Nếu không biết đã xử lý đến đâu, người vận hành khó truy nguyên; nếu chạy lại không an toàn, cùng một dữ liệu có thể bị nhân đôi.

**Giải pháp.** **Audit log** là nhật ký ghi batch, thủ tục, thời điểm, số dòng, trạng thái và lỗi. **Idempotency** nghĩa là chạy lại cùng một batch cho ra cùng trạng thái dữ liệu, không tạo thêm bản ghi sai; các script dự kiến dùng `MERGE` để UPSERT (cập nhật nếu đã có, thêm nếu chưa có).

**Lý do chọn.** Đây là nền tảng để pipeline chịu lỗi và có thể vận hành thay vì chỉ là một script chạy một lần. Các bảng/log và thủ tục khung nằm trong `sql/03_sp_dim_customer_scd2.sql` đến `sql/06_sp_fact_claims.sql`; chưa có bằng chứng chạy lại hai lần với kết quả ổn định.

### Airflow thay vì chạy script bằng tay

**Vấn đề.** Các bước có thứ tự phụ thuộc: phải nạp staging trước, nạp các bảng chiều trước Fact, rồi mới kiểm tra chất lượng. Chạy thủ công dễ quên bước, khó chạy lại có kiểm soát và khó biết lỗi ở đâu.

**Giải pháp.** Dùng Apache Airflow, công cụ **orchestration** (điều phối) các công việc theo lịch và theo quan hệ phụ thuộc. Một **DAG** là sơ đồ có hướng, không có vòng lặp, mô tả task nào phải xong trước task nào.

**Lý do chọn.** Airflow cho phép đặt retry, ghi log từng task và hiển thị trực quan tình trạng pipeline. DAG dự kiến tại `dags/insurance_dwh_pipeline.py` có thứ tự staging → dimension song song → fact → kiểm tra chất lượng → thông báo, nhưng chưa được chạy trên Airflow UI.

### Kiểm tra chất lượng dữ liệu trước khi báo cáo

**Vấn đề.** Dashboard có thể trông hợp lý dù dữ liệu bị thiếu khoá, âm số tiền hoặc Fact tham chiếu đến Dimension không tồn tại.

**Giải pháp.** **Data Quality check** là các quy tắc tự động kiểm tra dữ liệu, như bắt buộc có giá trị, không trùng business key, toàn vẹn tham chiếu và số tiền không âm. Kết quả dự kiến ghi vào `DQ_Check_Log`.

**Lý do chọn.** Dừng pipeline khi lỗi nghiêm trọng giúp tránh đưa dữ liệu sai vào Power BI. Bộ quy tắc khung nằm ở `sql/07_data_quality_checks.sql`; chưa được kiểm thử bằng dữ liệu lỗi.

### Tối ưu truy vấn bằng index dựa trên đo đạc

**Vấn đề.** Khi Fact table lớn, báo cáo theo thời gian, bang và sản phẩm có thể phải quét nhiều dữ liệu hơn cần thiết.

**Giải pháp.** Dùng Execution Plan và `STATISTICS IO, TIME` để đo truy vấn trước, sau đó mới cân nhắc Non-Clustered Index hoặc Covering Index đúng với cột lọc, nối và tổng hợp.

**Lý do chọn.** Index có chi phí lưu trữ và làm chậm ghi dữ liệu; vì vậy không nên thêm theo cảm tính. Đã lên kế hoạch, chưa triển khai ở Giai đoạn 7.

