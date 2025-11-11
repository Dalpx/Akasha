<?php

class DBConnection {
    // Propiedad estática para mantener la única instancia de la clase
    private static ?DBConnection $instance = null;

    // Propiedad para almacenar el objeto PDO
    private ?\PDO $pdo = null;

    // Configuración de la base de datos
    private const DB_HOST = 'localhost';
    private const DB_NAME = 'akasha';
    private const DB_USER = 'root';
    private const DB_PASS = '';
    private const DB_CHARSET = 'utf8mb4';

    /*  El constructor es privado para evitar crear la clase directamente.
    La conexión real se realiza aquí. */

    private function __construct() {
        $dsn = "mysql:host=" . self::DB_HOST . ";dbname=" . self::DB_NAME . ";charset=" . self::DB_CHARSET;
        $options = [
            // Activar excepciones en caso de error
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
            // Devolver resultados como objetos anónimos por defecto
            \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_OBJ, 
            // Deshabilitar preparación de sentencias emuladas para mayor seguridad
            \PDO::ATTR_EMULATE_PREPARES => false,
        ];

        try {
            $this->pdo = new \PDO($dsn, self::DB_USER, self::DB_PASS, $options);
        } catch (\PDOException $e) {
            // Detener la ejecución si la conexión falla
            throw new \PDOException("Fallo en la conexión a la base de datos: " . $e->getMessage(), 500);
        }
    }

    /**
     * El método estático para obtener la instancia única de la clase.
     * Crea la instancia si no existe (y por ende, establece la conexión).
     *
     * @return DBConnection La instancia única de la clase de conexión.
     */
    public static function getInstance(): DBConnection {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Método público que retorna el objeto PDO.
     *
     * @return \PDO 
     */
    public function getPDO(): \PDO {
        return $this->pdo;
    }

    // Evitar que la instancia se pueda clonar
    private function __clone() {}
    // Evitar que se pueda deserializar (para mayor seguridad en Singleton)
    public function __wakeup() {}
}

?>