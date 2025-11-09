<?php

header('Content-Type: application/json');

if (defined('ROUTE_PARAMS') && !empty('ROUTE_PARAMS')) {

    $params = ROUTE_PARAMS;
    $id = $params[0] ?? null;

    $con = DBConnection::getInstance();
    $pdo = $con->getPDO();

    try {

        if ($id) {
            $query = "SELECT producto.nombre, producto.sku, producto.descripcion, producto.precio_costo, producto.precio_venta, proveedor.nombre 
        AS nom_prov FROM producto INNER JOIN proveedor on producto.id_proveedor=proveedor.id_proveedor WHERE producto.id_producto = :id";
            $stmt = $pdo->prepare($query);
            $result = $stmt->execute([':id' => $id]);
            $result = $stmt->fetch(pdo::FETCH_ASSOC);

            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
        }else{

            $query = "SELECT producto.nombre, producto.sku, producto.descripcion, producto.precio_costo, producto.precio_venta, proveedor.nombre 
        AS nom_prov FROM producto INNER JOIN proveedor on producto.id_proveedor=proveedor.id_proveedor";
            $stmt = $pdo->prepare($query);
            $result = $stmt->execute();
            $result = $stmt->fetchAll(pdo::FETCH_ASSOC);

            if ($result) {
                http_response_code(200);
                echo json_encode($result);
            }
        }


    }catch (PDOException $e) {
        http_response_code(500);
    }

}