<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Supplier.php';

$database = new Database();
$db = $database->getConnection();

$supplier = new Supplier($db);

$stmt = $supplier->read();
$num = $stmt->rowCount();

if($num > 0) {
    $suppliers_arr = array();
    $suppliers_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);

        $supplier_item = array(
            "id" => $id,
            "name" => $name,
            "email" => $email,
            "phone" => $phone,
            "address" => $address,
            "contact_person" => $contact_person,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($suppliers_arr["records"], $supplier_item);
    }

    http_response_code(200);
    echo json_encode($suppliers_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No suppliers found."));
}
?> 