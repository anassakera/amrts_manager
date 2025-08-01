<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Invoice.php';

$database = new Database();
$db = $database->getConnection();

$invoice = new Invoice($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->id)) {
    $invoice->id = $data->id;
    $invoice->client_name = !empty($data->client_name) ? $data->client_name : $invoice->client_name;
    $invoice->invoice_number = !empty($data->invoice_number) ? $data->invoice_number : $invoice->invoice_number;
    $invoice->date = !empty($data->date) ? $data->date : $invoice->date;
    $invoice->is_local = !empty($data->is_local) ? $data->is_local : $invoice->is_local;
    $invoice->total_amount = !empty($data->total_amount) ? $data->total_amount : $invoice->total_amount;
    $invoice->status = !empty($data->status) ? $data->status : $invoice->status;

    if($invoice->update()) {
        http_response_code(200);
        echo json_encode(array("message" => "Invoice was updated successfully."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to update invoice."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to update invoice. Data is incomplete."));
}
?> 