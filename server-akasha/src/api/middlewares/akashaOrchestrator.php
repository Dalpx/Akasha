<?php
include_once __DIR__ . '/../api_router.php';
//En este archivo se manejan todos los registros akáshicos

class productoOrchestrator
{

    public static function getProducto(?int $id,  array $parts)
    {
        try {
            //Pequeña condición la cual nos deja saber si el programa pidio un id o no, si es un valor numérico presente en la URI, lo guarda
            //sino, se asigna null, que devuelve todas las entradas.
            $id = is_numeric(end($parts)) ? (int)end($parts) : null;
            $con = DBConnection::getInstance()->getPDO(); //Instancia de la DB y obtención del PDO
            $controller = new productoController($con); //productoController recibe el PDO como parámetro al ser instanciado
            $result = $controller->getProducto($id); //Método para obtener producto que puede recibir una id numérica o null
            return $result; //Retornar resultado
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function addProducto() //Lógica para añadir productos
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new productoController($con);
            $result = $controller->addProducto();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function editProducto() //Lógica para editar productos
    {

        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new productoController($con);
            $result = $controller->updateProducto();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function deleteProducto() //Lógica para eliminar de manera lógica productos
    {

        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new productoController($con);
            $result = $controller->deleteProducto();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }
}

class loginOrchestrator{
        
        public static function loginHandler(){
            $con = DBConnection::getInstance()->getPDO();
            $controller = new loginController($con);
            $result = $controller->loginHandler();
            return $result;
        }
    }
