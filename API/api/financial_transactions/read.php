<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/FinancialTransaction.php';

$database = new Database();
$db = $database->getConnection();

$transaction = new FinancialTransaction($db);

$stmt = $transaction->read();
$num = $stmt->rowCount();

if($num > 0) {
    $transactions_arr = array();
    $transactions_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);

        $transaction_item = array(
            "id" => $id,
            "type" => $type,
            "category" => $category,
            "amount" => $amount,
            "description" => $description,
            "date" => $date,
            "reference" => $reference,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($transactions_arr["records"], $transaction_item);
    }

    // الحصول على إحصائيات مالية
    $stats = $transaction->getFinancialStats();
    $transactions_arr["stats"] = $stats;

    http_response_code(200);
    echo json_encode($transactions_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No financial transactions found."));
}
?> 