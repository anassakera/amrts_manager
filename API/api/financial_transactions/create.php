<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/FinancialTransaction.php';

$database = new Database();
$db = $database->getConnection();

$transaction = new FinancialTransaction($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->type) && !empty($data->amount)) {
    $transaction->type = $data->type;
    $transaction->category = !empty($data->category) ? $data->category : '';
    $transaction->amount = $data->amount;
    $transaction->description = !empty($data->description) ? $data->description : '';
    $transaction->date = !empty($data->date) ? $data->date : date('Y-m-d');
    $transaction->reference = !empty($data->reference) ? $data->reference : '';

    $transaction_id = $transaction->create();
    if($transaction_id) {
        http_response_code(201);
        echo json_encode(array("message" => "Financial transaction was created successfully.", "id" => $transaction_id));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create financial transaction."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create financial transaction. Type and amount are required."));
}
?> 