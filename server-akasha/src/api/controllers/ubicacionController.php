<?php

class categoriaController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getCategoria(?int $id)
    {
        try {
            if ($id !== null) {
                $query = "SELECT * FROM categoria WHERE id_categoria = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Categoría no encontrada', 404);
                }
            } else {
                $query = "SELECT * FROM categoria";
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('No existen categorías registradas', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addCategoria()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        // Validaciones básicas
        if (empty($body['nombre_categoria'])) {
            throw new Exception('Nombre de categoría es obligatorio', 400);
        }

        try {
            $query = "INSERT INTO categoria (nombre_categoria) VALUES (:nombre_categoria)";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre_categoria' => $body['nombre_categoria']
            ]);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Error al crear categoría', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function updateCategoria()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (empty($body['id_categoria'])) {
            throw new Exception('ID de categoría es obligatorio', 400);
        }

        try {
            $query = "UPDATE categoria SET nombre_categoria = :nombre_categoria WHERE id_categoria = :id";
            
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nombre_categoria' => $body['nombre_categoria'],
                ':id' => $body['id_categoria']
            ]);

            $rowsAffected = $stmt->rowCount();

            if ($rowsAffected > 0) {
                return true;
            } else {
                throw new Exception('Categoría no encontrada', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function deleteCategoria()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $id = $body['id_categoria'] ?? null;

        if (!$id) {
            throw new Exception('ID de categoría es obligatorio', 400);
        }

        try {
            // Primero verificar si la categoría está siendo usada en productos
            $checkQuery = "SELECT COUNT(*) FROM producto WHERE id_categoria = :id";
            $checkStmt = $this->DB->prepare($checkQuery);
            $checkStmt->execute([':id' => $id]);
            $count = $checkStmt->fetchColumn();

            if ($count > 0) {
                throw new Exception('No se puede eliminar la categoría porque está siendo utilizada por productos', 400);
            }

            $query = "DELETE FROM categoria WHERE id_categoria = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $id]);
            
            $rowsAffected = $stmt->rowCount();

            if ($rowsAffected > 0) {
                return true;
            } else {
                throw new Exception('Categoría no encontrada', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}