<?php
// ملف اختبار الاتصال بقاعدة البيانات
header('Content-Type: application/json; charset=UTF-8');

require_once 'config/db_connection.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    if ($conn) {
        echo json_encode([
            'success' => true,
            'message' => 'Database connection successful!',
            'timestamp' => date('Y-m-d H:i:s'),
            'server' => 'DESKTOP-S2LBGQE\\SQLEXPRESS',
            'database' => 'DBAnas'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed!',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?>
