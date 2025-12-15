<?php
require_once __DIR__ . '/../middlewares/akashaValidator.php';

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
            $query = "SELECT * FROM ubicacion";
            if ($id !== null) {
                $query .= " WHERE id_ubicacion = :id";
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
                throw new Exception('Ubicación(es) no encontrada(s)', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addUbicacion()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (empty($body['nombre_almacen'])) {
            throw new Exception('Nombre de almacén es obligatorio', 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "INSERT INTO ubicacion (nombre_almacen, descripcion) VALUES (:nombre_almacen, :descripcion)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nombre_almacen' => $body['nombre_almacen'],
                ':descripcion' => $body['descripcion'] ?? null
            ]);

            $this->DB->commit();
            return true;
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function updateUbicacion()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);
        if (empty($body['id_ubicacion'])) {
            throw new Exception('ID de ubicación es obligatorio', 400);
        }
        if ($validator->entityAlreadyExists('ubicacion', $body['id_ubicacion'])) {
            throw new Exception('Una ubicación con este nombre ya existe', 409);
        }
        try {
            $this->DB->beginTransaction();

            $query = "UPDATE ubicacion SET nombre_almacen = :nombre_almacen, descripcion = :descripcion WHERE id_ubicacion = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nombre_almacen' => $body['nombre_almacen'],
                ':descripcion' => $body['descripcion'] ?? null,
                ':id' => $body['id_ubicacion']
            ]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Ubicación no encontrada o sin cambios', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function deleteUbicacion()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        if (empty($body['id_ubicacion'])) {
            throw new Exception('ID de ubicación es obligatorio', 400);
        }

        $validator = new akashaValidator($this->DB, $body);
        if ($validator->isAssigned('ubicacion')) {
            throw new Exception('No se puede eliminar la ubicación porque hay stock asociado', 400);
        }

        try {
            $this->DB->beginTransaction();

            // Borrado lógico
            $query = "UPDATE ubicacion SET activo = 0 WHERE id_ubicacion = :id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $body['id_ubicacion']]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Ubicación no encontrada', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}
