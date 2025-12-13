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
        if ($validator->entityAlreadyExists('producto', $body['id_producto'])) {
            throw new Exception('Otro producto ya utiliza este SKU.', 409);
        }

        // VALIDACIÓN DE 'id_producto' ES CRUCIAL, ya que es el WHERE
        if (!isset($body['id_producto'])) {
            throw new Exception('Falta el ID del producto para la actualización.', 400);
        }

        try {
            $this->DB->beginTransaction();

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
            // MENSAJES DE RESPUESTA
            // ----------------------------------------------------
            // Solo verificamos el resultado de la actualización del producto
            if ($result_prod) {
                $this->DB->commit();
                return ['success' => true, 'message' => 'Producto actualizado correctamente (información base).'];
            } else {
                $this->DB->rollBack();
                // Lanza una excepción si el producto no pudo actualizarse
                throw new Exception("Fallo en la actualización del producto. Verifique el ID.", 500);
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
