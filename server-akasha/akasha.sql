-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 05-12-2025 a las 08:18:50
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `akasha`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` varchar(45) NOT NULL,
  `activo` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`id_categoria`, `nombre_categoria`, `activo`) VALUES
(1, 'Herramientas manuales', 1),
(2, 'Herramientas eléctricas', 1),
(3, 'Tornillería y fijaciones', 1),
(4, 'Electricidad', 1),
(5, 'Plomería', 1),
(6, 'Pinturas y accesorios', 1),
(7, 'Materiales de construcción', 1),
(8, 'Adhesivos y selladores', 1),
(9, 'Seguridad industrial', 1),
(10, 'Bombas y equipos', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `id_cliente` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `tipo_documento` int(11) NOT NULL,
  `nro_documento` varchar(20) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `activo` tinyint(4) DEFAULT 1,
  `apellido` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`id_cliente`, `nombre`, `tipo_documento`, `nro_documento`, `telefono`, `email`, `direccion`, `activo`, `apellido`) VALUES
(1, 'José', 1, 'V-12345678', '04120000001', 'jose.perez@email.com', 'Urb. Centro, Calle 1', 1, 'Pérez'),
(2, 'María', 1, 'V-87654321', '04240000002', 'maria.g@email.com', 'Urb. Norte, Av. 2', 1, 'González'),
(3, 'Luis', 1, 'V-19283746', '04140000003', 'luis.r@email.com', 'Urb. Este, Calle 3', 1, 'Rodríguez'),
(4, 'Ana', 1, 'V-56473829', '04160000004', 'ana.s@email.com', 'Urb. Oeste, Av. 4', 1, 'Suárez'),
(5, 'Carlos', 1, 'V-10293847', '04260000005', 'carlos.m@email.com', 'Sector Industrial, Calle 5', 1, 'Méndez'),
(6, 'Constructora', 3, 'J-30111222-3', '04120000006', 'compras@horizonte.com', 'Zona Industrial Sur', 1, 'Horizonte C.A.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compra`
--

CREATE TABLE `compra` (
  `id_compra` int(11) NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `nro_comprobante` varchar(45) NOT NULL,
  `id_tipo_comprobante` int(11) NOT NULL,
  `id_proveedor` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `impuesto` decimal(10,2) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `compra`
--

INSERT INTO `compra` (`id_compra`, `fecha_hora`, `nro_comprobante`, `id_tipo_comprobante`, `id_proveedor`, `id_usuario`, `subtotal`, `impuesto`, `total`, `estado`) VALUES
(1, '2025-11-25 10:00:00', 'C-20251125-0001', 2, 1, 3, 430.00, 90.30, 520.30, 1),
(2, '2025-11-26 15:30:00', 'C-20251126-0002', 2, 2, 3, 340.00, 71.40, 411.40, 1),
(3, '2025-11-27 08:50:00', 'C-20251127-0003', 3, 3, 3, 1160.00, 243.60, 1403.60, 1),
(4, '2025-11-28 12:10:00', 'C-20251128-0004', 2, 4, 3, 436.00, 91.56, 527.56, 1),
(5, '2025-11-29 17:05:00', 'C-20251129-0005', 4, 5, 3, 345.00, 72.45, 417.45, 1),
(6, '2025-12-05 03:01:51', 'FC-PROV-811100891', 1, 1, 1, 6.50, 1.04, 7.54, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id_detalle_compra` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_compra`
--

INSERT INTO `detalle_compra` (`id_detalle_compra`, `id_compra`, `id_producto`, `cantidad`, `precio_unitario`, `subtotal`) VALUES
(1, 1, 1, 10, 6.50, 65.00),
(2, 1, 4, 5, 55.00, 275.00),
(3, 1, 7, 50, 1.80, 90.00),
(4, 2, 9, 5, 28.00, 140.00),
(5, 2, 10, 100, 0.90, 90.00),
(6, 2, 11, 100, 1.10, 110.00),
(7, 3, 17, 100, 6.80, 680.00),
(8, 3, 18, 100, 2.40, 240.00),
(9, 3, 15, 20, 12.00, 240.00),
(10, 4, 12, 80, 3.20, 256.00),
(11, 4, 13, 100, 0.45, 45.00),
(12, 4, 14, 30, 4.50, 135.00),
(13, 5, 21, 100, 0.60, 60.00),
(14, 5, 22, 20, 6.00, 120.00),
(15, 5, 24, 30, 5.50, 165.00),
(16, 6, 1, 1, 6.50, 6.50);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id_detalle_venta` int(11) NOT NULL,
  `id_venta` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `descuento_porcentaje` decimal(5,2) DEFAULT 0.00,
  `subtotal` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_venta`
--

INSERT INTO `detalle_venta` (`id_detalle_venta`, `id_venta`, `id_producto`, `cantidad`, `precio_unitario`, `descuento_porcentaje`, `subtotal`) VALUES
(1, 1, 4, 1, 99.00, 0.00, 99.00),
(2, 1, 1, 2, 12.99, 0.00, 25.98),
(3, 2, 17, 10, 9.80, 0.00, 98.00),
(4, 2, 18, 10, 3.90, 0.00, 39.00),
(5, 2, 15, 5, 22.00, 5.00, 104.50),
(6, 3, 9, 2, 49.00, 0.00, 98.00),
(7, 3, 10, 10, 1.80, 0.00, 18.00),
(8, 3, 11, 10, 2.20, 0.00, 22.00),
(9, 4, 12, 6, 6.50, 0.00, 39.00),
(10, 4, 13, 10, 1.10, 0.00, 11.00),
(11, 4, 14, 2, 9.50, 0.00, 19.00),
(12, 5, 22, 5, 12.00, 0.00, 60.00),
(13, 5, 21, 10, 1.50, 0.00, 15.00),
(14, 5, 24, 2, 11.00, 0.00, 22.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimiento_inventario`
--

CREATE TABLE `movimiento_inventario` (
  `id_movimiento` int(11) NOT NULL,
  `tipo_movimiento` tinyint(4) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `fecha_hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `descripcion` varchar(255) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `id_proveedor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `movimiento_inventario`
--

INSERT INTO `movimiento_inventario` (`id_movimiento`, `tipo_movimiento`, `cantidad`, `fecha_hora`, `descripcion`, `id_producto`, `id_usuario`, `id_proveedor`) VALUES
(1, 1, 10, '2025-12-05 06:00:25', 'Ingreso por compra inicial', 1, 3, 1),
(2, 1, 5, '2025-12-05 06:00:25', 'Ingreso por compra inicial', 4, 3, 1),
(3, 1, 50, '2025-12-05 06:00:25', 'Ingreso por compra inicial', 7, 3, 1),
(4, 1, 5, '2025-12-05 06:00:25', 'Ingreso por compra inicial', 9, 3, 2),
(5, 1, 100, '2025-12-05 06:00:25', 'Ingreso por compra inicial', 17, 3, 3),
(6, 2, 1, '2025-12-05 06:00:25', 'Salida por venta mostrador', 4, 2, NULL),
(7, 2, 10, '2025-12-05 06:00:25', 'Salida por venta materiales', 17, 2, NULL),
(8, 2, 5, '2025-12-05 06:00:25', 'Salida por venta seguridad', 22, 2, NULL),
(10, 1, 50, '2025-12-05 06:04:51', 'Recepción de nuevo lote de tornillos', 1, 1, 4),
(11, 2, 50, '2025-12-05 06:05:16', 'Recepción de nuevo lote de tornillos', 1, 1, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `id_producto` int(11) NOT NULL,
  `nombre` varchar(45) NOT NULL,
  `sku` varchar(45) NOT NULL,
  `descripcion` text NOT NULL,
  `precio_costo` double NOT NULL,
  `precio_venta` double NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `id_categoria` int(11) DEFAULT NULL,
  `activo` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`id_producto`, `nombre`, `sku`, `descripcion`, `precio_costo`, `precio_venta`, `id_proveedor`, `id_categoria`, `activo`) VALUES
(1, 'Martillo carpintero 16oz', 'HM-016OZ', 'Mango ergonómico, cabeza de acero templado', 6.5, 12.99, 1, 1, 1),
(2, 'Destornillador Phillips #2', 'DST-PH2', 'Punta imantada, mango antideslizante', 2.1, 4.5, 1, 1, 1),
(3, 'Juego llaves combinadas 8-19mm', 'LLC-SET-8-19', 'Acero cromo vanadio, 12 piezas', 18, 32, 1, 1, 1),
(4, 'Taladro percutor 18V', 'TLD-18V', 'Inalámbrico, incluye batería y cargador', 55, 99, 1, 2, 1),
(5, 'Amoladora angular 4 1/2\"', 'AMO-4.5', 'Motor 850W, guarda de seguridad', 40, 79, 1, 2, 1),
(6, 'Sierra circular 7 1/4\"', 'SRC-7.25', 'Motor 1400W, guía de corte', 70, 129, 1, 2, 1),
(7, 'Tornillos madera 1 1/2\" (caja 100u)', 'TOR-MAD-1.5', 'Acero zincado, rosca gruesa', 1.8, 3.5, 1, 3, 1),
(8, 'Tarugos nylon 8mm (bolsa 50u)', 'TAR-NYL-8', 'Alta expansión, uso general', 1.2, 2.4, 1, 3, 1),
(9, 'Cable THHN 12 AWG (rollo 100m)', 'CAB-THHN-12', 'Aislación 600V, uso residencial', 28, 49, 2, 4, 1),
(10, 'Interruptor sencillo', 'INT-SEN', 'Formato estándar, 10A', 0.9, 1.8, 2, 4, 1),
(11, 'Tomacorriente doble', 'TOM-DOB', 'Formato estándar, 15A', 1.1, 2.2, 2, 4, 1),
(12, 'Tubo PVC 1\" 3m', 'PVC-TUB-1', 'Presión estándar, blanco', 3.2, 6.5, 4, 5, 1),
(13, 'Codo PVC 1\"', 'PVC-COD-1', 'Conexión 90°, alta resistencia', 0.45, 1.1, 4, 5, 1),
(14, 'Llave de paso 1\"', 'LLP-1', 'Cuerpo metálico, cierre rápido', 4.5, 9.5, 4, 5, 1),
(15, 'Pintura látex blanca 4L', 'PNT-LAT-B4', 'Interior/exterior, alto rendimiento', 12, 22, 3, 6, 1),
(16, 'Rodillo 9\"', 'ROD-9', 'Felpón medio, para látex', 1.9, 4, 3, 6, 1),
(17, 'Cemento gris 50kg', 'CEM-GRI-50', 'Uso estructural general', 6.8, 9.8, 3, 7, 1),
(18, 'Arena lavada (saco 40kg)', 'ARE-LAV-40', 'Agregado fino para obra', 2.4, 3.9, 3, 7, 1),
(19, 'Sellador silicona transparente 280ml', 'SIL-TR-280', 'Uso sanitario y vidrio', 1.5, 3.2, 1, 8, 1),
(20, 'Adhesivo epóxico 2 componentes', 'EPX-2C', 'Alta resistencia, secado rápido', 3.8, 7.5, 1, 8, 1),
(21, 'Guantes de nitrilo (par)', 'GUA-NIT', 'Protección ligera para trabajo general', 0.6, 1.5, 5, 9, 1),
(22, 'Casco de seguridad', 'CAS-SEG', 'Ajuste ratchet, norma industrial', 6, 12, 5, 9, 1),
(23, 'Bomba de agua periférica 1HP', 'BOM-PER-1HP', 'Ideal para uso doméstico', 75, 135, 1, 10, 1),
(24, 'Linterna recargable LED', 'LIN-REC-LED', 'Batería 18650, cargador USB', 5.5, 11, 5, 9, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `id_proveedor` int(11) NOT NULL,
  `nombre` varchar(45) NOT NULL,
  `telefono` varchar(45) NOT NULL,
  `correo` varchar(12) DEFAULT NULL,
  `direccion` tinytext DEFAULT NULL,
  `activo` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`id_proveedor`, `nombre`, `telefono`, `correo`, `direccion`, `activo`) VALUES
(1, 'FerreDistribuciones Andina', '02120001111', 'ventas@andin', 'Av. Principal, Zona Industrial', 1),
(2, 'ElectroSuministros Centro', '02120002222', 'contacto@ele', 'Calle 10, Sector Electricidad', 1),
(3, 'ConcreMix & Agregados', '02120003333', 'pedidos@conc', 'Carretera Nacional Km 12', 1),
(4, 'PlastiPVC Import', '02120004444', 'info@plastip', 'Zona Franca, Galpón 3', 1),
(5, 'SafePro Industrial', '02120005555', 'comercial@sa', 'Av. Seguridad, Edif. 2', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stock`
--

CREATE TABLE `stock` (
  `id_producto` int(11) NOT NULL,
  `id_ubicacion` int(11) NOT NULL,
  `cantidad_actual` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `stock`
--

INSERT INTO `stock` (`id_producto`, `id_ubicacion`, `cantidad_actual`) VALUES
(1, 1, 51),
(2, 1, 80),
(3, 1, 20),
(4, 1, 15),
(5, 1, 10),
(6, 1, 8),
(7, 1, 200),
(8, 1, 150),
(9, 3, 12),
(10, 3, 300),
(11, 3, 250),
(12, 3, 120),
(13, 3, 500),
(14, 3, 60),
(15, 2, 40),
(16, 1, 100),
(17, 2, 200),
(18, 2, 180),
(19, 1, 90),
(20, 1, 70),
(21, 4, 200),
(22, 4, 40),
(23, 3, 6),
(24, 4, 50);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_documento`
--

CREATE TABLE `tipo_documento` (
  `id_tipo_documento` int(11) NOT NULL,
  `nombre_tipo_documento` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_documento`
--

INSERT INTO `tipo_documento` (`id_tipo_documento`, `nombre_tipo_documento`) VALUES
(1, 'Cédula'),
(2, 'Pasaporte'),
(3, 'RIF');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_pago`
--

CREATE TABLE `tipo_pago` (
  `id_tipo_comprobante` int(11) NOT NULL,
  `nombre` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_pago`
--

INSERT INTO `tipo_pago` (`id_tipo_comprobante`, `nombre`) VALUES
(1, 'Tarjeta de Crédito'),
(2, 'Transferencia Bancaria'),
(3, 'Pago Móvil'),
(4, 'Efectivo'),
(5, 'Divisa');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_usuario`
--

CREATE TABLE `tipo_usuario` (
  `id_tipo_usuario` int(11) NOT NULL,
  `nombre_tipo_usuario` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_usuario`
--

INSERT INTO `tipo_usuario` (`id_tipo_usuario`, `nombre_tipo_usuario`) VALUES
(1, 'super'),
(2, 'administrador'),
(3, 'almacen'),
(4, 'vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ubicacion`
--

CREATE TABLE `ubicacion` (
  `id_ubicacion` int(11) NOT NULL,
  `nombre_almacen` varchar(45) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ubicacion`
--

INSERT INTO `ubicacion` (`id_ubicacion`, `nombre_almacen`, `descripcion`, `activo`) VALUES
(1, 'Almacén Principal', 'Zona de herramientas y tornillería', 1),
(2, 'Almacén Principal', 'Zona de materiales de construcción y pintura', 1),
(3, 'Almacén Principal', 'Zona de electricidad y plomería', 1),
(4, 'Depósito Secundario', 'Seguridad, misceláneos y equipos especiales', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(45) NOT NULL,
  `clave_hash` varchar(45) NOT NULL,
  `nombre_completo` varchar(45) DEFAULT NULL,
  `email` varchar(45) DEFAULT NULL,
  `id_tipo_usuario` int(11) DEFAULT NULL,
  `activo` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id_usuario`, `nombre_usuario`, `clave_hash`, `nombre_completo`, `email`, `id_tipo_usuario`, `activo`) VALUES
(1, 'admin', 'admin', 'Administrador del Sistema', 'admin@akasha.com', 1, 1),
(2, 'caja01', '123456', 'Operador de Caja', 'caja01@akasha.com', 2, 1),
(3, 'almacen01', '123456', 'Encargado de Almacén', 'almacen01@akasha.com', 3, 1),
(4, 'vendedor01', '123456', 'Vendedor Mostrador', 'vendedor01@akasha.com', 4, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `id_venta` int(11) NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `nro_comprobante` varchar(45) NOT NULL,
  `id_tipo_comprobante` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `impuesto` decimal(10,2) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `venta`
--

INSERT INTO `venta` (`id_venta`, `fecha_hora`, `nro_comprobante`, `id_tipo_comprobante`, `id_cliente`, `id_usuario`, `subtotal`, `impuesto`, `total`, `estado`) VALUES
(1, '2025-12-01 11:15:00', 'VTA-20251201-0001', 4, 1, 2, 124.98, 26.25, 151.23, 1),
(2, '2025-12-02 16:40:00', 'VTA-20251202-0002', 2, 2, 2, 241.50, 50.72, 292.22, 1),
(3, '2025-12-03 09:05:00', 'VTA-20251203-0003', 3, 3, 2, 138.00, 28.98, 166.98, 1),
(4, '2025-12-04 13:20:00', 'VTA-20251204-0004', 4, 4, 2, 69.00, 14.49, 83.49, 1),
(5, '2025-12-05 10:10:00', 'VTA-20251205-0005', 1, 5, 2, 97.00, 20.37, 117.37, 1);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id_cliente`),
  ADD KEY `fk_cliente_tipo_documento` (`tipo_documento`);

--
-- Indices de la tabla `compra`
--
ALTER TABLE `compra`
  ADD PRIMARY KEY (`id_compra`),
  ADD KEY `id_proveedor` (`id_proveedor`),
  ADD KEY `id_tipo_comprobante` (`id_tipo_comprobante`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id_detalle_compra`),
  ADD KEY `id_compra` (`id_compra`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD PRIMARY KEY (`id_detalle_venta`),
  ADD KEY `id_venta` (`id_venta`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `movimiento_inventario`
--
ALTER TABLE `movimiento_inventario`
  ADD PRIMARY KEY (`id_movimiento`),
  ADD KEY `id_producto` (`id_producto`),
  ADD KEY `id_usuario` (`id_usuario`),
  ADD KEY `id_proveedor` (`id_proveedor`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id_producto`),
  ADD UNIQUE KEY `UQ_producto_sku` (`sku`),
  ADD KEY `id_proveedor` (`id_proveedor`),
  ADD KEY `id_categoria` (`id_categoria`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`id_proveedor`);

--
-- Indices de la tabla `stock`
--
ALTER TABLE `stock`
  ADD PRIMARY KEY (`id_producto`,`id_ubicacion`),
  ADD KEY `id_ubicacion` (`id_ubicacion`);

--
-- Indices de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  ADD PRIMARY KEY (`id_tipo_documento`);

--
-- Indices de la tabla `tipo_pago`
--
ALTER TABLE `tipo_pago`
  ADD PRIMARY KEY (`id_tipo_comprobante`);

--
-- Indices de la tabla `tipo_usuario`
--
ALTER TABLE `tipo_usuario`
  ADD PRIMARY KEY (`id_tipo_usuario`);

--
-- Indices de la tabla `ubicacion`
--
ALTER TABLE `ubicacion`
  ADD PRIMARY KEY (`id_ubicacion`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `nombre_usuario` (`nombre_usuario`),
  ADD KEY `id_tipo_usuario` (`id_tipo_usuario`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_tipo_comprobante` (`id_tipo_comprobante`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `compra`
--
ALTER TABLE `compra`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id_detalle_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  MODIFY `id_detalle_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `movimiento_inventario`
--
ALTER TABLE `movimiento_inventario`
  MODIFY `id_movimiento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `id_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  MODIFY `id_tipo_documento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `tipo_pago`
--
ALTER TABLE `tipo_pago`
  MODIFY `id_tipo_comprobante` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `tipo_usuario`
--
ALTER TABLE `tipo_usuario`
  MODIFY `id_tipo_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `ubicacion`
--
ALTER TABLE `ubicacion`
  MODIFY `id_ubicacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `fk_cliente_tipo_documento` FOREIGN KEY (`tipo_documento`) REFERENCES `tipo_documento` (`id_tipo_documento`);

--
-- Filtros para la tabla `compra`
--
ALTER TABLE `compra`
  ADD CONSTRAINT `compra_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id_proveedor`),
  ADD CONSTRAINT `compra_ibfk_2` FOREIGN KEY (`id_tipo_comprobante`) REFERENCES `tipo_pago` (`id_tipo_comprobante`),
  ADD CONSTRAINT `compra_ibfk_3` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `detalle_compra_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compra` (`id_compra`),
  ADD CONSTRAINT `detalle_compra_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD CONSTRAINT `detalle_venta_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`),
  ADD CONSTRAINT `detalle_venta_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `movimiento_inventario`
--
ALTER TABLE `movimiento_inventario`
  ADD CONSTRAINT `movimiento_inventario_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`),
  ADD CONSTRAINT `movimiento_inventario_ibfk_2` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  ADD CONSTRAINT `movimiento_inventario_ibfk_3` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id_proveedor`);

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `producto_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id_proveedor`),
  ADD CONSTRAINT `producto_ibfk_2` FOREIGN KEY (`id_categoria`) REFERENCES `categoria` (`id_categoria`);

--
-- Filtros para la tabla `stock`
--
ALTER TABLE `stock`
  ADD CONSTRAINT `stock_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`) ON DELETE CASCADE,
  ADD CONSTRAINT `stock_ibfk_2` FOREIGN KEY (`id_ubicacion`) REFERENCES `ubicacion` (`id_ubicacion`);

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`id_tipo_usuario`) REFERENCES `tipo_usuario` (`id_tipo_usuario`);

--
-- Filtros para la tabla `venta`
--
ALTER TABLE `venta`
  ADD CONSTRAINT `venta_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`),
  ADD CONSTRAINT `venta_ibfk_2` FOREIGN KEY (`id_tipo_comprobante`) REFERENCES `tipo_pago` (`id_tipo_comprobante`),
  ADD CONSTRAINT `venta_ibfk_3` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
