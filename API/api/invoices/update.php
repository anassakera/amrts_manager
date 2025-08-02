<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';

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
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $pdo->beginTransaction();
    
    // تحديث الفاتورة الرئيسية
    $invoiceQuery = "
        UPDATE invoices 
        SET clientName = ?, invoiceNumber = ?, date = ?, isLocal = ?, totalAmount = ?, status = ?
        WHERE id = ?
    ";
    
    $invoiceStmt = $pdo->prepare($invoiceQuery);
    $invoiceStmt->execute([
        $input['clientName'],
        $input['invoiceNumber'],
        $input['date'],
        $input['isLocal'] ? 1 : 0,
        $input['totalAmount'],
        $input['status'],
        $input['id']
    ]);
    
    // حذف العناصر القديمة
    $deleteItemsQuery = "DELETE FROM invoice_items WHERE invoice_id = ?";
    $deleteItemsStmt = $pdo->prepare($deleteItemsQuery);
    $deleteItemsStmt->execute([$input['id']]);
    
    // إضافة العناصر الجديدة
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
    
    // تحديث ملخص الفاتورة
    if (isset($input['summary'])) {
        $summaryQuery = "
            UPDATE invoice_summary 
            SET factureNumber = ?, transit = ?, droitDouane = ?, chequeChange = ?, freiht = ?, autres = ?, total = ?, txChange = ?, poidsTotal = ?
            WHERE invoice_id = ?
        ";
        
        $summaryStmt = $pdo->prepare($summaryQuery);
        $summaryStmt->execute([
            $input['summary']['factureNumber'],
            $input['summary']['transit'],
            $input['summary']['droitDouane'],
            $input['summary']['chequeChange'],
            $input['summary']['freiht'],
            $input['summary']['autres'],
            $input['summary']['total'],
            $input['summary']['txChange'],
            $input['summary']['poidsTotal'],
            $input['id']
        ]);
        
        // إذا لم يكن هناك ملخص موجود، قم بإنشاؤه
        if ($summaryStmt->rowCount() == 0) {
            $insertSummaryQuery = "
                INSERT INTO invoice_summary (invoice_id, factureNumber, transit, droitDouane, chequeChange, freiht, autres, total, txChange, poidsTotal)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ";
            
            $insertSummaryStmt = $pdo->prepare($insertSummaryQuery);
            $insertSummaryStmt->execute([
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
    }
    
    $pdo->commit();
    
    // إرجاع الفاتورة المحدثة
    $query = "
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
    
    $stmt = $pdo->prepare($query);
    $stmt->execute([$input['id']]);
    $invoice = $stmt->fetch(PDO::FETCH_ASSOC);
    
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
        'message' => 'Invoice updated successfully',
        'data' => $formattedInvoice
    ]);
    
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