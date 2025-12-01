<?php

class compraController
{

    protected $DB;

    public function __construct($pdo)
    {
        $this->DB = $pdo;
    }

    public function getCompra(?int $id)
    {
        //Lógica para la obtención detallada de los datos de una venta
        try {
            if ($id !== null) {
                 //Query mastodóntica para el caso en el que se nos envie una ID mediante get
                $query = "SELECT c.id_compra, c.fecha_hora, c.nro_comprobante, c.subtotal, c.impuesto, c.total, tp.nombre, pr.nombre, u.nombre_completo AS 'hecho_por', 
                u.email, tu.nombre_tipo_usuario FROM compra AS c 
                INNER JOIN tipo_pago AS tp ON c.id_tipo_comprobante=tp.id_tipo_comprobante 
                INNER JOIN proveedor AS pr ON c.id_proveedor=pr.id_proveedor 
                INNER JOIN usuario AS u ON c.id_usuario=u.id_usuario 
                INNER JOIN tipo_usuario AS tu ON u.id_tipo_usuario = tu.id_tipo_usuario WHERE c.id_compra = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Registro de compra no encontrado', 404);
                }
            } else {
                //Query mastodóntica para el caso en el que no nos se nos envíe un ID, por lo cual retornamos todo
                $query = "SELECT c.id_compra, c.fecha_hora, c.nro_comprobante, c.subtotal, c.impuesto, c.total, tp.nombre, pr.nombre, u.nombre_completo AS 
                'hecho_por', u.email, tu.nombre_tipo_usuario FROM compra AS c 
                INNER JOIN tipo_pago AS tp ON c.id_tipo_comprobante=tp.id_tipo_comprobante 
                INNER JOIN proveedor AS pr ON c.id_proveedor=pr.id_proveedor 
                INNER JOIN usuario AS u ON c.id_usuario=u.id_usuario 
                INNER JOIN tipo_usuario AS tu ON u.id_tipo_usuario = tu.id_tipo_usuario";
                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Registro de compra no encontrado', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addCompra()
    {
        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);
        try {
            // Debido a que este JSON es algo más complejo y tiene un arreglo de arreglos, debemos extraer los arreglos por partes
            $compra = $body['compra'];
            $detalles = $body['detalle_compra'];

            $this->DB->beginTransaction();

            // Query para la cabecera de la compra
            $query_compra = "INSERT INTO compra (nro_comprobante, id_tipo_comprobante, id_proveedor, id_usuario, subtotal, impuesto, total, estado) 
        VALUES (:num_comp, :id_tc, :id_prov, :id_usuario, :sub, :imp, :total, :estado)";
            $stmt_compra = $this->DB->prepare($query_compra);

            // Ejecuta la consulta
            $stmt_compra->execute([
                ':num_comp' => $compra['nro_comprobante'],
                ':id_tc' => $compra['id_tipo_comprobante'],
                ':id_prov' => $compra['id_proveedor'],
                ':id_usuario' => $compra['id_usuario'],
                ':sub' => $compra['subtotal'],
                ':imp' => $compra['impuesto'],
                ':total' => $compra['total'],
                ':estado' => $compra['estado']
            ]);

            // Obtiene el ID de la compra insertada
            $id_compra = $this->DB->lastInsertId();
            // Itera sobre el arreglo de detalles de la compra
            foreach ($detalles as $detalle_compra) {
                // Query para el detalle de la compra
                $query_detalles = "INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario, subtotal) 
                VALUES (:id_compra, :id_producto, :cant, :cost_unid, :sub)";

                // Prepara la consulta para el detalle
                $stmt_detalles = $this->DB->prepare($query_detalles);

                // Ejecuta la consulta para cada detalle
                $stmt_detalles->execute([
                    ':id_compra' => $id_compra,
                    ':id_producto' => $detalle_compra['id_producto'],
                    ':cant' => $detalle_compra['cantidad'],
                    ':cost_unid' => $detalle_compra['precio_unitario'],
                    // El subtotal se calcula: costo_unitario * cantidad
                    ':sub' => ($detalle_compra['precio_unitario'] * $detalle_compra['cantidad'])
                ]);

                //Maneja el aumento de stock tras la compra
                $query_stock = "UPDATE stock SET cantidad_actual= cantidad_actual + :cantidad WHERE id_producto = :id_p AND id_ubicacion = :id_u";
                $stmt_stock = $this->DB->prepare($query_stock);
                $stmt_stock->execute([
                    ':cantidad' => $detalle_compra['cantidad'],
                    ':id_p' => $detalle_compra['id_producto'],
                    ':id_u' => $detalle_compra['id_ubicacion']
                ]);
                $rows_af = $stmt_stock->rowCount();
            }

            // Verifica si las consultas se ejecutaron correctamente
            if ($stmt_compra && $stmt_detalles && $rows_af > 0) {
                $this->DB->commit();
                return true;
            } else {
                // Si algo salió mal, lanza una excepción (la transacción se revierte automáticamente)
                throw new Exception("Algo ha salido mal en el registro de compra", 500);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }
}
