<?php
require_once __DIR__ . '/../middlewares/akashaValidator.php';

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
            $query = "SELECT * FROM categoria";
            if ($id !== null) {
                $query .= " WHERE id_categoria = :id";
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
                throw new Exception('Categoría no encontrada o no existen registros', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addCategoria()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        // Validaciones
        if (empty($body['nombre_categoria'])) {
            throw new Exception('Nombre de categoría es obligatorio', 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "INSERT INTO categoria (nombre_categoria) VALUES (:nombre_categoria)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':nombre_categoria' => $body['nombre_categoria']]);

            $this->DB->commit();
            return true;
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function updateCategoria()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (empty($body['id_categoria']) || empty($body['nombre_categoria'])) {
            throw new Exception('ID y Nombre de categoría son obligatorios', 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "UPDATE categoria SET nombre_categoria = :nombre_categoria WHERE id_categoria = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nombre_categoria' => $body['nombre_categoria'],
                ':id' => $body['id_categoria']
            ]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Categoría no encontrada o sin cambios', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function deleteCategoria()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        
        if (empty($body['id_categoria'])) {
            throw new Exception('ID de categoría es obligatorio', 400);
        }

        $validator = new akashaValidator($this->DB, $body);
        if ($validator->isAssigned('categoria')) {
            throw new Exception('No se puede eliminar la categoría porque está siendo utilizada por al menos un producto', 400);
        }

        try {
            $this->DB->beginTransaction();

            // Borrado lógico
            $query = "UPDATE categoria SET activo = 0 WHERE id_categoria = :id"; 
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $body['id_categoria']]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Categoría no encontrada', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}