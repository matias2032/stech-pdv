@echo off
title STech PDV — Launcher
echo ========================================
echo   STech PDV — Launcher
echo ========================================
echo.
echo  [1] ONLINE    — Backend local + Flutter (baseline)
echo  [2] OFFLINE   — So Flutter, sem backend (testa full-offline)
echo  [3] CLOUD     — Flutter apontado para Render
echo.
set /p OPCAO="Escolha (1/2/3): "

if "%OPCAO%"=="1" (
    echo.
    echo [INFO] Iniciando Backend Spring Boot local...
    cd "C:\pdv-stech engenharia\pdv-backend"
    start "BACKEND" cmd /k "mvnw spring-boot:run"

    echo [INFO] Aguardando 15s...
    timeout /t 15 /nobreak

    echo [INFO] Iniciando Flutter...
    cd "C:\pdv-stech engenharia\frontend\pdv_stech"
    start "FLUTTER" cmd /k "flutter run -d windows"
    goto FIM
)

if "%OPCAO%"=="2" (
    echo.
    echo [AVISO] Nenhum backend sera iniciado.
    echo         A app deve usar cache local e mostrar badge vermelho.
    cd "C:\pdv-stech engenharia\frontend\pdv_stech"
    start "FLUTTER (OFFLINE)" cmd /k "flutter run -d windows"
    goto FIM
)

if "%OPCAO%"=="3" (
    echo.
    cd "C:\pdv-stech engenharia\frontend\pdv_stech"
    start "FLUTTER (CLOUD)" cmd /k "flutter run -d windows --dart-define=API_BASE_URL=https://stech-pdv.onrender.com --dart-define=FORCE_PROD=true"
    goto FIM
)

echo [ERRO] Opcao invalida.

:FIM
echo.
pause