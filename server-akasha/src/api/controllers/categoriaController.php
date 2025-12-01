<?php

class ubicacionController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getUbicacion(?int $id)
    {
        try {
            if ($id !== null) {
                $query = "SELECT * FROM ubicacion WHERE id_ubicacion = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Ubicación no encontrada', 404);
                }
            } else {
                $query = "SELECT * FROM ubicacion";
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('No existen ubicaciones registradas', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addUbicacion()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        // Validaciones básicas
        if (empty($body['nombre_almacen']) || empty($body['nombre_estante'])) {
            throw new Exception('Nombre de almacén y nombre de estante son obligatorios', 400);
        }

        try {
            $query = "INSERT INTO ubicacion (nombre_almacen, nombre_estante, descripcion) 
                      VALUES (:nombre_almacen, :nombre_estante, :descripcion)";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre_almacen' => $body['nombre_almacen'],
                ':nombre_estante' => $body['nombre_estante'],
                ':descripcion' => $body['descripcion'] ?? null
            ]);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Error al crear ubicación', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function updateUbicacion()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (empty($body['id_ubicacion'])) {
            throw new Exception('ID de ubicación es obligatorio', 400);
        }

        try {
            $query = "UPDATE ubicacion SET 
                      nombre_almacen = :nombre_almacen, 
                      nombre_estante = :nombre_estante, 
                      descripcion = :descripcion 
                      WHERE id_ubicacion = :id";
            
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre_almacen' => $body['nombre_almacen'],
                ':nombre_estante' => $body['nombre_estante'],
                ':descripcion' => $body['descripcion'] ?? null,
                ':id' => $body['id_ubicacion']
            ]);

            $rowsAffected = $stmt->rowCount();

            if ($rowsAffected > 0) {
                return true;
            } else {
                throw new Exception('Ubicación no encontrada', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function deleteUbicacion()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $id = $body['id_ubicacion'] ?? null;

        if (!$id) {
            throw new Exception('ID de ubicación es obligatorio', 400);
        }

        try {
            // Primero verificar si la ubicación está siendo usada en stock
            $checkQuery = "SELECT COUNT(*) FROM stock WHERE id_ubicacion = :id";
            $checkStmt = $this->DB->prepare($checkQuery);
            $checkStmt->execute([':id' => $id]);
            $count = $checkStmt->fetchColumn();

            if ($count > 0) {
                throw new Exception('No se puede eliminar la ubicación porque está siendo utilizada en el inventario', 400);
            }

            $query = "DELETE FROM ubicacion WHERE id_ubicacion = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $id]);
            
            $rowsAffected = $stmt->rowCount();

            if ($rowsAffected > 0) {
                return true;
            } else {
                throw new Exception('Ubicación no encontrada', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}