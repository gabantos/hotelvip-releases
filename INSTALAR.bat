@echo off
chcp 65001 >nul
echo ============================================
echo  HOTELVIP - Instalacion Inicial
echo  SistemasVIP - Cusco Peru
echo ============================================
echo.

cd /d "%~dp0"

echo REQUISITOS:
echo  - MariaDB 10.6+ instalado y corriendo
echo  - Puerto 3306 disponible
echo  - Puerto 9006 disponible
echo.

set /p CONFIRMAR="Continuar con la instalacion? (S/N): "
if /i not "%CONFIRMAR%"=="S" (
    echo Instalacion cancelada.
    pause
    exit /b 0
)

:: Datos de conexion BD
echo.
echo === Configuracion de Base de Datos ===
set /p DB_HOST="Servidor MariaDB (default: 127.0.0.1): "
if "%DB_HOST%"=="" set DB_HOST=127.0.0.1

set /p DB_PORT="Puerto (default: 3306): "
if "%DB_PORT%"=="" set DB_PORT=3306

set /p DB_USER="Usuario (default: root): "
if "%DB_USER%"=="" set DB_USER=root

set /p DB_PASS="Clave: "

set /p DB_NAME="Nombre BD (default: hotel_001): "
if "%DB_NAME%"=="" set DB_NAME=hotel_001

:: Crear base de datos
echo.
echo Creando base de datos %DB_NAME%...
mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;"

if errorlevel 1 (
    echo [ERROR] No se pudo crear la base de datos.
    echo Verifique los datos de conexion y que MariaDB este corriendo.
    pause
    exit /b 1
)

:: Ejecutar scripts SQL de estructura
if exist "SQL\01_Estructura.sql" (
    echo Creando estructura de tablas...
    mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "SQL\01_Estructura.sql"
)

if exist "SQL\02_Vistas.sql" (
    echo Creando vistas...
    mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "SQL\02_Vistas.sql"
)

if exist "SQL\03_StoredProcedures.sql" (
    echo Creando stored procedures...
    mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "SQL\03_StoredProcedures.sql"
)

if exist "SQL\04_DatosIniciales.sql" (
    echo Insertando datos iniciales...
    mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "SQL\04_DatosIniciales.sql"
)

:: Actualizar INI con datos de conexion
echo.
echo Configurando HotelVip_Server.ini...
if exist HotelVip_Server.ini (
    powershell -Command "(Get-Content 'HotelVip_Server.ini') -replace 'Servidor=.*', 'Servidor=%DB_HOST%' -replace 'Puerto=3306', 'Puerto=%DB_PORT%' -replace 'BaseDatos=.*', 'BaseDatos=%DB_NAME%' -replace 'Usuario=root', 'Usuario=%DB_USER%' -replace 'Clave=', 'Clave=%DB_PASS%' | Set-Content 'HotelVip_Server.ini'"
)

echo.
echo ============================================
echo  Instalacion completada!
echo.
echo  Base de datos: %DB_NAME%
echo  Servidor: %DB_HOST%:%DB_PORT%
echo  API Puerto: 9006
echo.
echo  Ejecute HotelVip_Server.exe para iniciar.
echo  Acceda a: http://localhost:9006/app/login.html
echo ============================================
echo.
pause
