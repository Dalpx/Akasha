<?php

require_once __DIR__ . '/../middlewares/akashaValidator.php';
class clienteController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getCliente(?int $id)
    {
        try {
            if ($id !== null) {
                $query = "SELECT c.id_cliente, c.nombre, c.apellido, td.nombre_tipo_documento as tipo_documento, c.nro_documento, c.telefono, c.email, c.activo
                FROM cliente as c LEFT JOIN tipo_documento as td ON c.tipo_documento=td.id_tipo_documento
                WHERE id_cliente = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Cliente no encontrado', 404);
                }
            } else {
                $query = "SELECT c.id_cliente, c.nombre, c.apellido, td.nombre_tipo_documento as tipo_documento, c.nro_documento, c.telefono, c.email, c.activo
                FROM cliente as c LEFT JOIN tipo_documento as td ON c.tipo_documento=td.id_tipo_documento";
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('No existen clientes registrados', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addCliente()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        $validator = new akashaValidator($this->DB, $body);
        $error = $validator->clienteIsValid();

        // Validaciones si los datos están presentes, si los datos como la cedula y pasaporte siguen un patron válido y si un usuario con
        //un mismo documento ya existe
        if ($validator->clienteAlreadyExists()) {
            throw new Exception('Un cliente con este documento ya existe', 409);

        } else if ($error !== false) {
            throw new Exception($error, 400);

        }

        try {
            $query = "INSERT INTO cliente (nombre, apellido, tipo_documento, nro_documento, telefono, email, direccion, activo) 
                      VALUES (:nombre, :apellido, :tipo_doc, :nro_doc, :telefono, :email, :direccion, 1)";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre' => $body['nombre'],
                ':apellido' =>$body['apellido'],
                ':tipo_doc' => $body['tipo_documento'],
                ':nro_doc' => $body['nro_documento'],
                ':telefono' => $body['telefono'] ?? null,
                ':email' => $body['email'] ?? null,
                ':direccion' => $body['direccion'] ?? null
            ]);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Error al crear cliente', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function updateCliente()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);
        $error = $validator->clienteIsValid();

         if ($validator->clienteAlreadyExists()) {
            throw new Exception('Un cliente con este documento ya existe', 409);
        } else if ($error !== false) {
            throw new Exception($error, 400);

        }

        try {
            $query = "UPDATE cliente SET 
                      nombre = :nombre,
                      apellido = :apellido, 
                      tipo_documento = :tipo_doc, 
                      nro_documento = :nro_doc, 
                      telefono = :telefono, 
                      email = :email, 
                      direccion = :direccion 
                      WHERE id_cliente = :id AND activo = 1";

            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre' => $body['nombre'],
                ':apellido' =>$body['apellido'],
                ':tipo_doc' => $body['tipo_documento'],
                ':nro_doc' => $body['nro_documento'],
                ':telefono' => $body['telefono'] ?? null,
                ':email' => $body['email'] ?? null,
                ':direccion' => $body['direccion'] ?? null,
                ':id' => $body['id_cliente']
            ]);

            $rowsAffected = $stmt->rowCount();

            if ($rowsAffected > 0) {
                return true;
            } else {
                throw new Exception('Cliente no encontrado o ya eliminado', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function deleteCliente()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $id = $body['id_cliente'] ?? null;

        if (!$id) {
            throw new Exception('ID de cliente es obligatorio', 400);
        }

        try {
            $query = "UPDATE cliente SET activo = 0 WHERE id_cliente = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $id]);

            $rowsAffected = $stmt->rowCount();

            if ($rowsAffected > 0) {
                return true;
            } else if ($rowsAffected == 0) {
                throw new Exception('El cliente ya ha sido eliminado o no fue posible encontrarlo', 404);
            } else {
                throw new Exception('Se ha producido un error', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}
