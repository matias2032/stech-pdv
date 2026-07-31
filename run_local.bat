@echo off
title STech PDV — Flutter Launcher

echo ========================================
echo   STech PDV — Flutter
echo ========================================

echo.
echo [INFO] A iniciar Flutter Windows apontando para Coolify VPS...
echo [INFO] Backend: http://ggvpkjwr9ec71e14n8gyimtb.162.35.186.240.sslip.io
echo.

cd /d "C:\pdv-stech engenharia\frontend\pdv_stech"

flutter run -d windows -v --no-pub --dart-define=API_BASE_URL=http://ggvpkjwr9ec71e14n8gyimtb.162.35.186.240.sslip.io

echo.
echo ========================================
echo   Flutter encerrado.
echo ========================================

pause