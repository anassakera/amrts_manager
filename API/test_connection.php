<?php
header('Content-Type: application/json');

try {
    require_once __DIR__ . '/config/db_connection.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if ($conn) {
        // Test query
        $sql = "SELECT COUNT(*) as count FROM CompanyInfo";
        $stmt = $database->executeQuery($sql);
        $result = $database->fetch($stmt);
        
        echo json_encode([
            'success' => true,
            'message' => 'Database connection successful',
            'company_count' => $result['count']
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed'
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
