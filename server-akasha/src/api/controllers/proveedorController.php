<?php

use LDAP\Result;

class proveedorController
{

    protected $DB;

    public function __construct($pdo)
    {
        $this->DB = $pdo;
    }


    public function getProveedor(?int $id_prov)
    {

        try {
            if ($id_prov !== null) {
                $query = "SELECT * FROM proveedor WHERE id_proveedor  = :id";
                $stmt = $this->DB->prepare($query);
                $result = $stmt->execute([':id' => $id_prov]);
                $result = $stmt->fetch(pdo::FETCH_ASSOC);

                if ($result) {
                    return $result;
                } else {
                    throw new Exception('Proveedor no encontrado', 404);
                }
            } else {
                $query = "SELECT * from proveedor";
                $stmt =  $this->DB->prepare($query);
                $result = $stmt->execute();
                $result = $stmt->fetchAll(pdo::FETCH_ASSOC);

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

    public function addProveedor()
    {

        $body = json_decode(file_get_contents('php://input'), true);

        $nom = $body['nom_prov'];
        $canal = $body['canal'];
        $cont = $body['cont'];
        $dir = $body['dir'];

        try {
            $query = "INSERT INTO proveedor (nombre, canal, contacto, direccion, activo) VALUES
                    (:nom, :canal, :cont, :dir, 1)";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nom' => $nom,
                ':canal' => $canal,
                ':cont' => $cont,
                ':dir' => $dir
            ]);

            if ($result) {
                return $result;
            } else {
                throw new Exception('Ha ocurrido un error', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function updateProveedor(){

        $body = json_decode(file_get_contents('php://input'), true);

        $nom = $body['nom_prov'];
        $canal = $body['canal'];
        $cont = $body['cont'];
        $dir = $body['dir'];
        $id_p = $body['id_prov'];

        try {
            $query = "UPDATE proveedor SET nombre=:nom, canal=:canal, contacto=:cont,
            direccion=:dir WHERE id_proveedor = :id_prov";
            $stmt = $this->DB->prepare($query);
            $result = $stmt->execute([
                ':nom'=>$nom,
                ':canal'=>$canal,
                ':cont' => $cont,
                ':dir'=>$dir,
                ':id_prov' => $id_p
            ]);

            if($result){
                return $result;
            }else{
                throw new Exception('Producto no encontrado', 404);
            }
        } catch (Exception $e) {
            throw $e;
        }
    }

    public function deleteProveedor(){
        $body = json_decode(file_get_contents('php://input'), true);

        $id = $body ['id_prov'];

        try {
            $query ="UPDATE proveedor SET activo=false WHERE id_proveedor = :id_prov";
            $stmt = $this->DB->prepare($query);
            $stmt->execute([':id_prov'=>$id]);

            $rows_af = $stmt->rowCount();

            if($rows_af > 0){
                return true;
            }else if ($rows_af == 0){
                throw new Exception('El proveedor ya ha sido eliminado o no fue posible encontrarlo', 404);
            }else{
                throw new Exception('Se ha producido un error', 500);
            }
        } catch (Exception $e) {
            throw $e;
        }

    }
}
