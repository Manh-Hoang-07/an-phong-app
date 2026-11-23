# Build iOS trên GitHub (không cần Mac)

Workflow: `.github/workflows/ios.yml` (chạy trên máy macOS của GitHub).

## Bước 0 — chạy thử, không cần tài khoản Apple
GitHub → tab **Actions** → **iOS build** → **Run workflow** (để `sign` tắt).
Việc này xuất dự án Xcode và biên dịch thử cho iPhone. Xanh = project hợp lệ; chưa tạo `.ipa` cài được.

## Cài lên iPhone thật: bắt buộc có Apple Developer Program (99 USD/năm)
Không có tài khoản trả phí thì không ký được `.ipa` trên CI (tài khoản miễn phí chỉ ký trong Xcode trên Mac).

### 1. Đăng ký App ID
developer.apple.com → Certificates, IDs & Profiles → Identifiers → App IDs → Bundle ID, ví dụ `com.anphong.app`.
Đặt cùng giá trị trong GitHub: Settings → Secrets and variables → Actions → **Variables** → `IOS_BUNDLE_ID`.

### 2. Chứng chỉ phân phối (làm được trên Windows bằng OpenSSL)
```powershell
openssl genrsa -out ios.key 2048
openssl req -new -key ios.key -out ios.csr -subj "/emailAddress=EMAIL_CUA_BAN/CN=Ten Ban/C=VN"
```
Upload `ios.csr` ở Certificates → "Apple Distribution" → tải `distribution.cer`, rồi:
```powershell
openssl x509 -inform DER -in distribution.cer -out distribution.pem
openssl pkcs12 -export -inkey ios.key -in distribution.pem -out cert.p12 -password pass:MAT_KHAU_P12
```

### 3. Provisioning profile
Profiles → New → **App Store** (để đưa lên TestFlight) hoặc **Ad Hoc** (cần đăng ký UDID iPhone) → chọn App ID + chứng chỉ → tải `.mobileprovision`.

### 4. API key để tự đẩy lên TestFlight (tùy chọn)
App Store Connect → Users and Access → Integrations → Keys → tạo key (role App Manager), tải `AuthKey_XXXX.p8`, ghi lại Key ID và Issuer ID.
Cũng cần tạo app trong App Store Connect (My Apps → New App) với đúng Bundle ID.

### 5. Nạp secrets vào GitHub (Settings → Secrets and variables → Actions → Secrets)
Mã hóa base64 trên Windows:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12")) | Set-Clipboard
```
| Secret | Giá trị |
|---|---|
| `IOS_TEAM_ID` | Team ID (developer.apple.com → Membership) |
| `IOS_CERT_P12_BASE64` | base64 của `cert.p12` |
| `IOS_CERT_PASSWORD` | mật khẩu đã đặt khi xuất p12 |
| `IOS_PROFILE_BASE64` | base64 của `.mobileprovision` |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` | (tùy chọn) để lên TestFlight |

Variable `IOS_EXPORT_METHOD`: `app-store` (mặc định) | `ad-hoc` | `development` — phải khớp loại profile.

### 6. Chạy
Actions → iOS build → Run workflow → bật **sign**. Kết quả: `.ipa` ở mục Artifacts, và/hoặc build xuất hiện trên TestFlight.
Cài qua TestFlight: tải app TestFlight trên iPhone, thêm email vào nhóm tester.

## Lưu ý
- Không bao giờ commit `ios.key`, `cert.p12`, `.mobileprovision`, `.p8` (chỉ để trong Secrets).
- Nếu bước "Xuất dự án Xcode" báo thiếu template: kiểm tra `GODOT_VERSION` trong workflow có khớp bản Godot đã dùng để phát triển (hiện 4.7.2).
- Icon app đang là icon mặc định; thêm icon ở preset iOS (Options → Icons) trước khi gửi App Store.
