<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // جلب جميع الفواتير مع العناصر والملخص
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
        GROUP BY i.id
        ORDER BY i.created_at DESC
    ";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // تحويل البيانات إلى التنسيق المطلوب
    $formattedInvoices = [];
    foreach ($invoices as $invoice) {
        $items = json_decode($invoice['items'], true);
        $summary = json_decode($invoice['summary'], true);
        
        // إزالة العناصر الفارغة
        $items = array_filter($items, function($item) {
            return $item['refFournisseur'] !== null;
        });
        
        $formattedInvoices[] = [
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
    }
    
    echo json_encode([
        'success' => true,
        'data' => $formattedInvoices
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