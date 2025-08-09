<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invoice ID is required']);
    exit;
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // تحديث الفاتورة الرئيسية
    $invoiceQuery = "
        UPDATE invoices 
        SET clientName = ?, invoiceNumber = ?, date = ?, isLocal = ?, totalAmount = ?, status = ?, updated_at = GETDATE()
        WHERE id = ?
    ";
    
    $database->executeQuery($invoiceQuery, [
        $input['clientName'],
        $input['invoiceNumber'],
        $input['date'],
        $input['isLocal'] ? 1 : 0,
        $input['totalAmount'],
        $input['status'],
        $input['id']
    ]);
    
    // حذف العناصر والملخص القديمة
    $deleteItemsQuery = "DELETE FROM invoice_items WHERE invoice_id = ?";
    $database->executeQuery($deleteItemsQuery, [$input['id']]);
    
    $deleteSummaryQuery = "DELETE FROM invoice_summary WHERE invoice_id = ?";
    $database->executeQuery($deleteSummaryQuery, [$input['id']]);
    
    // إضافة العناصر الجديدة
    if (isset($input['items']) && is_array($input['items'])) {
        $itemQuery = "
            INSERT INTO invoice_items (invoice_id, refFournisseur, articles, qte, poids, puPieces, exchangeRate, mt, prixAchat, autresCharges, cuHt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ";
        
        foreach ($input['items'] as $item) {
            $database->executeQuery($itemQuery, [
                $input['id'],
                $item['refFournisseur'],
                $item['articles'],
                $item['qte'],
                $item['poids'],
                $item['puPieces'],
                $item['exchangeRate'],
                $item['mt'],
                $item['prixAchat'],
                $item['autresCharges'],
                $item['cuHt']
            ]);
        }
    }
    
    // إضافة ملخص الفاتورة الجديد
    if (isset($input['summary'])) {
        $summaryQuery = "
            INSERT INTO invoice_summary (invoice_id, factureNumber, transit, droitDouane, chequeChange, freiht, autres, total, txChange, poidsTotal)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ";
        
        $database->executeQuery($summaryQuery, [
            $input['id'],
            $input['summary']['factureNumber'],
            $input['summary']['transit'],
            $input['summary']['droitDouane'],
            $input['summary']['chequeChange'],
            $input['summary']['freiht'],
            $input['summary']['autres'],
            $input['summary']['total'],
            $input['summary']['txChange'],
            $input['summary']['poidsTotal']
        ]);
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
        'message' => 'Invoice updated successfully',
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