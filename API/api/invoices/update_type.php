<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['id']) || !isset($input['isLocal'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invoice ID and isLocal are required']);
    exit;
}

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // تحديث نوع الفاتورة
    $query = "UPDATE invoices SET isLocal = ? WHERE id = ?";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$input['isLocal'] ? 1 : 0, $input['id']]);
    
    if ($stmt->rowCount() == 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Invoice not found']);
        exit;
    }
    
    // إرجاع الفاتورة المحدثة
    $getQuery = "
        SELECT 
            i.*,
            JSON_ARRAYAGG(
                JSON_OBJECT(
                    'refFournisseur', ii.refFournisseur,
                    'articles', ii.articles,
                    'qte', ii.qte,
                    'poids', ii.poids,
                    'puPieces', ii.puPieces,
                    'exchangeRate', ii.exchangeRate,
                    'mt', ii.mt,
                    'prixAchat', ii.prixAchat,
                    'autresCharges', ii.autresCharges,
                    'cuHt', ii.cuHt
                )
            ) as items,
            JSON_OBJECT(
                'factureNumber', is.factureNumber,
                'transit', is.transit,
                'droitDouane', is.droitDouane,
                'chequeChange', is.chequeChange,
                'freiht', is.freiht,
                'autres', is.autres,
                'total', is.total,
                'txChange', is.txChange,
                'poidsTotal', is.poidsTotal
            ) as summary
        FROM invoices i
        LEFT JOIN invoice_items ii ON i.id = ii.invoice_id
        LEFT JOIN invoice_summary is ON i.id = is.invoice_id
        WHERE i.id = ?
        GROUP BY i.id
    ";
    
    $getStmt = $pdo->prepare($getQuery);
    $getStmt->execute([$input['id']]);
    $invoice = $getStmt->fetch(PDO::FETCH_ASSOC);
    
    $items = json_decode($invoice['items'], true);
    $summary = json_decode($invoice['summary'], true);
    
    $items = array_filter($items, function($item) {
        return $item['refFournisseur'] !== null;
    });
    
    $formattedInvoice = [
        'id' => $invoice['id'],
        'clientName' => $invoice['clientName'],
        'invoiceNumber' => $invoice['invoiceNumber'],
        'date' => $invoice['date'],
        'isLocal' => (bool)$invoice['isLocal'],
        'totalAmount' => (float)$invoice['totalAmount'],
        'status' => $invoice['status'],
        'items' => array_values($items),
        'summary' => $summary
    ];
    
    echo json_encode([
        'success' => true,
        'message' => 'Invoice type updated successfully',
        'data' => $formattedInvoice
    ]);
    
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