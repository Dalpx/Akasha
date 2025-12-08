<?php
require_once __DIR__ . '/../middlewares/akashaValidator.php';

class productoController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getProducto(?int $id)
    {
        $query = "SELECT p.id_producto, p.nombre, p.sku, p.descripcion, p.precio_costo, p.precio_venta, pr.nombre as nombre_proveedor, 
                c.nombre_categoria as categoria, p.activo FROM producto as p 
                INNER JOIN proveedor as pr ON p.id_proveedor=pr.id_proveedor 
                INNER JOIN categoria as c ON p.id_categoria=c.id_categoria";
        try {
            //Lógica de transacción, si tenemos ID, buscamos la entrada que coincida con dicha ID
            if ($id !== null) {
                $query . "WHERE p.id_producto=:id";
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
        //Del JSON extraemos los datos y hacemos un array asociativo
        $body = json_decode(file_get_contents('php://input'), true);

        //Instanciamos akashaValidator y hacemos la validación de si el SKU ya existe, y si el SKU tiene la longitud requerida
        $validator = new akashaValidator($this->DB, $body);
        if ($validator->entityAlreadyExists('producto')) {
            throw new Exception('Un producto con este SKU ya existe.', 409);
        }/*else if($validator->skuLength()){
            throw new Exception('La longitud del SKU debe estar entre 8 y 12 caracteres', 400);
        }*/

        try {
            //Lógica de transacción que nos permite interactuar con la DB
            $this->DB->beginTransaction();
            $query = "INSERT INTO producto (nombre, sku, descripcion, precio_costo, precio_venta, id_proveedor, id_categoria) 
                VALUES (:nomprod, :sku, :descr, :precost, :pre_vent, :id_prov, :id_cat)";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':nomprod' => $body['nombre'],
                ':sku' => $body['sku'],
                ':descr' => $body['descripcion'],
                ':precost' => floatval($body['precio_costo']),
                ':pre_vent' => floatval($body['precio_venta']),
                ':id_prov' => $body['id_proveedor'],
                ':id_cat' => $body['id_categoria']
            ]);

            //Mensajes de respuesta
            if ($stmt) {
                $this->DB->commit();
                return true;
            } else {
                throw new Exception('Ha ocurrido un error', 500);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
            throw $e;
        }
    }


    public function updateProducto()
    {
        // Del JSON extraemos los datos
        $body = json_decode(file_get_contents('php://input'), true);

        $validator = new akashaValidator($this->DB, $body);
        // Valida que el SKU tenga la longitud deseada
        if ($validator->skuLength()) {
            throw new Exception('La longitud del SKU debe estar entre 8 y 12 caracteres', 400);
        }

        // Aseguramos que los datos necesarios para la lógica de stock existan en el body
        if (!isset($body['id_producto'], $body['id_ubicacion'])) {
            throw new Exception('Faltan datos de producto o ubicación para la actualización.', 400);
        }

        try {
            $this->DB->beginTransaction();

            // ----------------------------------------------------
            // PASO 1: Lógica de actualización de la tabla 'producto'
            // ----------------------------------------------------
            $query_prod = "UPDATE producto SET 
                            nombre=:nomprod, 
                            sku=:sku, 
                            descripcion=:descr, 
                            precio_costo=:pre_c, 
                            precio_venta=:pre_v, 
                            id_proveedor=:id_prov, 
                            id_categoria=:id_cat 
                        WHERE id_producto = :id_p";
            $stmt_prod = $this->DB->prepare($query_prod);
            $result_prod = $stmt_prod->execute([
                ':nomprod' => $body['nombre'],
                ':sku' => $body['sku'],
                ':descr' => $body['descripcion'],
                ':pre_c' => floatval($body['precio_costo']),
                ':pre_v' => floatval($body['precio_venta']),
                ':id_prov' => $body['id_proveedor'],
                ':id_cat' => $body['id_categoria'],
                ':id_p' => $body['id_producto']
            ]);

            // ----------------------------------------------------
            // PASO 2: Lógica de reubicación de STOCK
            // ----------------------------------------------------

            // 2.1 Obtener la ubicación y cantidad actuales del producto
            $query_current_stock = "SELECT id_ubicacion, cantidad_actual 
                                FROM stock 
                                WHERE id_producto = :id_p";
            $stmt_current_stock = $this->DB->prepare($query_current_stock);
            $stmt_current_stock->execute([':id_p' => $body['id_producto']]);
            $current_stock = $stmt_current_stock->fetch(PDO::FETCH_ASSOC);

            // Si existe stock registrado y la ubicación nueva es diferente a la antigua
            if ($current_stock && $current_stock['id_ubicacion'] != $body['id_ubicacion']) {

                // 2.2 Eliminar la fila de stock antigua (rompe la clave primaria compuesta)
                $query_delete = "DELETE FROM stock 
                             WHERE id_producto = :id_p AND id_ubicacion = :old_ubi";
                $stmt_delete = $this->DB->prepare($query_delete);
                $result_delete = $stmt_delete->execute([
                    ':id_p' => $body['id_producto'],
                    ':old_ubi' => $current_stock['id_ubicacion']
                ]);

                // 2.3 Insertar la nueva fila con la nueva ubicación y la cantidad_actual que tenía
                // Usamos INSERT en lugar de UPDATE para crear la nueva clave primaria (id_producto, id_ubicacion)
                $query_insert = "INSERT INTO stock (id_producto, id_ubicacion, cantidad_actual) 
                             VALUES (:id_p, :new_ubi, :cantidad)";
                $stmt_insert = $this->DB->prepare($query_insert);
                $result_insert = $stmt_insert->execute([
                    ':id_p' => $body['id_producto'],
                    ':new_ubi' => $body['id_ubicacion'],
                    ':cantidad' => $current_stock['cantidad_actual']
                ]);

                $result_stock = $result_delete && $result_insert;
            } else if ($current_stock && $current_stock['id_ubicacion'] == $body['id_ubicacion']) {
                // Si la ubicación es la misma, no se hace nada en la tabla 'stock'
                $result_stock = true;
            } else {
                // El producto no tenía stock, se omite la lógica de reubicación, pero la actualización del producto sigue
                $result_stock = true;
            }


            // ----------------------------------------------------
            // PASO 3: Mensajes de respuesta
            // ----------------------------------------------------
            if ($result_prod && $result_stock) {
                $this->DB->commit();
                return ['success' => true, 'message' => 'Producto y stock actualizados correctamente.'];
            } else {
                $this->DB->rollBack();
                // Lanza una excepción más específica si es posible
                throw new Exception("Fallo en la actualización del producto o el stock.", 500);
            }
        } catch (Exception $e) {
            $this->DB->rollBack();
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
