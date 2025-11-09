<?php

header('Content-Type: application/json');

if (defined('ROUTE_PARAMS') && !empty('ROUTE_PARAMS')) {
    //Obtenemos la ID de los parámetros de ruta obtenidos en index.php
    $params = ROUTE_PARAMS;
    $id = $params[0] ?? null;

    
    try {
        //Creamos una instancia de la conexión a la base de datos y obtenemos el PDO, que nos permite hacer las transacciones
        $con = DBConnection::getInstance();
        $pdo = $con->getPDO();
        //Lógica de transacción, si tenemos ID, buscamos la entrada que coincida con dicha ID
        if ($id) {
            $query = "SELECT producto.nombre, producto.sku, producto.descripcion, producto.precio_costo, producto.precio_venta, proveedor.nombre 
        AS nom_prov FROM producto INNER JOIN proveedor on producto.id_proveedor=proveedor.id_proveedor WHERE producto.id_producto = :id";
            $stmt = $pdo->prepare($query);
            $result = $stmt->execute([':id' => $id]);
            $result = $stmt->fetch(pdo::FETCH_ASSOC);
            //Mensajes de respuesta
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
        }else{
        //De no ser el caso, obtenemos todos los datos de la tabla (como sería en el caso de obtención al iniciar sesión en el programa)    
            $query = "SELECT producto.nombre, producto.sku, producto.descripcion, producto.precio_costo, producto.precio_venta, proveedor.nombre 
        AS nom_prov FROM producto INNER JOIN proveedor on producto.id_proveedor=proveedor.id_proveedor";
            $stmt = $pdo->prepare($query);
            $result = $stmt->execute();
            $result = $stmt->fetchAll(pdo::FETCH_ASSOC);
            //Mensajes de respuesta
            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
        }


    }catch (PDOException $e) {
        http_response_code(500);
    }

}