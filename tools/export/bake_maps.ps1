# Bake ảnh nền map -> assets/mapcache/*.png rồi nhập vào project (để game nạp tức thì khi vào map).
# Dùng:  .\tools\export\bake_maps.ps1            (mọi map)
#        .\tools\export\bake_maps.ps1 cong_do   (một vài map)
# Godot: đặt biến GODOT_EXE, mặc định dùng bản trong D:\Source\.godot-validate.
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Maps)
$godot = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { 'D:\Source\.godot-validate\Godot_v4.7.2-stable_win64.exe' }
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
& $godot --headless --path $root --script res://tools/export/bake_maps.gd -- @Maps
& $godot --headless --path $root --import
