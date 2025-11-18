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

class usuarioOrchestrator
{

    public static function getUsuario(?int $id, array $parts)
    {
        try {
            $id = is_numeric(end($parts)) ? (int)end($parts) : null;
            $con = DBConnection::getInstance()->getPDO();
            $controller = new usuarioController($con);
            $result = $controller->getUsuario($id);
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function createUsuario()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new usuarioController($con);
            $result = $controller->createUsuario();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function updateUsuario()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new usuarioController($con);
            $result = $controller->updateUsuario();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function deleteUsuario()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new usuarioController($con);
            $result = $controller->deleteUsuario();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }


    public static function loginHandler()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new usuarioController($con);
            $result = $controller->loginHandler();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }
}

class proveedorOrchestrator
{

    public static function getProveedor(?int $id, array $parts)
    {
        try {
            $id = is_numeric(end($parts)) ? (int)end($parts) : null;
            $con = DBConnection::getInstance()->getPDO();
            $controller = new proveedorController($con);
            $result = $controller->getProveedor($id);
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function addProveedor()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new proveedorController($con);
            $result = $controller->addProveedor();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function updateProveedor()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new proveedorController($con);
            $result = $controller->updateProveedor();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function deleteProveedor()
    {

        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new proveedorController($con);
            $result =  $controller->deleteProveedor();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }
}

class compraventaOrchestrator
{

    public static function getCompra(?int $id, array $parts)
    {
        try {
            $id = is_numeric(end($parts)) ? (int)end($parts) : null;
            $con = DBConnection::getInstance()->getPDO();
            $controller = new compraController($con);
            $result = $controller->getCompra($id);
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function getVenta(?int $id, array $parts)
    {
        try {
            $id = is_numeric(end($parts)) ? (int)end($parts) : null;
            $con = DBConnection::getInstance()->getPDO();
            $controller = new ventaController($con);
            $result = $controller->getVenta($id);
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function addCompra()
    {
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new compraController($con);
            $result = $controller->addCompra();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }

    public static function addVenta(){
        try {
            $con = DBConnection::getInstance()->getPDO();
            $controller = new ventaController($con);
            $result = $controller->addVenta();
            return $result;
        } catch (Exception $e) {
            throw $e;
        }
    }
}
