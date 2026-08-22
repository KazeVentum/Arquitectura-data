-- Carga de datos desde municipios.csv hacia las tablas normalizadas
USE municipios;

-- Tabla temporal para leer el CSV
CREATE TABLE staging_municipios (
	region VARCHAR (50) NOT NULL,
	departamento_id VARCHAR (2) NOT NULL,
	departamento_nombre VARCHAR (60) NOT NULL,
	municipio_id VARCHAR (10) NOT NULL,
	municipio_nombre VARCHAR (30) NOT NULL
);


LOAD DATA LOCAL INFILE 'municipios.csv'
INTO TABLE staging_municipios
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(region, departamento_id, departamento_nombre, municipio_id, municipio_nombre);

-- Corrige las 2 filas del departamento 88, mal formadas en el CSV origen (ver README)
UPDATE staging_municipios
SET region = 'Región Caribe',
	departamento_nombre = 'Archipiélago de San Andrés, Providencia y Santa Catalina',
	municipio_id = municipio_nombre,
	municipio_nombre = 'Providencia'
WHERE departamento_id = '88' AND municipio_nombre = '88.564';

UPDATE staging_municipios
SET region = 'Región Caribe',
	departamento_nombre = 'Archipiélago de San Andrés, Providencia y Santa Catalina',
	municipio_id = municipio_nombre,
	municipio_nombre = 'San Andrés'
WHERE departamento_id = '88' AND municipio_nombre = '88.001';

-- Poblar regiones
INSERT INTO regiones (nombre)
SELECT DISTINCT region FROM staging_municipios;

-- Poblar departamentos
INSERT INTO departamentos (departamento_id, nombre, region_id)
SELECT DISTINCT s.departamento_id, s.departamento_nombre, r.region_id
FROM staging_municipios s
JOIN regiones r ON r.nombre = s.region;

-- Poblar municipios
INSERT INTO municipios (municipio_id, nombre, departamento_id)
SELECT DISTINCT s.municipio_id, s.municipio_nombre, s.departamento_id
FROM staging_municipios s;

DROP TABLE staging_municipios;
