<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Invoice.php';

$database = new Database();
$db = $database->getConnection();

$invoice = new Invoice($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->client_name) && !empty($data->invoice_number)) {
    $invoice->client_name = $data->client_name;
    $invoice->invoice_number = $data->invoice_number;
    $invoice->date = !empty($data->date) ? $data->date : date('Y-m-d H:i:s');
    $invoice->is_local = !empty($data->is_local) ? $data->is_local : 1;
    $invoice->total_amount = !empty($data->total_amount) ? $data->total_amount : 0.0;
    $invoice->status = !empty($data->status) ? $data->status : 'Pending';

    $invoice_id = $invoice->create();
    if($invoice_id) {
        http_response_code(201);
        echo json_encode(array("message" => "Invoice was created successfully.", "id" => $invoice_id));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create invoice."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create invoice. Data is incomplete."));
}
?> 