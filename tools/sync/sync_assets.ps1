# Đồng bộ tài nguyên từ AnPhong\public\assets sang AnPhong-App\assets.
# Chạy từ thư mục bất kỳ:
#   powershell -ExecutionPolicy Bypass -File D:\Source\AnPhong-App\tools\sync\sync_assets.ps1
# Chạy thử vài file mẫu (không copy 59MB):
#   powershell -ExecutionPolicy Bypass -File ...\sync_assets.ps1 -Sample
# Tham số:
#   -DryRun   chỉ liệt kê, không ghi
#   -Sample   chỉ copy CREDITS.txt + vài PNG trong bg\bch1
#   -Force    ghi đè file đã có (mặc định bỏ qua file có sẵn)

param(
  [switch]$DryRun,
  [switch]$Sample,
  [switch]$Force
)

$src = 'D:\Source\AnPhong\public\assets'
$dst = 'D:\Source\AnPhong-App\assets'
if (-not (Test-Path $src)) { Write-Error "Không tìm thấy $src"; exit 1 }
if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }

if ($Sample) {
  # Mẫu nhỏ: 1 file text + 4 PNG đầu của bg\bch1 (~0.4MB)
  $files = @((Join-Path $src 'CREDITS.txt')) + @(Get-ChildItem (Join-Path $src 'bg\bch1') -Filter '*.png' -File | Select-Object -First 4 | ForEach-Object { $_.FullName })
} else {
  $files = @(Get-ChildItem $src -Recurse -File | ForEach-Object { $_.FullName })
}

$copied = 0
$skipped = 0
$bytes = 0
foreach ($f in $files) {
  $rel = $f.Substring($src.Length).TrimStart('\', '/')
  $target = Join-Path $dst $rel
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  if ((Test-Path $target) -and -not $Force) { $skipped++; continue }
  $len = (Get-Item $f).Length
  if (-not $DryRun) { Copy-Item $f $target -Force }
  $copied++
  $bytes += $len
  if ($DryRun -or $copied -le 10) { Write-Output ("{0}: {1} ({2:N0} bytes)" -f $(if ($DryRun) { 'SẼ COPY' } else { 'COPY' }), $rel, $len) }
}
Write-Output ("Tổng: {0} file, bỏ qua {1}, {2:N1} MB{3}" -f $copied, $skipped, ($bytes / 1MB), $(if ($DryRun) { ' (chỉ thử)' } else { '' }))
