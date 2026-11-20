# Nạp Xu qua ZaloPay sandbox: cài đặt và chạy thử

Chỉ dùng môi trường **sandbox** của ZaloPay, không có tiền thật. Backend tự khoá vào cổng sandbox khi `PAYMENT_MODE` khác `live`. App không tự quyết định sandbox: cờ do backend trả về trong đơn nạp.

Luồng: app tạo đơn → backend tạo đơn trên ZaloPay → **app mở thẳng app ZaloPay sandbox** (app-to-app) → trả trong app ZaloPay → quay lại ReStore → backend hỏi ZaloPay và cộng Xu.

> Trang web thanh toán của ZaloPay sandbox hiện đang lỗi ("Hệ thống đang có lỗi", mã -79) với app test 2554, nên **phải trả bằng app ZaloPay sandbox trên điện thoại Android thật**. Emulator thì dùng nút thanh toán tạm.

## 1. Backend

Trong `backend/.env` (chép từ `.env.example` nếu chưa có):

```env
PAYMENT_MODE="sandbox"
PAYMENT_SKIP_GATEWAY=""
ZALOPAY_APP_ID="2554"
ZALOPAY_KEY1="sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn"
ZALOPAY_KEY2="trMrHtvjo6myautxDUiAcYsVtaeQ8nhf"
ZALOPAY_ENDPOINT=""
ZALOPAY_METHODS=""
PUBLIC_API_URL=""
ZALOPAY_REDIRECT_URL=""
```

Đây là khoá thử công khai của ZaloPay, chỉ để ở backend. **Không commit file `.env`** (đã có `.gitignore` chặn).

Database là Supabase thật: chỉ chạy `migrate deploy`, không bao giờ `migrate dev`.

```bash
cd backend
npx prisma migrate deploy
npm run dev
```

Sửa `.env` xong phải **dừng hẳn backend (Ctrl+C) rồi chạy lại**, backend không tự đọc lại `.env`.

## 2. Điện thoại Android thật

1. Bật **Tuỳ chọn nhà phát triển → Gỡ lỗi USB**, cắm cáp, bấm **Cho phép** khi máy hỏi.
2. **Tắt "Chia sẻ kết nối qua USB"** (Cài đặt → Kết nối → Chia sẻ kết nối). Nếu bật, máy tính sẽ vào mạng qua 4G của điện thoại và backend hay mất kết nối database.
3. Cài **app ZaloPay sandbox** từ trang <https://docs.zalopay.vn/docs/developer-tools/test-instructions/test-wallets/> (bản Android).
4. Tạo tài khoản trong app sandbox (đã làm thành công ngày 17/11/2026). **Mọi mã OTP trong app sandbox đều là `111111`** (đăng ký, liên kết ngân hàng, nạp tiền, thanh toán).
   - Đăng nhập bằng số điện thoại, mã xác minh `111111`, đặt mật khẩu. Cần có tài khoản **Zalo** với số điện thoại này.
   - App bắt **xác minh danh tính bằng CMND/CCCD thật** (quét giấy tờ). Đây là yêu cầu của ZaloPay sandbox, không phải của ReStore. Mỗi người tự cân nhắc trước khi đưa giấy tờ vào app.
   - **Liên kết ngân hàng ảo Eximbank:** chọn Eximbank, số tài khoản là `10054695469` **ghép thêm 4 số cuối CCCD của chính bạn** (ví dụ CCCD đuôi `1234` thì nhập `100546954691234`).
   - **Nạp tiền thử vào ví:** mở trang tài liệu ZaloPay sandbox (trang tải app ở bước 3), **kéo xuống cuối trang**, nhập **số điện thoại đã đăng ký ví sandbox** rồi bấm **Submit**. Ví tự động được cộng **5 triệu đồng tiền ảo**.

## 3. Chạy app Flutter

Trong `frontend/env/dev.json` (chép từ `env/env.example.json`):

```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": "http://localhost:3000/api/v1",
  "USE_MOCK_DATA": false,
  "ENABLE_ADMIN_PREVIEW": false,
  "DEV_PLAN_SWITCH": false
}
```

Cho điện thoại gọi backend trên máy tính qua cáp USB (chạy lại mỗi lần cắm cáp):

```bash
adb reverse tcp:3000 tcp:3000
```

Chạy app (VS Code: cấu hình **"ReStore (dev)"**):

```bash
cd frontend
flutter run --dart-define-from-file=env/dev.json
```

Có sửa code Android hay file env thì **Stop hẳn rồi chạy lại**, hot reload không đủ.

> Không cắm cáp được thì dùng Wi-Fi: điện thoại và máy tính chung mạng, `API_BASE_URL` là `http://<IP-LAN-máy-tính>:3000/api/v1` (xem bằng `ipconfig`), cho Node.js qua tường lửa.

## 4. Thử nạp Xu

1. Đăng nhập app → **Ví Xu → Nạp xu** → chọn gói → **ZaloPay** → tick đồng ý → **Thanh toán**.
2. App tự mở app ZaloPay sandbox với đúng đơn và số tiền. Chọn ví hoặc ngân hàng ảo → **Xác nhận**.
3. Trả xong, **tự quay lại ReStore** (app ZaloPay sandbox không tự chuyển về). App hỏi đơn ngay và Xu được cộng sau vài giây.

Máy chưa cài app ZaloPay thì app báo và cho chọn trang web (trang web sandbox hiện đang lỗi).

## Emulator / web / desktop

Không có app ZaloPay, nên app hiện dòng **"Chế độ thử (sandbox)"** và nút **"Đã trả tiền / Thất bại"** để giả lập kết quả. Trên điện thoại thật hai thứ này bị ẩn.

Muốn bỏ hẳn ZaloPay để test nhanh luồng cộng Xu: đặt `PAYMENT_SKIP_GATEWAY="true"` rồi chạy lại backend. Khi đó máy nào cũng hiện nút thanh toán tạm.

## Callback (không bắt buộc)

Bình thường Xu được cộng khi app hỏi đơn. Muốn ZaloPay báo thẳng cho backend (giống khi chạy thật), mở tunnel miễn phí trong một terminal riêng và **để nguyên cửa sổ**:

```bash
winget install Cloudflare.cloudflared
cloudflared tunnel --url http://localhost:3000
```

Điền địa chỉ `https://....trycloudflare.com` nó in ra vào `PUBLIC_API_URL`, rồi chạy lại backend. Mỗi lần chạy lại `cloudflared` địa chỉ sẽ đổi. ZaloPay sandbox gọi callback không đều, nên đừng dựa vào nó khi test.

## Lỗi hay gặp

| Hiện tượng | Cách xử lý |
| --- | --- |
| Màn trả tiền ghi "Đang bỏ qua cổng ZaloPay" | `.env` đang `PAYMENT_SKIP_GATEWAY="true"` hoặc thiếu khoá; sửa rồi **chạy lại backend** và tạo đơn mới |
| App không kết nối được máy chủ | Chưa chạy `adb reverse`, sai `API_BASE_URL`, hoặc sửa `dev.json` mà chưa Stop/chạy lại app |
| Log backend `Can't reach database server`, `Timed out fetching a new connection` | Mạng chập chờn: tắt chia sẻ kết nối USB / VPN, chạy lại backend. `DATABASE_URL` nên có `&connect_timeout=20&pool_timeout=20` |
| App ZaloPay bắt xác minh CCCD / chưa trả được | Phải xác minh danh tính, liên kết Eximbank ảo (`10054695469` + 4 số cuối CCCD) và nạp ví (mục 2) |
| Liên kết ngân hàng trong app ZaloPay đòi số tài khoản thật / số điện thoại đăng ký tại ngân hàng | Chọn sai ngân hàng: dùng **Eximbank** với số tài khoản ảo ở mục 2 |
| Trả xong app vẫn quay vòng chờ | Quay lại ReStore hoặc bấm "Kiểm tra lại"; đơn tự hết hạn sau 15 phút nếu chưa trả |
