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

    if($invoice->delete()) {
        http_response_code(200);
        echo json_encode(array("message" => "Invoice was deleted successfully."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to delete invoice."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to delete invoice. ID is required."));
}
?> 