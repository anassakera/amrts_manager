<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Supplier.php';

$database = new Database();
$db = $database->getConnection();

$supplier = new Supplier($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->name)) {
    $supplier->name = $data->name;
    $supplier->email = !empty($data->email) ? $data->email : '';
    $supplier->phone = !empty($data->phone) ? $data->phone : '';
    $supplier->address = !empty($data->address) ? $data->address : '';
    $supplier->contact_person = !empty($data->contact_person) ? $data->contact_person : '';

    $supplier_id = $supplier->create();
    if($supplier_id) {
        http_response_code(201);
        echo json_encode(array("message" => "Supplier was created successfully.", "id" => $supplier_id));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create supplier."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create supplier. Name is required."));
}
?> 