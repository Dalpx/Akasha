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
            $query = "SELECT tu.nombre_tipo_usuario FROM tipo_usuario as tu inner join usuario  as u on u.id_usuario = tu.id_tipo_usuario WHERE nombre_usuario=:user AND cLave_hash=:pass";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':user' => $user, ':pass' => $pass]);
            $result = $stmt->fetch(pdo::FETCH_ASSOC);
            //Mensajes retornados dependiendo del resultado
            if ($result) {
                return $result;
            } else {
                http_response_code(401);
                echo 'No encontrado';
            }
        
        } catch (Exception $e) {
            echo $e;
        }
    }
}
