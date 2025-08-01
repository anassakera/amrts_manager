<?php
require_once '../config/database.php';

class InvoiceItem {
    private $conn;
    private $table_name = "invoice_items";

    public $id;
    public $invoice_id;
    public $ref_fournisseur;
    public $articles;
    public $qte;
    public $poids;
    public $pu_pieces;
    public $exchange_rate;
    public $mt;
    public $prix_achat;
    public $autres_charges;
    public $cu_ht;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    // إنشاء عنصر فاتورة جديد
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                SET
                    invoice_id = :invoice_id,
                    ref_fournisseur = :ref_fournisseur,
                    articles = :articles,
                    qte = :qte,
                    poids = :poids,
                    pu_pieces = :pu_pieces,
                    exchange_rate = :exchange_rate,
                    mt = :mt,
                    prix_achat = :prix_achat,
                    autres_charges = :autres_charges,
                    cu_ht = :cu_ht";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->invoice_id = htmlspecialchars(strip_tags($this->invoice_id));
        $this->ref_fournisseur = htmlspecialchars(strip_tags($this->ref_fournisseur));
        $this->articles = htmlspecialchars(strip_tags($this->articles));
        $this->qte = htmlspecialchars(strip_tags($this->qte));
        $this->poids = htmlspecialchars(strip_tags($this->poids));
        $this->pu_pieces = htmlspecialchars(strip_tags($this->pu_pieces));
        $this->exchange_rate = htmlspecialchars(strip_tags($this->exchange_rate));
        $this->mt = htmlspecialchars(strip_tags($this->mt));
        $this->prix_achat = htmlspecialchars(strip_tags($this->prix_achat));
        $this->autres_charges = htmlspecialchars(strip_tags($this->autres_charges));
        $this->cu_ht = htmlspecialchars(strip_tags($this->cu_ht));

        // ربط القيم
        $stmt->bindParam(":invoice_id", $this->invoice_id);
        $stmt->bindParam(":ref_fournisseur", $this->ref_fournisseur);
        $stmt->bindParam(":articles", $this->articles);
        $stmt->bindParam(":qte", $this->qte);
        $stmt->bindParam(":poids", $this->poids);
        $stmt->bindParam(":pu_pieces", $this->pu_pieces);
        $stmt->bindParam(":exchange_rate", $this->exchange_rate);
        $stmt->bindParam(":mt", $this->mt);
        $stmt->bindParam(":prix_achat", $this->prix_achat);
        $stmt->bindParam(":autres_charges", $this->autres_charges);
        $stmt->bindParam(":cu_ht", $this->cu_ht);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    // قراءة عناصر فاتورة معينة
    public function readByInvoiceId($invoice_id) {
        $query = "SELECT * FROM " . $this->table_name . " WHERE invoice_id = ? ORDER BY id ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $invoice_id);
        $stmt->execute();
        return $stmt;
    }

    // قراءة عنصر واحد
    public function readOne() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE id = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->invoice_id = $row['invoice_id'];
            $this->ref_fournisseur = $row['ref_fournisseur'];
            $this->articles = $row['articles'];
            $this->qte = $row['qte'];
            $this->poids = $row['poids'];
            $this->pu_pieces = $row['pu_pieces'];
            $this->exchange_rate = $row['exchange_rate'];
            $this->mt = $row['mt'];
            $this->prix_achat = $row['prix_achat'];
            $this->autres_charges = $row['autres_charges'];
            $this->cu_ht = $row['cu_ht'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        return false;
    }

    // تحديث عنصر فاتورة
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    ref_fournisseur = :ref_fournisseur,
                    articles = :articles,
                    qte = :qte,
                    poids = :poids,
                    pu_pieces = :pu_pieces,
                    exchange_rate = :exchange_rate,
                    mt = :mt,
                    prix_achat = :prix_achat,
                    autres_charges = :autres_charges,
                    cu_ht = :cu_ht,
                    updated_at = NOW()
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);

        // تنظيف البيانات
        $this->ref_fournisseur = htmlspecialchars(strip_tags($this->ref_fournisseur));
        $this->articles = htmlspecialchars(strip_tags($this->articles));
        $this->qte = htmlspecialchars(strip_tags($this->qte));
        $this->poids = htmlspecialchars(strip_tags($this->poids));
        $this->pu_pieces = htmlspecialchars(strip_tags($this->pu_pieces));
        $this->exchange_rate = htmlspecialchars(strip_tags($this->exchange_rate));
        $this->mt = htmlspecialchars(strip_tags($this->mt));
        $this->prix_achat = htmlspecialchars(strip_tags($this->prix_achat));
        $this->autres_charges = htmlspecialchars(strip_tags($this->autres_charges));
        $this->cu_ht = htmlspecialchars(strip_tags($this->cu_ht));
        $this->id = htmlspecialchars(strip_tags($this->id));

        // ربط القيم
        $stmt->bindParam(':ref_fournisseur', $this->ref_fournisseur);
        $stmt->bindParam(':articles', $this->articles);
        $stmt->bindParam(':qte', $this->qte);
        $stmt->bindParam(':poids', $this->poids);
        $stmt->bindParam(':pu_pieces', $this->pu_pieces);
        $stmt->bindParam(':exchange_rate', $this->exchange_rate);
        $stmt->bindParam(':mt', $this->mt);
        $stmt->bindParam(':prix_achat', $this->prix_achat);
        $stmt->bindParam(':autres_charges', $this->autres_charges);
        $stmt->bindParam(':cu_ht', $this->cu_ht);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // حذف عنصر فاتورة
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

    // حذف جميع عناصر فاتورة معينة
    public function deleteByInvoiceId($invoice_id) {
        $query = "DELETE FROM " . $this->table_name . " WHERE invoice_id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $invoice_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    // حساب إجماليات عناصر فاتورة معينة
    public function calculateTotals($invoice_id) {
        $query = "SELECT 
                    COUNT(*) as total_items,
                    SUM(qte) as total_quantity,
                    SUM(poids) as total_weight,
                    SUM(mt) as total_amount,
                    SUM(prix_achat) as total_purchase_price,
                    SUM(autres_charges) as total_other_charges,
                    SUM(cu_ht) as total_cost
                  FROM " . $this->table_name . " 
                  WHERE invoice_id = ?";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $invoice_id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
?> 