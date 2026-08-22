/*
Taller SQL Avanzado - Base de datos bdrh
5. EVENTO

Aplica un bono de antiguedad del 5% a los empleados cuyo mes de ingreso
es el mes actual, reutilizando sp_aumentar_salario (punto 3).

En un caso real este evento se programaria EVERY 1 YEAR. Para poder
mostrarlo funcionando en la exposicion, aqui se programa para ejecutarse
UNA SOLA VEZ, 30 segundos despues de correr este script (ON SCHEDULE AT
CURRENT_TIMESTAMP + INTERVAL 30 SECOND). Si necesitan mas tiempo para
explicar antes de que se dispare, cambien el "30 SECOND" por "2 MINUTE"
o el numero que necesiten antes de ejecutar el script.

Requiere:
- Base bdrh cargada (RRHH-db.sql)
- sp_aumentar_salario creado (3_procedimiento.sql)
- Opcional pero recomendado para verlo en la demo: trg_empleados_auditoria_salario
  (4_disparador.sql), asi cada aumento que aplique el evento queda registrado
  en auditoria_salarios.
*/

USE bdrh;

-- El Event Scheduler debe estar activo para que el evento se dispare solo
SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evt_bono_antiguedad
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND
DO
BEGIN
	DECLARE fin INT DEFAULT 0;
	DECLARE v_empleado_id INT;
	DECLARE cur CURSOR FOR
		SELECT empleado_id FROM empleados
		WHERE MONTH(fecha_ingreso) = MONTH(CURDATE());
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = 1;

	OPEN cur;
	bucle: LOOP
		FETCH cur INTO v_empleado_id;
		IF fin = 1 THEN
			LEAVE bucle;
		END IF;
		CALL sp_aumentar_salario(v_empleado_id, 5);
	END LOOP;
	CLOSE cur;
END$$

DELIMITER ;

-- Para la demo:
-- 1. Corran este script.
-- 2. Mientras esperan los 30 segundos, muestren los empleados que va a afectar:
SELECT empleado_id, nombres, apellidos, fecha_ingreso, salario
FROM empleados
WHERE MONTH(fecha_ingreso) = MONTH(CURDATE());

-- 3. Pasados los 30 segundos, vuelvan a correr el SELECT de arriba: el salario
--    de esos empleados debe haber subido (o quedarse igual si ya estaban en
--    el salario_max de su trabajo).
-- 4. Si tienen el trigger del punto 4 instalado, revisen tambien:
SELECT * FROM auditoria_salarios ORDER BY fecha_cambio DESC;

-- 5. El evento ya ejecuto una vez y no se repite; para revisar su estado:
SHOW EVENTS FROM bdrh;
