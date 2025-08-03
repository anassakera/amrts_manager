<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

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
    $pdo = $database->getConnection();
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // إعداد PDO لإرجاع البيانات الرقمية كأرقام وليس كسلاسل نصية
    $pdo->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    
    // تحديث حالة الفاتورة
    $query = "UPDATE invoices SET status = ? WHERE id = ?";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$input['status'], $input['id']]);
    
    if ($stmt->rowCount() == 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Invoice not found']);
        exit;
    }
    
    // إرجاع الفاتورة المحدثة
    $invoiceQuery = "SELECT * FROM invoices WHERE id = ?";
    $invoiceStmt = $pdo->prepare($invoiceQuery);
    $invoiceStmt->execute([$input['id']]);
    $invoice = $invoiceStmt->fetch(PDO::FETCH_ASSOC);
    
    // جلب عناصر الفاتورة
    $itemsQuery = "SELECT * FROM invoice_items WHERE invoice_id = ?";
    $itemsStmt = $pdo->prepare($itemsQuery);
    $itemsStmt->execute([$input['id']]);
    $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // جلب ملخص الفاتورة
    $summaryQuery = "SELECT * FROM invoice_summary WHERE invoice_id = ?";
    $summaryStmt = $pdo->prepare($summaryQuery);
    $summaryStmt->execute([$input['id']]);
    $summary = $summaryStmt->fetch(PDO::FETCH_ASSOC);
    
    // تحويل البيانات الرقمية بشكل صريح
    $totalAmount = is_numeric($invoice['totalAmount']) ? floatval($invoice['totalAmount']) : 0.0;
    
    $formattedInvoice = [
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
    
    echo json_encode([
        'success' => true,
        'message' => 'Invoice status updated successfully',
        'data' => $formattedInvoice
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