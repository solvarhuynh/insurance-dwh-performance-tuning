# Hệ thống tài liệu dự án (Documentation)

Thư mục `docs/` chứa toàn bộ tài liệu kiến trúc, hướng dẫn vận hành, đặc tả nghiệp vụ và báo cáo phân tích của dự án **Insurance DWH & Performance Tuning**.

## Cấu trúc thư mục tài liệu

```text
docs/
├── README.md                      # Mục lục và hướng dẫn tra cứu tài liệu
├── architecture/                  # Thiết kế kiến trúc và mô hình dữ liệu
│   ├── architecture-explained.md  # Giải thích luồng dữ liệu và quyết định kỹ thuật
│   ├── data-dictionary.md         # Từ điển dữ liệu nguồn và đích
│   └── repository-structure.md    # Phân bổ cấu trúc thư mục repository
├── guides/                        # Hướng dẫn thực hành và tra cứu
│   ├── how-to-run.md              # Hướng dẫn chi tiết thiết lập và chạy từng bước
│   └── glossary.md                # Bảng giải thích thuật ngữ DE và bảo hiểm
├── reports/                       # Báo cáo phân tích và hiệu năng
│   ├── insights.md                # Báo cáo phân tích insight nghiệp vụ bảo hiểm
│   └── performance-tuning-summary.md # Báo cáo đo lường và tối ưu hiệu năng truy vấn
└── specs/                         # Tài liệu đặc tả và định hướng gốc
    ├── implementation-guide.md    # Kế hoạch chi tiết 8 giai đoạn và Definition of Done
    └── insurance-dwh-overview.pdf # Bản tổng quan mục tiêu, kiến trúc và công nghệ
```

## Danh mục tài liệu theo nhóm

### 1. Nhóm Đặc tả & Định hướng (`specs/`)
- [implementation-guide.md](specs/implementation-guide.md): Tài liệu hướng dẫn thực hiện chi tiết qua 8 giai đoạn, kèm checklist và tiêu chí hoàn thành (Definition of Done) cho từng giai đoạn.
- [insurance-dwh-overview.pdf](specs/insurance-dwh-overview.pdf): Tài liệu PDF tổng quan về bối cảnh dự án, nguồn dữ liệu thật, kiến trúc tổng thể, công cụ sử dụng và lộ trình triển khai.

### 2. Nhóm Kiến trúc & Mô hình (`architecture/`)
- [architecture-explained.md](architecture/architecture-explained.md): Phân tích chi tiết luồng luân chuyển dữ liệu từ CSV thô qua Staging, Star Schema, CDC, Data Quality đến Airflow và Power BI; giải thích lý do lựa chọn từng giải pháp kỹ thuật.
- [data-dictionary.md](architecture/data-dictionary.md): Từ điển dữ liệu mô tả cấu trúc, kiểu dữ liệu, ràng buộc và ý nghĩa nghiệp vụ của các trường trong hai bộ dữ liệu nguồn (SUSEP, Prudential) và các bảng đích trong DWH.
- [repository-structure.md](architecture/repository-structure.md): Bản đồ phân chia khu vực trong repository, vai trò của từng thư mục, file và mối quan hệ giữa các thành phần.

### 3. Nhóm Hướng dẫn & Vận hành (`guides/`)
- [how-to-run.md](guides/how-to-run.md): Hướng dẫn từng bước từ chuẩn bị môi trường Docker, nạp dữ liệu Staging, chạy Schema Migration, kích hoạt CDC đến điều phối pipeline bằng Apache Airflow.
- [glossary.md](guides/glossary.md): Bảng tra cứu các khái niệm kỹ thuật Data Engineering (CDC, SCD Type 2, Watermark, Idempotency, Execution Plan, Covering Index) và thuật ngữ ngành bảo hiểm (Premium, Claim, Loss Ratio, Underwriting).

### 4. Nhóm Báo cáo & Phân tích (`reports/`)
- [insights.md](reports/insights.md): Tổng hợp các nhận định phân tích nghiệp vụ, đánh giá tỷ lệ tổn thất (Loss Ratio), xu hướng tăng trưởng phí và phát hiện rủi ro bất thường.
- [performance-tuning-summary.md](reports/performance-tuning-summary.md): Báo cáo so sánh chi tiết số liệu hiệu năng truy vấn (Execution Plan, Logical Reads, CPU Time, Elapsed Time) trước và sau khi tối ưu hóa bằng Indexing và Partitioning.
