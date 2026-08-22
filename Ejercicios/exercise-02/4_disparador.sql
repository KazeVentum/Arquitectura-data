/*
Taller SQL Avanzado - Base de datos bdrh
4. DISPARADOR

Registra en auditoria_salarios cada cambio real de salario, sea manual
o hecho por sp_aumentar_salario (punto 3).

Requiere tener cargada la base bdrh (RRHH-db.sql).
*/

USE bdrh;

CREATE TABLE auditoria_salarios (
	auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
	empleado_id INT NOT NULL,
	salario_anterior DECIMAL (8, 2) NOT NULL,
	salario_nuevo DECIMAL (8, 2) NOT NULL,
	fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER trg_empleados_auditoria_salario
AFTER UPDATE ON empleados
FOR EACH ROW
BEGIN
	IF NEW.salario <> OLD.salario THEN
		INSERT INTO auditoria_salarios (empleado_id, salario_anterior, salario_nuevo)
		VALUES (OLD.empleado_id, OLD.salario, NEW.salario);
	END IF;
END$$

DELIMITER ;

-- Prueba: cualquier UPDATE de salario debe dejar rastro en auditoria_salarios
UPDATE empleados SET salario = salario + 100 WHERE empleado_id = 104;
SELECT * FROM auditoria_salarios WHERE empleado_id = 104;
