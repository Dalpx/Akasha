<?php 
require 'db/db.php';

//Aqui obtenemos la URI proveniente de la petición del cliente
$uri = trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');
$base_path = 'akasha/server-akasha/src'; 

if (strpos($uri, $base_path) === 0) {
    $uri = substr($uri, strlen($base_path));
}
$uri = trim($uri, '/');

// 1. Dividir la URI en segmentos (ej: ['getData', '123'])
$uri_segments = explode('/', $uri);

// 2. El nombre de la ruta es el primer segmento
$route_name = $uri_segments[0];

// 3. Los parámetros adicionales son los segmentos restantes
$route_params = array_slice($uri_segments, 1);

// ------------------------------------

// Las rutas posibles se mantienen igual
$routes = [
    'login'=>'controllers/loginController.php',
    'getData'=>'api/handlers/getDataHandler.php',
    'add-product'=>'api/handlers/addHandler.php',
    'update-product'=>'api/handlers/updateHandler.php',
    'delete-product'=>'api/handlers/deleteHandler.php'
];

// Lógica de Ejecución, si la ruta existe, entonces procede a buscar el archivo para ejecutarse.
if (array_key_exists($route_name, $routes)) {
    $target_file = $routes[$route_name];

    if (file_exists($target_file)) {
        
        // Antes de incluir el archivo, definimos los parámetros como una variable global.
        // Esto permite que archivos como getDataHandler.php accedan al ID si está presente.
        define('ROUTE_PARAMS', $route_params);

        require $target_file; //Busca y ejecuta el archivo en cuestión

    } else {
        header('Content-Type: application/json');
        http_response_code(500);
        echo json_encode(["error" => "Internal Server Error", "details" => "Handler file missing"]);
    }

} else {
    // Si la URI completa o el primer segmento no es una ruta válida
    header('Content-Type: application/json');
    http_response_code(404);
    echo json_encode(["error" => "Not Found", "details" => "The requested API endpoint was not found: /" . htmlspecialchars($uri)]);
}

?>