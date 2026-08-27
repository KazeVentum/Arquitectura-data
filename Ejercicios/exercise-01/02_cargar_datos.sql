USE colombia;

-- ============================================================
-- CONFIGURACIÓN INICIAL (Permisos para leer el CSV)
-- ============================================================
SET GLOBAL local_infile = 1;

-- ============================================================
-- 1. CARGAR REGIONES
-- ============================================================
LOAD DATA LOCAL INFILE 'municipios.csv'
IGNORE INTO TABLE Regiones
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    @region,
    @cod_departamento,
    @departamento,
    @cod_municipio,
    @municipio
)
SET nombre_region = TRIM(@region);

-- ============================================================
-- 2. ELIMINAR LAS DOS FILAS MAL INTERPRETADAS
-- ============================================================
DELETE FROM Regiones
WHERE nombre_region LIKE 'Región Caribe,88,%';

-- ============================================================
-- 3. CARGAR DEPARTAMENTOS
-- ============================================================
LOAD DATA LOCAL INFILE 'municipios.csv'
IGNORE INTO TABLE Departamentos
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    @region,
    @cod_departamento,
    @departamento,
    @cod_municipio,
    @municipio
)
SET
    codigo_dane_departamento = TRIM(@cod_departamento),
    nombre_departamento = TRIM(@departamento),
    region_id = (
        SELECT id
        FROM Regiones
        WHERE nombre_region = TRIM(@region) COLLATE utf8mb4_unicode_ci
        LIMIT 1
    );

-- ============================================================
-- 4. CARGAR MUNICIPIOS
-- ============================================================
LOAD DATA LOCAL INFILE 'municipios.csv'
IGNORE INTO TABLE Municipios
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    @region,
    @cod_departamento,
    @departamento,
    @cod_municipio,
    @municipio
)
SET
    codigo_dane_municipio = TRIM(@cod_municipio),
    nombre_municipio = TRIM(@municipio),
    departamento_id = (
        SELECT id
        FROM Departamentos
        WHERE codigo_dane_departamento = TRIM(@cod_departamento) COLLATE utf8mb4_unicode_ci
        LIMIT 1
    );

-- ============================================================
-- 4b. ELIMINAR FILAS BASURA GENERADAS POR LA LÍNEA MAL FORMADA
--     DEL DEPARTAMENTO 88 (quedan con todos los campos en NULL)
-- ============================================================
DELETE FROM Municipios WHERE codigo_dane_municipio IS NULL;
DELETE FROM Departamentos WHERE codigo_dane_departamento IS NULL;

-- ============================================================
-- 5. SAN ANDRÉS (DEPARTAMENTO)
-- ============================================================
INSERT IGNORE INTO Departamentos
    (codigo_dane_departamento, nombre_departamento, region_id)
SELECT
    '88',
    'Archipiélago de San Andrés, Providencia y Santa Catalina',
    id
FROM Regiones
WHERE nombre_region = 'Región Caribe'
LIMIT 1;

-- ============================================================
-- 6. PROVIDENCIA (MUNICIPIO)
-- ============================================================
INSERT IGNORE INTO Municipios
    (codigo_dane_municipio, nombre_municipio, departamento_id)
SELECT
    '88.564',
    'Providencia',
    id
FROM Departamentos
WHERE codigo_dane_departamento = '88'
LIMIT 1;

-- ============================================================
-- 7. SAN ANDRÉS (MUNICIPIO)
-- ============================================================
INSERT IGNORE INTO Municipios
    (codigo_dane_municipio, nombre_municipio, departamento_id)
SELECT
    '88.001',
    'San Andrés',
    id
FROM Departamentos
WHERE codigo_dane_departamento = '88'
LIMIT 1;

-- ============================================================
-- 8. VERIFICACIÓN
-- ============================================================
SELECT COUNT(*) AS total_regiones FROM Regiones;
SELECT COUNT(*) AS total_departamentos FROM Departamentos;
SELECT COUNT(*) AS total_municipios FROM Municipios;