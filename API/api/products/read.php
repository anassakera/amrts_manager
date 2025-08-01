<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Product.php';

$database = new Database();
$db = $database->getConnection();

$product = new Product($db);

$stmt = $product->read();
$num = $stmt->rowCount();

if($num > 0) {
    $products_arr = array();
    $products_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);

        $product_item = array(
            "id" => $id,
            "name" => $name,
            "description" => $description,
            "category" => $category,
            "unit_price" => $unit_price,
            "cost_price" => $cost_price,
            "quantity_in_stock" => $quantity_in_stock,
            "min_quantity" => $min_quantity,
            "supplier_id" => $supplier_id,
            "supplier_name" => $supplier_name,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($products_arr["records"], $product_item);
    }

    // الحصول على إحصائيات المخزون
    $stats = $product->getInventoryStats();
    $products_arr["stats"] = $stats;

    http_response_code(200);
    echo json_encode($products_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No products found."));
}
?> 