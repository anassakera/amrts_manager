<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

try {
    $database = new Database();
    $pdo = $database->getConnection();
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // إعداد PDO لإرجاع البيانات الرقمية كأرقام وليس كسلاسل نصية
    $pdo->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    
    // جلب جميع الفواتير
    $query = "SELECT * FROM invoices ORDER BY created_at DESC";
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // تحويل البيانات إلى التنسيق المطلوب
    $formattedInvoices = [];
    foreach ($invoices as $invoice) {
        // جلب عناصر الفاتورة
        $itemsQuery = "SELECT * FROM invoice_items WHERE invoice_id = ?";
        $itemsStmt = $pdo->prepare($itemsQuery);
        $itemsStmt->execute([$invoice['id']]);
        $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // جلب ملخص الفاتورة
        $summaryQuery = "SELECT * FROM invoice_summary WHERE invoice_id = ?";
        $summaryStmt = $pdo->prepare($summaryQuery);
        $summaryStmt->execute([$invoice['id']]);
        $summary = $summaryStmt->fetch(PDO::FETCH_ASSOC);
        
        // تحويل البيانات الرقمية بشكل صريح
        $totalAmount = is_numeric($invoice['totalAmount']) ? floatval($invoice['totalAmount']) : 0.0;
        
        $formattedInvoices[] = [
            'id' => intval($invoice['id']),
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
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?> 