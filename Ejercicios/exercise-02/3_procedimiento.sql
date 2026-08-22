/*
Taller SQL Avanzado - Base de datos bdrh
3. PROCEDIMIENTO ALMACENADO

Aumenta el salario de un empleado en un porcentaje, sin superar el
salario_max definido para su trabajo.

Requiere tener cargada la base bdrh (RRHH-db.sql).
*/

USE bdrh;

DELIMITER $$

CREATE PROCEDURE sp_aumentar_salario (
	IN p_empleado_id INT,
	IN p_porcentaje DECIMAL (5, 2)
)
BEGIN
	DECLARE v_salario_actual DECIMAL (8, 2);
	DECLARE v_salario_max DECIMAL (8, 2);
	DECLARE v_salario_nuevo DECIMAL (8, 2);

	SELECT e.salario, t.salario_max
	INTO v_salario_actual, v_salario_max
	FROM empleados e
	JOIN trabajos t ON t.trabajo_id = e.trabajo_id
	WHERE e.empleado_id = p_empleado_id;

	IF v_salario_actual IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Empleado no existe';
	END IF;

	SET v_salario_nuevo = v_salario_actual * (1 + p_porcentaje / 100);

	IF v_salario_nuevo > v_salario_max THEN
		SET v_salario_nuevo = v_salario_max;
	END IF;

	UPDATE empleados
	SET salario = v_salario_nuevo
	WHERE empleado_id = p_empleado_id;
END$$

DELIMITER ;

-- Prueba: sube el salario del empleado 103 un 10%
SELECT empleado_id, salario FROM empleados WHERE empleado_id = 103;
CALL sp_aumentar_salario(103, 10);
SELECT empleado_id, salario FROM empleados WHERE empleado_id = 103;
