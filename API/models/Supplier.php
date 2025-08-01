<?php
require_once '../config/database.php';

class Supplier {
    private $conn;
    private $table_name = "suppliers";

    public $id;
    public $name;
    public $email;
    public $phone;
    public $address;
    public $contact_person;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // إنشاء مورد جديد
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                SET
                    name = :name,
                    email = :email,
                    phone = :phone,
                    address = :address,
                    contact_person = :contact_person";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone = htmlspecialchars(strip_tags($this->phone));
        $this->address = htmlspecialchars(strip_tags($this->address));
        $this->contact_person = htmlspecialchars(strip_tags($this->contact_person));

        // ربط القيم
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":contact_person", $this->contact_person);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    // قراءة جميع الموردين
    public function read() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    // قراءة مورد واحد
    public function readOne() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE id = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->name = $row['name'];
            $this->email = $row['email'];
            $this->phone = $row['phone'];
            $this->address = $row['address'];
            $this->contact_person = $row['contact_person'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        return false;
    }

    // تحديث مورد
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    name = :name,
                    email = :email,
                    phone = :phone,
                    address = :address,
                    contact_person = :contact_person,
                    updated_at = NOW()
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone = htmlspecialchars(strip_tags($this->phone));
        $this->address = htmlspecialchars(strip_tags($this->address));
        $this->contact_person = htmlspecialchars(strip_tags($this->contact_person));
        $this->id = htmlspecialchars(strip_tags($this->id));

        // ربط القيم
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':email', $this->email);
        $stmt->bindParam(':phone', $this->phone);
        $stmt->bindParam(':address', $this->address);
        $stmt->bindParam(':contact_person', $this->contact_person);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // حذف مورد
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

    // البحث في الموردين
    public function search($keywords) {
        $query = "SELECT * FROM " . $this->table_name . "
                WHERE
                    name LIKE ? OR
                    email LIKE ? OR
                    phone LIKE ? OR
                    contact_person LIKE ?
                ORDER BY created_at DESC";

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

    // الحصول على إحصائيات المورد
    public function getSupplierStats($supplier_id) {
        $query = "SELECT 
                    COUNT(DISTINCT i.id) as total_invoices,
                    SUM(ii.qte) as total_items_supplied,
                    SUM(ii.mt) as total_amount
                  FROM invoices i
                  JOIN invoice_items ii ON i.id = ii.invoice_id
                  WHERE i.client_name = (SELECT name FROM " . $this->table_name . " WHERE id = ?)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $supplier_id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
?> 