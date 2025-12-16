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
        // La lógica de lectura se mantiene simple (sin transacción) pero limpia
        try {
            $query = "SELECT u.id_usuario, u.nombre_usuario, u.nombre_completo, u.email, u.activo, tu.nombre_tipo_usuario as permiso 
                      FROM usuario as u 
                      INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario";

            if ($id_user !== null) {
                $query .= " WHERE id_usuario = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id_user]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);
            } else {
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }

            if ($result) {
                return $result;
            } else {
                throw new Exception('Usuario(s) no encontrado(s)', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function createUsuario()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);

        $error = $validator->usuarioIsValid();
        if ($validator->entityAlreadyExists('usuario')) {
            throw new Exception('Este usuario ya se encuentra registrado', 409);
        } else if ($error !== false) {
            throw new Exception($error, 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "INSERT INTO usuario (nombre_usuario, clave_hash, nombre_completo, email, id_tipo_usuario, activo) 
                      VALUES (:user, :pass, :nom_c, :email, :id_tu, 1)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':user' => $body['usuario'],
                ':pass' => $body['clave_hash'],
                ':nom_c' => $body['nombre_completo'],
                ':email' => $body['email'],
                ':id_tu' => (int)$body['id_tipo_usuario']
            ]);

            $this->DB->commit();
            return true;
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function updateUsuario()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (!isset($body['id_usuario'])) {
            throw new Exception('Falta el ID del usuario.', 400);
        }

        $validator = new akashaValidator($this->DB, $body);
        $error = $validator->usuarioIsValid();

        // Usamos la versión refactorizada que excluye el ID actual
        if ($validator->entityAlreadyExists('usuario', $body['id_usuario'])) {
            throw new Exception('Este nombre de usuario ya está en uso por otra cuenta', 409);
        }
        if ($error !== false) {
            throw new Exception($error, 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "UPDATE usuario SET nombre_usuario=:user, clave_hash=:pass, nombre_completo=:nom_c, email=:email, id_tipo_usuario=:id_tu 
                      WHERE id_usuario = :id_user";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':user' => $body['usuario'],
                ':pass' => $body['clave_hash'],
                ':nom_c' => $body['nombre_completo'],
                ':email' => $body['email'],
                ':id_user' => $body['id_usuario'],
                ':id_tu' => $body['id_tipo_usuario']
            ]);

            $this->DB->commit();
            return true;
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function deleteUsuario()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        try {
            $this->DB->beginTransaction();

            $query = "UPDATE usuario SET activo=0 WHERE id_usuario=:id_user";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id_user' => $body['id_usuario']]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('El usuario ya ha sido eliminado o no existe', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function loginHandler()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        try {
            $query = "SELECT u.id_usuario, u.activo, tu.nombre_tipo_usuario 
                  FROM usuario as u 
                  INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario = tu.id_tipo_usuario 
                  WHERE u.nombre_usuario = :user AND u.clave_hash = :pass";

            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':user' => $body['user'],
                ':pass' => $body['clave_hash']
            ]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($result) {

                if ($result['activo'] != 1) {
                    throw new Exception('Usuario inactivo', 403);
                }
                return $result;
            } else {
                throw new Exception('Credenciales inválidas', 401);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}
