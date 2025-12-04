<?php

require_once __DIR__ . '/../middlewares/akashaValidator.php';

class usuarioController
{

    protected $DB;

    public function __construct(\PDO $pdo)
    {
        $this->DB = $pdo;
    }


    public function getUsuario(?int $id_user)
    {
        try {
            if ($id_user !== null) {   //Si se cumple esta condición nos permite retornar usuarios en caso de que se especifique una ID
                $query = "SELECT u.id_usuario, u.nombre_usuario, u.nombre_completo, u.email, u.activo, tu.nombre_tipo_usuario 
                as permiso FROM usuario as u INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario 
                WHERE id_usuario = :id";
                $stmt = $this->DB->prepare($query);
                $result = $stmt->execute([':id' => $id_user]);
                $result = $stmt->fetch(pdo::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Usuario no encontrado', 404);
                }
            } else { //Si se cumple esta condición nos permite retornar usuarios en caso de que NO se especifique una ID
                $query = "SELECT u.id_usuario, u.nombre_usuario, u.nombre_completo, u.email, u.activo, tu.nombre_tipo_usuario 
                as permiso FROM usuario as u INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario";
                $stmt =  $this->DB->prepare($query);
                $result = $stmt->execute();
                $result = $stmt->fetchAll(pdo::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('No existen usuarios registrados', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function createUsuario()
    {
        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);

        //Instanciamos akashaValidator y hacemos las validaciones, de otra forma, se retorna un error 400 Bad Request
        $validator = new akashaValidator($this->DB, $body);
        $error = $validator->usuarioIsValid();
        if ($validator->entityAlreadyExists('usuario')) {
            throw new Exception('Este usuario ya se encuentra registrado', 409);
        } else if ($error !== false) {
            throw new Exception($error, 400);
        }

        try { //Lógica para insertar usuarios
            $query = "INSERT INTO usuario (nombre_usuario, clave_hash, nombre_completo, email, id_tipo_usuario, activo) 
            VALUES (:user, :pass, :nom_c, :email, :id_tu, 1)";
            $stmt = $this->DB->prepare($query);
            //Ejecutamos la query
            $result = $stmt->execute([
                ':user' => $body['usuario'],
                ':pass' => $body['clave_hash'],
                ':nom_c' => $body['nombre_completo'],
                ':email' => $body['email'],
                ':id_tu' => (int)$body['id_tipo_usuario']
            ]);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Error al crear usuario', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function updateUsuario()
    {
        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);

        //Instanciamos akashaValidator y hacemos las validaciones, de otra forma, se retorna un error 400 Bad Request
        $validator = new akashaValidator($this->DB, $body);
        $error = $validator->usuarioIsValid();
        if ($validator->entityAlreadyExists('usuario')) {
            throw new Exception('Este usuario ya se encuentra registrado', 409);
        } else if ($error !== false) {
            throw new Exception($error, 400);
        }

        try { //Permite actualizar los datos de usuario
            $query = "UPDATE usuario SET nombre_usuario=:user, clave_hash=:pass, nombre_completo=:nom_c, email=:email, id_tipo_usuario=:id_tu 
            WHERE id_usuario = :id_user";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':user' => $body['usuario'],
                ':pass' => $body['clave_hash'],
                ':nom_c' => $body['nombre_completo'],
                ':email' => $body['email'],
                ':id_user' => $body['id_usuario'],
                ':id_tu' => $body['id_tipo_usuario']
            ]);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Error al actualizar usuario', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function deleteUsuario()
    {
        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);

        try {
            $query = "UPDATE usuario SET activo=0 WHERE id_usuario=:id_user";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':id_user' => $body['id_usuario']
            ]);
            $rows_af = $stmt->rowCount();

            if ($rows_af > 0) {
                return true;
            } else if ($rows_af == 0) {
                throw new Exception('El usuario ya ha sido eliminado o no fue posible encontrarlo', 404);
            } else {
                throw new Exception('Se ha producido un error', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function loginHandler()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        //Del JSON extraemos los datos
        try {
            //Esta es toda la lógica de la transacción SQL, usamos PDO para eliminar o mitigar la cantidad de user body
            $query = "SELECT u.activo, tu.nombre_tipo_usuario FROM tipo_usuario as tu INNER JOIN usuario as u ON u.id_usuario = tu.id_tipo_usuario 
            WHERE nombre_usuario=:user AND cLave_hash=:pass";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':user' => $body['user'],
                ':pass' => $body['clave_hash']
            ]);
            $result = $stmt->fetch(pdo::FETCH_ASSOC);
            //Mensajes retornados dependiendo del resultado
            if ($result) {
                return $result;
            } else {
                throw new Exception('Credenciales inválidas', 401);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}
