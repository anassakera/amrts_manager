<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$id = $_GET['id'] ?? null;

if (!$id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invoice ID is required']);
    exit;
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // حذف الفاتورة (سيتم حذف العناصر والملخص تلقائياً بسبب CASCADE)
    $query = "DELETE FROM invoices WHERE id = ?";
    $stmt = $database->executeQuery($query, [$id]);
    
    if ($database->rowCount($stmt) == 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Invoice not found']);
        exit;
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Invoice deleted successfully'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?> 