@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title HotelVIP - Instalacion
color 0B

REM ============================================================
REM  HOTELVIP - Instalacion inicial en la PC del hotel
REM  SistemasVIP - Cusco, Peru
REM
REM  Crea la base de datos, aplica TODO el schema (01-04 + las
REM  migraciones de SQL\updates), deja configurado el .ini y
REM  opcionalmente hace que el sistema arranque solo con Windows.
REM ============================================================

cd /d "%~dp0"

echo ============================================================
echo   HOTELVIP - INSTALACION
echo   SistemasVIP - Cusco Peru
echo ============================================================
echo.
echo  Requisitos: MariaDB 10.6+ instalado y corriendo.
echo.

REM ── Buscar el cliente de MariaDB ──
set "MYSQL="
where mysql >nul 2>&1 && set "MYSQL=mysql"
if not defined MYSQL (
    for /d %%D in ("C:\Program Files\MariaDB*") do (
        if exist "%%D\bin\mysql.exe" set "MYSQL=%%D\bin\mysql.exe"
    )
)
if not defined MYSQL (
    color 0C
    echo  [ERROR] No se encontro MariaDB en esta PC.
    echo  Instalelo desde https://mariadb.org/download/ y vuelva a ejecutar.
    pause
    exit /b 1
)
echo  MariaDB encontrado: %MYSQL%
echo.

set /p CONFIRMAR="Continuar con la instalacion? (S/N): "
if /i not "%CONFIRMAR%"=="S" (
    echo Instalacion cancelada.
    pause
    exit /b 0
)

REM ── Datos de conexion ──
echo.
echo === Base de datos ===
set /p DB_HOST="Servidor (Enter = 127.0.0.1): "
if "%DB_HOST%"=="" set DB_HOST=127.0.0.1
set /p DB_PORT="Puerto (Enter = 3306): "
if "%DB_PORT%"=="" set DB_PORT=3306
set /p DB_ADMIN="Usuario administrador de MariaDB (Enter = root): "
if "%DB_ADMIN%"=="" set DB_ADMIN=root
set /p DB_ADMPASS="Clave de ese usuario: "
set /p DB_NAME="Nombre de la base a crear (ej: hotelvip_andinapardo): "
if "%DB_NAME%"=="" (
    color 0C
    echo  [ERROR] El nombre de la base es obligatorio.
    pause
    exit /b 1
)

echo.
echo === Puerto del sistema ===
set /p API_PORT="Puerto de HotelVIP (Enter = 9006): "
if "%API_PORT%"=="" set API_PORT=9006

REM MYSQL_PWD evita que la clave quede en la linea de comandos
set "MYSQL_PWD=%DB_ADMPASS%"

echo.
echo [1/7] Creando base de datos %DB_NAME%...
"%MYSQL%" -h %DB_HOST% -P %DB_PORT% -u %DB_ADMIN% --skip-ssl -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;"
if errorlevel 1 (
    color 0C
    echo  [ERROR] No se pudo crear la base. Revise usuario, clave y que MariaDB este corriendo.
    set "MYSQL_PWD="
    pause
    exit /b 1
)
echo    OK

REM Permisos para el respaldo automatico. mysqldump ejecuta 'show events' y
REM 'show create procedure', que un usuario de aplicacion normal NO puede.
REM Sin esto el respaldo falla en silencio y el hotel se queda sin copias.
REM Con root no hace falta, pero no molesta.
if /i not "%DB_ADMIN%"=="root" (
    "%MYSQL%" -h %DB_HOST% -P %DB_PORT% -u %DB_ADMIN% --skip-ssl -e "GRANT EVENT, TRIGGER, SHOW CREATE ROUTINE ON *.* TO '%DB_ADMIN%'@'localhost'; FLUSH PRIVILEGES;" 2>nul
    if not errorlevel 1 echo    Permisos de respaldo verificados
)

echo.
echo [2/7] Aplicando estructura...
for %%F in (01_Estructura.sql 02_Vistas.sql 03_StoredProcedures.sql 04_DatosIniciales.sql) do (
    if exist "SQL\%%F" (
        echo    - %%F
        "%MYSQL%" -h %DB_HOST% -P %DB_PORT% -u %DB_ADMIN% --skip-ssl %DB_NAME% < "SQL\%%F"
        if errorlevel 1 (
            color 0C
            echo  [ERROR] Fallo %%F. Instalacion incompleta.
            set "MYSQL_PWD="
            pause
            exit /b 1
        )
    )
)
echo    OK

echo.
echo [3/7] Aplicando actualizaciones de base...
if not exist "SQL\updates" mkdir "SQL\updates" >nul 2>nul
if exist "SQL\updates\.last_update" del /q "SQL\updates\.last_update"
for %%F in (SQL\updates\*.sql) do (
    echo    - %%~nxF
    "%MYSQL%" -h %DB_HOST% -P %DB_PORT% -u %DB_ADMIN% --skip-ssl %DB_NAME% < "%%F"
    if errorlevel 1 (
        color 0C
        echo  [ERROR] Fallo la actualizacion %%~nxF.
        set "MYSQL_PWD="
        pause
        exit /b 1
    )
    REM Solo se marca si se aplico BIEN
    echo %%~nxF>> "SQL\updates\.last_update"
)
set "MYSQL_PWD="
echo    OK

echo.
echo [4/7] Configurando HotelVip_Server.ini...
if not exist "HotelVip_Server.ini" (
    if exist "HotelVip_Server.ini.ejemplo" copy /y "HotelVip_Server.ini.ejemplo" "HotelVip_Server.ini" >nul
)
REM Clave de firma unica para esta instalacion (que no sea la de fabrica)
for /f %%K in ('powershell -NoProfile -Command "-join ((48..57)+(65..90)+(97..122) ^| Get-Random -Count 40 ^| %%{[char]$_})"') do set "SECRET=%%K"

powershell -NoProfile -Command ^
  "$p='HotelVip_Server.ini'; $t=Get-Content $p -Raw;" ^
  "$t=$t -replace '(?m)^Servidor=.*',   'Servidor=%DB_HOST%';" ^
  "$t=$t -replace '(?m)^BaseDatos=.*',  'BaseDatos=%DB_NAME%';" ^
  "$t=$t -replace '(?m)^Usuario=.*',    'Usuario=%DB_ADMIN%';" ^
  "$t=$t -replace '(?m)^Clave=.*',      'Clave=%DB_ADMPASS%';" ^
  "$t=$t -replace '(?m)^SecretKey=.*',  'SecretKey=%SECRET%';" ^
  "$t=$t -replace '(?m)^Puerto=9006',   'Puerto=%API_PORT%';" ^
  "Set-Content $p $t -Encoding UTF8"
echo    OK

echo.
echo [5/7] Conexion con las reservas web (opcional)
echo    Si este hotel tiene pagina web con motor de reservas, ingrese su
echo    token de enlace (lo entrega SistemasVIP). Enter para omitir.
set "SYNC_TOKEN="
set /p SYNC_TOKEN="Token de reservas web: "
if not "%SYNC_TOKEN%"=="" (
    set /p SYNC_NOM="Nombre de esta instancia (ej: AndinaPardo): "
    powershell -NoProfile -Command ^
      "$p='HotelVip_Server.ini'; $t=Get-Content $p -Raw;" ^
      "$t=$t -replace '(?m)^Habilitado=0',   'Habilitado=1';" ^
      "$t=$t -replace '(?m)^Token=\r?$',     'Token=%SYNC_TOKEN%';" ^
      "$t=$t -replace '(?m)^InstanciaNom=.*','InstanciaNom=%SYNC_NOM%';" ^
      "Set-Content $p $t -Encoding UTF8"
    echo    OK - las reservas de la web bajaran a esta recepcion
) else (
    echo    Omitido - se puede activar despues en el archivo de configuracion
)

echo.
echo [6/7] Copia de seguridad fuera de esta computadora
echo    El sistema guarda una copia de la informacion todos los dias.
echo    Conviene que ademas quede una copia FUERA de esta PC, por si el
echo    disco falla o la roban. Lo mas practico: una carpeta de Google
echo    Drive o OneDrive de este equipo, que sube sola a la nube.
echo.
echo    Ejemplo: C:\Users\%USERNAME%\Google Drive\Respaldos HotelVIP
echo    Enter para omitir (se puede configurar despues).
set "BK_EXT="
set /p BK_EXT="Carpeta para la copia externa: "
if not "%BK_EXT%"=="" (
    if not exist "%BK_EXT%" mkdir "%BK_EXT%" 2>nul
    powershell -NoProfile -Command ^
      "$p='HotelVip_Server.ini'; $t=Get-Content $p -Raw;" ^
      "$t=$t -replace '(?m)^BackupExterno=.*','BackupExterno=%BK_EXT%';" ^
      "Set-Content $p $t -Encoding UTF8"
    echo    OK - cada respaldo se copiara tambien a esa carpeta
) else (
    echo    Omitido - la copia quedara solo en esta PC
)

echo.
echo [7/7] Inicio automatico con Windows
set /p AUTORUN="Que HotelVIP arranque solo al prender la PC? (S/N): "
if /i "%AUTORUN%"=="S" (
    powershell -NoProfile -Command ^
      "$a=New-ScheduledTaskAction -Execute '%~dp0HotelVip_Server.exe' -WorkingDirectory '%~dp0';" ^
      "$t=New-ScheduledTaskTrigger -AtLogOn;" ^
      "$s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero);" ^
      "Register-ScheduledTask -TaskName 'HotelVIP_%DB_NAME%' -Action $a -Trigger $t -Settings $s -Force | Out-Null" 2>nul
    if errorlevel 1 (
        echo    No se pudo crear la tarea. Ejecute este instalador como Administrador.
    ) else (
        echo    OK - arrancara solo al iniciar sesion
    )
) else (
    echo    Omitido
)

color 0A
echo.
echo ============================================================
echo   INSTALACION COMPLETADA
echo ============================================================
echo   Base de datos : %DB_NAME%
echo   Servidor      : %DB_HOST%:%DB_PORT%
echo   Puerto sistema: %API_PORT%
echo.
echo   Para entrar:  http://localhost:%API_PORT%/app/login.html
echo   Usuario: admin   Clave: Admin123
echo.
echo   IMPORTANTE: cambie la clave de admin al primer ingreso,
echo   desde Administracion ^> Usuarios.
echo ============================================================
echo.
set /p INICIAR="Iniciar HotelVIP ahora? (S/N): "
if /i "%INICIAR%"=="S" start "" "HotelVip_Server.exe"
pause
