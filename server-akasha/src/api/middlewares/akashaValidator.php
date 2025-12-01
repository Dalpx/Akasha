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
    public function productoAlreadyExists()
    {

        $query = "SELECT sku FROM producto WHERE sku = :sku";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([':sku' => $this->data['sku']]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($result) return true;
        else return false;
    }

    public function usuarioAlreadyExists()
    {

        $query = "SELECT nombre_completo FROM usuario WHERE nombre_completo = :nom_c";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([':nom_c' => $this->data['nombre_completo']]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($result) return true;
        else return false;
    }

    //Mide la longitud del SKU, tiene que ser entre 8 y 12 caracteres
    public function skuLength()
    {
        $len = mb_strlen($this->data['sku'], 'UTF-8');

        if ($len >= 8 && $len <= 12) return false;
        else return true;
    }

    //Esta función nos permite verificar que la combinación de id_ubicacion e id_producto sea única, de forma que se pueda lanzar un error personalizado
    //en lugar de simplemente lanzar la excepcion SQL
    public function ubicacionIsNotUnique()
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

    private function esNombreCompletoValido(string $nombre): bool
    {
        // Patrón Regex: requiere que el nombre tenga al menos un espacio 
        // entre palabras y solo contenga letras, acentos y la ñ.
        // El modificador 'u' es crucial para Unicode (acentos/ñ).
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
        
        if($len_pass < 8 || $len_pass > 64){
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
}
