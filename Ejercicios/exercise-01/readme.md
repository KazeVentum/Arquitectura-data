# Ejercicio 01 - Municipios

Carga de `municipios.csv` a una base de datos MySQL (`colombia`) normalizada en 3 tablas: `Regiones`, `Departamentos`, `Municipios`.

## Archivos

- `01_crear_tablas.sql` - crea la base de datos `colombia` y las 3 tablas con sus FK y restricciones `UNIQUE`.
- `02_cargar_datos.sql` - carga el CSV directamente a las 3 tablas con `LOAD DATA ... IGNORE INTO TABLE` y corrige el departamento 88.
- `municipios.csv` - datos fuente (región, departamento, municipio). No se modifica.

## Cómo ejecutar

```
mysql -u root -p < 01_crear_tablas.sql
cd exercise-01
mysql -u root -p --local-infile=1 --default-character-set=utf8mb4 < 02_cargar_datos.sql
```

`--local-infile=1` es obligatorio en el cliente (el script usa `LOAD DATA LOCAL INFILE`), además de tenerlo habilitado en el servidor (`SET GLOBAL local_infile = 1;`, ya incluido al inicio de `02_cargar_datos.sql`).

`--default-character-set=utf8mb4` también es obligatorio: sin él, el cliente usa `latin1` por defecto y los literales con tildes del script (p. ej. `'Región Caribe'`) se guardan mal codificados.

El script debe correrse desde `exercise-01/` porque `municipios.csv` se referencia con ruta relativa.

## Problema de datos en el CSV

El departamento 88 (Archipiélago de San Andrés, Providencia y Santa Catalina) tiene una coma dentro del nombre. En el CSV esa coma está encerrada con comillas dobles anidadas mal formadas:

```
"Región Caribe,88,""Archipiélago de San Andrés, Providencia y Santa Catalina"",88.564,Providencia"
```

`02_cargar_datos.sql` carga con `OPTIONALLY ENCLOSED BY '"'`. Esa línea, al no seguir el formato de comillas normal del resto del CSV, se parsea mal y dos de sus columnas quedan vacías — en vez de arrastrar el resto del archivo, MySQL inserta filas con todos los campos en `NULL` (una en `Regiones`, una en `Departamentos`, una en `Municipios`, dependiendo del `LOAD DATA`).

Solución en `02_cargar_datos.sql`, sin tocar el CSV:

1. Después de cada `LOAD DATA`, un `DELETE` elimina esas filas basura (`nombre_region LIKE 'Región Caribe,88,%'` en `Regiones`; `codigo_dane_departamento IS NULL` en `Departamentos`; `codigo_dane_municipio IS NULL` en `Municipios`).
2. Tres `INSERT IGNORE` reconstruyen a mano el departamento 88 y sus 2 municipios (San Andrés, Providencia) con los valores correctos.

El CSV también usa finales de línea CRLF (`\r\n`). `LOAD DATA` declara `LINES TERMINATED BY '\r\n'`; con `'\n'` el `\r` queda pegado al último campo de cada fila, guardando nombres como `'Bogotá D.C.\r'` en vez de `'Bogotá D.C.'`.

## Cómo ejecutar con Docker

No requiere tener MySQL ni el cliente `mysql` instalados en el host.

```
cd Ejercicios/exercise-01/docker
docker compose up -d
docker compose exec -T -w /scripts mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4 -e "source 01_crear_tablas.sql;"
docker compose exec -T -w /scripts mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4 -e "source 02_cargar_datos.sql;"
```

El directorio `exercise-01/` (con los `.sql` y `municipios.csv`) queda montado en `/scripts` dentro del contenedor, por eso `LOAD DATA LOCAL INFILE 'municipios.csv'` funciona sin tocar el script.

Para entrar directo al contenedor:

```
docker exec -it colombia-mysql bash
docker exec -it colombia-mysql mysql -uroot -proot --local-infile=1 --default-character-set=utf8mb4
```

Para verificar:

```
docker compose exec mysql mysql -uroot -proot --default-character-set=utf8mb4 colombia -e "SELECT (SELECT COUNT(*) FROM Regiones) regiones, (SELECT COUNT(*) FROM Departamentos) departamentos, (SELECT COUNT(*) FROM Municipios) municipios;"
```

Apagar y borrar los datos:

```
docker compose down -v
```

## Verificación esperada

- 6 regiones
- 33 departamentos
- 1123 municipios
- 0 filas huérfanas (municipio sin departamento, departamento sin región)
