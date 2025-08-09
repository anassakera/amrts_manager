<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

    // جلب الفاتورة
    $query = "SELECT * FROM invoices WHERE id = ?";
    $stmt = $database->executeQuery($query, [$id]);
    $invoice = $database->fetch($stmt);
    
    if (!$invoice) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Invoice not found']);
        exit;
    }
    
    // جلب عناصر الفاتورة
    $itemsQuery = "SELECT * FROM invoice_items WHERE invoice_id = ?";
    $itemsStmt = $database->executeQuery($itemsQuery, [$id]);
    $items = $database->fetchAll($itemsStmt);
    
    // جلب ملخص الفاتورة
    $summaryQuery = "SELECT * FROM invoice_summary WHERE invoice_id = ?";
    $summaryStmt = $database->executeQuery($summaryQuery, [$id]);
    $summary = $database->fetch($summaryStmt);
    
    // تحويل البيانات الرقمية بشكل صريح
    $totalAmount = is_numeric($invoice['totalAmount']) ? floatval($invoice['totalAmount']) : 0.0;
    
    $formattedInvoice = [
        'id' => $invoice['id'],
        'clientName' => $invoice['clientName'],
        'invoiceNumber' => $invoice['invoiceNumber'],
        'date' => $invoice['date'],
        'isLocal' => (bool)$invoice['isLocal'],
        'totalAmount' => $totalAmount,
        'status' => $invoice['status'],
        'items' => $items,
        'summary' => $summary
    ];
    
    echo json_encode([
        'success' => true,
        'data' => $formattedInvoice
    ], JSON_NUMERIC_CHECK);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?> 