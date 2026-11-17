# Test nạp Xu qua ZaloPay sandbox trên điện thoại thật

Chỉ dùng môi trường sandbox của ZaloPay: không có tiền thật. Backend luôn gọi cổng sandbox (`sb-openapi.zalopay.vn`) khi `PAYMENT_MODE` khác `live`, kể cả khi `ZALOPAY_ENDPOINT` trỏ đi nơi khác. App không tự quyết định sandbox: cờ `payment.sandbox` của đơn nạp do backend trả về.

Thông tin test lấy từ tài liệu ZaloPay:
- App sandbox: https://docs.zalopay.vn/docs/developer-tools/test-instructions/test-wallets/
- Thẻ test: https://docs.zalopay.vn/docs/developer-tools/test-instructions/testing/

## 1. Backend

Trong `backend/.env` (chép từ `.env.example` nếu chưa có):

```env
PAYMENT_MODE="sandbox"
PAYMENT_SKIP_GATEWAY=""
ZALOPAY_APP_ID="2554"
ZALOPAY_KEY1="sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn"
ZALOPAY_KEY2="trMrHtvjo6myautxDUiAcYsVtaeQ8nhf"
ZALOPAY_ENDPOINT=""
# Để trống = thẻ ATM nội địa, dễ test nhất trên điện thoại. "all" để ZaloPay tự chọn (có thể đòi app ZaloPay)
ZALOPAY_METHODS=""
```

Khoá trên là khoá thử công khai của ZaloPay, chỉ nằm ở backend, không đưa vào app.

Database là Supabase thật: chỉ áp migration có sẵn, không dùng `migrate dev`.

```powershell
cd backend
npx prisma migrate deploy
npx prisma generate
npm run dev
```

## 2. Cho điện thoại gọi được backend

Điện thoại và máy tính phải chung Wi-Fi. Xem IP LAN của máy tính bằng `ipconfig` (dòng IPv4 của Wi-Fi, VD `192.168.1.2`; bỏ qua IP `26.x` của Radmin VPN).

1. Lần đầu chạy `npm run dev`, Windows hỏi tường lửa: cho phép Node.js trên mạng **Private**.
2. Trên điện thoại mở trình duyệt, vào `http://192.168.1.2:3000/api/v1/credits/packages`. Thấy JSON danh sách gói là được.

### Trang quay về sau khi trả

Sau khi trả, ZaloPay chuyển trình duyệt điện thoại về `ZALOPAY_REDIRECT_URL`. Mặc định là `localhost`, điện thoại không mở được, nên điền IP LAN:

```env
ZALOPAY_REDIRECT_URL="http://192.168.1.2:3000/api/v1/payments/zalopay/return"
```

### Callback (không bắt buộc)

ZaloPay chỉ gọi callback tới địa chỉ public. Không có cũng được: mỗi lần app hỏi đơn (5 giây một lần, và ngay khi quay lại app), backend tự hỏi ZaloPay rồi cộng Xu.

Muốn thử cả callback, dùng Cloudflare Quick Tunnel (miễn phí, không cần tài khoản):

```powershell
winget install Cloudflare.cloudflared
cloudflared tunnel --url http://localhost:3000
```

Lệnh in ra địa chỉ dạng `https://abc-xyz.trycloudflare.com`. Điền vào `.env` rồi khởi động lại backend:

```env
PUBLIC_API_URL="https://abc-xyz.trycloudflare.com"
ZALOPAY_REDIRECT_URL=""
```

Địa chỉ này đổi mỗi lần chạy lại `cloudflared`. Khi có `PUBLIC_API_URL`, trang quay về cũng dùng địa chỉ này nên để trống `ZALOPAY_REDIRECT_URL`.

## 3. App Flutter

Trong `frontend/env/dev.json`:

```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": "http://192.168.1.2:3000/api/v1",
  "USE_MOCK_DATA": false,
  "ENABLE_ADMIN_PREVIEW": false,
  "DEV_PLAN_SWITCH": false
}
```

Giá trị trong file env được build vào app: sửa `dev.json` xong phải Stop rồi chạy lại, hot reload/restart không đổi được.

Không muốn phụ thuộc Wi-Fi (Android cắm cáp): chạy `adb reverse tcp:3000 tcp:3000` (chạy lại mỗi lần cắm cáp) và đặt `API_BASE_URL` là `http://localhost:3000/api/v1`. Khi đó trang quay về mặc định `localhost` cũng mở được, không cần `ZALOPAY_REDIRECT_URL`.

- **Android:** bật Tuỳ chọn nhà phát triển → Gỡ lỗi USB, cắm cáp, chạy `flutter devices` rồi `flutter run -d <id> --dart-define-from-file=env/dev.json`. Bản debug cho phép gọi `http://`.
- **iPhone:** iOS chặn `http://`, nên dùng địa chỉ tunnel `https://...trycloudflare.com/api/v1` cho `API_BASE_URL`. Cần máy Mac và Xcode để cài app.

## 4. Cài app ZaloPay sandbox (nếu muốn trả bằng ví)

Mở trang test-wallets ở trên bằng điện thoại:
- **Android:** tải APK sandbox ở trang đó và cài (cho phép cài từ nguồn không xác định).
- **iPhone:** bấm cài, sau đó vào Cài đặt → Cài đặt chung → Quản lý thiết bị để tin cậy app.

Đăng ký: nhập số điện thoại, mã xác minh là `111111`, rồi đặt mật khẩu. Một số điện thoại chỉ gắn được một tài khoản sandbox. Ví sandbox phải được nạp tiền thử trước khi trả.

Không muốn cài app thì trả bằng thẻ ATM test ngay trên trang web của ZaloPay (bước 5).

## 5. Thử nạp Xu

1. Đăng nhập app, vào Ví Xu → Nạp xu, chọn gói, chọn ZaloPay, tick đồng ý, bấm Thanh toán.
2. Ở bước trả tiền thấy dòng "Chế độ thử (sandbox): không trừ tiền thật." là backend đang ở sandbox.
3. Bấm "Mở trang thanh toán ZaloPay": trình duyệt mở trang cổng sandbox.
4. Chọn thẻ ATM, nhập thẻ test (ngân hàng thử, tên `NGUYEN VAN A`, ngày phát hành `10/18`):

   | Kết quả | Số thẻ |
   | --- | --- |
   | Thành công | `9704540000000062` |
   | Thẻ bị mất | `9704540000000013` |
   | Hết thời gian | `9704540000000039` |
   | Không đủ tiền | `9704540000000047` |

   Thẻ quốc tế test: `4111111111111111`, tên `NGUYEN VAN A`, hạn `01/25`, CVV `123`.
   Hoặc chọn ví ZaloPay để mở app sandbox ở bước 4.
5. Trả xong quay lại app ReStore: app hỏi đơn ngay, đơn thành công thì Xu được cộng.

Nút "Đã trả tiền" / "Thất bại" ở bước trả tiền là nút giả lập của backend (chỉ có khi sandbox), dùng khi không muốn qua trang ZaloPay.

## Lỗi hay gặp

- **Điện thoại không vào được backend:** kiểm tra chung Wi-Fi, tường lửa, đúng IP; Wi-Fi công cộng hay chặn máy trong mạng nói chuyện với nhau.
- **"Đang bỏ qua cổng ZaloPay":** backend thiếu `ZALOPAY_APP_ID`/khoá, hoặc `PAYMENT_SKIP_GATEWAY="true"`.
- **Trả xong mà đơn vẫn chờ:** bấm "Kiểm tra lại"; xem log backend có `[credits] ZaloPay query failed` không.
- **Lỗi migration / thiếu cột `providerRef`:** chạy `npx prisma migrate deploy`.
