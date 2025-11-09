<?php
header('Content-Type: application/json');

$content_type = isset($_SERVER['CONTENT_TYPE']) ? trim($_SERVER['CONTENT_TYPE']) : '';

if ($content_type == 'application/json' && $_SERVER['REQUEST_METHOD'] == 'PUT') {
    //Del JSON extraemos los datos (que deben ser encriptados, pero no está añadido todavía)
    $body = json_decode(file_get_contents('php://input'), true);
    $nom = $body['nom_prod'];
    $sku = $body['sku_prod'];
    $desc = $body['desc_prod'];
    $pre_c = floatval($body['pre_cost']);
    $pre_v = floatval($body['pre_vent']);
    $id_p = $body['id_prod'];

    try {
        //Creamos la instancia de la conexión con la DB y ejecutamos las transacciones
        $con = DBConnection::getInstance();
        $pdo = $con->getPDO();
        $query = "UPDATE producto SET nombre=:nomprod, sku=:sku, descripcion=:descr, precio_costo=:pre_c, 
        precio_venta=:pre_v WHERE id_producto = :id_p";
        $stmt = $pdo->prepare($query);
        $result = $stmt->execute([':nomprod' => $nom, ':sku' => $sku, ':descr' => $desc, ':pre_c' => $pre_c, 'pre_v' => $pre_v, ':id_p' => $id_p]);
        //Mensajes de respuesta
        if ($result) {
            http_response_code(200);
            echo json_encode(['message' => "Transacción completada"]);
        } else {
            http_response_code(404);
            echo json_encode(['error' => "El producto con los datos especificados no fue encontrado"]);
        }
    } catch (PDOException $e) {
        echo $e;
    }
}
