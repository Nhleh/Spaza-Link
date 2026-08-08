@echo off
REM ============================================================
REM  SpazaLink Admin Dashboard - local launcher
REM  Double-click this file to open the admin dashboard.
REM  It serves the already-built web app and opens your browser.
REM  Close this window to stop the server.
REM ============================================================
title SpazaLink Admin Dashboard
cd /d "%~dp0build\web"

if not exist "index.html" (
  echo.
  echo   Could not find the built admin app in:
  echo   %~dp0build\web
  echo   Ask to rebuild it with:  flutter build web --profile -t lib/main_dev.dart
  echo.
  pause
  exit /b 1
)

echo.
echo   SpazaLink Admin is starting at:  http://127.0.0.1:8097
echo   Login:  admin@spazalink.com  /  Admin1234
echo   (Keep this window open. Close it to stop the server.)
echo.

start "" "http://127.0.0.1:8097"
python -m http.server 8097 --bind 127.0.0.1
