<?php

header('Content-Type: application/json');
//Aqui obtenemos la URI proveniente de la petición del cliente
$httpMethod = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

//Aquí llevaremos toda la lógica de enrutamiento, este archivo solo sirve para bootstrapping
require 'api/api_router.php';

exit;