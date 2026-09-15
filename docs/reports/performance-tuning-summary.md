# Tóm tắt Performance Tuning

Trạng thái: Chờ Giai đoạn 7.

Chưa có truy vấn nghiệp vụ đã chạy trên dữ liệu thật, Execution Plan, hoặc số đo `STATISTICS IO, TIME`; vì vậy chưa có kết quả before/after đáng tin cậy để tóm tắt.

Khi Giai đoạn 7 hoàn thành, bổ sung cho từng truy vấn:

1. Câu hỏi nghiệp vụ mà truy vấn trả lời.
2. Điểm nghẽn thấy trong Execution Plan trước tối ưu, ví dụ Table Scan hoặc Key Lookup.
3. Index đã chọn và lý do chọn cột khoá/cột `INCLUDE`.
4. So sánh logical reads, CPU time và elapsed time trước/sau, cùng quy mô dữ liệu và điều kiện đo.
5. Trade-off: chi phí lưu trữ và chi phí ghi dữ liệu do index tạo thêm.

