<?php

class categoriaController{

    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

}