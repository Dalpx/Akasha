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


    public function productoAlreadyExists()
    {

        $query = "SELECT sku FROM producto WHERE sku = :sku";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([':sku' => $this->data['sku']]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($result) {
            return true;
        } else return false;
    }

    public function ubicacionIsNotUnique()
    {
        $query = "SELECT COUNT(*) FROM stock WHERE id_producto = :id_prod  AND id_ubicacion = :id_ubi";
        $stmt = $this->DB->prepare($query);
        $stmt->execute([
            ':id_prod' => $this->data['id_producto'],
            ':id_ubi' =>  $this->data['id_ubicacion']
        ]);

        $count = $stmt->fetchColumn();

        if ($count > 0){
            return true;
        }else return false;
        
    }
}
