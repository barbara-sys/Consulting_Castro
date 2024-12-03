
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




insercion_datos.sql:
/********************************************************************************
--                             INSERCIÓN DE DATOS
-- ******************************************************************************/

USE ventas_coca_cola;

-- Inserción de datos en TiposClientes
INSERT INTO TiposClientes (tipo_cliente) VALUES 
('Minorista'), 
('Distribuidor'), 
('Multinacional'), 
('Corporativo'), 
('Retail');


-- Inserción de datos en Regiones
INSERT INTO Regiones (nombre_region) VALUES 
('Norteamérica'), 
('Europa'), 
('Latinoamérica'), 
('Asia-Pacífico'), 
('África');

-- Inserción de datos en Clientes
INSERT INTO Clientes (nombre_cliente, id_tipo_cliente) VALUES 
('Coca-Cola Retail', 1), 
('Pepsi Distribuidor', 2), 
('Nestlé Multinacional', 3), 
('Unilever Corporativo', 4), 
('Walmart Retail', 5),
('Amazon Distribuidor', 2), 
('Carrefour Retail', 1), 
('Heineken Multinacional', 3), 
('Danone Corporativo', 4), 
('Target Retail', 5),
('Metro Distribuidor', 2), 
('P&G Corporativo', 4), 
('Lidl Minorista', 1), 
('Kraft Multinacional', 3), 
('Costco Retail', 5);

-- Inserción de datos en Proyecciones
INSERT INTO Proyecciones (id_cliente, id_region, fecha_proyeccion, forecast) VALUES 
(1, 1, '2024-01-15', 10000.50), 
(2, 2, '2024-02-10', 20000.75), 
(3, 3, '2024-03-20', 15000.00), 
(4, 4, '2024-04-25', 25000.30), 
(5, 5, '2024-05-05', 30000.60),
(6, 1, '2024-06-15', 12000.40), 
(7, 2, '2024-07-22', 22000.80), 
(8, 3, '2024-08-12', 18000.90), 
(9, 4, '2024-09-30', 17000.20), 
(10, 5, '2024-10-18', 29000.55),
(11, 1, '2024-11-05', 15500.70), 
(12, 2, '2024-12-25', 21000.80), 
(13, 3, '2024-01-10', 19500.60), 
(14, 4, '2024-02-14', 16500.45), 
(15, 5, '2024-03-01', 23000.90);

-- Inserción de datos en Ventas
INSERT INTO Ventas (fecha_venta, cantidad_vendida) VALUES 
('2024-01-15', 9000.00), 
('2024-02-10', 19000.00), 
('2024-03-20', 16000.00), 
('2024-04-25', 24000.00), 
('2024-05-05', 31000.00),
('2024-06-15', 11000.00), 
('2024-07-22', 21000.00), 
('2024-08-12', 17000.00), 
('2024-09-30', 16000.00), 
('2024-10-18', 28000.00),
('2024-11-05', 15000.00), 
('2024-12-25', 20000.00), 
('2024-01-10', 19000.00), 
('2024-02-14', 16000.00), 
('2024-03-01', 22000.00);

-- Inserción de datos en Proyecciones_Ventas
INSERT INTO Proyecciones_Ventas (id_proyeccion, id_venta) VALUES 
(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), 
(6, 6), (7, 7), (8, 8), (9, 9), (10, 10),
(11, 11), (12, 12), (13, 13), (14, 14), (15, 15);

/*Verificación de datos insertados
SELECT * FROM TiposClientes;
SELECT * FROM Regiones;
SELECT * FROM Clientes;
SELECT * FROM Proyecciones;
SELECT * FROM Ventas;
SELECT * FROM Proyecciones_Ventas;

SELECT * FROM vista_clientes_activos;
SELECT * FROM vista_discrepancia_proyeccion;
SELECT * FROM vista_ventas_mensuales_por_region;
SELECT * FROM vista_ventas_por_region;

CALL insertar_nueva_venta (2, "2024-01-15", 10000); 
CALL ordenar_ventas ("fecha_venta", "ASC");

SELECT obtener_discrepancia (2); 
SELECT obtener_total_ventas_cliente (4);

INSERT INTO Proyecciones (id_cliente, id_region, fecha_proyeccion, forecast) VALUES 
(3, 1, '2024-01-15', -10000.50); 

UPDATE Ventas SET cantidad_vendida = 10 WHERE id_venta = 1; */

-- Informes Generados 
# Análisis: Ventas Reales vs Proyecciones por Región

 SELECT 
    r.nombre_region,
    SUM(v.cantidad_vendida) AS ventas_reales,
    SUM(p.forecast) AS proyeccion_ventas,
    (SUM(v.cantidad_vendida) - SUM(p.forecast)) AS diferencia
FROM Proyecciones p
INNER JOIN Proyecciones_Ventas pv ON p.id_proyeccion = pv.id_proyeccion
INNER JOIN Ventas v ON pv.id_venta = v.id_venta
INNER JOIN Regiones r ON p.id_region = r.id_region
GROUP BY r.nombre_region;

# Análisis: Ventas Mensuales por Región

 SELECT 
    MONTH(v.fecha_venta) AS mes,
    r.nombre_region,
    SUM(v.cantidad_vendida) AS total_ventas
FROM Ventas v
INNER JOIN Proyecciones_Ventas pv ON v.id_venta = pv.id_venta
INNER JOIN Proyecciones p ON p.id_proyeccion = pv.id_proyeccion
INNER JOIN Regiones r ON p.id_region = r.id_region
GROUP BY mes, r.nombre_region;

-- Tablas Adicionales Propuestas
-- Tabla Productos
CREATE TABLE Productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre_producto VARCHAR(100) NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL
);

-- Tabla VentasProductos
CREATE TABLE VentasProductos (
   id_venta_producto INT AUTO_INCREMENT PRIMARY KEY,
   id_venta INT NOT NULL,
   id_producto INT NOT NULL,
   cantidad INT NOT NULL,
   precio_unitario DECIMAL(10, 2) NOT NULL,
   FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY (id_producto) REFERENCES Productos(id_producto) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabla Canales de Distribución
CREATE TABLE CanalesDistribucion (
    id_canal INT AUTO_INCREMENT PRIMARY KEY,
    nombre_canal VARCHAR(50) NOT NULL
);

-- Tabla Segmentos de Mercado
CREATE TABLE SegmentosMercado (
    id_segmento INT AUTO_INCREMENT PRIMARY KEY,
    descripcion_segmento VARCHAR(100) NOT NULL
);


