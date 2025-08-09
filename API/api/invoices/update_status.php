<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['id']) || !isset($input['status'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invoice ID and status are required']);
    exit;
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // تحديث حالة الفاتورة
    $query = "UPDATE invoices SET status = ?, updated_at = GETDATE() WHERE id = ?";
    $stmt = $database->executeQuery($query, [$input['status'], $input['id']]);
    
    if ($database->rowCount($stmt) == 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Invoice not found']);
        exit;
    }
    
    // إرجاع الفاتورة المحدثة
    $invoiceQuery = "SELECT * FROM invoices WHERE id = ?";
    $invoiceStmt = $database->executeQuery($invoiceQuery, [$input['id']]);
    $invoice = $database->fetch($invoiceStmt);
    
    // جلب عناصر الفاتورة
    $itemsQuery = "SELECT * FROM invoice_items WHERE invoice_id = ?";
    $itemsStmt = $database->executeQuery($itemsQuery, [$input['id']]);
    $items = $database->fetchAll($itemsStmt);
    
    // جلب ملخص الفاتورة
    $summaryQuery = "SELECT * FROM invoice_summary WHERE invoice_id = ?";
    $summaryStmt = $database->executeQuery($summaryQuery, [$input['id']]);
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
        'message' => 'Invoice status updated successfully',
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