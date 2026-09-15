# Báo cáo duyệt repo — 2026-09-15

## Tóm tắt

Đã kiểm tra tĩnh toàn bộ các hạng mục 2a–2f dựa trên `insurance-dwh-overview.pdf`, `implementation-guide.md` và `log/progress-log.md`. Phát hiện 5 sai lệch: 4 sai lệch đã tự sửa và 1 mục cần người dùng xác nhận. Không chạy Docker, SQL Server hoặc Airflow theo phạm vi yêu cầu.

## Danh sách đã kiểm tra

| Hạng mục | Kết quả | Ghi nhận |
|---|---|---|
| 2a. Cấu trúc thư mục | Có sai lệch | Các thư mục/file theo kế hoạch có mặt; `.cursor/rules/` là phần bổ sung không có trong hai tài liệu nguồn và cần xác nhận giữ lại. |
| 2b. README.md | Có sai lệch | Đủ 9 nội dung yêu cầu, không có icon/emoji và thông tin đều truy được về tài liệu nguồn; cây repo trong README thiếu nhiều file thực tế. Đã sửa. |
| 2c. Tên gọi xuyên suốt | Đạt | Tên sáu bảng Fact/Dimension nhất quán. Tám task DAG đúng tên và dependency đúng thứ tự. Migration chỉ có `V1__create_dwh_schema.sql`, không trùng version. |
| 2d. Docs và progress log | Đạt | `insights.md` và `performance-tuning-summary.md` đều ghi rõ đang chờ Giai đoạn 8 và 7. Glossary có đủ 18 thuật ngữ bắt buộc. |
| 2e. Progress log | Đạt | Bảng có đủ 7 cột quy định; lịch sử hiện có được giữ nguyên. Giai đoạn hiện tại và việc tiếp theo vẫn đúng là Giai đoạn 1. |
| 2f. Khả thi kỹ thuật cơ bản | Có sai lệch | DAG hợp lệ về cú pháp; các file SQL có cặp block comment cân bằng và tên bảng khớp migration. Compose có lỗi cấu trúc service/mount và thuộc tính version đã lỗi thời; đã sửa và kiểm tra lại bằng parse tĩnh. |

## Sai lệch đã phát hiện và tự sửa

| Hạng mục | Mô tả sai lệch | File liên quan | Cách đã sửa |
|---|---|---|---|
| 2b | Cây repo trong README chỉ liệt kê `.gitkeep` trong `docs/`, đồng thời thiếu các file docs, `log/`, tài liệu nguồn và `.cursor/rules/` đang tồn tại. | `README.md` | Cập nhật cây text để phản ánh toàn bộ cấu trúc đang có trong repo, ngoại trừ thư mục nội bộ `.git/` và môi trường cục bộ `.venv/`. |
| 2f | Compose khai báo ba service (`sqlserver`, `airflow-webserver`, `airflow-scheduler`) trong khi kế hoạch quy định hai service tổng thể: SQL Server và Airflow. Hai container Airflow cũng dùng SQLite ở filesystem riêng nên không chia sẻ metadata database. | `docker-compose.yml` | Gộp thành service `airflow` dùng lệnh `standalone`, khởi tạo metadata và chạy webserver/scheduler trong một service; giữ `sqlserver` là service còn lại. |
| 2f | Cả hai service Airflow mount `./logs`, nhưng repo chỉ có thư mục chuẩn `log/`. Nếu chạy sẽ tạo thêm thư mục ngoài kế hoạch. | `docker-compose.yml`, `docs/how-to-run.md` | Đổi mount thành `./log:/opt/airflow/logs` và cập nhật tên/container Airflow trong hướng dẫn chạy. |
| 2f | Thuộc tính Compose `version: '3.8'` đã lỗi thời và bị Docker Compose hiện tại bỏ qua. | `docker-compose.yml` | Xoá thuộc tính lỗi thời; cấu hình vẫn được parse với hai service `sqlserver` và `airflow`. |

## Cần người dùng xác nhận

| Hạng mục | Mô tả vấn đề | Lý do không tự sửa | Đề xuất hướng xử lý |
|---|---|---|---|
| 2a | `.cursor/rules/` không có trong cấu trúc được nêu tại `implementation-guide.md` hoặc hai tài liệu nguồn. Một số rule còn nhắc các đường dẫn owner `docs/logs/log_tv*.md`, khác với `log/progress-log.md` của repo. | Không rõ đây là cấu hình nội bộ người dùng muốn giữ hay file dư từ một template khác; xoá hoặc sửa có thể làm mất hướng dẫn đang dùng. | Xác nhận giữ và chuẩn hoá các rule theo repo này, hoặc cho phép xoá `.cursor/` nếu không thuộc phạm vi dự án. |

## Kết luận

Repo sườn đã sẵn sàng về mặt kiểm tra tĩnh để tiếp tục Giai đoạn 1 — Khảo sát và chuẩn bị dữ liệu thật. Bước tiếp theo là tải hai bộ dữ liệu vào `data/raw/`, chạy `notebooks/01-eda.ipynb`, rồi điền `docs/data-dictionary.md`. Mục `.cursor/rules/` cần xác nhận về quản trị tài liệu, nhưng không chặn các công việc kỹ thuật của Giai đoạn 1.
