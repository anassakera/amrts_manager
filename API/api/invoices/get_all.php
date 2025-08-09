<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // جلب جميع الفواتير
    $query = "SELECT * FROM invoices ORDER BY created_at DESC";
    $stmt = $database->executeQuery($query);
    $invoices = $database->fetchAll($stmt);
    
    // تحويل البيانات إلى التنسيق المطلوب
    $formattedInvoices = [];
    foreach ($invoices as $invoice) {
        // جلب عناصر الفاتورة
        $itemsQuery = "SELECT * FROM invoice_items WHERE invoice_id = ?";
        $itemsStmt = $database->executeQuery($itemsQuery, [$invoice['id']]);
        $items = $database->fetchAll($itemsStmt);
        
        // جلب ملخص الفاتورة
        $summaryQuery = "SELECT * FROM invoice_summary WHERE invoice_id = ?";
        $summaryStmt = $database->executeQuery($summaryQuery, [$invoice['id']]);
        $summary = $database->fetch($summaryStmt);
        
        // تحويل البيانات الرقمية بشكل صريح
        $totalAmount = is_numeric($invoice['totalAmount']) ? floatval($invoice['totalAmount']) : 0.0;
        
        $formattedInvoices[] = [
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
    }
    
    echo json_encode([
        'success' => true,
        'data' => $formattedInvoices
    ], JSON_NUMERIC_CHECK);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?> 