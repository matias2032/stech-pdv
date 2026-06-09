@echo off
title STech PDV — Launcher
echo ========================================
echo   STech PDV — Launcher
echo ========================================

echo.
echo [INFO] A verificar ligacao à internet...
ping -n 1 8.8.8.8 >nul 2>&1

if %errorlevel% == 0 (
    echo [INFO] Online — iniciando Backend Spring Boot...
    cd "C:\pdv-stech engenharia\pdv-backend"
    start "BACKEND - SPRING BOOT" cmd /k "mvnw spring-boot:run"

    echo.
    echo [INFO] Aguardando o servidor Java inicializar...
    timeout /t 15 /nobreak
) else (
    echo [AVISO] Offline — Backend nao sera iniciado.
    echo         A app Flutter usara apenas cache local.
    timeout /t 3 /nobreak
)

echo.
echo [INFO] Iniciando Flutter Windows...
cd "C:\pdv-stech engenharia\frontend\pdv_stech"
start "FLUTTER WINDOWS" cmd /c "flutter run -d windows --no-pub"

echo.
echo ========================================
echo   Launch concluido!
echo ========================================
pause