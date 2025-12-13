<?php
require_once __DIR__ . '/../middlewares/akashaValidator.php';

class proveedorController
{
    protected $DB;

    public function __construct($pdo)
    {
        $this->DB = $pdo;
    }

    public function getProveedor(?int $id_prov)
    {
        try {
            $query = "SELECT * FROM proveedor";
            if ($id_prov !== null) {
                $query .= " WHERE id_proveedor = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id_prov]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);
            } else {
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }

            if ($result) {
                return $result;
            } else {
                throw new Exception('Proveedor(es) no encontrado(s)', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addProveedor()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);

        if ($validator->entityAlreadyExists('proveedor')) {
            throw new Exception('Un proveedor con este nombre ya existe', 409);
        }

        try {
            $this->DB->beginTransaction();

            $query = "INSERT INTO proveedor (nombre, telefono, correo, direccion, activo) VALUES (:nom, :telefono, :corr, :dir, 1)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nom' => $body['nombre'],
                ':telefono' => $body['telefono'],
                ':corr' => $body['correo'],
                ':dir' => $body['direccion']
            ]);

            $this->DB->commit();
            return true;

        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function updateProveedor()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($body['id_proveedor'])) {
            throw new Exception('Falta el ID del proveedor.', 400);
        }

        $validator = new akashaValidator($this->DB, $body);
        // Validación con exclusión de ID
        if ($validator->entityAlreadyExists('proveedor', $body['id_proveedor'])) {
            throw new Exception('Otro proveedor ya utiliza este nombre.', 409);
        }

        try {
            $this->DB->beginTransaction();

            $query = "UPDATE proveedor SET nombre=:nom, telefono=:telefono, correo=:corr, direccion=:dir WHERE id_proveedor = :id_prov";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nom' => $body['nombre'],
                ':telefono' => $body['telefono'],
                ':corr' => $body['correo'],
                ':dir' => $body['direccion'],
                ':id_prov' => $body['id_proveedor']
            ]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
            
                throw new Exception('Proveedor no encontrado o sin cambios', 404);
            }

        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function deleteProveedor()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);

        if ($validator->isAssigned('proveedor')) {
            throw new Exception('No se puede eliminar el proveedor porque tiene productos asociados', 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "UPDATE proveedor SET activo=0 WHERE id_proveedor = :id_prov";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id_prov' => $body['id_prov']]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('El proveedor ya ha sido eliminado o no existe', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}