<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Product.php';

$database = new Database();
$db = $database->getConnection();

$product = new Product($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->name)) {
    $product->name = $data->name;
    $product->description = !empty($data->description) ? $data->description : '';
    $product->category = !empty($data->category) ? $data->category : '';
    $product->unit_price = !empty($data->unit_price) ? $data->unit_price : 0.0;
    $product->cost_price = !empty($data->cost_price) ? $data->cost_price : 0.0;
    $product->quantity_in_stock = !empty($data->quantity_in_stock) ? $data->quantity_in_stock : 0;
    $product->min_quantity = !empty($data->min_quantity) ? $data->min_quantity : 0;
    $product->supplier_id = !empty($data->supplier_id) ? $data->supplier_id : null;

    $product_id = $product->create();
    if($product_id) {
        http_response_code(201);
        echo json_encode(array("message" => "Product was created successfully.", "id" => $product_id));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create product."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create product. Name is required."));
}
?> 