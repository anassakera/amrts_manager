<?php
require_once '../config/database.php';

class Product {
    private $conn;
    private $table_name = "products";

    public $id;
    public $name;
    public $description;
    public $category;
    public $unit_price;
    public $cost_price;
    public $quantity_in_stock;
    public $min_quantity;
    public $supplier_id;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // إنشاء منتج جديد
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                SET
                    name = :name,
                    description = :description,
                    category = :category,
                    unit_price = :unit_price,
                    cost_price = :cost_price,
                    quantity_in_stock = :quantity_in_stock,
                    min_quantity = :min_quantity,
                    supplier_id = :supplier_id";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->category = htmlspecialchars(strip_tags($this->category));
        $this->unit_price = htmlspecialchars(strip_tags($this->unit_price));
        $this->cost_price = htmlspecialchars(strip_tags($this->cost_price));
        $this->quantity_in_stock = htmlspecialchars(strip_tags($this->quantity_in_stock));
        $this->min_quantity = htmlspecialchars(strip_tags($this->min_quantity));
        $this->supplier_id = htmlspecialchars(strip_tags($this->supplier_id));

        // ربط القيم
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":category", $this->category);
        $stmt->bindParam(":unit_price", $this->unit_price);
        $stmt->bindParam(":cost_price", $this->cost_price);
        $stmt->bindParam(":quantity_in_stock", $this->quantity_in_stock);
        $stmt->bindParam(":min_quantity", $this->min_quantity);
        $stmt->bindParam(":supplier_id", $this->supplier_id);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    // قراءة جميع المنتجات
    public function read() {
        $query = "SELECT p.*, s.name as supplier_name 
                  FROM " . $this->table_name . " p
                  LEFT JOIN suppliers s ON p.supplier_id = s.id
                  ORDER BY p.created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    // قراءة منتج واحد
    public function readOne() {
        $query = "SELECT p.*, s.name as supplier_name 
                  FROM " . $this->table_name . " p
                  LEFT JOIN suppliers s ON p.supplier_id = s.id
                  WHERE p.id = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->name = $row['name'];
            $this->description = $row['description'];
            $this->category = $row['category'];
            $this->unit_price = $row['unit_price'];
            $this->cost_price = $row['cost_price'];
            $this->quantity_in_stock = $row['quantity_in_stock'];
            $this->min_quantity = $row['min_quantity'];
            $this->supplier_id = $row['supplier_id'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        return false;
    }

    // تحديث منتج
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    name = :name,
                    description = :description,
                    category = :category,
                    unit_price = :unit_price,
                    cost_price = :cost_price,
                    quantity_in_stock = :quantity_in_stock,
                    min_quantity = :min_quantity,
                    supplier_id = :supplier_id,
                    updated_at = NOW()
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->category = htmlspecialchars(strip_tags($this->category));
        $this->unit_price = htmlspecialchars(strip_tags($this->unit_price));
        $this->cost_price = htmlspecialchars(strip_tags($this->cost_price));
        $this->quantity_in_stock = htmlspecialchars(strip_tags($this->quantity_in_stock));
        $this->min_quantity = htmlspecialchars(strip_tags($this->min_quantity));
        $this->supplier_id = htmlspecialchars(strip_tags($this->supplier_id));
        $this->id = htmlspecialchars(strip_tags($this->id));

        // ربط القيم
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':description', $this->description);
        $stmt->bindParam(':category', $this->category);
        $stmt->bindParam(':unit_price', $this->unit_price);
        $stmt->bindParam(':cost_price', $this->cost_price);
        $stmt->bindParam(':quantity_in_stock', $this->quantity_in_stock);
        $stmt->bindParam(':min_quantity', $this->min_quantity);
        $stmt->bindParam(':supplier_id', $this->supplier_id);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // حذف منتج
    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $this->id = htmlspecialchars(strip_tags($this->id));
        $stmt->bindParam(1, $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // البحث في المنتجات
    public function search($keywords) {
        $query = "SELECT p.*, s.name as supplier_name 
                  FROM " . $this->table_name . " p
                  LEFT JOIN suppliers s ON p.supplier_id = s.id
                  WHERE
                    p.name LIKE ? OR
                    p.description LIKE ? OR
                    p.category LIKE ? OR
                    s.name LIKE ?
                  ORDER BY p.created_at DESC";

        $stmt = $this->conn->prepare($query);

        $keywords = htmlspecialchars(strip_tags($keywords));
        $keywords = "%{$keywords}%";

        $stmt->bindParam(1, $keywords);
        $stmt->bindParam(2, $keywords);
        $stmt->bindParam(3, $keywords);
        $stmt->bindParam(4, $keywords);

        $stmt->execute();
        return $stmt;
    }

    // تحديث كمية المخزون
    public function updateStock($quantity_change) {
        $query = "UPDATE " . $this->table_name . "
                SET quantity_in_stock = quantity_in_stock + :quantity_change,
                    updated_at = NOW()
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':quantity_change', $quantity_change);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // الحصول على المنتجات منخفضة المخزون
    public function getLowStockProducts() {
        $query = "SELECT p.*, s.name as supplier_name 
                  FROM " . $this->table_name . " p
                  LEFT JOIN suppliers s ON p.supplier_id = s.id
                  WHERE p.quantity_in_stock <= p.min_quantity
                  ORDER BY p.quantity_in_stock ASC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    // الحصول على إحصائيات المخزون
    public function getInventoryStats() {
        $query = "SELECT 
                    COUNT(*) as total_products,
                    SUM(quantity_in_stock) as total_quantity,
                    SUM(quantity_in_stock * cost_price) as total_value,
                    COUNT(CASE WHEN quantity_in_stock <= min_quantity THEN 1 END) as low_stock_count
                  FROM " . $this->table_name;
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
?> 