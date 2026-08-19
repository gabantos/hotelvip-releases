@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title HotelVIP - Actualizacion
color 0B

REM ============================================================
REM  HOTELVIP - Actualizacion del sistema
REM  SistemasVIP - Cusco, Peru
REM
REM  Baja la ultima version y aplica las actualizaciones de base
REM  que falten. Las credenciales las lee del HotelVip_Server.ini
REM  (no se piden ni se guardan en ningun lado).
REM
REM  OJO: la version anterior de este script MARCABA las
REM  actualizaciones SQL como aplicadas sin ejecutarlas nunca.
REM  Ahora se ejecutan de verdad y solo se marcan si salieron bien.
REM ============================================================

cd /d "%~dp0"

echo ============================================================
echo   HOTELVIP - ACTUALIZACION
echo ============================================================
echo.

REM ── 1. Cerrar el servidor ──
echo [1/4] Cerrando el sistema...
taskkill /IM HotelVip_Server.exe /F >nul 2>nul
timeout /t 3 /nobreak >nul
echo    OK

REM ── 2. Bajar la nueva version ──
echo.
echo [2/4] Descargando la ultima version...
where git >nul 2>&1
if errorlevel 1 (
    color 0C
    echo  [ERROR] Git no esta instalado. Descarguelo de https://git-scm.com/download/win
    pause
    exit /b 1
)
if exist HotelVip_Server.exe copy /y HotelVip_Server.exe HotelVip_Server.exe.bak >nul

git fetch origin main
if errorlevel 1 (
    color 0C
    echo  [ERROR] No se pudo conectar. Revise el internet.
    if exist HotelVip_Server.exe.bak copy /y HotelVip_Server.exe.bak HotelVip_Server.exe >nul
    pause
    exit /b 1
)
git reset --hard origin/main
if errorlevel 1 (
    color 0C
    echo  [ERROR] No se pudo actualizar los archivos.
    if exist HotelVip_Server.exe.bak copy /y HotelVip_Server.exe.bak HotelVip_Server.exe >nul
    pause
    exit /b 1
)
echo    OK

REM ── 3. Aplicar actualizaciones de base pendientes ──
echo.
echo [3/4] Actualizando la base de datos...

REM Credenciales desde el .ini (seccion [Database])
set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_NAME="
set "DB_USER=root"
set "DB_PASS="
for /f "usebackq tokens=1,* delims==" %%A in ("HotelVip_Server.ini") do (
    if /i "%%A"=="Servidor"  set "DB_HOST=%%B"
    if /i "%%A"=="BaseDatos" set "DB_NAME=%%B"
    if /i "%%A"=="Usuario"   set "DB_USER=%%B"
    if /i "%%A"=="Clave"     set "DB_PASS=%%B"
)

set "MYSQL="
where mysql >nul 2>&1 && set "MYSQL=mysql"
if not defined MYSQL (
    for /d %%D in ("C:\Program Files\MariaDB*") do (
        if exist "%%D\bin\mysql.exe" set "MYSQL=%%D\bin\mysql.exe"
    )
)

if not defined MYSQL (
    echo    [AVISO] No se encontro MariaDB; se omiten las actualizaciones de base.
    echo    Avise a SistemasVIP antes de seguir usando el sistema.
) else if not defined DB_NAME (
    echo    [AVISO] No se pudo leer la base desde el .ini; se omiten.
) else (
    if not exist "SQL\updates" mkdir "SQL\updates" >nul 2>nul
    if not exist "SQL\updates\.last_update" type nul > "SQL\updates\.last_update"
    set "MYSQL_PWD=!DB_PASS!"
    set "HUBO=0"
    for %%F in (SQL\updates\*.sql) do (
        findstr /x /c:"%%~nxF" "SQL\updates\.last_update" >nul 2>nul
        if errorlevel 1 (
            echo    - aplicando %%~nxF
            "!MYSQL!" -h !DB_HOST! -P !DB_PORT! -u !DB_USER! --skip-ssl !DB_NAME! < "%%F"
            if errorlevel 1 (
                color 0C
                echo    [ERROR] Fallo %%~nxF. NO se marca como aplicada.
                echo    Avise a SistemasVIP antes de usar el sistema.
                set "MYSQL_PWD="
                pause
                exit /b 1
            )
            REM Solo se marca si se aplico BIEN
            echo %%~nxF>> "SQL\updates\.last_update"
            set "HUBO=1"
        )
    )
    set "MYSQL_PWD="
    if "!HUBO!"=="0" (echo    Sin cambios pendientes) else (echo    OK)
)

REM ── 4. Reiniciar ──
if exist HotelVip_Server.exe.bak del /q HotelVip_Server.exe.bak
echo.
echo [4/4] Iniciando el sistema...
start "" "HotelVip_Server.exe"
timeout /t 3 /nobreak >nul

color 0A
echo.
echo ============================================================
echo   ACTUALIZACION COMPLETADA
echo   El sistema ya esta corriendo de nuevo.
echo ============================================================
echo.
pause
