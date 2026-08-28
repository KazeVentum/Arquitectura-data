@echo off
REM Levanta el contenedor MySQL con docker compose y ejecuta los pasos del README:
REM crear tablas, cargar datos y verificar los conteos.
setlocal

set "SCRIPT_DIR=%~dp0"
set "DOCKER_DIR=%SCRIPT_DIR%docker"

echo ==^> Levantando contenedor MySQL...
pushd "%DOCKER_DIR%"
docker compose up -d
if errorlevel 1 goto :error

echo ==^> Esperando a que MySQL este listo...
:waitloop
docker compose exec -T mysql mysqladmin ping -h localhost -uroot -proot --silent >nul 2>&1
if errorlevel 1 (
  timeout /t 2 /nobreak >nul
  goto :waitloop
)
echo     MySQL listo.

echo ==^> Creando base de datos y tablas (01_crear_tablas.sql)...
docker compose exec -T -w /scripts mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4 -e "source 01_crear_tablas.sql;"
if errorlevel 1 goto :error

echo ==^> Cargando datos (02_cargar_datos.sql)...
docker compose exec -T -w /scripts mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4 -e "source 02_cargar_datos.sql;"
if errorlevel 1 goto :error

echo ==^> Verificacion:
docker compose exec -T mysql mysql -uroot -proot --default-character-set=utf8mb4 colombia -e "SELECT (SELECT COUNT(*) FROM Regiones) regiones, (SELECT COUNT(*) FROM Departamentos) departamentos, (SELECT COUNT(*) FROM Municipios) municipios;"

popd
echo ==^> Listo.
exit /b 0

:error
popd
echo Ocurrio un error ejecutando el script.
exit /b 1
