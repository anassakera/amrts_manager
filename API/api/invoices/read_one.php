<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Invoice.php';

$database = new Database();
$db = $database->getConnection();

$invoice = new Invoice($db);

$invoice->id = isset($_GET['id']) ? $_GET['id'] : die();

if($invoice->readOne()) {
    $invoice_arr = array(
        "id" => $invoice->id,
        "client_name" => $invoice->client_name,
        "invoice_number" => $invoice->invoice_number,
        "date" => $invoice->date,
        "is_local" => $invoice->is_local,
        "total_amount" => $invoice->total_amount,
        "status" => $invoice->status,
        "created_at" => $invoice->created_at,
        "updated_at" => $invoice->updated_at
    );

    http_response_code(200);
    echo json_encode($invoice_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "Invoice does not exist."));
}
?> 