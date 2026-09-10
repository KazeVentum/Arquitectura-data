@echo off
REM Levanta el contenedor MySQL con docker compose y ejecuta los pasos del README
REM (crear tablas, cargar datos y verificar los conteos) y luego reconstruye el
REM proyecto Python ppythonPrueba\: estructura de carpetas, entorno virtual,
REM dependencias y el notebook con la consulta a la BD dockerizada.
setlocal

set "SCRIPT_DIR=%~dp0"
set "DOCKER_DIR=%SCRIPT_DIR%docker"
set "PROJECT_DIR=%SCRIPT_DIR%ppythonPrueba"
if not defined PYTHON_BIN set "PYTHON_BIN=python"

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

REM ---------------------------------------------------------------------------
REM Proyecto Python: ppythonPrueba\ (dentro de este exercise-01)
REM ---------------------------------------------------------------------------

echo ==^> Creando estructura de ppythonPrueba\ ...
md "%PROJECT_DIR%\src\datasets"    2>nul
md "%PROJECT_DIR%\src\controller"  2>nul
md "%PROJECT_DIR%\src\persistence" 2>nul
md "%PROJECT_DIR%\src\model"       2>nul
md "%PROJECT_DIR%\src\view"        2>nul
md "%PROJECT_DIR%\notebook"        2>nul

(
  echo notebook
  echo ipykernel
  echo pandas
  echo mysql-connector-python
)> "%PROJECT_DIR%\requirements.txt"

if not exist "%PROJECT_DIR%\main.py" type nul > "%PROJECT_DIR%\main.py"

echo ==^> Creando entorno virtual (.venv) ...
if not exist "%PROJECT_DIR%\.venv" %PYTHON_BIN% -m venv "%PROJECT_DIR%\.venv"
if errorlevel 1 goto :error
set "VENV_PY=%PROJECT_DIR%\.venv\Scripts\python.exe"

echo ==^> Instalando dependencias (requirements.txt) ...
"%VENV_PY%" -m pip install --upgrade pip >nul
"%VENV_PY%" -m pip install -r "%PROJECT_DIR%\requirements.txt"
if errorlevel 1 goto :error

echo ==^> Registrando kernel de Jupyter (ppythonprueba) ...
"%VENV_PY%" -m ipykernel install --user --name ppythonprueba --display-name "Python (ppythonPrueba)" >nul

echo ==^> Generando notebook\ppythonPrueba.ipynb ...
powershell -NoProfile -Command "[IO.File]::WriteAllText('%PROJECT_DIR%\notebook\ppythonPrueba.ipynb', [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('ewogImNlbGxzIjogWwogIHsKICAgImNlbGxfdHlwZSI6ICJtYXJrZG93biIsCiAgICJtZXRhZGF0YSI6IHt9LAogICAic291cmNlIjogWwogICAgIiMgQ29uc3VsdGEgYSBsYSBCRCBgY29sb21iaWFgIChtdW5pY2lwaW9zKSBkZXNkZSBQeXRob25cbiIsCiAgICAiXG4iLAogICAgIlJlcXVpZXJlIGVsIGNvbnRlbmVkb3IgKipgY29sb21iaWEtbXlzcWxgKiogbGV2YW50YWRvIChsbyBoYWNlIGVzdGUgbWlzbW8gYHJ1bi5zaGAsIG8gYGRvY2tlciBjb21wb3NlIHVwIC1kYCBlbiBgZXhlcmNpc2UtMDEvZG9ja2VyL2ApLlxuIiwKICAgICJFbCBwdWVydG8gMzMwNiBkZWwgY29udGVuZWRvciBlc3TDoSBwdWJsaWNhZG8gZW4gZWwgaG9zdCwgcG9yIGVzbyBzZSBjb25lY3RhIGEgYDEyNy4wLjAuMTozMzA2YC4iCiAgIF0KICB9LAogIHsKICAgImNlbGxfdHlwZSI6ICJjb2RlIiwKICAgImV4ZWN1dGlvbl9jb3VudCI6IG51bGwsCiAgICJtZXRhZGF0YSI6IHt9LAogICAib3V0cHV0cyI6IFtdLAogICAic291cmNlIjogWwogICAgImltcG9ydCBteXNxbC5jb25uZWN0b3JcbiIsCiAgICAiaW1wb3J0IHBhbmRhcyBhcyBwZFxuIiwKICAgICJcbiIsCiAgICAiY29uZXhpb24gPSBteXNxbC5jb25uZWN0b3IuY29ubmVjdChcbiIsCiAgICAiICAgIGhvc3Q9XCIxMjcuMC4wLjFcIixcbiIsCiAgICAiICAgIHBvcnQ9MzMwNixcbiIsCiAgICAiICAgIHVzZXI9XCJyb290XCIsXG4iLAogICAgIiAgICBwYXNzd29yZD1cInJvb3RcIixcbiIsCiAgICAiICAgIGRhdGFiYXNlPVwiY29sb21iaWFcIixcbiIsCiAgICAiKVxuIiwKICAgICJwcmludChcIkNvbmVjdGFkbzpcIiwgY29uZXhpb24uaXNfY29ubmVjdGVkKCkpIgogICBdCiAgfSwKICB7CiAgICJjZWxsX3R5cGUiOiAiY29kZSIsCiAgICJleGVjdXRpb25fY291bnQiOiBudWxsLAogICAibWV0YWRhdGEiOiB7fSwKICAgIm91dHB1dHMiOiBbXSwKICAgInNvdXJjZSI6IFsKICAgICJjb25zdWx0YSA9IFwiXCJcIlxuIiwKICAgICIgICAgU0VMRUNUIHIubm9tYnJlX3JlZ2lvbiwgQ09VTlQoKikgQVMgdG90YWxfbXVuaWNpcGlvc1xuIiwKICAgICIgICAgRlJPTSBNdW5pY2lwaW9zIG1cbiIsCiAgICAiICAgIEpPSU4gRGVwYXJ0YW1lbnRvcyBkIE9OIGQuaWQgPSBtLmRlcGFydGFtZW50b19pZFxuIiwKICAgICIgICAgSk9JTiBSZWdpb25lcyByIE9OIHIuaWQgPSBkLnJlZ2lvbl9pZFxuIiwKICAgICIgICAgR1JPVVAgQlkgci5ub21icmVfcmVnaW9uXG4iLAogICAgIiAgICBPUkRFUiBCWSB0b3RhbF9tdW5pY2lwaW9zIERFU0NcbiIsCiAgICAiXCJcIlwiXG4iLAogICAgIlxuIiwKICAgICJwZC5yZWFkX3NxbChjb25zdWx0YSwgY29uZXhpb24pIgogICBdCiAgfSwKICB7CiAgICJjZWxsX3R5cGUiOiAiY29kZSIsCiAgICJleGVjdXRpb25fY291bnQiOiBudWxsLAogICAibWV0YWRhdGEiOiB7fSwKICAgIm91dHB1dHMiOiBbXSwKICAgInNvdXJjZSI6IFsKICAgICIjIE11bmljaXBpb3MgZGUgdW4gZGVwYXJ0YW1lbnRvIGNvbmNyZXRvIChwYXJhbWV0cml6YWRvKVxuIiwKICAgICJwZC5yZWFkX3NxbChcbiIsCiAgICAiICAgIFwiXCJcIlxuIiwKICAgICIgICAgU0VMRUNUIG0uY29kaWdvX2RhbmVfbXVuaWNpcGlvLCBtLm5vbWJyZV9tdW5pY2lwaW9cbiIsCiAgICAiICAgIEZST00gTXVuaWNpcGlvcyBtXG4iLAogICAgIiAgICBKT0lOIERlcGFydGFtZW50b3MgZCBPTiBkLmlkID0gbS5kZXBhcnRhbWVudG9faWRcbiIsCiAgICAiICAgIFdIRVJFIGQubm9tYnJlX2RlcGFydGFtZW50byA9ICVzXG4iLAogICAgIiAgICBPUkRFUiBCWSBtLm5vbWJyZV9tdW5pY2lwaW9cbiIsCiAgICAiICAgIFwiXCJcIixcbiIsCiAgICAiICAgIGNvbmV4aW9uLFxuIiwKICAgICIgICAgcGFyYW1zPVtcIkFudGlvcXVpYVwiXSxcbiIsCiAgICAiKSIKICAgXQogIH0sCiAgewogICAiY2VsbF90eXBlIjogImNvZGUiLAogICAiZXhlY3V0aW9uX2NvdW50IjogbnVsbCwKICAgIm1ldGFkYXRhIjoge30sCiAgICJvdXRwdXRzIjogW10sCiAgICJzb3VyY2UiOiBbCiAgICAiY29uZXhpb24uY2xvc2UoKSIKICAgXQogIH0KIF0sCiAibWV0YWRhdGEiOiB7CiAgImtlcm5lbHNwZWMiOiB7CiAgICJkaXNwbGF5X25hbWUiOiAiUHl0aG9uIChwcHl0aG9uUHJ1ZWJhKSIsCiAgICJsYW5ndWFnZSI6ICJweXRob24iLAogICAibmFtZSI6ICJwcHl0aG9ucHJ1ZWJhIgogIH0sCiAgImxhbmd1YWdlX2luZm8iOiB7CiAgICJuYW1lIjogInB5dGhvbiIKICB9CiB9LAogIm5iZm9ybWF0IjogNCwKICJuYmZvcm1hdF9taW5vciI6IDQKfQo=')))" || goto :error

echo.
echo ==^> Listo. Para abrir el notebook:
echo       cd "%PROJECT_DIR%"
echo       .venv\Scripts\jupyter notebook notebook\ppythonPrueba.ipynb
exit /b 0

:error
popd
echo Ocurrio un error ejecutando el script.
exit /b 1
