<?php
header('Content-Type: application-json');
require_once 'database/DBConnection.php';
require_once 'controllers/productoController.php';
require_once 'controllers/loginController.php';
require_once 'middlewares/akashaOrchestrator.php';

try { //Con este bloque try podemos capturar todas las excepciones de cada situación, en lugar de tener varios.

    //Convertimos la URL en un array y la concatenamos de forma que quede en la forma {Header}_{ruta}, para que el switch case pueda obtener la condición.
    $parts = explode('/', trim($uri, '/'));
    $action = $httpMethod . '_' . $parts['3'];
    $id = (int)end($parts);

    switch ($action) {
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
        case 'POST_login':
            $result = loginOrchestrator::loginHandler();
            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Login exitoso"]);
            }
            break;
        default: //Excepción default de no ser encontrada la ruta
            throw new Exception("Ruta no encontrada", 404);
            break;
    }
} catch (Exception $e) { //Manejo de excepciones que retorna un JSON con detalles
    $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500;

    http_response_code($status);
    echo json_encode([
        'error' => true,
        'codigo' => $status,
        'mensaje' => $e->getMessage()
    ]);
} catch (PDOException $e) { //Error genérico para excepciones de PDO
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'codigo' => 500,
        'mensaje' => 'Error interno en la base de datos'
    ]);
}
