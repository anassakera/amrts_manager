<?php
require_once '../config/database.php';

class FinancialTransaction {
    private $conn;
    private $table_name = "financial_transactions";

    public $id;
    public $type; // income, expense
    public $category;
    public $amount;
    public $description;
    public $date;
    public $reference;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // إنشاء معاملة مالية جديدة
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                SET
                    type = :type,
                    category = :category,
                    amount = :amount,
                    description = :description,
                    date = :date,
                    reference = :reference";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->type = htmlspecialchars(strip_tags($this->type));
        $this->category = htmlspecialchars(strip_tags($this->category));
        $this->amount = htmlspecialchars(strip_tags($this->amount));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->date = htmlspecialchars(strip_tags($this->date));
        $this->reference = htmlspecialchars(strip_tags($this->reference));

        // ربط القيم
        $stmt->bindParam(":type", $this->type);
        $stmt->bindParam(":category", $this->category);
        $stmt->bindParam(":amount", $this->amount);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":date", $this->date);
        $stmt->bindParam(":reference", $this->reference);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    // قراءة جميع المعاملات المالية
    public function read() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY date DESC, created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    // قراءة معاملة مالية واحدة
    public function readOne() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE id = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->type = $row['type'];
            $this->category = $row['category'];
            $this->amount = $row['amount'];
            $this->description = $row['description'];
            $this->date = $row['date'];
            $this->reference = $row['reference'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        return false;
    }

    // تحديث معاملة مالية
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    type = :type,
                    category = :category,
                    amount = :amount,
                    description = :description,
                    date = :date,
                    reference = :reference,
                    updated_at = NOW()
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->type = htmlspecialchars(strip_tags($this->type));
        $this->category = htmlspecialchars(strip_tags($this->category));
        $this->amount = htmlspecialchars(strip_tags($this->amount));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->date = htmlspecialchars(strip_tags($this->date));
        $this->reference = htmlspecialchars(strip_tags($this->reference));
        $this->id = htmlspecialchars(strip_tags($this->id));

        // ربط القيم
        $stmt->bindParam(':type', $this->type);
        $stmt->bindParam(':category', $this->category);
        $stmt->bindParam(':amount', $this->amount);
        $stmt->bindParam(':description', $this->description);
        $stmt->bindParam(':date', $this->date);
        $stmt->bindParam(':reference', $this->reference);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // حذف معاملة مالية
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

    // البحث في المعاملات المالية
    public function search($keywords) {
        $query = "SELECT * FROM " . $this->table_name . "
                WHERE
                    category LIKE ? OR
                    description LIKE ? OR
                    reference LIKE ?
                ORDER BY date DESC, created_at DESC";

        $stmt = $this->conn->prepare($query);

        $keywords = htmlspecialchars(strip_tags($keywords));
        $keywords = "%{$keywords}%";

        $stmt->bindParam(1, $keywords);
        $stmt->bindParam(2, $keywords);
        $stmt->bindParam(3, $keywords);

        $stmt->execute();
        return $stmt;
    }

    // الحصول على معاملات مالية حسب النوع
    public function getByType($type) {
        $query = "SELECT * FROM " . $this->table_name . " WHERE type = ? ORDER BY date DESC, created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $type);
        $stmt->execute();
        return $stmt;
    }

    // الحصول على معاملات مالية حسب الفترة
    public function getByDateRange($start_date, $end_date) {
        $query = "SELECT * FROM " . $this->table_name . " 
                  WHERE date BETWEEN ? AND ? 
                  ORDER BY date DESC, created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $start_date);
        $stmt->bindParam(2, $end_date);
        $stmt->execute();
        return $stmt;
    }

    // الحصول على إحصائيات مالية
    public function getFinancialStats($start_date = null, $end_date = null) {
        $where_clause = "";
        $params = [];
        
        if ($start_date && $end_date) {
            $where_clause = "WHERE date BETWEEN ? AND ?";
            $params = [$start_date, $end_date];
        }

        $query = "SELECT 
                    COUNT(*) as total_transactions,
                    SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
                    SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expense,
                    SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as net_amount
                  FROM " . $this->table_name . " " . $where_clause;
        
        $stmt = $this->conn->prepare($query);
        
        if (!empty($params)) {
            $stmt->bindParam(1, $params[0]);
            $stmt->bindParam(2, $params[1]);
        }
        
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // الحصول على إحصائيات حسب الفئة
    public function getStatsByCategory($start_date = null, $end_date = null) {
        $where_clause = "";
        $params = [];
        
        if ($start_date && $end_date) {
            $where_clause = "WHERE date BETWEEN ? AND ?";
            $params = [$start_date, $end_date];
        }

        $query = "SELECT 
                    category,
                    type,
                    COUNT(*) as transaction_count,
                    SUM(amount) as total_amount
                  FROM " . $this->table_name . " " . $where_clause . "
                  GROUP BY category, type
                  ORDER BY total_amount DESC";
        
        $stmt = $this->conn->prepare($query);
        
        if (!empty($params)) {
            $stmt->bindParam(1, $params[0]);
            $stmt->bindParam(2, $params[1]);
        }
        
        $stmt->execute();
        return $stmt;
    }
}
?> 