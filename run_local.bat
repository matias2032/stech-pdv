@echo off
title STech PDV — Launcher
echo ========================================
echo   STech PDV — Launcher
echo ========================================

echo.
echo [INFO] Iniciando Backend Spring Boot...
cd "C:\pdv-stech engenharia\pdv-backend"
start "BACKEND - SPRING BOOT" cmd /k "mvnw spring-boot:run -Dspring-boot.run.arguments=--server.port=8081"

echo.
echo [INFO] Aguardando o servidor Java inicializar...
timeout /t 20 /nobreak

echo.
echo [INFO] Iniciando Flutter Windows...
cd "C:\pdv-stech engenharia\frontend\pdv_stech"
start "FLUTTER WINDOWS" cmd /c "flutter run -d windows -v --no-pub"

echo.
echo ========================================
echo   Launch concluido!
echo ========================================
pause