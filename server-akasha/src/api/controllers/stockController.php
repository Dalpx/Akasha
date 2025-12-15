<?php
require_once __DIR__ . '/../middlewares/akashaValidator.php';

class stockController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getStockProducto(?int $id)
    {
        try {
            $query = "SELECT s.id_producto, p.nombre, u.nombre_almacen, s.cantidad_actual as stock 
                      FROM stock as s 
                      LEFT JOIN producto as p ON s.id_producto = p.id_producto 
                      LEFT JOIN ubicacion as u ON u.id_ubicacion=s.id_ubicacion";

            if ($id !== null) {
                $query .= " WHERE s.id_producto = :id_prod";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id_prod' => $id]);
            } else {
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
            }
            
            $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Producto no encontrado en stock', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addStock()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);

        if ($validator->ubicacionIsNotUnique()) {
            throw new Exception('Esta combinación de producto y ubicación ya está registrada', 409);
        }

        try {
            $this->DB->beginTransaction();

            $query = "INSERT INTO stock (id_producto, id_ubicacion, cantidad_actual) VALUES (:id_prod, :id_ubi, 0)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':id_prod' => $body['id_producto'],
                ':id_ubi' => $body['id_ubicacion']
            ]);

            $this->DB->commit();
            return true;

        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }

    public function deleteStock()
    {
        $body = json_decode(file_get_contents('php://input'), true);
        $validator = new akashaValidator($this->DB, $body);

        if ($validator->stockIsNotEmpty()) {
            throw new Exception('Debe vaciar el stock antes de eliminar el producto de este almacén', 400);
        }

        try {
            $this->DB->beginTransaction();

            $query = "DELETE FROM stock WHERE id_producto = :id_prod AND id_ubicacion = :id_ubi";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':id_prod' => $body['id_producto'],
                ':id_ubi' => $body['id_ubicacion']
            ]);

            if ($stmt->rowCount() > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Registro de stock no encontrado', 404);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}
