# Ejercicio 01 - Municipios

Carga de `municipios.csv` a una base de datos MySQL normalizada en 3 tablas: `regiones`, `departamentos`, `municipios`.

## Archivos

- `01_crear_tablas.sql` - crea la base de datos `municipios` y las 3 tablas con sus FK.
- `02_cargar_datos.sql` - carga el CSV a una tabla staging y puebla las 3 tablas.
- `municipios.csv` - datos fuente (región, departamento, municipio). No se modifica.

## Cómo ejecutar

```
mysql -u root -p < 01_crear_tablas.sql
cd exercise-01
mysql -u root -p --local-infile=1 < 02_cargar_datos.sql
```

`--local-infile=1` es obligatorio (el script usa `LOAD DATA LOCAL INFILE`). El servidor también debe tener `local_infile=1`:

```
mysql -u root -p -e "SET GLOBAL local_infile = 1;"
```

El script debe correrse desde `exercise-01/` porque `municipios.csv` se referencia con ruta relativa.

## Problema de datos en el CSV

El departamento 88 (Archipiélago de San Andrés, Providencia y Santa Catalina) tiene una coma dentro del nombre. En el CSV esa coma está encerrada con comillas dobles anidadas mal formadas:

```
"Región Caribe,88,""Archipiélago de San Andrés, Providencia y Santa Catalina"",88.564,Providencia"
```

Con `LOAD DATA ... OPTIONALLY ENCLOSED BY '"'`, MySQL interpreta esa línea como un solo campo y arrastra el resto del archivo, perdiendo cientos de filas sin lanzar error (solo warnings).

Solución en `02_cargar_datos.sql`, sin tocar el CSV:

1. Se carga sin `ENCLOSED BY`. Ninguna otra fila del CSV usa comillas, así que el resto del archivo carga bien.
2. Las 2 filas del departamento 88 quedan con columnas corridas por la coma sin escapar.
3. Dos `UPDATE` después del `LOAD DATA` recomponen esas 2 filas usando `departamento_id = '88'` como referencia.

## Verificación esperada

- 6 regiones
- 33 departamentos
- 1123 municipios
- 0 filas huérfanas (municipio sin departamento, departamento sin región)
