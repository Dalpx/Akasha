<?php
header('Content-Type: application/json');
require_once 'database/DBConnection.php';
require_once 'controllers/productoController.php';
require_once 'controllers/usuarioController.php';
require_once 'controllers/proveedorController.php';
require_once 'controllers/ventaController.php';
require_once 'controllers/compraController.php';
require_once 'middlewares/akashaOrchestrator.php';

try { //Con este bloque try podemos capturar todas las excepciones de cada situación, en lugar de tener varios.
    //Convertimos la URL en un array y la concatenamos de forma que quede en la forma {Header}_{ruta}, para que el switch case pueda obtener la condición.
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
        case 'POST_producto': //Para crear productos nuevos
            $result = productoOrchestrator::addProducto();
            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Producto añadido con éxito"]);
            }
            break;
        case 'PUT_producto': //Para editar productos existentes
            $result = productoOrchestrator::editProducto();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Producto editado con éxito"]);
            }
            break;
        case 'DELETE_producto': //Para borrar productos existentes de forma lógica
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
                echo json_encode(["message" => "Datos recuperados con éxito", "data" => $result]);
            }
            break;
        case 'GET_compra':
            $result = compraventaOrchestrator::getCompra($id, $parts);
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Datos recuperados con éxito", "data" => $result]);
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

        default: //Excepción default de no ser encontrada la ruta
            throw new Exception("Ruta no encontrada", 404);
            break;
    }
} catch (Exception $e) { //Manejo de excepciones que retorna un JSON con detalles

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
} catch (PDOException $e) { //Error genérico para excepciones de PDO
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'codigo' => 500,
        'mensaje' => 'Error interno en la base de datos'
    ]);
}
