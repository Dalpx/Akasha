<?php

class loginController
{

    protected $DB;

    public function __construct(\PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function loginHandler()
    {
        $input = json_decode(file_get_contents('php://input'), true);

        //Del JSON extraemos los datos (que deben ser encriptados, pero no está añadido todavía)
        $user = $input['user'];
        $pass = $input['pass'];

        try {
            //Esta es toda la lógica de la transacción SQL, usamos PDO para eliminar o mitigar la cantidad de user input
            $query = 'SELECT nombre_usuario, clave_hash, id_tipo_usuario FROM usuario WHERE nombre_usuario = :user AND cLave_hash= :pass';
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':user' => $user, ':pass' => $pass]);
            $result = $stmt->fetch(pdo::FETCH_ASSOC);
            //Mensajes retornados dependiendo del resultado
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
}
