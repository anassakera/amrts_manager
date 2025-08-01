<?php
require_once '../config/database.php';

class Invoice {
    private $conn;
    private $table_name = "invoices";

    public $id;
    public $client_name;
    public $invoice_number;
    public $date;
    public $is_local;
    public $total_amount;
    public $status;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // إنشاء فاتورة جديدة
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                SET
                    client_name = :client_name,
                    invoice_number = :invoice_number,
                    date = :date,
                    is_local = :is_local,
                    total_amount = :total_amount,
                    status = :status";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->client_name = htmlspecialchars(strip_tags($this->client_name));
        $this->invoice_number = htmlspecialchars(strip_tags($this->invoice_number));
        $this->date = htmlspecialchars(strip_tags($this->date));
        $this->is_local = htmlspecialchars(strip_tags($this->is_local));
        $this->total_amount = htmlspecialchars(strip_tags($this->total_amount));
        $this->status = htmlspecialchars(strip_tags($this->status));

        // ربط القيم
        $stmt->bindParam(":client_name", $this->client_name);
        $stmt->bindParam(":invoice_number", $this->invoice_number);
        $stmt->bindParam(":date", $this->date);
        $stmt->bindParam(":is_local", $this->is_local);
        $stmt->bindParam(":total_amount", $this->total_amount);
        $stmt->bindParam(":status", $this->status);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    // قراءة جميع الفواتير
    public function read() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    // قراءة فاتورة واحدة
    public function readOne() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE id = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->client_name = $row['client_name'];
            $this->invoice_number = $row['invoice_number'];
            $this->date = $row['date'];
            $this->is_local = $row['is_local'];
            $this->total_amount = $row['total_amount'];
            $this->status = $row['status'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        return false;
    }

    // تحديث فاتورة
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    client_name = :client_name,
                    invoice_number = :invoice_number,
                    date = :date,
                    is_local = :is_local,
                    total_amount = :total_amount,
                    status = :status,
                    updated_at = NOW()
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->client_name = htmlspecialchars(strip_tags($this->client_name));
        $this->invoice_number = htmlspecialchars(strip_tags($this->invoice_number));
        $this->date = htmlspecialchars(strip_tags($this->date));
        $this->is_local = htmlspecialchars(strip_tags($this->is_local));
        $this->total_amount = htmlspecialchars(strip_tags($this->total_amount));
        $this->status = htmlspecialchars(strip_tags($this->status));
        $this->id = htmlspecialchars(strip_tags($this->id));

        // ربط القيم
        $stmt->bindParam(':client_name', $this->client_name);
        $stmt->bindParam(':invoice_number', $this->invoice_number);
        $stmt->bindParam(':date', $this->date);
        $stmt->bindParam(':is_local', $this->is_local);
        $stmt->bindParam(':total_amount', $this->total_amount);
        $stmt->bindParam(':status', $this->status);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // حذف فاتورة
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

    // البحث في الفواتير
    public function search($keywords) {
        $query = "SELECT * FROM " . $this->table_name . "
                WHERE
                    client_name LIKE ? OR
                    invoice_number LIKE ? OR
                    status LIKE ?
                ORDER BY created_at DESC";

        $stmt = $this->conn->prepare($query);

        $keywords = htmlspecialchars(strip_tags($keywords));
        $keywords = "%{$keywords}%";

        $stmt->bindParam(1, $keywords);
        $stmt->bindParam(2, $keywords);
        $stmt->bindParam(3, $keywords);

        $stmt->execute();
        return $stmt;
    }
}
?> 