<?php
//Define el tipo de datos que se enviarán o recibirán
header("Content-Type: application/json");
/*Estos headers permiten que tráfico de otros dominios pueda hacer requests a nuestro backend, así evitando las violaciones
CORS en navegadores*/
header("Access-Control-Allow-Origin: *"); //MUCHO OJO CON ESTE HEADER, HAY QUE MODIFICARLO PARA QUE SOLO ACEPTE SOLICITUDES DE NUESTRO DOMINIO
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

//Prueba para la pantalla de Login, no sé dónde irá a implementarse esa lógica luego, probablemente se quede así.
$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $con = DBConnection::getInstance();
    $pdo = $con->getPDO();

    $user = $input['user'];
    $pass = $input['pass'];

    try {

        $query = 'SELECT nombre_usuario, clave_hash, id_tipo_usuario FROM usuario WHERE nombre_usuario = :user AND cLave_hash= :pass';
        $stmt = $pdo->prepare($query);
        $stmt->execute([':user' => $user, ':pass' => $pass]);
        $result = $stmt->fetch(pdo::FETCH_ASSOC);

        if ($result) {
            http_response_code(200);
            echo json_encode(['message' => "Login exitoso"]);
        } else {
            http_response_code(401);
            echo 'No encontrado';
        }
    } catch (PDOException $e) {
        echo $e;
    }
}
