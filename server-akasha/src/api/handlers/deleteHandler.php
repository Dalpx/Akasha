<?php 
header('Content-Type: application/json');

$content_type = isset($_SERVER['CONTENT_TYPE']) ? trim($_SERVER['CONTENT_TYPE']) : '';

if ($content_type == 'application/json' && $_SERVER['REQUEST_METHOD'] == 'DELETE') {

    $body = json_decode(file_get_contents("php://input"), true);
    $id = $body['del_id'];

    try{
        $con = DBConnection::getInstance();
        $pdo = $con->getPDO();
        $query = "UPDATE producto SET activo=0 WHERE id_producto=:id";
        $stmt = $pdo->prepare($query);
        $result = $stmt->execute([':id' => $id]);

        $rows_af= $stmt->rowCount();

        if($rows_af > 0){
            http_response_code(200);
            echo json_encode(['message' => "Se ha eliminado el producto correctamente"]);
        }else if ($rows_af == 0){
            http_response_code(404);
            echo json_encode(['warning' => "La operación se hizo con éxito, pero el elemento ya fue eliminado o no fue encontrado"]);
        }else{
            http_response_code(500);
            echo json_encode(['error' => "Internal Server Error"]);
        }

    }
    catch(PDOException $e){
        echo $e;
    }

}


?>