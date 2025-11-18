<?php

class productoController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getProducto(?int $id)
    {
        try {
            //Lógica de transacción, si tenemos ID, buscamos la entrada que coincida con dicha ID
            if ($id !== null) {
                $query = "SELECT producto.id_producto, producto.nombre, producto.sku, producto.descripcion, producto.precio_costo, producto.precio_venta, producto.activo, proveedor.id_proveedor
                AS id_prov FROM producto INNER JOIN proveedor on producto.id_proveedor=proveedor.id_proveedor WHERE producto.id_producto = :id";
                $stmt = $this->DB->prepare($query);
                $result = $stmt->execute([':id' => $id]);
                $result = $stmt->fetch(\pdo::FETCH_ASSOC);
                //Mensajes de respuesta
                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Producto no encontrado', 404);
                }
            } else {
                //De no ser el caso, obtenemos todos los datos de la tabla (como sería en el caso de obtención al iniciar sesión en el programa)    
                $query = "SELECT producto.id_producto, producto.nombre, producto.sku, producto.descripcion, producto.precio_costo, producto.precio_venta, proveedor.id_proveedor 
                AS id_prov, producto.activo FROM producto INNER JOIN proveedor on producto.id_proveedor=proveedor.id_proveedor";
                $stmt = $this->DB->prepare($query);
                $result = $stmt->execute();
                $result = $stmt->fetchAll(\pdo::FETCH_ASSOC);
                //Mensajes de respuesta
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

    public function addProducto()
    {

        $body = json_decode(file_get_contents('php://input'), true);

        //Del JSON extraemos los datos
        $nom = $body['nombre'];
        $sku = $body['sku'];
        $desc = $body['descripcion'];
        $pre_c = floatval($body['precio_costo']);
        $pre_v = floatval($body['precio_venta']);
        $id_p = $body['id_proveedor'];

        try {
            //Lógica de transacción que nos permite interactuar con la DB
            $query = "INSERT INTO producto (nombre, sku, descripcion, precio_costo, precio_venta, id_proveedor) 
            VALUES (:nomprod, :sku, :descr, :precost, :pre_vent, :id_prov)";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nomprod' => $body['nombre'],
                ':sku' => $body['sku'],
                ':descr' => $body['descripcion'],
                ':precost' => floatval($body['precio_costo']),
                ':pre_vent' => floatval($body['precio_venta']),
                ':id_prov' => $body['id_proveedor']
            ]);
            //Mensajes de respuesta
            if ($result) {
                return $result;
            } else {
                throw new Exception('Ha ocurrido un error', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function updateProducto()
    {

        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);

        try {
            //Lógica de transacción, buscamos el producto con el ID que sea idéntico
            $query = "UPDATE producto SET nombre=:nomprod, sku=:sku, descripcion=:descr, precio_costo=:pre_c, 
        precio_venta=:pre_v WHERE id_producto = :id_p";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nomprod' => $body['nombre'],
                ':sku' => $body['sku'],
                ':descr' => $body['descripcion'],
                ':pre_c' => floatval($body['precio_costo']),
                'pre_v' => floatval($body['precio_venta']),
                ':id_p' => $body['id_producto']
            ]);
            //Mensajes de respuesta
            if ($result) {
                return $result;
            } else {
                throw new Exception('Algo ha sucedido mal', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function deleteProducto()
    {
        //Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);
        $id = $body['id_producto'];

        try {
            //Lógica para eliminación de producto, la cual es una eliminación lógica, no física.
            $query = "UPDATE producto SET activo=0 WHERE id_producto=:id";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id' => $id]);
            //Debido a la naturaleza de SQL, la transacción no marca error incluso si es duplicada, entonces obtenemos la cantidad de columnas
            //afectadas con el objetivo de saber si se hizo algo
            $rows_af = $stmt->rowCount();

            //En base al número de columnas afectadas, podemos retornar un mensaje de error o success
            if ($rows_af > 0) {
                return true;
            } else if ($rows_af == 0) {
                throw new Exception('El producto ya ha sido eliminado o no fue posible encontrarlo', 404);
            } else {
                throw new Exception('Se ha producido un error', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}
