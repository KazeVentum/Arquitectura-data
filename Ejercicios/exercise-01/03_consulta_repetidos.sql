USE colombia;

SELECT 
    m.nombre_municipio, 
    COUNT(DISTINCT m.departamento_id) AS cantidad_repeticiones,
    GROUP_CONCAT(d.nombre_departamento SEPARATOR ', ') AS departamentos_donde_existe
FROM Municipios m
JOIN Departamentos d ON m.departamento_id = d.id
GROUP BY m.nombre_municipio
HAVING COUNT(DISTINCT m.departamento_id) > 1
ORDER BY cantidad_repeticiones DESC, m.nombre_municipio;