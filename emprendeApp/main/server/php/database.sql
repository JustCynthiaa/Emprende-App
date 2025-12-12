-- Script para crear la base de datos y tablas de EmprendeApp
-- Estructura real según la BD en XAMPP
-- Ejecuta este script en phpMyAdmin o en la consola MySQL de XAMPP

CREATE DATABASE IF NOT EXISTS emprendeapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE emprendeapp;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario INT(11) AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    contraseña VARCHAR(30) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de emprendimientos
CREATE TABLE IF NOT EXISTS emprendimientos (
    id_emprendimiento INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT(11) NOT NULL,
    nombre_emprendimiento VARCHAR(100) NOT NULL,
    descripcion_emp INT(11),
    contacto DECIMAL(10,0),
    estado TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    INDEX idx_usuario (id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de archivos (imágenes)
CREATE TABLE IF NOT EXISTS archivos (
    id_archivo INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_emprendimiento INT(11) NOT NULL,
    imagen LONGBLOB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_emprendimiento) REFERENCES emprendimientos(id_emprendimiento) ON DELETE CASCADE,
    INDEX idx_emprendimiento (id_emprendimiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de productos
CREATE TABLE IF NOT EXISTS producto (
    id_producto INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_emprendimiento INT(11) NOT NULL,
    descripcion_producto VARCHAR(200),
    precio DOUBLE,
    id_archivo INT(11),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_emprendimiento) REFERENCES emprendimientos(id_emprendimiento) ON DELETE CASCADE,
    FOREIGN KEY (id_archivo) REFERENCES archivos(id_archivo) ON DELETE SET NULL,
    INDEX idx_emprendimiento (id_emprendimiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de horarios
CREATE TABLE IF NOT EXISTS horarios (
    id_horario INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_emprendimiento INT(11) NOT NULL,
    dia_semana VARCHAR(20),
    hora_inicial TIME,
    hora_final TIME,
    ubicacion VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_emprendimiento) REFERENCES emprendimientos(id_emprendimiento) ON DELETE CASCADE,
    INDEX idx_emprendimiento (id_emprendimiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar un usuario de prueba (password: test123)
INSERT INTO usuarios (nombre_usuario, email, contraseña) VALUES 
('Usuario Prueba', 'test@example.com', 'test123');
