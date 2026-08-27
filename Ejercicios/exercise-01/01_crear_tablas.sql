-- 1. Creación de la Base de Datos con soporte para español
CREATE DATABASE colombia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE colombia;

-- 2. Creación de Tablas con tamaños optimizados
CREATE TABLE `Regiones` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nombre_region` varchar(50) -- 50 es suficiente para "Región Andina", etc.
);

CREATE TABLE `Departamentos` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `codigo_dane_departamento` varchar(5), -- Optimizamos el tamaño
  `nombre_departamento` varchar(100),
  `region_id` int
);

CREATE TABLE `Municipios` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `codigo_dane_municipio` varchar(10), -- Optimizamos el tamaño
  `nombre_municipio` varchar(100),
  `departamento_id` int
);

-- 3. Definición de Llaves Foráneas (Relaciones)
ALTER TABLE `Departamentos` 
ADD FOREIGN KEY (`region_id`) REFERENCES `Regiones` (`id`);

ALTER TABLE `Municipios` 
ADD FOREIGN KEY (`departamento_id`) REFERENCES `Departamentos` (`id`);

-- 4. VITAL: Restricciones Únicas para evitar duplicados en el LOAD DATA
ALTER TABLE `Regiones` ADD UNIQUE (`nombre_region`);
ALTER TABLE `Departamentos` ADD UNIQUE (`codigo_dane_departamento`);
ALTER TABLE `Municipios` ADD UNIQUE (`codigo_dane_municipio`);