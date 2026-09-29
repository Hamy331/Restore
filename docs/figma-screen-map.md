# ReStore Figma screen map

Nguồn thiết kế: `ReStore UI — v1`, node gốc `85:590`.

| Page node | Frame đã đọc | Ánh xạ Flutter | Trạng thái |
| --- | --- | --- | --- |
| `85:587` Authentication | `78:583` Welcome | `/welcome` | Đã dựng foundation |
| `85:587` Authentication | `78:618` Login | `/login` | Đã dựng, dùng LoginBloc hiện có |
| `85:587` Authentication | `78:653` Register | `/register` | Đã dựng đúng field Figma; username API được ánh xạ từ email |
| `85:587` Authentication | `79:583` Email verification | `/verify-email` | Đã dựng UI và OTP state |
| `85:587` Authentication | `79:620` Email verified | `/email-verified` | Đã dựng |
| `85:587` Authentication | `80:583` Forgot password | `/forgot-password` | Đã dựng UI flow |
| `85:587` Authentication | `80:607` Forgot password OTP | `/forgot-password/otp` | Đã dựng UI và OTP state |
| `85:587` Authentication | `80:644` Reset password | `/reset-password` | Đã dựng validation |
| `85:587` Authentication | `80:676` Password reset success | `/password-reset-success` | Đã dựng |
| `85:587` Authentication | `82:588` Auth states | Shared auth widgets | Feedback, field error và loading primitives |
| `35:2` Home & Discovery | `35:5` Home | `/home` | Đã dựng theo Figma, responsive mobile/tablet |
| `35:2` Home & Discovery | `35:12` Search / Product Listing | `/search` | Đã dựng filter/sort interaction cục bộ |
| `85:583` Product | `35:19` Product Detail | `/listings/:id` | Đã dựng; chỉ có Chat và Trả giá |
| `85:584` Chat & Offers | `35:33` Chat List | `/messages` | Đã dựng tabs và conversation list |
| `85:584` Chat & Offers | `35:40` Chat Conversation | `/messages/:id` | Đã dựng conversation UI và composer |
| `85:584` Chat & Offers | `54:186` Make Offer | Product Detail/Chat bottom sheet | Đã dựng interactive bottom sheet |
| `85:584` Chat & Offers | `54:285` Seller offer review | `/messages/:id/offer/seller-review` | Đã dựng UI state |
| `85:584` Chat & Offers | `54:383` Buyer counter-offer | `/messages/:id/offer/buyer-review` | Đã dựng UI state |
| `85:584` Chat & Offers | `54:483` Agreed price | `/messages/:id/offer/agreed` | Đã dựng; không tạo order/payment |
| `85:585` Selling | `35:26` Create Listing Step 1 | `/create-listing` | Đã dựng interactive step 1 |
| `85:585` Selling | `60:358` Create Listing Step 2 | `/create-listing` | Đã dựng interactive step 2 |
| `85:585` Selling | `60:423` Listing Preview | `/create-listing/preview` | Đã dựng preview |
| `85:585` Selling | `61:369` My Listings | `/manage-listings` | Đã dựng trạng thái đang hiển thị |
| `85:585` Selling | `63:458` Pending | `/manage-listings` | Đã dựng tab chờ duyệt |
| `85:585` Selling | `63:507` Hidden | `/manage-listings` | Đã dựng tab đã ẩn |
| `85:585` Selling | `62:420` Sold | `/manage-listings` | Đã dựng tab đã bán |
| `85:585` Selling | `62:374` Mark as Sold | Manage Listings bottom sheet | Đã dựng; chỉ đổi availability |
| `4:4` Buttons | `90:22` Button variants | `AppButton` | Primary, secondary, text, loading, disabled |
| `4:6` Search | `91:92` Search states | `AppSearchField` | Default, focus, input |

## Token được trích xuất

- Colors: `#E9A529`, `#A65B00`, `#FFF1D6`, `#FFF9ED`, `#FAF9F6`, `#FFFFFF`, `#29231B`, `#70695F`, `#E9E4DB`, `#B91C1C`.
- Typography: Roboto hệ thống, 12–28 px, weight 400/600/700.
- Spacing: 4, 8, 12, 16, 20, 24 px.
- Radius: 4, 8, 10, 12, 16 và pill.
- Heights: button 48, search 42, bottom navigation 68 px.
- Shadow: rất nhẹ hoặc không dùng; ưu tiên border 1 px.

## Chưa triển khai

Các page trên hiện là UI foundation dùng presentation fixtures. Listing CRUD, Cloudinary upload, moderation, Socket.IO chat và price-offer persistence vẫn chờ API/data layer; không có fake repository hay checkout. Tài khoản vẫn là placeholder. UI xác minh email và khôi phục mật khẩu đã khớp Figma nhưng OTP/reset thật vẫn chờ backend.
