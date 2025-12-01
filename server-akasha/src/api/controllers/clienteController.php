<?php

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
                $query = "SELECT * FROM cliente WHERE id_cliente = :id AND activo = 1";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Cliente no encontrado', 404);
                }
            } else {
                $query = "SELECT * FROM cliente WHERE activo = 1";
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

        // Validaciones básicas
        if (empty($body['nombre']) || empty($body['tipo_documento']) || empty($body['nro_documento'])) {
            throw new Exception('Nombre, tipo de documento y número de documento son obligatorios', 400);
        }

        try {
            $query = "INSERT INTO cliente (nombre, tipo_documento, nro_documento, telefono, email, direccion, activo) 
                      VALUES (:nombre, :tipo_doc, :nro_doc, :telefono, :email, :direccion, 1)";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre' => $body['nombre'],
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

        if (empty($body['id_cliente'])) {
            throw new Exception('ID de cliente es obligatorio', 400);
        }

        try {
            $query = "UPDATE cliente SET 
                      nombre = :nombre, 
                      tipo_documento = :tipo_doc, 
                      nro_documento = :nro_doc, 
                      telefono = :telefono, 
                      email = :email, 
                      direccion = :direccion 
                      WHERE id_cliente = :id AND activo = 1";
            
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre' => $body['nombre'],
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