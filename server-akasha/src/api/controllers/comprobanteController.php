<?php

class comprobanteController
{
    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

    public function getComprobante()
    {
        try {
            $query = "SELECT * FROM tipo_pago";

            $stmt = $this->DB->prepare($query);
            $stmt->execute();

            // Usamos fetchAll para obtener múltiples ventas si no hay ID, 
            // o un array de una venta si hay ID
            $comprobante = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if ($comprobante) {
                return $comprobante;
            } else {
                throw new Exception('Comprobante no encontrado', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }
}