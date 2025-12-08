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

            if ($id !== null) { //Esta función nos permite retornar el stock en caso de que se especifique una ID o no
                $query = "SELECT s.id_producto, p.nombre, u.nombre_almacen, s.cantidad_actual as stock FROM stock as s 
                LEFT JOIN producto as p ON s.id_producto = p.id_producto 
                LEFT JOIN ubicacion as u ON u.id_ubicacion=s.id_ubicacion 
                WHERE s.id_producto = :id_prod";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id_prod' => $id]);
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Producto no encontrado', 404);
                }
            } else {
                $query = "SELECT p.nombre, u.nombre_almacen, s.cantidad_actual as stock FROM stock as s 
                LEFT JOIN producto as p ON s.id_producto = p.id_producto 
                LEFT JOIN ubicacion as u ON u.id_ubicacion=s.id_ubicacion";
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Producto no encontrado', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addStock()
    {
        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);

        $validator = new akashaValidator($this->DB, $body);
        if ($validator->ubicacionIsNotUnique()) {
            throw new Exception('Esta combinación de ubicación ya está registrada', 401);
        }

        $query = "INSERT INTO stock (id_producto, id_ubicacion, cantidad_actual) VALUES (:id_prod, :id_ubi, 0)";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([
            ':id_prod' => $body['id_producto'],
            ':id_ubi' => $body['id_ubicacion']
        ]);

        if ($stmt) {
            $this->DB->commit();
            return true;
        } else {
            throw new Exception('Ha ocurrido un error', 500);
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

            $query = "DELETE FROM stock WHERE id_producto = :id_prod AND id_ubicacion = :id_ubi";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':id_prod' => $body['id_producto'],
                ':id_ubi' => $body['id_ubicacion']
            ]);

            $rows_af = $stmt->columnCount();

            if ($rows_af > 0) {
                return true;
            } else if ($rows_af == 0) {
                throw new Exception('Este producto ya ha sido eliminado de esta ubicación o no fue posible encontrarlo', 404);
            } else {
                throw new Exception('Se ha producido un error', 500);
            }
        } catch (Exception $e) {
        }
    }
}
