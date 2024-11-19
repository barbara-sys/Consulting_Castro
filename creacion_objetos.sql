-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS ventas_coca_cola;
USE ventas_coca_cola;

-- Tabla TiposClientes
CREATE TABLE IF NOT EXISTS TiposClientes (
    id_tipo_cliente INT AUTO_INCREMENT,
    tipo_cliente VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_tipo_cliente)
);

-- Tabla Clientes
CREATE TABLE IF NOT EXISTS Clientes (
    id_cliente INT AUTO_INCREMENT,
    nombre_cliente VARCHAR(100) NOT NULL,
    id_tipo_cliente INT,
    PRIMARY KEY (id_cliente),
    FOREIGN KEY (id_tipo_cliente) REFERENCES TiposClientes(id_tipo_cliente) ON DELETE CASCADE
);

-- Tabla Regiones
CREATE TABLE IF NOT EXISTS Regiones (
    id_region INT AUTO_INCREMENT,
    nombre_region VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_region)
);

-- Tabla Proyecciones
CREATE TABLE IF NOT EXISTS Proyecciones (
    id_proyeccion INT AUTO_INCREMENT,
    id_cliente INT,
    id_region INT,
    fecha_proyeccion DATE NOT NULL,
    forecast DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_proyeccion),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente) ON DELETE CASCADE,
    FOREIGN KEY (id_region) REFERENCES Regiones(id_region) ON DELETE CASCADE
);

-- Tabla Ventas (Corregida)
CREATE TABLE IF NOT EXISTS Ventas (
    id_venta INT AUTO_INCREMENT,
    fecha_venta DATE NOT NULL,
    cantidad_vendida DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_venta)
);

-- Tabla Proyecciones_Ventas
CREATE TABLE IF NOT EXISTS Proyecciones_Ventas (
    id_proyeccion INT,
    id_venta INT,
    PRIMARY KEY (id_proyeccion, id_venta),
    FOREIGN KEY (id_proyeccion) REFERENCES Proyecciones(id_proyeccion) ON DELETE CASCADE,
    FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta) ON DELETE CASCADE
);

-- Creación de Vistas

CREATE OR REPLACE VIEW vista_ventas_por_region AS
SELECT r.nombre_region, c.nombre_cliente, SUM(v.cantidad_vendida) AS total_ventas
FROM Ventas v
INNER JOIN Proyecciones_Ventas pv ON v.id_venta = pv.id_venta
INNER JOIN Proyecciones p ON p.id_proyeccion = pv.id_proyeccion
INNER JOIN Regiones r ON p.id_region = r.id_region
INNER JOIN Clientes c ON c.id_cliente = p.id_cliente
GROUP BY r.nombre_region, c.nombre_cliente;

CREATE OR REPLACE VIEW vista_discrepancia_proyeccion AS
SELECT c.nombre_cliente, r.nombre_region, SUM(v.cantidad_vendida) AS ventas_reales, SUM(p.forecast) AS forecast,
       (SUM(v.cantidad_vendida) - SUM(p.forecast)) AS diferencia
FROM Proyecciones p
JOIN Proyecciones_Ventas pv ON p.id_proyeccion = pv.id_proyeccion
JOIN Ventas v ON pv.id_venta = v.id_venta
JOIN Clientes c ON p.id_cliente = c.id_cliente
JOIN Regiones r ON p.id_region = r.id_region
GROUP BY c.nombre_cliente, r.nombre_region;

CREATE OR REPLACE VIEW vista_clientes_activos AS
SELECT DISTINCT c.id_cliente, c.nombre_cliente
FROM Proyecciones p 
INNER JOIN Proyecciones_Ventas pv ON p.id_proyeccion = pv.id_proyeccion
INNER JOIN Ventas v ON pv.id_venta = v.id_venta
INNER JOIN Clientes c ON p.id_cliente = c.id_cliente
WHERE YEAR(v.fecha_venta) = YEAR(CURDATE());

CREATE OR REPLACE VIEW vista_ventas_por_tipo_cliente AS
SELECT tc.tipo_cliente, SUM(v.cantidad_vendida) AS total_ventas
FROM Proyecciones p 
INNER JOIN Proyecciones_Ventas pv ON p.id_proyeccion = pv.id_proyeccion
INNER JOIN Ventas v ON pv.id_venta = v.id_venta
INNER JOIN Clientes c ON p.id_cliente = c.id_cliente
INNER JOIN TiposClientes tc ON c.id_tipo_cliente = tc.id_tipo_cliente
GROUP BY tc.tipo_cliente;

CREATE OR REPLACE VIEW vista_ventas_mensuales_por_region AS
SELECT r.nombre_region, MONTH(v.fecha_venta) AS mes, SUM(v.cantidad_vendida) AS total_ventas
FROM Ventas v
INNER JOIN Proyecciones_Ventas pv ON v.id_venta = pv.id_venta
INNER JOIN Proyecciones p ON p.id_proyeccion = pv.id_proyeccion
INNER JOIN Regiones r ON p.id_region = r.id_region
INNER JOIN Clientes c ON c.id_cliente = p.id_cliente
GROUP BY r.nombre_region, mes;

-- Creación de Funciones
DELIMITER //
CREATE FUNCTION obtener_total_ventas_cliente(cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_ventas DECIMAL(10,2);
    SELECT SUM(cantidad_vendida) INTO total_ventas
    FROM Proyecciones p 
    INNER JOIN Proyecciones_Ventas pv ON p.id_proyeccion = pv.id_proyeccion
	INNER JOIN Ventas v ON pv.id_venta = v.id_venta
    INNER JOIN Clientes c ON p.id_cliente = c.id_cliente
    WHERE c.id_cliente = cliente_id;
    RETURN total_ventas;
END;
//


DELIMITER //
CREATE FUNCTION obtener_discrepancia(id_proyeccion INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE discrepancia DECIMAL(10,2);
    
    -- Manejar posibles valores NULL usando IFNULL
    SELECT IFNULL(SUM(p.forecast), 0) - IFNULL(SUM(v.cantidad_vendida), 0) INTO discrepancia
    FROM Proyecciones p
    INNER JOIN Proyecciones_Ventas pv ON p.id_proyeccion = pv.id_proyeccion
    INNER JOIN Ventas v ON pv.id_venta = v.id_venta
    WHERE p.id_proyeccion = id_proyeccion;
    
    RETURN discrepancia;
END;
//
DELIMITER ;



-- Creación de Stored Procedures
DELIMITER //
CREATE PROCEDURE ordenar_ventas(IN campo VARCHAR(50), IN direccion VARCHAR(4))
BEGIN
    SET @query = CONCAT('SELECT * FROM Ventas ORDER BY ', campo, ' ', direccion);
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END;
//


DELIMITER //
CREATE PROCEDURE insertar_nueva_venta(IN cliente_id INT, IN fecha DATE, IN cantidad DECIMAL(10,2))
BEGIN
    -- Verificar si el cliente existe
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE id_cliente = cliente_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: El cliente no existe.';
    ELSE
        -- Insertar la nueva venta
        INSERT INTO Ventas (fecha_venta, cantidad_vendida)
        VALUES (fecha, cantidad);
    END IF;
END;
//
DELIMITER ;


-- Creación de Triggers
DELIMITER //
CREATE TRIGGER before_insert_proyecciones
BEFORE INSERT ON Proyecciones
FOR EACH ROW
BEGIN
    IF NEW.forecast <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: El valor de forecast debe ser positivo';
    END IF;
END;
//


DELIMITER //
CREATE TRIGGER before_update_ventas
BEFORE UPDATE ON Ventas
FOR EACH ROW
BEGIN
    SET NEW.fecha_venta = NOW();
END;
//
DELIMITER ;

