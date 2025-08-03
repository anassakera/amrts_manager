<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON data']);
    exit;
}

try {
    $database = new Database();
    $pdo = $database->getConnection();
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // إعداد PDO لإرجاع البيانات الرقمية كأرقام وليس كسلاسل نصية
    $pdo->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    
    $pdo->beginTransaction();
    
    // إضافة الفاتورة الرئيسية
    $invoiceQuery = "
        INSERT INTO invoices (id, clientName, invoiceNumber, date, isLocal, totalAmount, status)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ";
    
    $invoiceStmt = $pdo->prepare($invoiceQuery);
    $invoiceStmt->execute([
        $input['id'],
        $input['clientName'],
        $input['invoiceNumber'],
        $input['date'],
        $input['isLocal'] ? 1 : 0,
        $input['totalAmount'],
        $input['status']
    ]);
    
    // إضافة عناصر الفاتورة
    if (isset($input['items']) && is_array($input['items'])) {
        $itemQuery = "
            INSERT INTO invoice_items (invoice_id, refFournisseur, articles, qte, poids, puPieces, exchangeRate, mt, prixAchat, autresCharges, cuHt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ";
        
        $itemStmt = $pdo->prepare($itemQuery);
        
        foreach ($input['items'] as $item) {
            $itemStmt->execute([
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
    
    // إضافة ملخص الفاتورة
    if (isset($input['summary'])) {
        $summaryQuery = "
            INSERT INTO invoice_summary (invoice_id, factureNumber, transit, droitDouane, chequeChange, freiht, autres, total, txChange, poidsTotal)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ";
        
        $summaryStmt = $pdo->prepare($summaryQuery);
        $summaryStmt->execute([
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
    
    $pdo->commit();
    
    // إرجاع الفاتورة المضافة
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
        'message' => 'Invoice created successfully',
        'data' => $formattedInvoice
    ], JSON_NUMERIC_CHECK);
    
} catch (PDOException $e) {
    if (isset($pdo)) {
        $pdo->rollback();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    if (isset($pdo)) {
        $pdo->rollback();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?> 