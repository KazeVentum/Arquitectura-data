#!/usr/bin/env bash
# Levanta el contenedor MySQL con docker compose y ejecuta los pasos del README
# (crear tablas, cargar datos y verificar los conteos) y luego reconstruye el
# proyecto Python `ppythonPrueba/`: estructura de carpetas, entorno virtual,
# dependencias y el notebook con la consulta a la BD dockerizada.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/docker"
PROJECT_DIR="$SCRIPT_DIR/ppythonPrueba"
PYTHON_BIN="${PYTHON_BIN:-python3}"

echo "==> Levantando contenedor MySQL..."
(cd "$DOCKER_DIR" && docker compose up -d)

echo "==> Esperando a que MySQL esté listo..."
until (cd "$DOCKER_DIR" && docker compose exec -T mysql mysqladmin ping -h localhost -uroot -proot --silent) >/dev/null 2>&1; do
  sleep 2
done
echo "    MySQL listo."

echo "==> Creando base de datos y tablas (01_crear_tablas.sql)..."
(cd "$DOCKER_DIR" && docker compose exec -T -w /scripts mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4 -e "source 01_crear_tablas.sql;")

echo "==> Cargando datos (02_cargar_datos.sql)..."
(cd "$DOCKER_DIR" && docker compose exec -T -w /scripts mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4 -e "source 02_cargar_datos.sql;")

echo "==> Verificación:"
(cd "$DOCKER_DIR" && docker compose exec -T mysql mysql -uroot -proot --default-character-set=utf8mb4 colombia -e "SELECT (SELECT COUNT(*) FROM Regiones) regiones, (SELECT COUNT(*) FROM Departamentos) departamentos, (SELECT COUNT(*) FROM Municipios) municipios;")

# ---------------------------------------------------------------------------
# Proyecto Python: ppythonPrueba/ (dentro de este exercise-01)
# ---------------------------------------------------------------------------

echo "==> Creando estructura de ppythonPrueba/ ..."
mkdir -p \
  "$PROJECT_DIR/src/datasets" \
  "$PROJECT_DIR/src/controller" \
  "$PROJECT_DIR/src/persistence" \
  "$PROJECT_DIR/src/model" \
  "$PROJECT_DIR/src/view" \
  "$PROJECT_DIR/notebook"

cat > "$PROJECT_DIR/requirements.txt" <<'EOF'
notebook
ipykernel
pandas
mysql-connector-python
EOF

[ -e "$PROJECT_DIR/main.py" ] || : > "$PROJECT_DIR/main.py"

echo "==> Creando entorno virtual (.venv) ..."
if [ ! -d "$PROJECT_DIR/.venv" ]; then
  "$PYTHON_BIN" -m venv "$PROJECT_DIR/.venv"
fi
VENV_PY="$PROJECT_DIR/.venv/bin/python"

echo "==> Instalando dependencias (requirements.txt) ..."
"$VENV_PY" -m pip install --upgrade pip >/dev/null
"$VENV_PY" -m pip install -r "$PROJECT_DIR/requirements.txt"

echo "==> Registrando kernel de Jupyter (ppythonprueba) ..."
"$VENV_PY" -m ipykernel install --user --name ppythonprueba --display-name "Python (ppythonPrueba)" >/dev/null

echo "==> Generando notebook/ppythonPrueba.ipynb ..."
cat > "$PROJECT_DIR/notebook/ppythonPrueba.ipynb" <<'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Consulta a la BD `colombia` (municipios) desde Python\n",
    "\n",
    "Requiere el contenedor **`colombia-mysql`** levantado (lo hace este mismo `run.sh`, o `docker compose up -d` en `exercise-01/docker/`).\n",
    "El puerto 3307 del host mapea al 3306 del contenedor, por eso se conecta a `127.0.0.1:3307`."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import mysql.connector\n",
    "import pandas as pd\n",
    "\n",
    "conexion = mysql.connector.connect(\n",
    "    host=\"127.0.0.1\",\n",
    "    port=3307,\n",
    "    user=\"root\",\n",
    "    password=\"root\",\n",
    "    database=\"colombia\",\n",
    ")\n",
    "print(\"Conectado:\", conexion.is_connected())"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "consulta = \"\"\"\n",
    "    SELECT r.nombre_region, COUNT(*) AS total_municipios\n",
    "    FROM Municipios m\n",
    "    JOIN Departamentos d ON d.id = m.departamento_id\n",
    "    JOIN Regiones r ON r.id = d.region_id\n",
    "    GROUP BY r.nombre_region\n",
    "    ORDER BY total_municipios DESC\n",
    "\"\"\"\n",
    "\n",
    "pd.read_sql(consulta, conexion)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Municipios de un departamento concreto (parametrizado)\n",
    "pd.read_sql(\n",
    "    \"\"\"\n",
    "    SELECT m.codigo_dane_municipio, m.nombre_municipio\n",
    "    FROM Municipios m\n",
    "    JOIN Departamentos d ON d.id = m.departamento_id\n",
    "    WHERE d.nombre_departamento = %s\n",
    "    ORDER BY m.nombre_municipio\n",
    "    \"\"\",\n",
    "    conexion,\n",
    "    params=[\"Antioquia\"],\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "conexion.close()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python (ppythonPrueba)",
   "language": "python",
   "name": "ppythonprueba"
  },
  "language_info": {
   "name": "python"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

echo
echo "==> Listo. Para abrir el notebook:"
echo "      cd \"$PROJECT_DIR\""
echo "      .venv/bin/jupyter notebook notebook/ppythonPrueba.ipynb"
