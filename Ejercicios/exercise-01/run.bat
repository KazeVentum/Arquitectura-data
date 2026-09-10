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
powershell -NoProfile -Command "[IO.File]::WriteAllText('%PROJECT_DIR%\notebook\ppythonPrueba.ipynb', [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('ewogImNlbGxzIjogWwogIHsKICAgImNlbGxfdHlwZSI6ICJtYXJrZG93biIsCiAgICJtZXRhZGF0YSI6IHt9LAogICAic291cmNlIjogWwogICAgIiMgQ29uc3VsdGEgYSBsYSBCRCBgY29sb21iaWFgIChtdW5pY2lwaW9zKSBkZXNkZSBQeXRob25cbiIsCiAgICAiXG4iLAogICAgIlJlcXVpZXJlIGVsIGNvbnRlbmVkb3IgKipgY29sb21iaWEtbXlzcWxgKiogbGV2YW50YWRvIChsbyBoYWNlIGVzdGUgbWlzbW8gYHJ1bi5zaGAsIG8gYGRvY2tlciBjb21wb3NlIHVwIC1kYCBlbiBgZXhlcmNpc2UtMDEvZG9ja2VyL2ApLlxuIiwKICAgICJFbCBwdWVydG8gMzMwNyBkZWwgaG9zdCBtYXBlYSBhbCAzMzA2IGRlbCBjb250ZW5lZG9yLCBwb3IgZXNvIHNlIGNvbmVjdGEgYSBgMTI3LjAuMC4xOjMzMDdgLiIKICAgXQogIH0sCiAgewogICAiY2VsbF90eXBlIjogImNvZGUiLAogICAiZXhlY3V0aW9uX2NvdW50IjogbnVsbCwKICAgIm1ldGFkYXRhIjoge30sCiAgICJvdXRwdXRzIjogW10sCiAgICJzb3VyY2UiOiBbCiAgICAiaW1wb3J0IG15c3FsLmNvbm5lY3RvclxuIiwKICAgICJpbXBvcnQgcGFuZGFzIGFzIHBkXG4iLAogICAgIlxuIiwKICAgICJjb25leGlvbiA9IG15c3FsLmNvbm5lY3Rvci5jb25uZWN0KFxuIiwKICAgICIgICAgaG9zdD1cIjEyNy4wLjAuMVwiLFxuIiwKICAgICIgICAgcG9ydD0zMzA3LFxuIiwKICAgICIgICAgdXNlcj1cInJvb3RcIixcbiIsCiAgICAiICAgIHBhc3N3b3JkPVwicm9vdFwiLFxuIiwKICAgICIgICAgZGF0YWJhc2U9XCJjb2xvbWJpYVwiLFxuIiwKICAgICIpXG4iLAogICAgInByaW50KFwiQ29uZWN0YWRvOlwiLCBjb25leGlvbi5pc19jb25uZWN0ZWQoKSkiCiAgIF0KICB9LAogIHsKICAgImNlbGxfdHlwZSI6ICJjb2RlIiwKICAgImV4ZWN1dGlvbl9jb3VudCI6IG51bGwsCiAgICJtZXRhZGF0YSI6IHt9LAogICAib3V0cHV0cyI6IFtdLAogICAic291cmNlIjogWwogICAgImNvbnN1bHRhID0gXCJcIlwiXG4iLAogICAgIiAgICBTRUxFQ1Qgci5ub21icmVfcmVnaW9uLCBDT1VOVCgqKSBBUyB0b3RhbF9tdW5pY2lwaW9zXG4iLAogICAgIiAgICBGUk9NIE11bmljaXBpb3MgbVxuIiwKICAgICIgICAgSk9JTiBEZXBhcnRhbWVudG9zIGQgT04gZC5pZCA9IG0uZGVwYXJ0YW1lbnRvX2lkXG4iLAogICAgIiAgICBKT0lOIFJlZ2lvbmVzIHIgT04gci5pZCA9IGQucmVnaW9uX2lkXG4iLAogICAgIiAgICBHUk9VUCBCWSByLm5vbWJyZV9yZWdpb25cbiIsCiAgICAiICAgIE9SREVSIEJZIHRvdGFsX211bmljaXBpb3MgREVTQ1xuIiwKICAgICJcIlwiXCJcbiIsCiAgICAiXG4iLAogICAgInBkLnJlYWRfc3FsKGNvbnN1bHRhLCBjb25leGlvbikiCiAgIF0KICB9LAogIHsKICAgImNlbGxfdHlwZSI6ICJjb2RlIiwKICAgImV4ZWN1dGlvbl9jb3VudCI6IG51bGwsCiAgICJtZXRhZGF0YSI6IHt9LAogICAib3V0cHV0cyI6IFtdLAogICAic291cmNlIjogWwogICAgIiMgTXVuaWNpcGlvcyBkZSB1biBkZXBhcnRhbWVudG8gY29uY3JldG8gKHBhcmFtZXRyaXphZG8pXG4iLAogICAgInBkLnJlYWRfc3FsKFxuIiwKICAgICIgICAgXCJcIlwiXG4iLAogICAgIiAgICBTRUxFQ1QgbS5jb2RpZ29fZGFuZV9tdW5pY2lwaW8sIG0ubm9tYnJlX211bmljaXBpb1xuIiwKICAgICIgICAgRlJPTSBNdW5pY2lwaW9zIG1cbiIsCiAgICAiICAgIEpPSU4gRGVwYXJ0YW1lbnRvcyBkIE9OIGQuaWQgPSBtLmRlcGFydGFtZW50b19pZFxuIiwKICAgICIgICAgV0hFUkUgZC5ub21icmVfZGVwYXJ0YW1lbnRvID0gJXNcbiIsCiAgICAiICAgIE9SREVSIEJZIG0ubm9tYnJlX211bmljaXBpb1xuIiwKICAgICIgICAgXCJcIlwiLFxuIiwKICAgICIgICAgY29uZXhpb24sXG4iLAogICAgIiAgICBwYXJhbXM9W1wiQW50aW9xdWlhXCJdLFxuIiwKICAgICIpIgogICBdCiAgfSwKICB7CiAgICJjZWxsX3R5cGUiOiAiY29kZSIsCiAgICJleGVjdXRpb25fY291bnQiOiBudWxsLAogICAibWV0YWRhdGEiOiB7fSwKICAgIm91dHB1dHMiOiBbXSwKICAgInNvdXJjZSI6IFsKICAgICJjb25leGlvbi5jbG9zZSgpIgogICBdCiAgfQogXSwKICJtZXRhZGF0YSI6IHsKICAia2VybmVsc3BlYyI6IHsKICAgImRpc3BsYXlfbmFtZSI6ICJQeXRob24gKHBweXRob25QcnVlYmEpIiwKICAgImxhbmd1YWdlIjogInB5dGhvbiIsCiAgICJuYW1lIjogInBweXRob25wcnVlYmEiCiAgfSwKICAibGFuZ3VhZ2VfaW5mbyI6IHsKICAgIm5hbWUiOiAicHl0aG9uIgogIH0KIH0sCiAibmJmb3JtYXQiOiA0LAogIm5iZm9ybWF0X21pbm9yIjogNAp9Cg==')))" || goto :error

echo.
echo ==^> Listo. Para abrir el notebook:
echo       cd "%PROJECT_DIR%"
echo       .venv\Scripts\jupyter notebook notebook\ppythonPrueba.ipynb
exit /b 0

:error
popd
echo Ocurrio un error ejecutando el script.
exit /b 1
