<?php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); //Permite cualquier origen (*): Esto significa que cualquier dominio puede hacer solicitudes. (Debe ser cambiado)
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE'); //Permite cualquier método HTTP (GET, POST, PUT, DELETE, OPTIONS, etc.)
// Permite cualquier cabecera HTTP personalizada que el cliente pueda enviar:
// Esto es importante para cabeceras como Content-Type, Authorization, X-Requested-With, etc.
header('Access-Control-Allow-Headers: *');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200); // Esto asegura el "HTTP ok status" que el error pedía
    exit();
}

//Aqui obtenemos la URI proveniente de la petición del cliente
$httpMethod = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

//Aquí llevaremos toda la lógica de enrutamiento, este archivo solo sirve para bootstrapping
require 'api/api_router.php';

exit;