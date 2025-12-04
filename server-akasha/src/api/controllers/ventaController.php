<?php

class ventaController
{

    protected $DB;

    public function __construct($pdo)
    {
        $this->DB = $pdo;
    }

    
    /*public function getVenta(?int $id)
    {
        //Lógica para la obtención detallada de los datos de una venta
        try {
            if ($id !== null) {
                //Query mastodóntica para el caso en el que se nos envie una ID mediante get
                $query = "SELECT v.id_venta, v.fecha_hora as 'fecha', v.nro_comprobante as 'numero_comprobante', c.nombre as 'nombre_cliente', v.subtotal, v.impuesto, v.total, 
                    tp.nombre as 'metodo_pago', u.nombre_completo 
                    as 'registrado_por', u.email, tu.nombre_tipo_usuario FROM venta as v 
                    LEFT JOIN tipo_pago as tp ON v.id_tipo_comprobante=tp.id_tipo_comprobante 
                    LEFT JOIN cliente as c ON v.id_cliente=c.id_cliente 
                    LEFT JOIN usuario as u ON v.id_usuario=u.id_usuario 
                    LEFT JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(pdo::FETCH_ASSOC);
                
                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Registro de venta no encontrado', 404);
                }
            } else {
                //Query mastodóntica para el caso en el que no nos se nos envíe un ID, por lo cual retornamos todo
                $query = "SELECT v.id_venta, v.fecha_hora as 'fecha', v.nro_comprobante as 'numero_comprobante', c.nombre as 'nombre_cliente', v.subtotal, v.impuesto, v.total, 
                    tp.nombre as 'metodo_pago', u.nombre_completo 
                    as 'registrado_por', u.email, tu.nombre_tipo_usuario FROM venta as v 
                    LEFT JOIN tipo_pago as tp ON v.id_tipo_comprobante=tp.id_tipo_comprobante 
                    LEFT JOIN cliente as c ON v.id_cliente=c.id_cliente 
                    LEFT JOIN usuario as u ON v.id_usuario=u.id_usuario 
                    LEFT JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario";

                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(pdo::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Registro de venta no encontrado', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }*/
    
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
            // o un array de una venta si hay ID, manteniendo consistencia.
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
        //Lógica transaccional para la adición de una venta
        $body = json_decode(file_get_contents('php://input'), true);
        try {
            // Se corrige la variable a 'venta'
            $venta = $body['venta'];
            $detalles = $body['detalle_venta'];

            $this->DB->beginTransaction();

            // Query para la cabecera de la venta
            $query_venta = "INSERT INTO venta (nro_comprobante, id_tipo_comprobante, id_cliente, id_usuario, subtotal, impuesto, total, estado) 
        VALUES (:num_comp, :id_tc, :id_cliente, :id_usuario, :sub, :imp, :total, :estado)";
            $stmt_venta = $this->DB->prepare($query_venta);

            // Ejecuta la consulta (Se corrige :id_prov a :id_cliente)
            $stmt_venta->execute([
                ':num_comp' => $venta['nro_comprobante'],
                ':id_tc' => $venta['id_tipo_comprobante'],
                ':id_cliente' => $venta['id_cliente'],
                ':id_usuario' => $venta['id_usuario'],
                ':sub' => $venta['subtotal'],
                ':imp' => $venta['impuesto'],
                ':total' => $venta['total'],
                ':estado' => $venta['estado']
            ]);

            // Obtiene el ID de la venta insertada
            $id_venta = $this->DB->lastInsertId();
            $rows_af = 0; // Inicializamos contador de filas afectadas por stock

            // Itera sobre el arreglo de detalles de la venta
            foreach ($detalles as $detalle_venta) {
                // Query para el detalle de la venta (Se corrige :id_compra a :id_venta)
                $query_detalles = "INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal) 
            VALUES (:id_venta, :id_producto, :cant, :cost_unid, :sub)";

                // Prepara la consulta para el detalle
                $stmt_detalles = $this->DB->prepare($query_detalles);

                // Ejecuta la consulta para cada detalle (Se corrige :id_compra a :id_venta)
                $stmt_detalles->execute([
                    ':id_venta' => $id_venta,
                    ':id_producto' => $detalle_venta['id_producto'],
                    ':cant' => $detalle_venta['cantidad'],
                    ':cost_unid' => $detalle_venta['precio_unitario'],
                    ':sub' => ($detalle_venta['precio_unitario'] * $detalle_venta['cantidad'])
                ]);

                // Maneja la disminución del stock
                $query_stock = "UPDATE stock SET cantidad_actual= cantidad_actual - :cantidad WHERE id_producto = :id_p AND id_ubicacion = :id_u";
                $stmt_stock = $this->DB->prepare($query_stock);
                $stmt_stock->execute([
                    ':cantidad' => $detalle_venta['cantidad'],
                    ':id_p' => $detalle_venta['id_producto'],
                    ':id_u' => $detalle_venta['id_ubicacion']
                ]);
                $rows_af += $stmt_stock->rowCount(); // Sumamos filas afectadas

            }

            // Verifica si las consultas se ejecutaron correctamente
            if ($id_venta && $rows_af > 0) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception("Algo ha salido mal en el registro de la venta", 500);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}