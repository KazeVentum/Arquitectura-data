/*
Taller SQL Avanzado - Base de datos bdrh
1. VISTA

Junta empleado, trabajo, departamento, ciudad y pais en una sola consulta.
Evita repetir los JOIN cada vez que se necesita ese detalle.

Requiere tener cargada la base bdrh (RRHH-db.sql).
*/

USE bdrh;

CREATE OR REPLACE VIEW vista_empleados_detalle AS
SELECT
	e.empleado_id,
	CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
	t.trabajo_nombre,
	e.salario,
	d.departamento_nombre,
	u.ciudad,
	p.pais_nombre
FROM empleados e
JOIN trabajos t ON t.trabajo_id = e.trabajo_id
LEFT JOIN departamentos d ON d.departamento_id = e.departamento_id
LEFT JOIN ubicaciones u ON u.ubicacion_id = d.ubicacion_id
LEFT JOIN paises p ON p.pais_id = u.pais_id;

-- Prueba:
SELECT * FROM vista_empleados_detalle WHERE departamento_nombre = 'IT';
