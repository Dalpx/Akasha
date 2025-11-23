<?php

class ubicacionController{

    protected $DB;

    public function __construct(PDO $pdo)
    {
        $this->DB = $pdo;
    }

}