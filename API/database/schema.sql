-- إنشاء قاعدة البيانات
CREATE DATABASE IF NOT EXISTS amrts_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE amrts_manager;

-- جدول الموردين
CREATE TABLE IF NOT EXISTS suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    contact_person VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- جدول الفواتير
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_name VARCHAR(255) NOT NULL,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    date DATETIME NOT NULL,
    is_local BOOLEAN DEFAULT TRUE,
    total_amount DECIMAL(15,2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- جدول عناصر الفواتير
CREATE TABLE IF NOT EXISTS invoice_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    ref_fournisseur VARCHAR(100),
    articles VARCHAR(255) NOT NULL,
    qte INT NOT NULL DEFAULT 0,
    poids DECIMAL(10,2) DEFAULT 0.00,
    pu_pieces DECIMAL(15,2) DEFAULT 0.00,
    exchange_rate DECIMAL(10,2) DEFAULT 1.00,
    mt DECIMAL(15,2) DEFAULT 0.00,
    prix_achat DECIMAL(15,2) DEFAULT 0.00,
    autres_charges DECIMAL(15,2) DEFAULT 0.00,
    cu_ht DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- جدول المنتجات
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit_price DECIMAL(15,2) DEFAULT 0.00,
    cost_price DECIMAL(15,2) DEFAULT 0.00,
    quantity_in_stock INT DEFAULT 0,
    min_quantity INT DEFAULT 0,
    supplier_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- جدول المعاملات المالية
CREATE TABLE IF NOT EXISTS financial_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('income', 'expense') NOT NULL,
    category VARCHAR(100),
    amount DECIMAL(15,2) NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    reference VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX idx_invoices_client_name ON invoices(client_name);
CREATE INDEX idx_invoices_date ON invoices(date);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);
CREATE INDEX idx_products_supplier_id ON products(supplier_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_financial_transactions_type ON financial_transactions(type);
CREATE INDEX idx_financial_transactions_date ON financial_transactions(date);
CREATE INDEX idx_financial_transactions_category ON financial_transactions(category);

-- إدخال بيانات تجريبية للموردين
INSERT INTO suppliers (name, email, phone, address, contact_person) VALUES
('AMR TECH SOLUTION', 'info@amrtech.com', '+212123456789', 'Casablanca, Morocco', 'Ahmed Mohammed'),
('Tech Supplies Co.', 'contact@techsupplies.com', '+212987654321', 'Rabat, Morocco', 'Fatima Zahra'),
('Industrial Parts Ltd.', 'sales@industrialparts.com', '+212555666777', 'Fez, Morocco', 'Karim Hassan');

-- إدخال بيانات تجريبية للمنتجات
INSERT INTO products (name, description, category, unit_price, cost_price, quantity_in_stock, min_quantity, supplier_id) VALUES
('FIRE PLATE 10m', 'Fire resistant plate 10 meters', 'Safety Equipment', 150.00, 120.00, 50, 10, 1),
('FIRE PLATE 20m', 'Fire resistant plate 20 meters', 'Safety Equipment', 280.00, 220.00, 30, 5, 1),
('FIRE PLATE 15m', 'Fire resistant plate 15 meters', 'Safety Equipment', 210.00, 165.00, 40, 8, 2),
('FIRE PLATE 25m', 'Fire resistant plate 25 meters', 'Safety Equipment', 350.00, 275.00, 25, 4, 2),
('FIRE PLATE 30m', 'Fire resistant plate 30 meters', 'Safety Equipment', 420.00, 330.00, 20, 6, 3);

-- إدخال بيانات تجريبية للفواتير
INSERT INTO invoices (client_name, invoice_number, date, is_local, total_amount, status) VALUES
('AMR TECH SOLUTION', 'FA-001', '2025-01-27 11:45:00', TRUE, 1250.00, 'Terminée'),
('Tech Supplies Co.', 'FA-002', '2025-01-28 14:30:00', TRUE, 890.00, 'En cours'),
('Industrial Parts Ltd.', 'FA-003', '2025-01-29 09:15:00', FALSE, 2100.00, 'Terminée');

-- إدخال بيانات تجريبية لعناصر الفواتير
INSERT INTO invoice_items (invoice_id, ref_fournisseur, articles, qte, poids, pu_pieces, exchange_rate, mt, prix_achat, autres_charges, cu_ht) VALUES
(1, 'REF001', 'FIRE PLATE 10m', 10, 10.0, 10.0, 11.0, 100.0, 110.0, 7.0, 117.0),
(1, 'REF002', 'FIRE PLATE 20m', 5, 20.0, 20.0, 22.0, 100.0, 220.0, 14.0, 234.0),
(1, 'REF003', 'FIRE PLATE 15m', 8, 15.0, 12.5, 10.8, 100.0, 108.0, 5.5, 113.5),
(2, 'REF004', 'FIRE PLATE 25m', 4, 25.0, 30.0, 9.5, 120.0, 114.0, 8.2, 122.2),
(2, 'REF005', 'FIRE PLATE 30m', 6, 30.0, 18.0, 12.3, 108.0, 132.84, 6.7, 139.54);

-- إدخال بيانات تجريبية للمعاملات المالية
INSERT INTO financial_transactions (type, category, amount, description, date, reference) VALUES
('expense', 'Purchase', 1250.00, 'Purchase invoice FA-001', '2025-01-27', 'INV-001'),
('expense', 'Transport', 150.00, 'Transportation costs', '2025-01-27', 'TRANS-001'),
('expense', 'Customs', 200.00, 'Customs duties', '2025-01-28', 'CUSTOMS-001'),
('income', 'Sales', 3000.00, 'Product sales', '2025-01-29', 'SALES-001'),
('expense', 'Utilities', 500.00, 'Electricity and water bills', '2025-01-30', 'UTIL-001'); 