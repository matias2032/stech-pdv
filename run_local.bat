@echo off
title STech PDV — Flutter Launcher

echo ========================================
echo   STech PDV — Flutter
echo ========================================

echo.
echo [INFO] A iniciar Flutter Windows apontando para Render...
echo [INFO] Backend: https://stech-pdv.onrender.com
echo.

cd /d "C:\pdv-stech engenharia\frontend\pdv_stech"

flutter run -d windows -v --no-pub --dart-define=API_BASE_URL=https://stech-pdv.onrender.com

echo.
echo ========================================
echo   Flutter encerrado.
echo ========================================

pause