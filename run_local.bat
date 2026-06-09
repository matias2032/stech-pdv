@echo off
title STech PDV — Launcher
echo ========================================
echo   STech PDV — Launcher
echo ========================================

echo.
echo [INFO] Iniciando Backend Spring Boot local...
:: Usando o caminho absoluto seguro da tua máquina
cd "C:\pdv-stech engenharia\pdv-backend"
start "BACKEND - SPRING BOOT" cmd /k "mvnw spring-boot:run"

echo.
echo [INFO] Aguardando o servidor Java inicializar...
timeout /t 15 /nobreak

echo.
echo [INFO] Iniciando Flutter Windows (LOCAL)...
:: Navegando até à pasta correta do teu frontend
cd "C:\pdv-stech engenharia\frontend\pdv_stech"
start "FLUTTER WINDOWS" cmd /c "flutter run -d windows"

echo.
echo ========================================
echo   Launch concluido com sucesso!
echo ========================================