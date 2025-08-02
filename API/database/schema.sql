-- جدول الفواتير الرئيسي
CREATE TABLE IF NOT EXISTS invoices (
    id VARCHAR(50) PRIMARY KEY,
    clientName VARCHAR(255) NOT NULL,
    invoiceNumber VARCHAR(100) NOT NULL,
    date VARCHAR(100) NOT NULL,
    isLocal BOOLEAN DEFAULT true,
    totalAmount DECIMAL(15,2) DEFAULT 0.0,
    status VARCHAR(50) DEFAULT 'En cours',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- جدول عناصر الفاتورة
CREATE TABLE IF NOT EXISTS invoice_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id VARCHAR(50) NOT NULL,
    refFournisseur VARCHAR(100) NOT NULL,
    articles VARCHAR(255) NOT NULL,
    qte INT NOT NULL,
    poids DECIMAL(10,2) NOT NULL,
    puPieces DECIMAL(10,2) NOT NULL,
    exchangeRate DECIMAL(10,2) NOT NULL,
    mt DECIMAL(10,2) NOT NULL,
    prixAchat DECIMAL(10,2) NOT NULL,
    autresCharges DECIMAL(10,2) NOT NULL,
    cuHt DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- جدول ملخص الفاتورة
CREATE TABLE IF NOT EXISTS invoice_summary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id VARCHAR(50) NOT NULL,
    factureNumber VARCHAR(100) NOT NULL,
    transit DECIMAL(10,2) DEFAULT 0,
    droitDouane DECIMAL(10,2) DEFAULT 0,
    chequeChange DECIMAL(10,2) DEFAULT 0,
    freiht DECIMAL(10,2) DEFAULT 0,
    autres DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(15,2) DEFAULT 0,
    txChange DECIMAL(10,2) DEFAULT 0,
    poidsTotal DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX idx_invoices_client_name ON invoices(clientName);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoiceNumber);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_is_local ON invoices(isLocal);
CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);
CREATE INDEX idx_invoice_summary_invoice_id ON invoice_summary(invoice_id);
