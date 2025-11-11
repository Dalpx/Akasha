<?php
header('Content-Type: application-json');
require_once 'database/DBConnection.php';
require_once 'controllers/productoController.php';
try {//Con este bloque try podemos capturar todas las excepciones de cada situación, en lugar de tener varios.

    //Convertimos la URL en un array y la concatenamos de forma que quede en la forma {Header}_{ruta}, para que el switch case pueda obtener la condición.
    $parts = explode('/', trim($uri, '/'));
    $action = $httpMethod . '_' . $parts['3'];

    switch ($action) {
        case 'GET_producto': //Para el caso de obtener producto, tenemos 'GET_producto'
            //Pequeña condición la cual nos deja saber si el programa pidio un id o no, si es un valor numérico presente en la URI, lo guarda
            //sino, se asigna null, que devuelve todas las entradas.
            $id = is_numeric(end($parts)) ? (int)end($parts) : null;
            $con = DBConnection::getInstance()->getPDO(); //Instancia de la DB y obtención del PDO
            $controller = new productoController($con); //productoController recibe el PDO como parámetro al ser instanciado
            $result = $controller->getProducto($id); //Método para obtener producto que puede recibir una id numérica o null
            echo json_encode($result); //Retornar resultado
            break;
        case 'POST_producto': //Para crear productos nuevos
            $con = DBConnection::getInstance()->getPDO();
            $controller = new productoController($con);
            $result = $controller->addProducto();

            if ($result) {
                http_response_code(201);
                echo json_encode(["message" => "Producto añadido con éxito"]);
            }
            break;
        case 'PUT_producto': //Para editar productos existentes
            $con = DBConnection::getInstance()->getPDO();
            $controller = new productoController($con);
            $result = $controller->updateProducto();

            if($result){
                http_response_code(200);
                echo json_encode(["message" => "Producto editado con éxito"]);
            }

            break;
        case 'DELETE_producto': //Para borrar productos existentes de forma lógica
            $con = DBConnection::getInstance()->getPDO();
            $controller = new productoController($con);
            $result = $controller->deleteProducto();

            if ($result) {
                http_response_code(200);
                echo json_encode(["message" => "Producto eliminado con éxito"]);
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
