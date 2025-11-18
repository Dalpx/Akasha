<?php

class ventaController
{

    protected $DB;

    public function __construct($pdo)
    {
        $this->DB = $pdo;
    }

    public function getVenta(?int $id)
    {
        try {
            if ($id !== null) {
                $query = "SELECT v.id_venta, v.fecha_hora as 'fecha', v.nro_comprobante as 'numero_comprobante', c.nombre as 'nombre_cliente', v.subtotal, v.impuesto, v.total, 
                    tp.nombre as 'metodo_pago', u.nombre_completo 
                    as 'registrado_por', u.email, tu.nombre_tipo_usuario FROM venta as v 
                    INNER JOIN tipo_pago as tp ON v.id_tipo_comprobante=tp.id_tipo_comprobante 
                    INNER JOIN cliente as c ON v.id_cliente=c.id_cliente 
                    INNER JOIN usuario as u ON v.id_usuario=u.id_usuario 
                    INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario WHERE id_venta = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(pdo::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Registro de venta no encontrado', 404);
                }
            } else {
                $query = "SELECT v.id_venta, v.fecha_hora as 'fecha', v.nro_comprobante as 'numero_comprobante', c.nombre as 'nombre_cliente', v.subtotal, v.impuesto, v.total, 
                    tp.nombre as 'metodo_pago', u.nombre_completo 
                    as 'registrado_por', u.email, tu.nombre_tipo_usuario FROM venta as v 
                    INNER JOIN tipo_pago as tp ON v.id_tipo_comprobante=tp.id_tipo_comprobante 
                    INNER JOIN cliente as c ON v.id_cliente=c.id_cliente 
                    INNER JOIN usuario as u ON v.id_usuario=u.id_usuario 
                    INNER JOIN tipo_usuario as tu ON u.id_tipo_usuario=tu.id_tipo_usuario";

                $stmt = $this->DB->prepare($query);
                $stmt->execute();
                $result = $stmt->fetch(pdo::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Registro de venta no encontrado', 404);
                }
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function addVenta(){

        $body = json_decode(file_get_contents('php://input'), true);
        try {
            // Debido a que este JSON es algo más complejo y tiene un arreglo de arreglos, debemos extraer los arreglos por partes
            $compra = $body['venta'];
            $detalles = $body['detalle_venta'];

            $this->DB->beginTransaction();

            // Query para la cabecera de la compra
            $query_compra = "INSERT INTO venta (nro_comprobante, id_tipo_comprobante, id_cliente, id_usuario, subtotal, impuesto, total, estado) 
        VALUES (:num_comp, :id_tc, :id_prov, :id_usuario, :sub, :imp, :total, :estado)";

            // Prepara la consulta
            $stmt_compra = $this->DB->prepare($query_compra);

            // Ejecuta la consulta
            $stmt_compra->execute([
                ':num_comp' => $compra['nro_comprobante'],
                ':id_tc' => $compra['id_tipo_comprobante'],
                ':id_prov' => $compra['id_cliente'],
                ':id_usuario' => $compra['id_usuario'],
                ':sub' => $compra['subtotal'],
                ':imp' => $compra['impuesto'],
                ':total' => $compra['total'],
                ':estado' => $compra['estado']
            ]);

            // Obtiene el ID de la compra insertada
            $id_venta = $this->DB->lastInsertId();

            // Itera sobre el arreglo de detalles de la compra
            foreach ($detalles as $detalle_venta) {
                // Query para el detalle de la compra
                $query_detalles = "INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal) 
            VALUES (:id_compra, :id_producto, :cant, :cost_unid, :sub)";

                // Prepara la consulta para el detalle
                $stmt_detalles = $this->DB->prepare($query_detalles);

                // Ejecuta la consulta para cada detalle
                $stmt_detalles->execute([
                    ':id_compra' => $id_venta,
                    ':id_producto' => $detalle_venta['id_producto'],
                    ':cant' => $detalle_venta['cantidad'],
                    ':cost_unid' => $detalle_venta['precio_unitario'],
                    // El subtotal se calcula: costo_unitario * cantidad
                    ':sub' => ($detalle_venta['precio_unitario'] * $detalle_venta['cantidad'])
                ]);
            }

            // Verifica si las consultas se ejecutaron correctamente
            if ($stmt_compra && $stmt_detalles) {
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
