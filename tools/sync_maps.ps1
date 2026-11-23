# Đồng bộ bản đồ: mỗi map một file, copy từ AnPhong\shared\maps sang AnPhong-App\data\maps.
#   powershell -ExecutionPolicy Bypass -File D:\Source\AnPhong-App\tools\sync_maps.ps1
$src = 'D:\Source\AnPhong\shared\maps'
$dst = 'D:\Source\AnPhong-App\data\maps'
if (-not (Test-Path $src)) { Write-Error "Không tìm thấy $src"; exit 1 }
New-Item -ItemType Directory -Path $dst -Force | Out-Null
$n = 0
Get-ChildItem $src -Filter *.txt | ForEach-Object { Copy-Item $_.FullName (Join-Path $dst $_.Name) -Force; $n++ }
Write-Host "Đã đồng bộ $n bản đồ -> $dst"
