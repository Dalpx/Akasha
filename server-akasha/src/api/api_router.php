<?php
header('Content-Type: application/json');
require_once 'database/DBConnection.php';
require_once 'controllers/productoController.php';
require_once 'controllers/usuarioController.php';
require_once 'controllers/proveedorController.php';
require_once 'controllers/ventaController.php';
require_once 'controllers/compraController.php';
require_once 'controllers/stockController.php';
require_once 'controllers/clienteController.php';
require_once 'controllers/ubicacionController.php';
require_once 'controllers/categoriaController.php';
require_once 'controllers/movimientoController.php';
require_once 'controllers/comprobanteController.php';
require_once 'middlewares/akashaOrchestrator.php';

try {
    $parts = explode('/', trim($uri, '/'));
    $action = $httpMethod . '_' . $parts['3']; // En el servidor debe ser 0 en lugar de 3
    $id = (int)end($parts);

    switch ($action) {
        case 'POST_login':
            $result = usuarioOrchestrator::loginHandler();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Login exitoso", "permisos" => $result]);
            }
            break;
        case 'GET_producto':
            $result = productoOrchestrator::getProducto($id, $parts);
            http_response_code(200);
            echo json_encode($result);
            break;
        case 'POST_producto':
            $result = productoOrchestrator::addProducto();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Producto añadido con éxito"]);
            }
            break;
        case 'PUT_producto':
            $result = productoOrchestrator::editProducto();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Producto editado con éxito"]);
            }
            break;
        case 'DELETE_producto':
            $result = productoOrchestrator::deleteProducto();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Producto eliminado con éxito"]);
            }
            break;
        case 'GET_proveedor':
            $result = proveedorOrchestrator::getProveedor($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_proveedor':
            $result = proveedorOrchestrator::addProveedor();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Proveedor añadido con éxito"]);
            }
            break;
        case 'PUT_proveedor':
            $result = proveedorOrchestrator::updateProveedor();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Proveedor editado con éxito"]);
            }
            break;
        case 'DELETE_proveedor':
            $result = proveedorOrchestrator::deleteProveedor();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Proveedor eliminado con éxito"]);
            }
            break;
        case 'GET_usuario':
            $result = usuarioOrchestrator::getUsuario($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_usuario':
            $result = usuarioOrchestrator::createUsuario();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Usuario añadido con éxito"]);
            }
            break;
        case 'PUT_usuario':
            $result = usuarioOrchestrator::updateUsuario();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Usuario editado con éxito"]);
            }
            break;
        case 'DELETE_usuario':
            $result = usuarioOrchestrator::deleteUsuario();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Usuario eliminado con éxito"]);
            }
            break;
        case 'GET_venta':
            $result = compraventaOrchestrator::getVenta($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'GET_compra':
            $result = compraventaOrchestrator::getCompra($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_venta':
            $result = compraventaOrchestrator::addVenta();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Registro de venta añadido con éxito"]);
            }
            break;
        case 'POST_compra':
            $result = compraventaOrchestrator::addCompra();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Registro de compra añadido con éxito"]);
            }
            break;
        case 'GET_stock':
            $result = stockOrchestrator::getStockProducto($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_stock':
            $result = stockOrchestrator::addStock();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Stock añadido con éxito"]);
            }
            break;
        case 'GET_cliente':
            $result = clienteOrchestrator::getCliente($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_cliente':
            $result = clienteOrchestrator::addCliente();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Cliente añadido con éxito"]);
            }
            break;
        case 'PUT_cliente':
            $result = clienteOrchestrator::updateCliente();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Cliente editado con éxito"]);
            }
            break;
        case 'DELETE_cliente':
            $result = clienteOrchestrator::deleteCliente();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Cliente eliminado con éxito"]);
            }
            break;
        case 'GET_ubicacion':
            $result = ubicacionOrchestrator::getUbicacion($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_ubicacion':
            $result = ubicacionOrchestrator::addUbicacion();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Ubicación añadida con éxito"]);
            }
            break;
        case 'PUT_ubicacion':
            $result = ubicacionOrchestrator::updateUbicacion();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Ubicación editada con éxito"]);
            }
            break;
        case 'DELETE_ubicacion':
            $result = ubicacionOrchestrator::deleteUbicacion();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Ubicación eliminada con éxito"]);
            }
            break;
        case 'GET_categoria':
            $result = categoriaOrchestrator::getCategoria($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
            break;
        case 'POST_categoria':
            $result = categoriaOrchestrator::addCategoria();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Categoría añadida con éxito"]);
            }
            break;
        case 'PUT_categoria':
            $result = categoriaOrchestrator::updateCategoria();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Categoría editada con éxito"]);
            }
            break;
        case 'DELETE_categoria':
            $result = categoriaOrchestrator::deleteCategoria();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Categoría eliminada con éxito"]);
            }
        case 'GET_movimiento':
            $result = movimientoOrchestrator::getMovimientos($id, $parts);
            if ($result) {
                echo json_encode($result);
            }
            break;
        case 'POST_movimiento':
            $result = movimientoOrchestrator::addMovimiento();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Movimiendo añadido con éxito"]);
            }
            break;
        case 'GET_comprobante':
            $result = comprobanteOrchestrator::getComprobante();
            if ($result) {
                echo json_encode($result);
            }
            break;
        default:
            throw new Exception("Ruta no encontrada", 404);
    }
} catch (Exception $e) {
    if (is_numeric($e->getCode())) {
        $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500;

        http_response_code($status);
        echo json_encode([
            'error' => true,
            'codigo' => $status,
            'mensaje' => $e->getMessage()
        ]);
    } else {
        echo $e;
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'codigo' => 500,
        'message' => 'Error interno en la base de datos'
    ]);
}
