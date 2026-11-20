# Restore — đánh giá sau giao dịch

Luồng đã được nối từ nút chat và trả giá của tin đăng tới tab Đánh giá trên hồ sơ. Người bán chọn người mua trong đoạn chat của tin. Người mua xác nhận đã nhận hàng. Sau đó, mỗi bên có thể đánh giá bên còn lại một lần. Hai bên có thể hủy yêu cầu trước khi người mua xác nhận.

Hồ sơ hiển thị tổng số đánh giá, điểm trung bình, thẻ nhận xét, sản phẩm giao dịch và bộ lọc theo vai trò người viết. Chat cá nhân cũ vẫn dùng được. Để xác nhận giao dịch, mở chat từ đúng tin đăng.

Backend đã build, schema Prisma đã validate và bài kiểm thử nghiệp vụ với dữ liệu mô phỏng đã chạy thành công. Migration 20261119000000_verified_trade_reviews chưa được áp dụng lên Supabase do kết nối P1001. Cần chạy migration trên database đích và kiểm tra giao dịch bằng hai tài khoản với dữ liệu thật trước khi phát hành.
