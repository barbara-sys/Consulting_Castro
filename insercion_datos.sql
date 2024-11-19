
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

-- Verificación de datos insertados
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

UPDATE Ventas SET cantidad_vendida = 10 WHERE id_venta = 1; 

