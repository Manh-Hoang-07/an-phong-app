@echo off
rem Mo game An Phong bang Godot. Nhap dup file nay de chay.
rem Neu Godot nam cho khac, dat bien GODOT_EXE truoc khi chay.
setlocal
if "%GODOT_EXE%"=="" set "GODOT_EXE=D:\Source\.godot-validate\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Khong thay Godot tai: %GODOT_EXE%
  echo Dat bien GODOT_EXE tro toi file Godot .exe roi chay lai.
  pause
  exit /b 1
)
start "" "%GODOT_EXE%" --path "%~dp0."
endlocal
