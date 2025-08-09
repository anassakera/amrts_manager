<?php
class Database {
    private $config;
    public $conn;

    public function __construct() {
        $this->loadConfig();
    }

    private function loadConfig() {
        $configFile = __DIR__ . '/connectivity.config';
        if (!file_exists($configFile)) {
            throw new Exception('Configuration file not found');
        }

        $configContent = file_get_contents($configFile);
        $this->config = json_decode($configContent, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception('Invalid configuration file format');
        }
    }

    public function getConnection() {
        try {
            $connectionOptions = [
                "Database" => $this->config['database'],
                "Uid" => $this->config['uid'],
                "PWD" => $this->config['pwd'],
                "TrustServerCertificate" => 1,
                "Encrypt" => 0
            ];

            $this->conn = sqlsrv_connect($this->config['serverName'], $connectionOptions);

            if ($this->conn === false) {
                throw new Exception('Database connection failed');
            }

            return $this->conn;

        } catch(Exception $exception) {
            throw new Exception('Connection error: ' . $exception->getMessage());
        }
    }

    public function executeQuery($query, $params = []) {
        if (!$this->conn) {
            throw new Exception('No database connection');
        }

        $stmt = sqlsrv_prepare($this->conn, $query, $params);
        if ($stmt === false) {
            throw new Exception('Query preparation failed');
        }

        $result = sqlsrv_execute($stmt);
        if ($result === false) {
            throw new Exception('Query execution failed');
        }

        return $stmt;
    }

    public function fetchAll($stmt) {
        $rows = [];
        while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
            $rows[] = $row;
        }
        return $rows;
    }

    public function fetch($stmt) {
        return sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC);
    }

    public function rowCount($stmt) {
        return sqlsrv_rows_affected($stmt);
    }

    public function isConnected() {
        return $this->conn !== null && $this->conn !== false;
    }

    public function closeConnection() {
        if ($this->conn) {
            sqlsrv_close($this->conn);
            $this->conn = null;
        }
    }
}
?>

