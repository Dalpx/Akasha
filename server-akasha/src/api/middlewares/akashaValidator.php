<?php

class akashaValidator
{

    protected $DB;
    protected $data;

    public function __construct(\PDO $pdo, array $body)
    {
        $this->DB = $pdo;
        $this->data = $body;
    }

    //Función que chquea si el producto ya existe mediante el SKU que tiene la restricción UNIQUE
    //También chequea si un usuario ya existe mediante el nombre de usuario y si un cliente existe mediante el número de documento
    /**
     * Función que chequea si la entidad ya existe (producto por SKU, usuario por nombre, cliente por documento, proveedor por nombre)
     * @param string $tipo El tipo de entidad a verificar ('producto', 'usuario', 'cliente', 'proveedor').
     * @param ?int $excludeId ID de la entidad a excluir de la comprobación (usado en actualizaciones).
     * @return bool
     */
    public function entityAlreadyExists(string $tipo, ?int $excludeId = null): bool
    {
        switch ($tipo) {
            case 'producto':
                $query = "SELECT sku FROM producto WHERE sku = :sku";
                $params = [':sku' => $this->data['sku']];

                if ($excludeId !== null) {
                    $query .= " AND id_producto != :id_excluir";
                    $params[':id_excluir'] = $excludeId;
                }
                break;

            case 'usuario':
                $query = "SELECT nombre_usuario FROM usuario WHERE nombre_usuario = :nom_u";
                $params = [':nom_u' => $this->data['usuario']];

                if ($excludeId !== null) {
                    $query .= " AND id_usuario != :id_excluir";
                    $params[':id_excluir'] = $excludeId;
                }
                break;

            case 'cliente':
                $query = "SELECT nro_documento FROM cliente WHERE nro_documento = :nro_d";
                $params = [':nro_d' => $this->data['nro_documento']];

                if ($excludeId !== null) {
                    $query .= " AND id_cliente != :id_excluir";
                    $params[':id_excluir'] = $excludeId;
                }
                break;

            case 'proveedor':
                $query = "SELECT nombre FROM proveedor WHERE nombre = :nom";
                $params = [':nom' => $this->data['nombre']];

                if ($excludeId !== null) {
                    $query .= " AND id_proveedor != :id_excluir";
                    $params[':id_excluir'] = $excludeId;
                }
                break;

            case 'categoria':
                $query = "SELECT nombre_categoria FROM categoria WHERE nombre_categoria = :nom";
                $params = [':nom' => $this->data['nombre_categoria']];

                if ($excludeId !== null) {
                    $query .= " AND id_categoria != :id_excluir";
                    $params[':id_excluir'] = $excludeId;
                }
                break;

            case 'ubicacion':
                $query = "SELECT nombre_almacen FROM ubicacion WHERE nombre_almacen = :nom";
                $params = [':nom' => $this->data['nombre_almacen']];

                if ($excludeId !== null) {
                    $query .= " AND id_ubicacion != :id_excluir";
                    $params[':id_excluir'] = $excludeId;
                }
                break;

            default:
                return false;
        }

        $stmt = $this->DB->prepare($query);
        $stmt->execute($params);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        return (bool)$result;
    }

    public function isAssigned(string $tipo)
    {
        switch ($tipo) {
            case 'proveedor': // Validación de Proveedor
                $query = "SELECT COUNT(*) FROM producto WHERE id_proveedor = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $this->data['id_prov']]);
                $count = $stmt->fetchColumn();

                if ($count > 0) {
                    return true;
                }
                break;

            case 'categoria': // Validación de Categoría
                $query = "SELECT COUNT(*) FROM producto WHERE id_categoria = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $this->data['id_categoria']]);
                $count = $stmt->fetchColumn();

                if ($count > 0) {
                    return true;
                }
                break;

            case 'ubicacion': // Validación de Ubicación
                $query = "SELECT COUNT(*) FROM stock WHERE id_ubicacion = :id";
                $stmt = $this->DB->prepare($query);
                $stmt->execute([':id' => $this->data['id_ubicacion']]);
                $count = $stmt->fetchColumn();

                if ($count > 0) {
                    return true;
                }
                break;

            default:
                return false;
        }
        return false;
    }

    //Mide la longitud del SKU, tiene que ser entre 8 y 12 caracteres
    public function skuLength(): bool
    {
        $len = mb_strlen($this->data['sku'], 'UTF-8');

        if ($len < 8 && $len > 12) return true;
        else return false;
    }

    public function stockIsNotEmpty(): bool
    {
        $query = "SELECT cantidad_actual FROM stock WHERE id_producto = :id_prod AND id_ubicacion = :id_ubi";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([
            ':id_prod' => $this->data['id_producto'],
            ':id_ubi' => $this->data['id_ubicacion']
        ]);
        $count = $stmt->fetchColumn();

        if ($count > 0) return true;

        else return false;
    }

    /**
     * Valida que la cantidad solicitada no supere el stock actual.
     * Itera sobre el array de detalles incluido en el JSON.
     * * @return string|bool Retorna un mensaje de error (string) si falta stock, o false si todo está correcto.
     */
    public function checkStockAvailability(): string|bool
    {
        // Verificamos que existan detalles en el JSON
        if (!isset($this->data['detalle_venta']) || !is_array($this->data['detalle_venta'])) {
            return "No se han proporcionado detalles de venta válidos.";
        }

        foreach ($this->data['detalle_venta'] as $item) {
            // Validamos que vengan los datos mínimos necesarios
            if (!isset($item['id_producto'], $item['id_ubicacion'], $item['cantidad'])) {
                return "Datos incompletos en el detalle de venta (se requiere id_producto, id_ubicacion y cantidad).";
            }

            $id_producto = $item['id_producto'];
            $id_ubicacion = $item['id_ubicacion'];
            $cantidad_solicitada = $item['cantidad'];

            // Consultamos la cantidad actual en la tabla stock
            // Es vital filtrar por producto Y ubicación, ya que el stock se divide por almacenes
            $query = "SELECT cantidad_actual FROM stock WHERE id_producto = :id_p AND id_ubicacion = :id_u";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([
                ':id_p' => $id_producto,
                ':id_u' => $id_ubicacion
            ]);

            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            // Si no existe registro en stock, asumimos cantidad 0
            $cantidad_actual = $result ? (int)$result['cantidad_actual'] : 0;

            // COMPARACIÓN: Si lo que pide el cliente es mayor a lo que hay
            if ($cantidad_solicitada > $cantidad_actual) {
                return "Stock insuficiente para el producto ID $id_producto en la ubicación ID $id_ubicacion. Solicitado: $cantidad_solicitada, Disponible: $cantidad_actual.";
            }
        }

        // Si el bucle termina sin retornar errores, es que hay stock para todo
        return false;
    }

    //Esta función nos permite verificar que la combinación de id_ubicacion e id_producto sea única, de forma que se pueda lanzar un error personalizado
    //en lugar de simplemente lanzar la excepcion SQL
    public function ubicacionIsNotUnique(): bool
    {
        $query = "SELECT COUNT(*) FROM stock WHERE id_producto = :id_prod AND id_ubicacion = :id_ubi";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([
            ':id_prod' => $this->data['id_producto'],
            ':id_ubi' =>  $this->data['id_ubicacion']
        ]);

        $count = $stmt->fetchColumn();

        if ($count > 0) return true;
        else return false;
    }

    //Función auxiliar que evalúa el formato del nombre completo para los clientes (seguramente cambiará)
    private function esNombreCompletoValido(string $nombre): bool
    {
        // Patrón Regex: requiere que el nombre tenga al menos un espacio 
        // entre palabras y solo contenga letras, acentos y la ñ
        // El modificador u permite acentos/ñ
        $patron_nombre = "/^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?:[\s][a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+)+$/u";

        // Devuelve true si el nombre cumple el patrón
        return preg_match($patron_nombre, $nombre) === 1;
    }

    public function usuarioIsValid(): string|bool
    {
        $usuario = $this->data['usuario'] ?? '';
        $nombre_completo = $this->data['nombre_completo'] ?? '';
        $email = $this->data['email'] ?? '';
        $password = $this->data['clave_hash'];

        //Validar la Longitud del nombre de usuario y contraseña
        $len_user = mb_strlen($usuario, 'UTF-8');
        $len_pass = mb_strlen($password, 'UTF-8');

        if ($len_user < 3 || $len_user > 36) {
            //Devuelve el mensaje de error si la longitud falla
            return "El nombre de usuario debe tener entre 3 y 36 caracteres.";
        }

        if ($len_pass < 8 || $len_pass > 64) {
            //Devuelve el mensaje de error si la longitud falla
            return "La contraseña debe tener entre 8 y 64 caracteres";
        }

        //Validar el Nombre Completo
        if (!$this->esNombreCompletoValido($nombre_completo)) {
            // Devuelve el mensaje de error si el nombre es inválido
            return "El nombre completo es inválido. Debe contener al menos un nombre y un apellido (solo letras y espacios).";
        }

        //Validar el Email
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            // Devuelve el mensaje de error si el email es inválido
            return "El formato del correo electrónico proporcionado es incorrecto.";
        }

        // Si pasa todas las validaciones, devuelve false (indicando que NO hay error)
        return false;
    }

    private function documentoIsValid(int $tipo_doc): bool
    {
        // 1. Validar Cédula (tipo 1)
        if ($tipo_doc == 1) {
            $patron_cedula = '/^(V|E)-\d{8,9}$/i';
            // Si NO COINCIDE, la función es Inválida. Retornamos TRUE y salimos.
            if (!preg_match($patron_cedula, $this->data['nro_documento'])) {
                return true;
            }
        }

        // 2. Validar Pasaporte (tipo 2)
        else if ($tipo_doc == 2) {
            // Patrón para pasaporte: 9 a 15 caracteres alfanuméricos.
            $patron_pasaporte = '/^P-[A-Z0-9]{9,15}$/i';
            // Si NO COINCIDE, la función es Inválida. Retornamos TRUE y salimos.
            if (!preg_match($patron_pasaporte, $this->data['nro_documento'])) {
                return true;
            }
        }

        return false;
    }

    private function isTelefonoValid(): bool
    {
        //Patrón para el teléfono, que admite todos los códigos existentes, y el all new 0422 by Digitel
        $patron_telefono = '/^(0412|0422|0414|0424|0416|0426)\d{7}$/';
        //Si no coincide, la función retorna true
        if (!preg_match($patron_telefono, $this->data['telefono'])) return true;
        else return false;
    }

    //Validar formato de cédula o pasaporte, número de teléfono, no puede haber dos usuarios con el mismo documento
    public function clienteIsValid(): string|bool
    {
        $tipo_doc = $this->data['tipo_documento'];
        if ($tipo_doc == 1 && $this->documentoIsValid($tipo_doc)) {
            return 'El formato de la cédula no es válido, debe ser: V-12345678 o E-12345678 y debe estar entre 7 y 8 caracteres';
        } else if ($tipo_doc == 2 && $this->documentoIsValid($tipo_doc)) {
            return 'El formato del pasaporte no es válido. Debe contener entre 9 y 15 caracteres alfanuméricos.';
        } else if ($this->isTelefonoValid()) {
            return 'El formato del número de teléfono no es válido. Debe contener el identificador y los numeros adicionales, Ej: 0424-1112233';
        } else return false;
    }
}
