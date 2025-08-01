<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Invoice.php';

$database = new Database();
$db = $database->getConnection();

$invoice = new Invoice($db);

$keywords = isset($_GET['s']) ? $_GET['s'] : "";

if(!empty($keywords)) {
    $stmt = $invoice->search($keywords);
    $num = $stmt->rowCount();

    if($num > 0) {
        $invoices_arr = array();
        $invoices_arr["records"] = array();

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            extract($row);

            $invoice_item = array(
                "id" => $id,
                "client_name" => $client_name,
                "invoice_number" => $invoice_number,
                "date" => $date,
                "is_local" => $is_local,
                "total_amount" => $total_amount,
                "status" => $status,
                "created_at" => $created_at,
                "updated_at" => $updated_at
            );

            array_push($invoices_arr["records"], $invoice_item);
        }

        http_response_code(200);
        echo json_encode($invoices_arr);
    } else {
        http_response_code(404);
        echo json_encode(array("message" => "No invoices found matching the search criteria."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Search keyword is required."));
}
?> 