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
            $query = "SELECT c.id_cliente, c.nombre, c.apellido, td.nombre_tipo_documento as tipo_documento, c.nro_documento, c.telefono, c.email, c.activo, c.direccion
                      FROM cliente as c 
                      LEFT JOIN tipo_documento as td ON c.tipo_documento=td.id_tipo_documento";

            if ($id !== null) {
                $query .= " WHERE id_cliente = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);
            } else {
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }

            if ($result) {
                return $result;
            } else {
                throw new Exception('Cliente(s) no encontrado(s)', 404);
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

        if ($validator->entityAlreadyExists('cliente')) {
            throw new Exception('Un cliente con este documento ya existe', 409);
        } else if ($error !== false) {
            throw new Exception($error, 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "INSERT INTO cliente (nombre, apellido, tipo_documento, nro_documento, telefono, email, direccion, activo) 
                      VALUES (:nombre, :apellido, :tipo_doc, :nro_doc, :telefono, :email, :direccion, 1)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nombre' => $body['nombre'],
                ':apellido' => $body['apellido'],
                ':tipo_doc' => $body['tipo_documento'],
                ':nro_doc' => $body['nro_documento'],
                ':telefono' => $body['telefono'] ?? null,
                ':email' => $body['email'] ?? null,
                ':direccion' => $body['direccion'] ?? null
            ]);

            $this->DB->commit();
            return true;

        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function updateCliente()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($body['id_cliente'])) {
            throw new Exception('Falta el ID del cliente.', 400);
        }

        $validator = new akashaValidator($this->DB, $body);
        $error = $validator->clienteIsValid();

        // Validación con exclusión de ID
        if ($validator->entityAlreadyExists('cliente', $body['id_cliente'])) {
            throw new Exception('Otro cliente ya posee este documento', 409);
        } else if ($error !== false) {
            throw new Exception($error, 400);
        }

        try {
            $this->DB->beginTransaction();

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
            $stmt->execute([
                ':nombre' => $body['nombre'],
                ':apellido' => $body['apellido'],
                ':tipo_doc' => $body['tipo_documento'],
                ':nro_doc' => $body['nro_documento'],
                ':telefono' => $body['telefono'] ?? null,
                ':email' => $body['email'] ?? null,
                ':direccion' => $body['direccion'] ?? null,
                ':id' => $body['id_cliente']
            ]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Cliente no encontrado o sin cambios', 404);
            }

        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function deleteCliente()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (empty($body['id_cliente'])) {
            throw new Exception('ID de cliente es obligatorio', 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "UPDATE cliente SET activo = 0 WHERE id_cliente = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $body['id_cliente']]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('El cliente ya ha sido eliminado o no existe', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}