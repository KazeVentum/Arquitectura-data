-- Creación de la base de datos y sus tablas

CREATE DATABASE IF NOT EXISTS municipios;
USE municipios;

CREATE TABLE regiones (
	region_id INT AUTO_INCREMENT PRIMARY KEY,
	nombre VARCHAR (50) NOT NULL UNIQUE
);

CREATE TABLE departamentos (
	departamento_id VARCHAR (2) PRIMARY KEY,
	nombre VARCHAR (60) NOT NULL,
	region_id INT NOT NULL,
	FOREIGN KEY (region_id) REFERENCES regiones (region_id)
);

CREATE TABLE municipios (
	municipio_id VARCHAR (10) PRIMARY KEY,
	nombre VARCHAR (30) NOT NULL,
	departamento_id VARCHAR (2) NOT NULL,
	FOREIGN KEY (departamento_id) REFERENCES departamentos (departamento_id)
);
