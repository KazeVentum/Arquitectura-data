/*
Taller SQL Avanzado - Base de datos bdrh
2. INDICE

empleados.departamento_id ya tiene indice por ser llave foranea, pero las
consultas que filtran por departamento y ademas ordenan o filtran por
salario (como la vista del punto 1 o el procedimiento del punto 3) se
benefician de un indice compuesto que cubra ambas columnas.

Requiere tener cargada la base bdrh (RRHH-db.sql).
*/

USE bdrh;

CREATE INDEX idx_empleados_departamento_salario
ON empleados (departamento_id, salario);

-- Prueba: el indice debe aparecer en el plan de ejecucion (columna "key")
EXPLAIN SELECT empleado_id, salario
FROM empleados
WHERE departamento_id = 6
ORDER BY salario DESC;

-- Prueba: el indice debe existir
SHOW INDEX FROM empleados WHERE Key_name = 'idx_empleados_departamento_salario';
