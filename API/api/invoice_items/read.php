<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/InvoiceItem.php';

$database = new Database();
$db = $database->getConnection();

$invoice_item = new InvoiceItem($db);

$invoice_id = isset($_GET['invoice_id']) ? $_GET['invoice_id'] : die();

$stmt = $invoice_item->readByInvoiceId($invoice_id);
$num = $stmt->rowCount();

if($num > 0) {
    $items_arr = array();
    $items_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);

        $item = array(
            "id" => $id,
            "invoice_id" => $invoice_id,
            "ref_fournisseur" => $ref_fournisseur,
            "articles" => $articles,
            "qte" => $qte,
            "poids" => $poids,
            "pu_pieces" => $pu_pieces,
            "exchange_rate" => $exchange_rate,
            "mt" => $mt,
            "prix_achat" => $prix_achat,
            "autres_charges" => $autres_charges,
            "cu_ht" => $cu_ht,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($items_arr["records"], $item);
    }

    // الحصول على إجماليات الفاتورة
    $totals = $invoice_item->calculateTotals($invoice_id);
    $items_arr["totals"] = $totals;

    http_response_code(200);
    echo json_encode($items_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No items found for this invoice."));
}
?> 