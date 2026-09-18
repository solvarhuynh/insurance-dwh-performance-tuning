# Insight Nghiệp vụ — Phân tích & Dự đoán Rủi ro

Trạng thái: Khung cấu trúc insight phân tích và đối chiếu rủi ro dự đoán (Giai đoạn 8 — Power BI & Insight).

Khi hoàn thành Giai đoạn 8, tài liệu này sẽ tổng hợp các nhận định phân tích cụ thể, có số liệu dẫn chứng và đề xuất hành động kinh doanh:

## 1. Xu hướng phí và bồi thường theo thời gian
- Phân tích chu kỳ mùa vụ của doanh thu phí bảo hiểm (`Fact_Premium`) và bồi thường tổn thất (`Fact_Claims`) từ 2003 đến nay.
- [Chờ số liệu từ DWH].

## 2. Phân tích Loss Ratio theo bang và dòng sản phẩm
- Tỷ lệ tổn thất (Loss Ratio = Claims / Premium) theo từng bang tại Brazil (SP, RJ, MG, RS, etc.).
- Nhận diện các bang có tỷ lệ tổn thất vượt ngưỡng an toàn (>70%).
- [Chờ số liệu từ DWH].

## 3. Đối chiếu giữa Rủi ro Dự đoán (ML Risk Scoring) và Tổn thất Thực tế
- Đánh giá mức độ tương quan giữa nhóm rủi ro dự đoán của mô hình (`Fact_Customer_Risk_Prediction`: 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL') và tỷ lệ phát sinh bồi thường thực tế.
- Kiểm chứng hiệu quả phân tầng rủi ro phục vụ thẩm định hợp đồng (Underwriting Risk Stratification).
- [Chờ số liệu từ DWH].

## 4. Phát hiện bất thường và khuyến nghị hành động
- Đề xuất điều chỉnh chính sách định phí (Pricing Strategy) cho các nhóm rủi ro cao.
- Cảnh báo các khu vực có tỷ lệ tổn thất đột biến để tăng cường thẩm định hiện trường.
- [Chờ số liệu từ DWH].
