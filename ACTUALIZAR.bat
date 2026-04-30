@echo off
chcp 65001 >nul
echo ============================================
echo  HOTELVIP - Actualizacion del Sistema
echo  SistemasVIP - Cusco Peru
echo ============================================
echo.

cd /d "%~dp0"

:: Detener servidor si esta corriendo
echo Deteniendo servidor...
taskkill /IM HotelVip_Server.exe /F >nul 2>nul
timeout /t 3 /nobreak >nul

:: Backup del exe actual
if exist HotelVip_Server.exe (
    echo Respaldando version actual...
    copy /y HotelVip_Server.exe HotelVip_Server.exe.bak >nul
)

:: Actualizar desde GitHub
echo Descargando actualizacion...
git pull origin main

if errorlevel 1 (
    echo [ERROR] No se pudo actualizar. Verifique su conexion a internet.
    echo Restaurando version anterior...
    if exist HotelVip_Server.exe.bak (
        copy /y HotelVip_Server.exe.bak HotelVip_Server.exe >nul
    )
    pause
    exit /b 1
)

:: Ejecutar scripts SQL pendientes si existen
if exist "SQL\updates" (
    echo Verificando actualizaciones SQL...
    if not exist "SQL\updates\.last_update" (
        echo. > "SQL\updates\.last_update"
    )
    for %%f in (SQL\updates\*.sql) do (
        findstr /c:"%%~nxf" "SQL\updates\.last_update" >nul 2>nul
        if errorlevel 1 (
            echo Ejecutando: %%~nxf
            echo %%~nxf >> "SQL\updates\.last_update"
        )
    )
)

:: Limpiar backup
if exist HotelVip_Server.exe.bak del /q HotelVip_Server.exe.bak

echo.
echo ============================================
echo  Actualizacion completada!
echo  Iniciando servidor...
echo ============================================
echo.

:: Iniciar servidor
start "" "HotelVip_Server.exe"

timeout /t 3 /nobreak >nul
pause
