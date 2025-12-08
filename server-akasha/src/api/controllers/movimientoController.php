<?php

class movimientoController
{

    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getMovimientos(?int $id)
    {
        try {
            $query = "SELECT 
            mi.id_movimiento, 
            CASE 
                WHEN mi.tipo_movimiento = 1 THEN 'entrada' 
                WHEN mi.tipo_movimiento = 0 THEN 'salida'
            END AS 'tipo_movimiento', 
            mi.cantidad, 
            mi.fecha_hora as fecha, 
            mi.descripcion, 
            p.nombre AS nombre_producto,
            u.nombre_completo AS nombre_usuario,
            ubi.nombre_almacen as ubicacion
            FROM movimiento_inventario as mi
            LEFT JOIN producto as p ON mi.id_producto = p.id_producto
            LEFT JOIN usuario as u ON mi.id_usuario = u.id_usuario
            LEFT JOIN ubicacion as ubi ON mi.id_ubicacion = ubi.id_ubicacion";

            $params = [];
            if ($id !== null) {
                $query .= " WHERE mi.id_movimiento = :id";
                $params[':id'] = $id;
            }

            $stmt = $this->DB->prepare($query);
            $stmt->execute($params);

            // Usamos fetchAll para obtener múltiples ventas si no hay ID, 
            // o un array de una venta si hay ID
            $movimiento = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if ($movimiento) {
                if ($id !== null && count($movimiento) === 1) {
                    return $movimiento[0];
                }

                return $movimiento;
            } else {
                throw new Exception('Registro de movimiento no encontrado', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addMovimiento()
    {
        $body = json_decode(file_get_contents('php://input'), true);

        /*
         NOTA IMPORTANTE: Basado en la imagen de la tabla 'stock', se requiere
         que el $body incluya 'id_ubicacion' para saber qué registro actualizar.
        */

        try {
            // Iniciar la transacción
            $this->DB->beginTransaction();

            // --- PASO 1: Insertar el registro en movimiento_inventario ---
            $queryMov = "INSERT INTO movimiento_inventario (tipo_movimiento, cantidad, descripcion, id_producto, id_usuario, id_ubicacion)
                         VALUES (:tipo_mov, :cant, :descripcion, :id_producto, :id_usuario, :id_ubi)";
            $stmtMov = $this->DB->prepare($queryMov);

            // Ejecución con chequeo de errores SQL, estilo ventaController
            if (!$stmtMov->execute([
                ':tipo_mov' => $body['tipo_movimiento'],
                ':cant' => $body['cantidad'],
                ':descripcion' => $body['descripcion'],
                ':id_producto' => $body['id_producto'],
                ':id_usuario' => $body['id_usuario'],
                ':id_ubi' => $body['id_ubicacion']
            ])) {
                $errorInfo = $stmtMov->errorInfo();
                // Lanzamos el error específico de SQL
                throw new Exception("Error al registrar el movimiento: " . $errorInfo[2], 500);
            }


            // --- PASO 2: Actualizar la tabla Stock ---

            // Determinamos si sumamos o restamos según el tipo_movimiento.
            // Asumiendo (basado en getMovimientos): 1 = Entrada (+), 0 = Salida (-)
            $operador = ($body['tipo_movimiento'] == 1) ? '+' : '-';

            // Query dinámica usando el operador determinado
            // Se requiere filtrar por id_producto Y id_ubicacion según la imagen
            $queryStock = "UPDATE stock 
                           SET cantidad_actual = cantidad_actual $operador :cantidad 
                           WHERE id_producto = :id_p AND id_ubicacion = :id_u";

            $stmtStock = $this->DB->prepare($queryStock);

            if (!$stmtStock->execute([
                ':cantidad' => $body['cantidad'],
                ':id_p' => $body['id_producto'],
                // Asumimos que id_ubicacion viene en el body, es necesario por la estructura de la tabla.
                ':id_u' => $body['id_ubicacion']
            ])) {
                $errorInfo = $stmtStock->errorInfo();
                throw new Exception("Error SQL al ejecutar la actualización de stock: " . $errorInfo[2], 500);
            }

            // Verificación Final de filas afectadas
            // Debe afectar exactamente a 1 fila. Si es 0, el producto/ubicación no existe.
            $rows_af_stock = $stmtStock->rowCount();

            if ($rows_af_stock !== 1) {
                $prodId = $body['id_producto'];
                $ubicId = $body['id_ubicacion'] ?? 'Desconocida';
                throw new Exception("Error crítico de inventario: No se encontró el registro de stock para Producto ID: $prodId en Ubicación ID: $ubicId, o los datos son inconsistentes. No se realizó la actualización.", 500);
            }


            // --- Commit final ---
            // Si llegamos aquí, el insert y el update funcionaron correctamente.
            $this->DB->commit();
            return true;
        } catch (Exception $e) {
            // Si algo falla, revertimos todos los cambios
            $this->DB->rollBack();
            // Re-lanzamos la excepción con el mensaje detallado
            throw $e;
        }
    }
}
