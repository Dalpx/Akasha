<?php

header('Content-Type: application/json');
$content_type = isset($_SERVER['CONTENT_TYPE']) ? trim($_SERVER['CONTENT_TYPE']) : '';

if ($content_type == 'application/json' && $_SERVER['REQUEST_METHOD'] == 'POST') {

$body = json_decode(file_get_contents('php://input'), true);
    
    //Del JSON extraemos los datos (que deben ser encriptados, pero no está añadido todavía)
    $nom = $body['nom_prod'];
    $sku = $body['sku_prod'];
    $desc = $body['desc_prod'];
    $pre_c = floatval($body['pre_cost']);
    $pre_v = floatval($body['pre_vent']);
    $id_p = $body['id_prov'];

    try {
        //Creamos una instancia de la conexión a la base de datos y obtenemos el PDO, que nos permite hacer las transacciones
        //Aquí también manejamos la lógica de la misma
        $con = DBConnection::getInstance();
        $pdo = $con->getPDO();
        $query = "INSERT INTO producto (nombre, sku, descripcion, precio_costo, precio_venta, id_proveedor) 
            VALUES (:nomprod, :sku, :descr, :precost, :pre_vent, :id_prov)";
        $stmt = $pdo->prepare($query);
        $result = $stmt->execute([
            ':nomprod' => $nom,
            ':sku' => $sku,
            ':descr' => $desc,
            ':precost' => $pre_c,
            ':pre_vent' => $pre_v,
            ':id_prov' => $id_p
        ]);
        //Mensajes de respuesta
        if ($result) {
            http_response_code(200);
            echo json_encode(["message" => "Transaccion completada"]);
            exit;
        } else {
            http_response_code(500);
        }
    } catch (PDOException $e) {
        echo $e;
    }
}
