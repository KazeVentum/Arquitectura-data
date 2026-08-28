#!/usr/bin/env bash
# Levanta el contenedor MySQL con docker compose y ejecuta los pasos del README:
# crear tablas, cargar datos y verificar los conteos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/docker"

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

echo "==> Listo."
