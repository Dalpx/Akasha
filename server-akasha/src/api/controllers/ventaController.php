<?php

class ventaController
{

    protected $DB;

    public function __construct($pdo)
    {
        $this->DB = $pdo;
    }

    /*
    Función Auxiliar Privada: Obtiene los productos (detalles) de una venta específica.
    @param int $id_venta ID de la venta para buscar sus detalles.
    Los detalles de la venta.
    */
    private function getDetallesPorIdVenta(int $id_venta): array
    {
        // Se hace JOIN con la tabla de productos para obtener el nombre del producto vendido.
        $query = "SELECT 
                    dv.id_detalle_venta,
                    dv.id_producto,
                    p.nombre AS nombre_producto, 
                    dv.cantidad,
                    dv.precio_unitario,
                    dv.subtotal
                  FROM detalle_venta AS dv
                  INNER JOIN producto AS p ON dv.id_producto = p.id_producto
                  WHERE dv.id_venta = :id";

        $stmt = $this->DB->prepare($query);
        $stmt->execute([':id' => $id_venta]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }


    public function getVenta(?int $id)
    {
        try {
            //Preparamos la query mastodóntica
            $query = "SELECT 
                        v.id_venta, v.fecha_hora as 'fecha', v.nro_comprobante as 'numero_comprobante', 
                        c.nombre as 'nombre_cliente', v.subtotal, v.impuesto, v.total, 
                        tp.nombre as 'metodo_pago', u.nombre_completo as 'registrado_por', 
                        u.email, tu.nombre_tipo_usuario 
                      FROM venta as v 
                      INNER JOIN tipo_pago as tp ON v.id_tipo_comprobante=tp.id_tipo_comprobante 
                      INNER JOIN cliente as c ON v.id_cliente=c.id_cliente 
                      INNER JOIN usuario as u ON v.id_usuario=u.id_usuario 
                      INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario";

            $params = [];

            //Si hay ID, filtramos para una sola venta
            if ($id !== null) {
                $query .= " WHERE v.id_venta = :id";
                $params[':id'] = $id;
            }

            $stmt = $this->DB->prepare($query);
            $stmt->execute($params);

            // Usamos fetchAll para obtener múltiples ventas si no hay ID, 
            // o un array de una venta si hay ID
            $ventas = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if ($ventas) {
                // Iteramos sobre los resultados para inyectar los detalles (el contenido de la venta)
                // Usamos '&' para modificar el array original por referencia.
                foreach ($ventas as &$venta) {
                    $detalles = $this->getDetallesPorIdVenta($venta['id_venta']);
                    // Añadimos la nueva clave 'detalle_venta'
                    $venta['detalle_venta'] = $detalles;
                }

                // Si se buscó por ID, retornamos el objeto único en lugar del array de un elemento.
                if ($id !== null && count($ventas) === 1) {
                    return $ventas[0];
                }

                return $ventas;
            } else {
                throw new Exception('Registro de venta no encontrado', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }


    public function addVenta()
    {
        // Decodificar JSON
        $body = json_decode(file_get_contents('php://input'), true);

        // --- INICIO DE VALIDACIÓN DE STOCK ---
        // Instanciamos el validador pasándole la conexión DB y el body
        $validator = new akashaValidator($this->DB, $body);

        // Ejecutamos la validación. Si retorna un string (mensaje de error), lanzamos la excepción.
        $errorStock = $validator->checkStockAvailability();

        if ($errorStock) {
            // Lanzamos excepción con código 409 (Conflict) o 400 (Bad Request)
            throw new Exception($errorStock, 409);
        }

        try {
            $venta = $body['venta'];
            $detalles = $body['detalle_venta'];

            $this->DB->beginTransaction();

            // ... (Resto de tu código original: Inserts de venta y detalles) ...

            // 1. Inserción de la Cabecera de Venta
            $query_venta = "INSERT INTO venta (nro_comprobante, id_tipo_comprobante, id_cliente, id_usuario, subtotal, impuesto, total, estado) 
        VALUES (:num_comp, :id_tc, :id_cliente, :id_usuario, :sub, :imp, :total, :estado)";
            $stmt_venta = $this->DB->prepare($query_venta);

            if (!$stmt_venta->execute([
                ':num_comp' => $venta['nro_comprobante'],
                ':id_tc' => $venta['id_tipo_comprobante'],
                ':id_cliente' => $venta['id_cliente'],
                ':id_usuario' => $venta['id_usuario'],
                ':sub' => $venta['subtotal'],
                ':imp' => $venta['impuesto'],
                ':total' => $venta['total'],
                ':estado' => $venta['estado']
            ])) {
                $errorInfo = $stmt_venta->errorInfo();
                throw new Exception("Error al insertar cabecera de venta: " . $errorInfo[2], 500);
            }

            $id_venta = $this->DB->lastInsertId();
            $rows_af_total = 0; // Usaremos un contador total de filas de stock

            // 2. Itera sobre los Detalles (Inserción y Actualización de Stock)
            foreach ($detalles as $detalle_venta) {

                // 2.1. Inserción del Detalle de Venta
                $query_detalles = "INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal) 
            VALUES (:id_venta, :id_producto, :cant, :cost_unid, :sub)";

                $stmt_detalles = $this->DB->prepare($query_detalles);
                if (!$stmt_detalles->execute([
                    ':id_venta' => $id_venta,
                    ':id_producto' => $detalle_venta['id_producto'],
                    ':cant' => $detalle_venta['cantidad'],
                    ':cost_unid' => $detalle_venta['precio_unitario'],
                    ':sub' => ($detalle_venta['precio_unitario'] * $detalle_venta['cantidad'])
                ])) {
                    $errorInfo = $stmt_detalles->errorInfo();
                    throw new Exception("Error al insertar detalle de venta: " . $errorInfo[2], 500);
                }

                // 2.2. Manejo de la disminución del Stock
                $query_stock = "UPDATE stock SET cantidad_actual= cantidad_actual - :cantidad WHERE id_producto = :id_p AND id_ubicacion = :id_u";
                $stmt_stock = $this->DB->prepare($query_stock);

                if (!$stmt_stock->execute([
                    ':cantidad' => $detalle_venta['cantidad'],
                    ':id_p' => $detalle_venta['id_producto'],
                    ':id_u' => $detalle_venta['id_ubicacion']
                ])) {
                    $errorInfo = $stmt_stock->errorInfo();
                    throw new Exception("Error al ejecutar la actualización de stock: " . $errorInfo[2], 500);
                }

                $rows_af_stock = $stmt_stock->rowCount();

                if ($rows_af_stock !== 1) {
                    $producto_id = $detalle_venta['id_producto'];
                    $ubicacion_id = $detalle_venta['id_ubicacion'];
                    $msg = "Error de stock: No se encontró o se actualizó el stock para Producto ID: $producto_id y Ubicación ID: $ubicacion_id. Filas afectadas: $rows_af_stock.";
                    throw new Exception($msg, 500);
                }

                $rows_af_total += $rows_af_stock; // Sumamos filas afectadas (siempre 1)
            }

            // 3. Verificación Final y Commit
            // Verificamos que se insertó la venta y que el total de filas de stock sea igual al total de detalles
            if ($id_venta && $rows_af_total === count($detalles)) {
                $this->DB->commit();
                return true;
            } else {
                // Este caso solo debería ocurrir si el count($detalles) es 0 (detalle_venta vacío).
                throw new Exception("La transacción no pudo completarse correctamente o la lista de detalles está vacía. Detalles esperados: " . count($detalles) . ". Filas de stock afectadas: $rows_af_total", 500);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            // La excepción ahora contiene el mensaje de error SQL, o el error de stock específico.
            throw $e;
        }
    }
}
