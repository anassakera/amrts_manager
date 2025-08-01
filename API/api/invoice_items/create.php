<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/InvoiceItem.php';

$database = new Database();
$db = $database->getConnection();

$invoice_item = new InvoiceItem($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->invoice_id) && !empty($data->articles)) {
    $invoice_item->invoice_id = $data->invoice_id;
    $invoice_item->ref_fournisseur = !empty($data->ref_fournisseur) ? $data->ref_fournisseur : '';
    $invoice_item->articles = $data->articles;
    $invoice_item->qte = !empty($data->qte) ? $data->qte : 0;
    $invoice_item->poids = !empty($data->poids) ? $data->poids : 0.0;
    $invoice_item->pu_pieces = !empty($data->pu_pieces) ? $data->pu_pieces : 0.0;
    $invoice_item->exchange_rate = !empty($data->exchange_rate) ? $data->exchange_rate : 1.0;
    $invoice_item->mt = !empty($data->mt) ? $data->mt : 0.0;
    $invoice_item->prix_achat = !empty($data->prix_achat) ? $data->prix_achat : 0.0;
    $invoice_item->autres_charges = !empty($data->autres_charges) ? $data->autres_charges : 0.0;
    $invoice_item->cu_ht = !empty($data->cu_ht) ? $data->cu_ht : 0.0;

    $item_id = $invoice_item->create();
    if($item_id) {
        http_response_code(201);
        echo json_encode(array("message" => "Invoice item was created successfully.", "id" => $item_id));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create invoice item."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create invoice item. Data is incomplete."));
}
?> 