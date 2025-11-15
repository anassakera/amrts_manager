# 📋 وثائق مشروع نظام حساب التكاليف الصناعية (CMUP)

## 📑 جدول المحتويات

1. [نظرة عامة على النظام](#نظرة-عامة-على-النظام)
2. [المفاهيم الأساسية](#المفاهيم-الأساسية)
3. [المراحل الإنتاجية (الورشات)](#المراحل-الإنتاجية-الورشات)
4. [نظام CMUP](#نظام-cmup)
5. [إدارة المخزون](#إدارة-المخزون)
6. [تصميم قاعدة البيانات](#تصميم-قاعدة-البيانات)
7. [API Endpoints](#api-endpoints)
8. [Flutter Integration](#flutter-integration)
9. [أمثلة عملية](#أمثلة-عملية)
10. [دليل التنفيذ](#دليل-التنفيذ)

---

## 🎯 نظرة عامة على النظام

### الهدف الرئيسي
بناء نظام متكامل لحساب تكاليف الإنتاج في مصنع ألمنيوم يعتمد على منهجية **التكلفة المتوسطة المرجحة (CMUP - Coût Moyen Unitaire Pondéré)**.

### البيئة التقنية

#### الواجهة الأمامية (Frontend)
- **Framework:** Flutter + Dart
- **UI Pattern:** Glassmorphism Design
- **State Management:** Provider / Riverpod

#### الواجهة الخلفية (Backend)
- **Language:** PHP خام (بدون frameworks)
- **Architecture:** RESTful API
- **Server:** Apache (XAMPP محلياً)
- **Hosting:** CPanel

#### قواعد البيانات
- **Primary:** MySQL (على VPS عبر phpMyAdmin)
- **Development:** SQL Server Developer Edition (محلي)
- **Sync:** ODBC Driver + SQL Server Agent Jobs

#### هيكل المشروع
```
/api/
├── config/
│   └── database.php
├── fonderie/
├── extrusion/
├── peinture/
├── cmup/
├── stock/
└── .htaccess

/lib/ (Flutter)
├── screens/
│   ├── fonderie_screen.dart
│   ├── extrusion_screen.dart
│   └── peinture_screen.dart
├── services/
│   ├── api_service.dart
│   ├── fonderie_service.dart
│   └── cmup_service.dart
└── models/
```

---

## 💡 المفاهيم الأساسية

### 1. CMUP (التكلفة المتوسطة المرجحة)

**التعريف:**  
طريقة محاسبية لتقييم المخزون تقوم بحساب متوسط تكلفة الوحدة بناءً على المخزون القديم والإنتاج الجديد.

**المعادلة:**
```
CMUP = (قيمة المخزون القديم + قيمة الإنتاج الجديد) 
       ÷ (كمية المخزون القديم + كمية الإنتاج الجديد)
```

**مثال:**
```
مخزون قديم: 500 كغ × 29 درهم = 14,500 درهم
إنتاج جديد: 43,000 كغ × 35.43 درهم = 1,523,595 درهم
────────────────────────────────────────────────
المجموع: 43,500 كغ بقيمة 1,538,095 درهم
CMUP = 1,538,095 ÷ 43,500 = 35.36 درهم/كغ
```

**القاعدة الذهبية:**  
> كل منتج يخرج من المخزن يُسعر بـ CMUP، وليس بسعر الإنتاج المباشر!

---

### 2. دورة الإنتاج (Production Cycle)

**التعريف:**  
فترة زمنية محددة (عادة شهر) يتم فيها حساب جميع التكاليف والإنتاج.

**الخصائص:**
- يتم الحساب **مرة واحدة في نهاية كل شهر**
- كل دورة لها CMUP خاص بها
- لا يمكن تعديل الدورات المغلقة

---

### 3. النفايات (Déchets)

#### نوعان من النفايات:

**أ. نفايات غير قابلة للاستخدام (14% في الصهر)**
- تُخصم من الكمية فقط
- لا تُخصم من التكلفة
- تكلفتها تُوزع على المنتج الصالح

**ب. نفايات قابلة لإعادة الاستخدام (16% في البثق)**
- ترجع للمخزن بسعر ثابت: **25 درهم/كغ**
- تُخصم قيمتها من تكلفة الورشة
- تُعامل كمادة خام جديدة

**القاعدة:**
```
الديشي (النفايات القابلة للاسترجاع) = مادة خام بسعر 25 درهم/كغ
```

---

## 🏭 المراحل الإنتاجية (الورشات)

### المرحلة 1: ورشة الصهر (FONDERIE) 🔥

#### الوظيفة
تحويل خردة الألمنيوم إلى قوالب (Billetes) جاهزة للبثق.

#### المدخلات
| العنصر | الوحدة | السعر المرجعي |
|--------|--------|----------------|
| خردة ألمنيوم | كغ | 26 درهم |
| يد عاملة | ساعة | 4,254.74 درهم/شهر |
| بروبان | لتر | 12.05 درهم |
| كهرباء | كيلو واط | 16 درهم |
| إهتلاك آلات | شهري | 16,666.67 درهم |
| صيانة ومتفرقات | شهري | 8,666.67 درهم |

#### المخرجات
- **القوالب (Billetes):** 43,000 كغ
- **نفايات:** 14% (7,000 كغ) - غير قابلة للاستخدام
- **تكلفة الوحدة:** 35.43 درهم/كغ

#### الحسابات
```
إجمالي المدخلات = 1,700,000 درهم
÷ الإنتاج الصافي (43,000 كغ)
= 35.43 درهم/كغ
```

---

### المرحلة 2: ورشة البثق (EXTRUSION) 🏗️

#### الوظيفة
تحويل القوالب إلى قضبان خام بأشكال وأطوال محددة.

#### المدخلات
| العنصر | الوحدة | السعر/الملاحظة |
|--------|--------|-----------------|
| قوالب (Billetes) | كغ | CMUP من المرحلة السابقة |
| يد عاملة | ساعة | 34,037.89 درهم/شهر |
| كهرباء | كيلو واط | 22,500 درهم/شهر |
| قوالب الآلات (Filières) | شهري | 51,600 درهم |
| صيانة ومتفرقات | شهري | 8,666.67 درهم |

#### ⚠️ ملاحظة مهمة
**البثق لا يستخدم البروبان!** يعمل بالكهرباء فقط.

#### المخرجات
- **قضبان خام:** 36,120 كغ
- **نفايات (ديشي):** 16% (6,880 كغ) - **قابلة لإعادة الاستخدام**
- **تكلفة الوحدة:** 42.48 درهم/كغ

#### معالجة الديشي
```sql
-- إرجاع الديشي للمخزن
قيمة الديشي = 6,880 كغ × 25 درهم = 172,000 درهم
تكلفة الورشة = التكلفة الإجمالية - قيمة الديشي
```

---

### المرحلة 3: ورشة الطلاء (LAQUAGE/PEINTURE) 🎨

#### الوظيفة
طلاء القضبان الخام وتحويلها إلى منتج نهائي جاهز للبيع.

#### المدخلات
| العنصر | الوحدة | السعر المرجعي |
|--------|--------|----------------|
| قضبان خام | كغ | CMUP من المرحلة السابقة |
| يد عاملة | ساعة | 21,273.68 درهم/شهر |
| مواد طلاء | كغ | 30,000 درهم/شهر |
| مواد كيميائية | شهري | 10,836 درهم |
| بروبان | لتر | 12.05 درهم |
| كهرباء | كيلو واط | 4,500 درهم/شهر |
| تغليف | شهري | 1,500 درهم |

#### المخرجات
- **قضبان جاهزة:** 35,578 كغ
- **معيب:** 1.5% (542 كغ)
- **تكلفة الوحدة:** 49.87 درهم/كغ
- **سعر البيع:** 65 درهم/كغ (مثال)

---

## 📊 نظام CMUP

### آلية العمل

#### الخطوة 1: جمع البيانات
```
المخزون القديم:
  - الكمية: من جدول cmup_calculations (final_stock_qty)
  - التكلفة: من جدول cmup_calculations (cmup)
  - القيمة: الكمية × التكلفة

الإنتاج الجديد:
  - الكمية: من جدول الإنتاج (fonderie/extrusion/peinture)
  - التكلفة: التكلفة المحسوبة من الورشة
  - القيمة: الكمية × التكلفة
```

#### الخطوة 2: الحساب
```javascript
// Pseudo-code
total_qty = old_stock_qty + new_production_qty
total_value = old_stock_value + new_production_value
cmup = total_value / total_qty
```

#### الخطوة 3: التطبيق
```
كل منتج يخرج من المخزن → يُسعر بـ CMUP
مثال:
  CMUP = 35.36 درهم/كغ
  خروج 43,000 كغ للبثق = 43,000 × 35.36 = 1,520,416 درهم
```

---

### حالات خاصة

#### حالة 1: المخزون القديم = صفر
```
CMUP = تكلفة الإنتاج الجديد مباشرة
مثال:
  مخزون قديم: 0 كغ
  إنتاج جديد: 43,000 كغ × 35.43 = 1,523,595 درهم
  CMUP = 1,523,595 ÷ 43,000 = 35.43 درهم/كغ
```

#### حالة 2: إنتاج متعدد في نفس الدورة
```
CMUP يُحدث بعد كل إضافة:
  
  اليوم 1: إنتاج 10,000 كغ × 35 = 350,000
  CMUP₁ = 350,000 ÷ 10,000 = 35.00
  
  اليوم 5: إنتاج 5,000 كغ × 36 = 180,000
  مخزون حالي: 10,000 × 35 = 350,000
  CMUP₂ = (350,000 + 180,000) ÷ (10,000 + 5,000)
        = 530,000 ÷ 15,000 = 35.33 درهم/كغ
```

---

## 📦 إدارة المخزون

### الأنواع الثلاثة للمخزون

#### 1. مخزن المواد الأولية (SMP - Stock de Matière Première)

**المحتوى:**
- خردة ألمنيوم (مشتريات)
- ديشي مُسترجع من البثق (25 درهم/كغ)
- ديشي مُسترجع من الطلاء (25 درهم/كغ)
- بروبان، مواد كيميائية، دهانات

**الحركات:**
- **دخول:** فواتير شراء، استلام ديشي من الورشات
- **خروج:** سحب للصهر

**الجدول:** `inventory_smp`

---

#### 2. مخزن نصف المصنع (SSF - Stock Semi-Fini)

**المحتوى:**
- قوالب (Billetes) من الصهر
- قضبان خام (Barres Brut) من البثق

**الحركات:**
- **دخول:** إنتاج من الورشات (بسعر CMUP)
- **خروج:** سحب للورشة التالية

**الجدول:** `billetes_stock`, `barres_brut_stock` (يمكن دمجهما في `inventory_ssf`)

---

#### 3. مخزن المنتج النهائي (SPF - Stock Produits Finis)

**المحتوى:**
- قضبان مطلية جاهزة للبيع

**الحركات:**
- **دخول:** إنتاج من الطلاء (بسعر CMUP)
- **خروج:** مبيعات للعملاء

**الجدول:** `produits_finis_stock`

---

### تشبيه المصفاة 💧

> **تخيل CMUP كمصفاة مياه:**
> 
> - المياه الجديدة (الإنتاج) تختلط مع المياه القديمة (المخزون) في خزان واحد
> - كل نقطة تخرج تحمل نفس التكلفة الموحدة (CMUP)
> - لا يمكن تمييز المياه الجديدة عن القديمة بعد الخلط

---

## 🗄️ تصميم قاعدة البيانات

### ERD (Entity Relationship Diagram)

```
┌─────────────────────┐
│ production_cycles   │
│ ─────────────────── │
│ PK: id              │
│     cycle_name      │
│     start_date      │
│     end_date        │
│     status          │
└──────────┬──────────┘
           │
           │ 1
           │
           │ N
┌──────────┴──────────┐
│ fonderie_operations │
│ ─────────────────── │
│ PK: id              │
│ FK: cycle_id        │
│     ref_fondrie     │
│     total_quantity  │
│     total_cout      │
└──────────┬──────────┘
           │ 1
           │
           │ N
┌──────────┴──────────┐
│ fonderie_details    │
│ ─────────────────── │
│ PK: id              │
│ FK: fonderie_id     │
│     ref_article     │
│     quantity        │
│     cout            │
└─────────────────────┘
```

---

### الجداول (15 جدول)

#### مجموعة الجداول الأساسية

##### 1. production_cycles
```sql
CREATE TABLE production_cycles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cycle_name VARCHAR(100) NOT NULL COMMENT 'مثال: يناير 2025',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('active', 'completed', 'archived') DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** تنظيم الحسابات شهرياً  
**الحالات:**
- `active`: الدورة النشطة حالياً (واحدة فقط)
- `completed`: دورات مكتملة
- `archived`: دورات قديمة مؤرشفة

---

##### 2. articles
```sql
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ref_article VARCHAR(50) UNIQUE NOT NULL COMMENT 'مثال: ART-001',
    article_name VARCHAR(200) NOT NULL COMMENT 'مثال: Profilé Aluminium A',
    ref_code VARCHAR(50) COMMENT 'مثال: AL-6063',
    ind VARCHAR(10) COMMENT 'مثال: A',
    type ENUM('profile', 'tube', 'barre', 'other') DEFAULT 'profile',
    weight_per_meter DECIMAL(10,3) COMMENT 'الوزن للمتر الواحد',
    standard_length DECIMAL(10,2) COMMENT 'الطول القياسي بالمليمتر',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_ref (ref_article),
    INDEX idx_type (type),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** كتالوج المنتجات  
**الاستخدام:** ربط جميع العمليات بمنتج محدد

---

##### 3. employees
```sql
CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    employee_name VARCHAR(100) NOT NULL,
    role ENUM('conducteur', 'dressage', 'operator', 'supervisor', 'other') NOT NULL,
    team VARCHAR(10) COMMENT 'A, B, C',
    phone VARCHAR(20),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_role (role),
    INDEX idx_team (team),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** إدارة الموظفين والفرق  
**الأدوار:**
- `conducteur`: قائد المكبس
- `dressage`: مسؤول التقويم
- `operator`: عامل
- `supervisor`: مشرف

---

##### 4. reference_prices
```sql
CREATE TABLE reference_prices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    element_name VARCHAR(100) NOT NULL COMMENT 'مثال: خردة ألمنيوم',
    element_type ENUM('raw_material', 'energy', 'waste', 'labor') NOT NULL,
    unit VARCHAR(20) NOT NULL COMMENT 'كغ، لتر، ساعة',
    unit_price DECIMAL(10,2) NOT NULL,
    effective_from DATE NOT NULL COMMENT 'تاريخ بداية السعر',
    effective_to DATE COMMENT 'تاريخ نهاية السعر',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_element (element_name),
    INDEX idx_type (element_type),
    INDEX idx_dates (effective_from, effective_to),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** تخزين أسعار المواد والطاقة  
**الاستخدام:** حساب التكاليف تلقائياً عند تغير الأسعار

---

##### 5. colors
```sql
CREATE TABLE colors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    color_code VARCHAR(50) NOT NULL COMMENT 'مثال: RAL 9016',
    color_name VARCHAR(100) NOT NULL COMMENT 'مثال: Blanc signalisation',
    color_hex VARCHAR(7) COMMENT '#FFFFFF',
    additional_cost DECIMAL(10,2) DEFAULT 0 COMMENT 'تكلفة إضافية للون',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_code (color_code),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** كتالوج الألوان المتاحة  
**الاستخدام:** ربط المنتجات النهائية بألوانها

---

#### مجموعة جداول الصهر

##### 6. fonderie_operations
```sql
CREATE TABLE fonderie_operations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ref_fondrie VARCHAR(50) UNIQUE NOT NULL COMMENT 'مثال: FO-25-01-00001',
    cycle_id INT NOT NULL,
    operation_date DATE NOT NULL,
    operation_time TIME NOT NULL,
    total_quantity DECIMAL(10,2) NOT NULL COMMENT 'إجمالي الإنتاج بالكيلو',
    total_cout DECIMAL(12,2) NOT NULL COMMENT 'التكلفة الإجمالية بالدرهم',
    operations_count INT DEFAULT 1 COMMENT 'عدد العمليات في هذا الصهر',
    status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cycle_id) REFERENCES production_cycles(id) ON DELETE RESTRICT,
    
    INDEX idx_ref (ref_fondrie),
    INDEX idx_date (operation_date),
    INDEX idx_cycle (cycle_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** رأس عملية الصهر (Header)  
**العلاقات:** ينتمي لدورة إنتاجية واحدة

---

##### 7. fonderie_details
```sql
CREATE TABLE fonderie_details (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fonderie_id INT NOT NULL,
    ref_article VARCHAR(50) NOT NULL,
    article_name VARCHAR(200) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL COMMENT 'الكمية المنتجة',
    dechet_fondrie DECIMAL(10,2) NOT NULL COMMENT 'نفايات الصهر (%)',
    billete DECIMAL(10,2) NOT NULL COMMENT 'وزن القوالب الناتجة',
    propane DECIMAL(10,2) NOT NULL COMMENT 'استهلاك البروبان',
    electricite DECIMAL(10,2) COMMENT 'استهلاك الكهرباء',
    mod_hours DECIMAL(10,2) COMMENT 'ساعات العمل',
    cout DECIMAL(12,2) NOT NULL COMMENT 'التكلفة',
    
    FOREIGN KEY (fonderie_id) REFERENCES fonderie_operations(id) ON DELETE CASCADE,
    FOREIGN KEY (ref_article) REFERENCES articles(ref_article) ON DELETE RESTRICT,
    
    INDEX idx_fonderie (fonderie_id),
    INDEX idx_article (ref_article)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** تفاصيل كل عملية صهر  
**العلاقات:** عملية صهر واحدة يمكن أن تحتوي على عدة تفاصيل

---

##### 8. billetes_stock
```sql
CREATE TABLE billetes_stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fonderie_id INT NOT NULL,
    num_lot_billette VARCHAR(50) UNIQUE NOT NULL COMMENT 'مثال: BL-2023-145',
    ref_article VARCHAR(50) NOT NULL,
    quantity INT NOT NULL COMMENT 'عدد القوالب',
    weight_per_billete DECIMAL(10,3) NOT NULL COMMENT 'وزن القالب الواحد',
    total_weight DECIMAL(10,2) NOT NULL COMMENT 'الوزن الإجمالي',
    unit_cost DECIMAL(10,2) NOT NULL COMMENT 'التكلفة للكغ (CMUP)',
    production_date DATE NOT NULL,
    status ENUM('available', 'used', 'reserved') DEFAULT 'available',
    used_quantity INT DEFAULT 0 COMMENT 'الكمية المستخدمة',
    remaining_quantity INT COMMENT 'الكمية المتبقية',
    
    FOREIGN KEY (fonderie_id) REFERENCES fonderie_operations(id) ON DELETE RESTRICT,
    FOREIGN KEY (ref_article) REFERENCES articles(ref_article) ON DELETE RESTRICT,
    
    INDEX idx_lot (num_lot_billette),
    INDEX idx_status (status),
    INDEX idx_article (ref_article),
    INDEX idx_production_date (production_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** مخزون القوالب  
**الحسابات التلقائية:**
```sql
remaining_quantity = quantity - used_quantity
status = CASE 
    WHEN remaining_quantity = 0 THEN 'used'
    WHEN remaining_quantity > 0 THEN 'available'
END
```

---

#### مجموعة جداول البثق

##### 9. extrusion_operations
```sql
CREATE TABLE extrusion_operations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero VARCHAR(50) UNIQUE NOT NULL COMMENT 'مثال: EX-25-01-00001',
    cycle_id INT NOT NULL,
    operation_date DATE NOT NULL,
    horaire VARCHAR(50) COMMENT 'مثال: 8:00-16:00',
    equipe VARCHAR(10) COMMENT 'A, B, C',
    conducteur_id INT COMMENT 'ID الموظف',
    dressage_id INT COMMENT 'ID الموظف',
    presse VARCHAR(10) COMMENT 'رقم المكبس',
    total_arrets VARCHAR(50) COMMENT 'إجمالي التوقفات',
    status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cycle_id) REFERENCES production_cycles(id) ON DELETE RESTRICT,
    FOREIGN KEY (conducteur_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (dressage_id) REFERENCES employees(id) ON DELETE SET NULL,
    
    INDEX idx_numero (numero),
    INDEX idx_date (operation_date),
    INDEX idx_cycle (cycle_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** رأس عملية البثق  
**الاستخدام:** تسجيل الفريق والمعدات المستخدمة

---

##### 10. extrusion_production
```sql
CREATE TABLE extrusion_production (
    id INT PRIMARY KEY AUTO_INCREMENT,
    extrusion_id INT NOT NULL,
    nbr_eclt VARCHAR(10) COMMENT 'رقم الإيكلاتي',
    ref VARCHAR(50) NOT NULL,
    ind VARCHAR(10),
    heur_debut TIME,
    heur_fin TIME,
    nbr_blocs INT COMMENT 'عدد القوالب المستخدمة',
    lg_blocs DECIMAL(10,2) COMMENT 'طول القالب',
    prut_kg DECIMAL(10,2) COMMENT 'الوزن الخام',
    num_lot_billette VARCHAR(50) COMMENT 'رقم دفعة القوالب',
    vitesse DECIMAL(10,2) COMMENT 'السرعة',
    pres_extru DECIMAL(10,2) COMMENT 'ضغط البثق',
    nbr_barres INT COMMENT 'عدد القضبان الناتجة',
    long DECIMAL(10,2) COMMENT 'الطول',
    p_barre_reel DECIMAL(10,3) COMMENT 'وزن القضيب الفعلي',
    net_kg DECIMAL(10,2) COMMENT 'الوزن الصافي',
    long_eclt DECIMAL(10,2) COMMENT 'طول الإيكلاتي',
    etirage_kg DECIMAL(10,2) COMMENT 'وزن السحب',
    taux_de_chutes DECIMAL(5,2) COMMENT 'نسبة النفايات (%)',
    nbr_barres_chutes INT COMMENT 'عدد القضبان النفايات',
    observation TEXT,
    
    FOREIGN KEY (extrusion_id) REFERENCES extrusion_operations(id) ON DELETE CASCADE,
    FOREIGN KEY (num_lot_billette) REFERENCES billetes_stock(num_lot_billette) ON DELETE RESTRICT,
    
    INDEX idx_extrusion (extrusion_id),
    INDEX idx_lot (num_lot_billette),
    INDEX idx_ref (ref)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** تفاصيل إنتاج البثق  
**البيانات التقنية:** سرعة، ضغط، أوزان، أطوال

---

##### 11. extrusion_arrets
```sql
CREATE TABLE extrusion_arrets (
    id INT PRIMARY KEY AUTO_INCREMENT,
    extrusion_id INT NOT NULL,
    debut TIME NOT NULL,
    fin TIME NOT NULL,
    duree VARCHAR(20) COMMENT 'مثال: 15 min',
    cause VARCHAR(200) COMMENT 'سبب التوقف',
    action VARCHAR(200) COMMENT 'الإجراء المتخذ',
    
    FOREIGN KEY (extrusion_id) REFERENCES extrusion_operations(id) ON DELETE CASCADE,
    
    INDEX idx_extrusion (extrusion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** تسجيل التوقفات والأعطال  
**الاستخدام:** تحليل الكفاءة وتقليل الهدر الزمني

---

##### 12. extrusion_culot
```sql
CREATE TABLE extrusion_culot (
    id INT PRIMARY KEY AUTO_INCREMENT,
    extrusion_id INT NOT NULL,
    par_nc DECIMAL(10,2) COMMENT 'قطع غير مطابقة',
    culot DECIMAL(10,2) COMMENT 'الكولو',
    pag DECIMAL(10,2) COMMENT 'PAG',
    fo DECIMAL(10,2) COMMENT 'FO',
    retour_f DECIMAL(10,2) COMMENT 'رجوع F',
    total DECIMAL(10,2) COMMENT 'الإجمالي',
    unit_price DECIMAL(10,2) DEFAULT 25.00 COMMENT 'سعر الكيلو (ثابت)',
    total_value DECIMAL(12,2) COMMENT 'القيمة الإجمالية',
    returned_to_stock BOOLEAN DEFAULT FALSE COMMENT 'هل رجع للمخزن؟',
    return_date DATE COMMENT 'تاريخ الإرجاع',
    
    FOREIGN KEY (extrusion_id) REFERENCES extrusion_operations(id) ON DELETE CASCADE,
    
    INDEX idx_extrusion (extrusion_id),
    INDEX idx_returned (returned_to_stock)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** تسجيل النفايات (الديشي) القابلة للاسترجاع  
**القاعدة:** `total_value = total × 25`

**Trigger تلقائي:**
```sql
DELIMITER $$
CREATE TRIGGER calculate_culot_value
BEFORE INSERT ON extrusion_culot
FOR EACH ROW
BEGIN
    SET NEW.total_value = NEW.total * NEW.unit_price;
END$$
DELIMITER ;
```

---

#### مجموعة جداول الطلاء

##### 13. peinture_operations
```sql
CREATE TABLE peinture_operations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ref_doc VARCHAR(50) UNIQUE NOT NULL COMMENT 'مثال: PE-25-01-00001',
    cycle_id INT NOT NULL,
    operation_date DATE NOT NULL,
    ref VARCHAR(50) NOT NULL,
    designations TEXT,
    qte INT NOT NULL COMMENT 'الكمية (عدد القطع)',
    poid_barre DECIMAL(10,3) NOT NULL COMMENT 'وزن القضيب الواحد',
    poid DECIMAL(10,2) NOT NULL COMMENT 'الوزن الإجمالي',
    dichet DECIMAL(10,2) NOT NULL COMMENT 'النفايات',
    poid_net DECIMAL(10,2) NOT NULL COMMENT 'الوزن الصافي',
    color_id INT COMMENT 'ID اللون',
    cout_production_unitaire DECIMAL(10,2) NOT NULL COMMENT 'تكلفة الإنتاج للكغ',
    prix_vente DECIMAL(10,2) COMMENT 'سعر البيع المقترح',
    type VARCHAR(100) COMMENT 'نوع الطلاء',
    source VARCHAR(100),
    observations TEXT,
    statut ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cycle_id) REFERENCES production_cycles(id) ON DELETE RESTRICT,
    FOREIGN KEY (color_id) REFERENCES colors(id) ON DELETE SET NULL,
    
    INDEX idx_ref_doc (ref_doc),
    INDEX idx_date (operation_date),
    INDEX idx_cycle (cycle_id),
    INDEX idx_statut (statut),
    INDEX idx_color (color_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** عمليات الطلاء  
**الحسابات:**
```sql
poid_net = poid - dichet
dichet = poid × 0.015  -- 1.5%
```

---

##### 14. produits_finis_stock
```sql
CREATE TABLE produits_finis_stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    peinture_id INT NOT NULL,
    ref_article VARCHAR(50) NOT NULL,
    designations TEXT,
    quantity INT NOT NULL COMMENT 'عدد القطع',
    weight_per_unit DECIMAL(10,3) COMMENT 'وزن القطعة',
    total_weight DECIMAL(10,2) COMMENT 'الوزن الإجمالي',
    color_id INT,
    unit_cost DECIMAL(10,2) NOT NULL COMMENT 'CMUP',
    selling_price DECIMAL(10,2) COMMENT 'سعر البيع',
    production_date DATE,
    status ENUM('available', 'sold', 'reserved') DEFAULT 'available',
    sold_quantity INT DEFAULT 0,
    remaining_quantity INT,
    
    FOREIGN KEY (peinture_id) REFERENCES peinture_operations(id) ON DELETE RESTRICT,
    FOREIGN KEY (ref_article) REFERENCES articles(ref_article) ON DELETE RESTRICT,
    FOREIGN KEY (color_id) REFERENCES colors(id) ON DELETE SET NULL,
    
    INDEX idx_status (status),
    INDEX idx_article (ref_article),
    INDEX idx_color (color_id),
    INDEX idx_production_date (production_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** مخزون المنتجات الجاهزة للبيع  
**الحسابات:**
```sql
remaining_quantity = quantity - sold_quantity
profit_per_unit = selling_price - unit_cost
```

---

#### جدول CMUP (الأهم!)

##### 15. cmup_calculations
```sql
CREATE TABLE cmup_calculations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cycle_id INT NOT NULL,
    product_type ENUM('billetes', 'barres_brut', 'barres_fini') NOT NULL,
    ref_article VARCHAR(50),
    
    -- المخزون القديم
    initial_stock_qty DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT 'كمية المخزون السابق',
    initial_stock_unit_cost DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT 'تكلفة الوحدة السابقة',
    initial_stock_value DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'قيمة المخزون السابق',
    
    -- الإنتاج الجديد
    production_qty DECIMAL(10,2) NOT NULL COMMENT 'كمية الإنتاج الجديد',
    production_unit_cost DECIMAL(10,2) NOT NULL COMMENT 'تكلفة إنتاج الوحدة',
    production_value DECIMAL(12,2) NOT NULL COMMENT 'قيمة الإنتاج الجديد',
    
    -- الإجمالي
    total_qty DECIMAL(10,2) NOT NULL COMMENT 'إجمالي الكمية',
    cmup DECIMAL(10,2) NOT NULL COMMENT '⭐ التكلفة المتوسطة المرجحة',
    total_value DECIMAL(12,2) NOT NULL COMMENT 'إجمالي القيمة',
    
    -- المخرجات
    output_qty DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT 'الكمية الخارجة',
    output_value DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'قيمة المخرجات',
    
    -- المخزون النهائي
    final_stock_qty DECIMAL(10,2) NOT NULL COMMENT 'المخزون المتبقي',
    final_stock_value DECIMAL(12,2) NOT NULL COMMENT 'قيمة المخزون المتبقي',
    
    calculation_date DATE NOT NULL,
    workshop ENUM('fonderie', 'extrusion', 'laquage') NOT NULL,
    notes TEXT,
    
    FOREIGN KEY (cycle_id) REFERENCES production_cycles(id) ON DELETE RESTRICT,
    FOREIGN KEY (ref_article) REFERENCES articles(ref_article) ON DELETE RESTRICT,
    
    INDEX idx_cycle (cycle_id),
    INDEX idx_type (product_type),
    INDEX idx_workshop (workshop),
    INDEX idx_article (ref_article),
    INDEX idx_date (calculation_date),
    
    -- Constraint: للتأكد من صحة المعادلة
    CONSTRAINT chk_cmup_balance CHECK (
        ABS((initial_stock_value + production_value) - total_value) < 0.01
    ),
    CONSTRAINT chk_final_stock CHECK (
        ABS((total_value - output_value) - final_stock_value) < 0.01
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**الغرض:** قلب النظام - حساب CMUP  
**المعادلات المدمجة:**
```sql
total_qty = initial_stock_qty + production_qty
total_value = initial_stock_value + production_value
cmup = total_value / total_qty
final_stock_qty = total_qty - output_qty
final_stock_value = total_value - output_value
```

---

### Triggers التلقائية

#### Trigger 1: حساب CMUP للقوالب تلقائياً

```sql
DELIMITER $$

CREATE TRIGGER auto_calculate_billetes_cmup
AFTER INSERT ON billetes_stock
FOR EACH ROW
BEGIN
    DECLARE v_initial_qty DECIMAL(10,2);
    DECLARE v_initial_cost DECIMAL(10,2);
    DECLARE v_initial_value DECIMAL(12,2);
    DECLARE v_new_cmup DECIMAL(10,2);
    DECLARE v_cycle_id INT;
    
    -- جلب الدورة النشطة
    SELECT id INTO v_cycle_id 
    FROM production_cycles 
    WHERE status = 'active' 
    LIMIT 1;
    
    -- جلب آخر CMUP للمنتج
    SELECT 
        COALESCE(final_stock_qty, 0),
        COALESCE(cmup, 0),
        COALESCE(final_stock_value, 0)
    INTO v_initial_qty, v_initial_cost, v_initial_value
    FROM cmup_calculations
    WHERE product_type = 'billetes'
        AND ref_article = NEW.ref_article
        AND cycle_id = v_cycle_id
    ORDER BY calculation_date DESC
    LIMIT 1;
    
    -- إذا لم يوجد، استخدم صفر
    IF v_initial_qty IS NULL THEN
        SET v_initial_qty = 0;
        SET v_initial_cost = 0;
        SET v_initial_value = 0;
    END IF;
    
    -- حساب CMUP الجديد
    SET v_new_cmup = (v_initial_value + (NEW.total_weight * NEW.unit_cost)) 
                     / (v_initial_qty + NEW.total_weight);
    
    -- حفظ الحساب
    INSERT INTO cmup_calculations (
        cycle_id, product_type, ref_article,
        initial_stock_qty, initial_stock_unit_cost, initial_stock_value,
        production_qty, production_unit_cost, production_value,
        total_qty, cmup, total_value,
        output_qty, output_value,
        final_stock_qty, final_stock_value,
        calculation_date, workshop
    ) VALUES (
        v_cycle_id, 'billetes', NEW.ref_article,
        v_initial_qty, v_initial_cost, v_initial_value,
        NEW.total_weight, NEW.unit_cost, NEW.total_weight * NEW.unit_cost,
        v_initial_qty + NEW.total_weight, v_new_cmup,
        v_initial_value + (NEW.total_weight * NEW.unit_cost),
        0, 0,
        v_initial_qty + NEW.total_weight,
        v_initial_value + (NEW.total_weight * NEW.unit_cost),
        CURDATE(), 'fonderie'
    );
    
    -- تحديث تكلفة القالب بـ CMUP
    UPDATE billetes_stock 
    SET unit_cost = v_new_cmup 
    WHERE id = NEW.id;
    
END$$

DELIMITER ;
```

---

#### Trigger 2: تحديث CMUP عند السحب للبثق

```sql
DELIMITER $$

CREATE TRIGGER update_cmup_on_extrusion
AFTER INSERT ON extrusion_production
FOR EACH ROW
BEGIN
    DECLARE v_cmup DECIMAL(10,2);
    DECLARE v_used_weight DECIMAL(10,2);
    DECLARE v_cycle_id INT;
    
    -- جلب الدورة النشطة
    SELECT id INTO v_cycle_id 
    FROM production_cycles 
    WHERE status = 'active' 
    LIMIT 1;
    
    -- جلب CMUP الحالي
    SELECT cmup INTO v_cmup
    FROM cmup_calculations
    WHERE product_type = 'billetes'
        AND ref_article = NEW.ref
        AND cycle_id = v_cycle_id
    ORDER BY calculation_date DESC
    LIMIT 1;
    
    -- الوزن المستخدم
    SET v_used_weight = NEW.prut_kg;
    
    -- تحديث المخرجات
    UPDATE cmup_calculations
    SET output_qty = output_qty + v_used_weight,
        output_value = output_value + (v_used_weight * v_cmup),
        final_stock_qty = total_qty - (output_qty + v_used_weight),
        final_stock_value = total_value - (output_value + (v_used_weight * v_cmup))
    WHERE product_type = 'billetes'
        AND ref_article = NEW.ref
        AND cycle_id = v_cycle_id
    ORDER BY calculation_date DESC
    LIMIT 1;
    
    -- تحديث حالة القوالب
    UPDATE billetes_stock
    SET used_quantity = used_quantity + NEW.nbr_blocs,
        remaining_quantity = quantity - (used_quantity + NEW.nbr_blocs),
        status = CASE 
            WHEN (quantity - (used_quantity + NEW.nbr_blocs)) = 0 THEN 'used'
            ELSE 'available'
        END
    WHERE num_lot_billette = NEW.num_lot_billette;
    
END$$

DELIMITER ;
```

---

## 🔌 API Endpoints

### البنية الأساسية

#### ملف: `/api/config/database.php`

```php
<?php
class Database {
    private $host = "localhost";
    private $db_name = "production_cmup";
    private $username = "root";
    private $password = "";
    public $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4",
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
        } catch(PDOException $exception) {
            echo json_encode([
                "success" => false,
                "message" => "فشل الاتصال بقاعدة البيانات",
                "error" => $exception->getMessage()
            ]);
            exit();
        }

        return $this->conn;
    }
}
?>
```

---

### API الصهر (Fonderie)

#### ملف: `/api/fonderie/create.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->ref_fondrie) &&
    !empty($data->cycle_id) &&
    !empty($data->operation_date) &&
    !empty($data->items) &&
    is_array($data->items)
) {
    
    try {
        $db->beginTransaction();
        
        // حساب الإجماليات
        $total_quantity = 0;
        $total_cout = 0;
        $operations_count = count($data->items);
        
        foreach ($data->items as $item) {
            $total_quantity += $item->quantity;
            $total_cout += $item->cout;
        }
        
        // إدخال العملية الرئيسية
        $query = "INSERT INTO fonderie_operations 
                  (ref_fondrie, cycle_id, operation_date, operation_time, 
                   total_quantity, total_cout, operations_count, status, notes)
                  VALUES 
                  (:ref_fondrie, :cycle_id, :operation_date, :operation_time,
                   :total_quantity, :total_cout, :operations_count, :status, :notes)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(":ref_fondrie", $data->ref_fondrie);
        $stmt->bindParam(":cycle_id", $data->cycle_id);
        $stmt->bindParam(":operation_date", $data->operation_date);
        $stmt->bindParam(":operation_time", $data->operation_time);
        $stmt->bindParam(":total_quantity", $total_quantity);
        $stmt->bindParam(":total_cout", $total_cout);
        $stmt->bindParam(":operations_count", $operations_count);
        
        $status = isset($data->status) ? $data->status : 'completed';
        $stmt->bindParam(":status", $status);
        $stmt->bindParam(":notes", $data->notes);
        
        $stmt->execute();
        $fonderie_id = $db->lastInsertId();
        
        // إدخال التفاصيل وإنشاء القوالب
        foreach ($data->items as $item) {
            // إدخال التفصيل
            $query_detail = "INSERT INTO fonderie_details 
                            (fonderie_id, ref_article, article_name, quantity,
                             dechet_fondrie, billete, propane, electricite, cout)
                            VALUES 
                            (:fonderie_id, :ref_article, :article_name, :quantity,
                             :dechet_fondrie, :billete, :propane, :electricite, :cout)";
            
            $stmt_detail = $db->prepare($query_detail);
            
            $stmt_detail->bindParam(":fonderie_id", $fonderie_id);
            $stmt_detail->bindParam(":ref_article", $item->ref_article);
            $stmt_detail->bindParam(":article_name", $item->articleName);
            $stmt_detail->bindParam(":quantity", $item->quantity);
            $stmt_detail->bindParam(":dechet_fondrie", $item->dechet_fondrie);
            $stmt_detail->bindParam(":billete", $item->billete);
            $stmt_detail->bindParam(":propane", $item->propane);
            
            $electricite = isset($item->electricite) ? $item->electricite : 0;
            $stmt_detail->bindParam(":electricite", $electricite);
            $stmt_detail->bindParam(":cout", $item->cout);
            
            $stmt_detail->execute();
            
            // حساب تكلفة الوحدة للقوالب
            $unit_cost = $item->cout / $item->billete;
            
            // توليد رقم دفعة فريد
            $num_lot = "BL-" . date('Y') . "-" . str_pad($fonderie_id, 6, "0", STR_PAD_LEFT);
            
            // إنشاء القوالب في المخزون
            $query_billete = "INSERT INTO billetes_stock 
                             (fonderie_id, num_lot_billette, ref_article,
                              quantity, weight_per_billete, total_weight,
                              unit_cost, production_date, status)
                             VALUES 
                             (:fonderie_id, :num_lot, :ref_article,
                              :quantity, :weight_per_billete, :total_weight,
                              :unit_cost, :production_date, 'available')";
            
            $stmt_billete = $db->prepare($query_billete);
            
            // عدد القوالب (افتراضي: الكمية ÷ 10)
            $nbr_billetes = ceil($item->quantity / 10);
            $weight_per_billete = $item->billete / $nbr_billetes;
            
            $stmt_billete->bindParam(":fonderie_id", $fonderie_id);
            $stmt_billete->bindParam(":num_lot", $num_lot);
            $stmt_billete->bindParam(":ref_article", $item->ref_article);
            $stmt_billete->bindParam(":quantity", $nbr_billetes);
            $stmt_billete->bindParam(":weight_per_billete", $weight_per_billete);
            $stmt_billete->bindParam(":total_weight", $item->billete);
            $stmt_billete->bindParam(":unit_cost", $unit_cost);
            $stmt_billete->bindParam(":production_date", $data->operation_date);
            
            $stmt_billete->execute();
        }
        
        $db->commit();
        
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "تم إضافة عملية الصهر بنجاح",
            "fonderie_id" => $fonderie_id,
            "ref_fondrie" => $data->ref_fondrie
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "فشل في إضافة عملية الصهر",
            "error" => $e->getMessage()
        ]);
    }
    
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "بيانات غير مكتملة"
    ]);
}
?>
```

---

#### ملف: `/api/fonderie/read.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT 
                fo.id,
                fo.ref_fondrie,
                fo.operation_date,
                fo.operation_time,
                fo.total_quantity,
                fo.total_cout,
                fo.operations_count,
                fo.status,
                fo.notes,
                pc.cycle_name
              FROM fonderie_operations fo
              LEFT JOIN production_cycles pc ON fo.cycle_id = pc.id
              ORDER BY fo.operation_date DESC, fo.operation_time DESC";
    
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $fonderies = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $fonderie_id = $row['id'];
        
        // جلب التفاصيل
        $query_details = "SELECT * FROM fonderie_details 
                          WHERE fonderie_id = :fonderie_id";
        $stmt_details = $db->prepare($query_details);
        $stmt_details->bindParam(":fonderie_id", $fonderie_id);
        $stmt_details->execute();
        
        $items = [];
        while ($detail = $stmt_details->fetch(PDO::FETCH_ASSOC)) {
            $items[] = [
                'id' => $detail['id'],
                'ref_article' => $detail['ref_article'],
                'articleName' => $detail['article_name'],
                'quantity' => floatval($detail['quantity']),
                'dechet_fondrie' => floatval($detail['dechet_fondrie']),
                'billete' => floatval($detail['billete']),
                'propane' => floatval($detail['propane']),
                'electricite' => floatval($detail['electricite']),
                'cout' => floatval($detail['cout'])
            ];
        }
        
        $fonderies[] = [
            'id' => $row['id'],
            'ref_fondrie' => $row['ref_fondrie'],
            'cycle_name' => $row['cycle_name'],
            'operation_date' => $row['operation_date'],
            'operation_time' => $row['operation_time'],
            'total_quantity' => floatval($row['total_quantity']),
            'total_cout' => floatval($row['total_cout']),
            'operations_count' => intval($row['operations_count']),
            'status' => $row['status'],
            'notes' => $row['notes'],
            'items' => $items
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "records" => $fonderies,
        "count" => count($fonderies)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "فشل في جلب البيانات",
        "error" => $e->getMessage()
    ]);
}
?>
```

---

#### ملف: `/api/fonderie/get_cmup.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->ref_article) && !empty($data->cycle_id)) {
    
    try {
        $query = "SELECT * FROM cmup_calculations
                  WHERE ref_article = :ref_article
                    AND cycle_id = :cycle_id
                    AND product_type = 'billetes'
                  ORDER BY calculation_date DESC
                  LIMIT 1";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(":ref_article", $data->ref_article);
        $stmt->bindParam(":cycle_id", $data->cycle_id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "cmup" => floatval($row['cmup']),
                "total_qty" => floatval($row['total_qty']),
                "final_stock_qty" => floatval($row['final_stock_qty']),
                "final_stock_value" => floatval($row['final_stock_value']),
                "calculation_date" => $row['calculation_date']
            ]);
        } else {
            http_response_code(404);
            echo json_encode([
                "success" => false,
                "message" => "لم يتم العثور على حسابات CMUP"
            ]);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "فشل في جلب CMUP",
            "error" => $e->getMessage()
        ]);
    }
    
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "بيانات غير مكتملة"
    ]);
}
?>
```

---

### API البثق (Extrusion)

#### ملف: `/api/extrusion/create.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->numero) &&
    !empty($data->cycle_id) &&
    !empty($data->operation_date) &&
    !empty($data->production_data)
) {
    
    try {
        $db->beginTransaction();
        
        // إدخال العملية الرئيسية
        $query = "INSERT INTO extrusion_operations 
                  (numero, cycle_id, operation_date, horaire, equipe,
                   conducteur_id, dressage_id, presse, total_arrets, status, notes)
                  VALUES 
                  (:numero, :cycle_id, :operation_date, :horaire, :equipe,
                   :conducteur_id, :dressage_id, :presse, :total_arrets, :status, :notes)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(":numero", $data->numero);
        $stmt->bindParam(":cycle_id", $data->cycle_id);
        $stmt->bindParam(":operation_date", $data->operation_date);
        $stmt->bindParam(":horaire", $data->horaire);
        $stmt->bindParam(":equipe", $data->equipe);
        $stmt->bindParam(":conducteur_id", $data->conducteur_id);
        $stmt->bindParam(":dressage_id", $data->dressage_id);
        $stmt->bindParam(":presse", $data->presse);
        $stmt->bindParam(":total_arrets", $data->total_arrets);
        
        $status = isset($data->status) ? $data->status : 'completed';
        $stmt->bindParam(":status", $status);
        $stmt->bindParam(":notes", $data->notes);
        
        $stmt->execute();
        $extrusion_id = $db->lastInsertId();
        
        // إدخال بيانات الإنتاج
        foreach ($data->production_data as $prod) {
            $query_prod = "INSERT INTO extrusion_production 
                          (extrusion_id, nbr_eclt, ref, ind, heur_debut, heur_fin,
                           nbr_blocs, lg_blocs, prut_kg, num_lot_billette, vitesse,
                           pres_extru, nbr_barres, long, p_barre_reel, net_kg,
                           long_eclt, etirage_kg, taux_de_chutes, nbr_barres_chutes, observation)
                          VALUES 
                          (:extrusion_id, :nbr_eclt, :ref, :ind, :heur_debut, :heur_fin,
                           :nbr_blocs, :lg_blocs, :prut_kg, :num_lot_billette, :vitesse,
                           :pres_extru, :nbr_barres, :long, :p_barre_reel, :net_kg,
                           :long_eclt, :etirage_kg, :taux_de_chutes, :nbr_barres_chutes, :observation)";
            
            $stmt_prod = $db->prepare($query_prod);
            
            $stmt_prod->bindParam(":extrusion_id", $extrusion_id);
            $stmt_prod->bindParam(":nbr_eclt", $prod->nbr_eclt);
            $stmt_prod->bindParam(":ref", $prod->ref);
            $stmt_prod->bindParam(":ind", $prod->ind);
            $stmt_prod->bindParam(":heur_debut", $prod->heur_debut);
            $stmt_prod->bindParam(":heur_fin", $prod->heur_fin);
            $stmt_prod->bindParam(":nbr_blocs", $prod->nbr_blocs);
            $stmt_prod->bindParam(":lg_blocs", $prod->Lg_blocs);
            $stmt_prod->bindParam(":prut_kg", $prod->prut_kg);
            $stmt_prod->bindParam(":num_lot_billette", $prod->num_lot_billette);
            $stmt_prod->bindParam(":vitesse", $prod->vitesse);
            $stmt_prod->bindParam(":pres_extru", $prod->pres_extru);
            $stmt_prod->bindParam(":nbr_barres", $prod->nbr_barres);
            $stmt_prod->bindParam(":long", $prod->long);
            $stmt_prod->bindParam(":p_barre_reel", $prod->p_barre_reel);
            $stmt_prod->bindParam(":net_kg", $prod->net_kg);
            $stmt_prod->bindParam(":long_eclt", $prod->Long_eclt);
            $stmt_prod->bindParam(":etirage_kg", $prod->etirage_kg);
            $stmt_prod->bindParam(":taux_de_chutes", $prod->taux_de_chutes);
            $stmt_prod->bindParam(":nbr_barres_chutes", $prod->nbr_barres_chutes);
            $stmt_prod->bindParam(":observation", $prod->observation);
            
            $stmt_prod->execute();
        }
        
        // إدخال التوقفات
        if (isset($data->arrets) && is_array($data->arrets)) {
            foreach ($data->arrets as $arret) {
                $query_arret = "INSERT INTO extrusion_arrets 
                               (extrusion_id, debut, fin, duree, cause, action)
                               VALUES 
                               (:extrusion_id, :debut, :fin, :duree, :cause, :action)";
                
                $stmt_arret = $db->prepare($query_arret);
                $stmt_arret->bindParam(":extrusion_id", $extrusion_id);
                $stmt_arret->bindParam(":debut", $arret->debut);
                $stmt_arret->bindParam(":fin", $arret->fin);
                $stmt_arret->bindParam(":duree", $arret->duree);
                $stmt_arret->bindParam(":cause", $arret->cause);
                $stmt_arret->bindParam(":action", $arret->action);
                $stmt_arret->execute();
            }
        }
        
        // إدخال الكولو
        if (isset($data->culot)) {
            $culot = $data->culot;
            $query_culot = "INSERT INTO extrusion_culot 
                           (extrusion_id, par_nc, culot, pag, fo, retour_f, total)
                           VALUES 
                           (:extrusion_id, :par_nc, :culot, :pag, :fo, :retour_f, :total)";
            
            $stmt_culot = $db->prepare($query_culot);
            $stmt_culot->bindParam(":extrusion_id", $extrusion_id);
            $stmt_culot->bindParam(":par_nc", $culot->par_NC);
            $stmt_culot->bindParam(":culot", $culot->culot);
            $stmt_culot->bindParam(":pag", $culot->pag);
            $stmt_culot->bindParam(":fo", $culot->FO);
            $stmt_culot->bindParam(":retour_f", $culot->retour_F);
            $stmt_culot->bindParam(":total", $culot->total);
            $stmt_culot->execute();
        }
        
        $db->commit();
        
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "تم إضافة عملية البثق بنجاح",
            "extrusion_id" => $extrusion_id,
            "numero" => $data->numero
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "فشل في إضافة عملية البثق",
            "error" => $e->getMessage()
        ]);
    }
    
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "بيانات غير مكتملة"
    ]);
}
?>
```

---

#### ملف: `/api/extrusion/get_billetes.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT 
                bs.num_lot_billette,
                bs.ref_article,
                a.article_name,
                bs.quantity,
                bs.weight_per_billete,
                bs.total_weight,
                bs.unit_cost,
                bs.remaining_quantity,
                bs.status,
                bs.production_date
              FROM billetes_stock bs
              LEFT JOIN articles a ON bs.ref_article = a.ref_article
              WHERE bs.status = 'available' 
                AND bs.remaining_quantity > 0
              ORDER BY bs.production_date ASC";
    
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $billetes = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $billetes[] = [
            'num_lot_billette' => $row['num_lot_billette'],
            'ref_article' => $row['ref_article'],
            'article_name' => $row['article_name'],
            'quantity' => intval($row['quantity']),
            'weight_per_billete' => floatval($row['weight_per_billete']),
            'total_weight' => floatval($row['total_weight']),
            'unit_cost' => floatval($row['unit_cost']),
            'remaining_quantity' => intval($row['remaining_quantity']),
            'status' => $row['status'],
            'production_date' => $row['production_date']
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "records" => $billetes,
        "count" => count($billetes)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "فشل في جلب القوالب",
        "error" => $e->getMessage()
    ]);
}
?>
```

---

### API الطلاء (Peinture)

#### ملف: `/api/peinture/create.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->ref_doc) &&
    !empty($data->cycle_id) &&
    !empty($data->operation_date) &&
    !empty($data->ref)
) {
    
    try {
        $db->beginTransaction();
        
        // إدخال عملية الطلاء
        $query = "INSERT INTO peinture_operations 
                  (ref_doc, cycle_id, operation_date, ref, designations,
                   qte, poid_barre, poid, dichet, poid_net, color_id,
                   cout_production_unitaire, prix_vente, type, source,
                   observations, statut)
                  VALUES 
                  (:ref_doc, :cycle_id, :operation_date, :ref, :designations,
                   :qte, :poid_barre, :poid, :dichet, :poid_net, :color_id,
                   :cout_production_unitaire, :prix_vente, :type, :source,
                   :observations, :statut)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(":ref_doc", $data->ref_doc);
        $stmt->bindParam(":cycle_id", $data->cycle_id);
        $stmt->bindParam(":operation_date", $data->operation_date);
        $stmt->bindParam(":ref", $data->ref);
        $stmt->bindParam(":designations", $data->designations);
        $stmt->bindParam(":qte", $data->qte);
        $stmt->bindParam(":poid_barre", $data->poid_barre);
        $stmt->bindParam(":poid", $data->poid);
        $stmt->bindParam(":dichet", $data->dichet);
        $stmt->bindParam(":poid_net", $data->poid_net);
        $stmt->bindParam(":color_id", $data->color_id);
        $stmt->bindParam(":cout_production_unitaire", $data->cout_production_unitaire);
        $stmt->bindParam(":prix_vente", $data->prix_vente);
        $stmt->bindParam(":type", $data->type);
        $stmt->bindParam(":source", $data->source);
        $stmt->bindParam(":observations", $data->observations);
        
        $statut = isset($data->statut) ? $data->statut : 'completed';
        $stmt->bindParam(":statut", $statut);
        
        $stmt->execute();
        $peinture_id = $db->lastInsertId();
        
        // إضافة للمخزون النهائي
        $query_stock = "INSERT INTO produits_finis_stock 
                       (peinture_id, ref_article, designations, quantity,
                        weight_per_unit, total_weight, color_id, unit_cost,
                        selling_price, production_date, status)
                       VALUES 
                       (:peinture_id, :ref_article, :designations, :quantity,
                        :weight_per_unit, :total_weight, :color_id, :unit_cost,
                        :selling_price, :production_date, 'available')";
        
        $stmt_stock = $db->prepare($query_stock);
        
        $stmt_stock->bindParam(":peinture_id", $peinture_id);
        $stmt_stock->bindParam(":ref_article", $data->ref);
        $stmt_stock->bindParam(":designations", $data->designations);
        $stmt_stock->bindParam(":quantity", $data->qte);
        $stmt_stock->bindParam(":weight_per_unit", $data->poid_barre);
        $stmt_stock->bindParam(":total_weight", $data->poid_net);
        $stmt_stock->bindParam(":color_id", $data->color_id);
        $stmt_stock->bindParam(":unit_cost", $data->cout_production_unitaire);
        $stmt_stock->bindParam(":selling_price", $data->prix_vente);
        $stmt_stock->bindParam(":production_date", $data->operation_date);
        
        $stmt_stock->execute();
        
        $db->commit();
        
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "تم إضافة عملية الطلاء بنجاح",
            "peinture_id" => $peinture_id,
            "ref_doc" => $data->ref_doc
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "فشل في إضافة عملية الطلاء",
            "error" => $e->getMessage()
        ]);
    }
    
} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "بيانات غير مكتملة"
    ]);
}
?>
```

---

## 📱 Flutter Integration

### البنية الأساسية

#### ملف: `lib/services/api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String API_URL = "https://yourdomain.com/api";
  
  /// معالجة الأخطاء العامة
  static Map<String, dynamic> _handleError(dynamic error) {
    return {
      "success": false,
      "error": "خطأ في الاتصال: $error",
    };
  }
  
  /// طلب GET عام
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/$endpoint'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
      );
      
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return {
          "success": false,
          "error": "HTTP ${response.statusCode}",
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// طلب POST عام
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/$endpoint'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return {
          "success": false,
          "error": json.decode(utf8.decode(response.bodyBytes))['message'],
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }
}
```

---

#### ملف: `lib/services/fonderie_service.dart`

```dart
import 'api_service.dart';

class FonderieService {
  /// إضافة عملية صهر جديدة
  static Future<Map<String, dynamic>> createFonderie({
    required String refFondrie,
    required int cycleId,
    required String operationDate,
    required String operationTime,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    return await ApiService.post('fonderie/create.php', {
      "ref_fondrie": refFondrie,
      "cycle_id": cycleId,
      "operation_date": operationDate,
      "operation_time": operationTime,
      "items": items,
      "notes": notes,
    });
  }
  
  /// جلب جميع عمليات الصهر
  static Future<Map<String, dynamic>> getAllFonderies() async {
    return await ApiService.get('fonderie/read.php');
  }
  
  /// حساب CMUP للقوالب
  static Future<Map<String, dynamic>> getCMUP({
    required String refArticle,
    required int cycleId,
  }) async {
    return await ApiService.post('fonderie/get_cmup.php', {
      "ref_article": refArticle,
      "cycle_id": cycleId,
      "product_type": "billetes",
    });
  }
  
  /// تحديث عملية صهر
  static Future<Map<String, dynamic>> updateFonderie({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    return await ApiService.post('fonderie/update.php', {
      "id": id,
      ...data,
    });
  }
  
  /// حذف عملية صهر
  static Future<Map<String, dynamic>> deleteFonderie(int id) async {
    return await ApiService.post('fonderie/delete.php', {
      "id": id,
    });
  }
}
```

---

#### ملف: `lib/services/extrusion_service.dart`

```dart
import 'api_service.dart';

class ExtrusionService {
  /// إضافة عملية بثق جديدة
  static Future<Map<String, dynamic>> createExtrusion({
    required String numero,
    required int cycleId,
    required String operationDate,
    required String horaire,
    required String equipe,
    int? conducteurId,
    int? dressageId,
    String? presse,
    required List<Map<String, dynamic>> productionData,
    List<Map<String, dynamic>>? arrets,
    Map<String, dynamic>? culot,
    String? totalArrets,
    String? notes,
  }) async {
    return await ApiService.post('extrusion/create.php', {
      "numero": numero,
      "cycle_id": cycleId,
      "operation_date": operationDate,
      "horaire": horaire,
      "equipe": equipe,
      "conducteur_id": conducteurId,
      "dressage_id": dressageId,
      "presse": presse,
      "production_data": productionData,
      "arrets": arrets,
      "culot": culot,
      "total_arrets": totalArrets,
      "notes": notes,
    });
  }
  
  /// جلب القوالب المتاحة
  static Future<Map<String, dynamic>> getAvailableBilletes() async {
    return await ApiService.get('extrusion/get_billetes.php');
  }
  
  /// جلب جميع عمليات البثق
  static Future<Map<String, dynamic>> getAllExtrusions() async {
    return await ApiService.get('extrusion/read.php');
  }
}
```

---

#### ملف: `lib/services/peinture_service.dart`

```dart
import 'api_service.dart';

class PeintureService {
  /// إضافة عملية طلاء جديدة
  static Future<Map<String, dynamic>> createPeinture({
    required String refDoc,
    required int cycleId,
    required String operationDate,
    required String ref,
    required String designations,
    required int qte,
    required double poidBarre,
    required double poid,
    required double dichet,
    required double poidNet,
    int? colorId,
    required double coutProductionUnitaire,
    double? prixVente,
    String? type,
    String? source,
    String? observations,
  }) async {
    return await ApiService.post('peinture/create.php', {
      "ref_doc": refDoc,
      "cycle_id": cycleId,
      "operation_date": operationDate,
      "ref": ref,
      "designations": designations,
      "qte": qte,
      "poid_barre": poidBarre,
      "poid": poid,
      "dichet": dichet,
      "poid_net": poidNet,
      "color_id": colorId,
      "cout_production_unitaire": coutProductionUnitaire,
      "prix_vente": prixVente,
      "type": type,
      "source": source,
      "observations": observations,
    });
  }
  
  /// جلب جميع عمليات الطلاء
  static Future<Map<String, dynamic>> getAllPeintures() async {
    return await ApiService.get('peinture/read.php');
  }
}
```

---

### استخدام الخدمات في الشاشات

#### مثال: تحديث `fonderie_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/fonderie_service.dart';

class FonderieScreen extends StatefulWidget {
  @override
  _FonderieScreenState createState() => _FonderieScreenState();
}

class _FonderieScreenState extends State<FonderieScreen> {
  List<Map<String, dynamic>> fondries = [];
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadFonderies();
  }
  
  /// تحميل العمليات من API
  Future<void> _loadFonderies() async {
    setState(() => isLoading = true);
    
    try {
      final result = await FonderieService.getAllFonderies();
      
      if (result['success']) {
        setState(() {
          fondries = List<Map<String, dynamic>>.from(result['records']);
          isLoading = false;
        });
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('خطأ في تحميل البيانات: $e');
    }
  }
  
  /// حفظ عملية جديدة
  Future<void> _saveFonderie(Map<String, dynamic> data) async {
    setState(() => isLoading = true);
    
    final result = await FonderieService.createFonderie(
      refFondrie: data['ref_fondrie'],
      cycleId: data['cycle_id'],
      operationDate: data['operation_date'],
      operationTime: data['operation_time'],
      items: List<Map<String, dynamic>>.from(data['items']),
      notes: data['notes'],
    );
    
    setState(() => isLoading = false);
    
    if (result['success']) {
      _showSuccess('تم حفظ العملية بنجاح');
      _loadFonderies(); // إعادة تحميل
    } else {
      _showError(result['error']);
    }
  }
  
  /// عرض رسالة نجاح
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// عرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ورشة الصهر'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : fondries.isEmpty
              ? Center(child: Text('لا توجد عمليات'))
              : ListView.builder(
                  itemCount: fondries.length,
                  itemBuilder: (context, index) {
                    return _buildFonderieCard(fondries[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildFonderieCard(Map<String, dynamic> fondrie) {
    // بناء البطاقة...
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(fondrie['ref_fondrie']),
        subtitle: Text('${fondrie['total_quantity']} كغ'),
        trailing: Text('${fondrie['total_cout']} دh'),
      ),
    );
  }
  
  void _showAddDialog() {
    // عرض نافذة الإضافة...
  }
}
```

---

## 🎯 أمثلة عملية

### مثال كامل: سيناريو من البداية للنهاية

#### الخطوة 1: إنشاء دورة إنتاجية جديدة

```sql
INSERT INTO production_cycles (cycle_name, start_date, end_date, status)
VALUES ('يناير 2025', '2025-01-01', '2025-01-31', 'active');
-- cycle_id = 1
```

---

#### الخطوة 2: عملية صهر

**الإدخال:**
```json
{
  "ref_fondrie": "FO-25-01-00001",
  "cycle_id": 1,
  "operation_date": "2025-01-15",
  "operation_time": "08:30:00",
  "items": [
    {
      "ref_article": "ART-001",
      "articleName": "Profilé Aluminium A",
      "quantity": 50000,
      "dechet_fondrie": 14,
      "billete": 43000,
      "propane": 301024,
      "cout": 1523595
    }
  ]
}
```

**النتيجة في قاعدة البيانات:**

```sql
-- في fonderie_operations
INSERT INTO fonderie_operations VALUES
(1, 'FO-25-01-00001', 1, '2025-01-15', '08:30:00', 50000, 1523595, 1, 'completed', NULL);

-- في billetes_stock
INSERT INTO billetes_stock VALUES
(1, 1, 'BL-2025-000001', 'ART-001', 10, 4300, 43000, 35.43, '2025-01-15', 'available', 0, 10);

-- في cmup_calculations (trigger تلقائي)
INSERT INTO cmup_calculations VALUES
(1, 1, 'billetes', 'ART-001',
 0, 0, 0,                    -- مخزون قديم (صفر لأول مرة)
 43000, 35.43, 1523595,      -- إنتاج جديد
 43000, 35.43, 1523595,      -- الإجمالي
 0, 0,                       -- مخرجات (صفر الآن)
 43000, 1523595,             -- مخزون نهائي
 '2025-01-15', 'fonderie', NULL);
```

---

#### الخطوة 3: عملية بثق

**الإدخال:**
```json
{
  "numero": "EX-25-01-00001",
  "cycle_id": 1,
  "operation_date": "2025-01-16",
  "production_data": [
    {
      "ref": "ART-001",
      "num_lot_billette": "BL-2025-000001",
      "nbr_blocs": 8,
      "prut_kg": 43000,
      "nbr_barres": 120,
      "net_kg": 36120,
      "taux_de_chutes": 16
    }
  ],
  "culot": {
    "total": 6880
  }
}
```

**النتيجة:**

```sql
-- تحديث billetes_stock
UPDATE billetes_stock
SET used_quantity = 8,
    remaining_quantity = 2,
    status = 'available'
WHERE num_lot_billette = 'BL-2025-000001';

-- تحديث cmup_calculations (trigger تلقائي)
UPDATE cmup_calculations
SET output_qty = 43000,
    output_value = 43000 × 35.43 = 1523490,
    final_stock_qty = 0,
    final_stock_value = 0
WHERE product_type = 'billetes' AND cycle_id = 1;

-- إضافة culot
INSERT INTO extrusion_culot VALUES
(1, 1, 0, 6880, 0, 0, 0, 6880, 25, 172000, FALSE, NULL);

-- حساب CMUP للقضبان الخام (جديد)
-- تكلفة البثق = تكلفة القوالب + تكاليف الورشة - قيمة الديشي
-- تكلفة القوالب = 1,523,490 درهم
-- تكاليف الورشة = 183,304.56 درهم
-- قيمة الديشي = 172,000 درهم
-- الإجمالي = 1,523,490 + 183,304.56 - 172,000 = 1,534,794.56 درهم
-- CMUP = 1,534,794.56 ÷ 36,120 = 42.48 درهم/كغ

INSERT INTO cmup_calculations VALUES
(2, 1, 'barres_brut', 'ART-001',
 0, 0, 0,
 36120, 42.48, 1534794.56,
 36120, 42.48, 1534794.56,
 0, 0,
 36120, 1534794.56,
 '2025-01-16', 'extrusion', NULL);
```

---

#### الخطوة 4: عملية طلاء

**الإدخال:**
```json
{
  "ref_doc": "PE-25-01-00001",
  "cycle_id": 1,
  "operation_date": "2025-01-17",
  "ref": "ART-001",
  "qte": 120,
  "poid_barre": 35.5,
  "poid": 4260,
  "dichet": 213,
  "poid_net": 4047,
  "color_id": 1,
  "cout_production_unitaire": 49.87,
  "prix_vente": 65
}
```

**النتيجة:**

```sql
-- حساب CMUP للمنتج النهائي
-- تكلفة القضبان = 36,120 × 42.48 = 1,534,794.56
-- تكاليف الطلاء = 289,397.44 درهم
-- معيب 1.5% = 542 كغ × 42.48 = 23,024.16 درهم (تُطرح)
-- الإجمالي = 1,534,794.56 + 289,397.44 - 23,024.16 = 1,801,167.84 درهم
-- الإنتاج الصافي = 35,578 كغ
-- CMUP = 1,801,167.84 ÷ 35,578 = 50.63 درهم/كغ

INSERT INTO cmup_calculations VALUES
(3, 1, 'barres_fini', 'ART-001',
 0, 0, 0,
 35578, 50.63, 1801167.84,
 35578, 50.63, 1801167.84,
 0, 0,
 35578, 1801167.84,
 '2025-01-17', 'laquage', NULL);

-- المنتج النهائي في المخزون
INSERT INTO produits_finis_stock VALUES
(1, 1, 'ART-001', 'Profilé Aluminium A peint',
 120, 35.5, 4047, 1, 50.63, 65,
 '2025-01-17', 'available', 0, 120);
```

---

#### الخطوة 5: حساب الربح

```sql
SELECT 
    ref_article,
    total_weight,
    unit_cost AS cmup,
    selling_price,
    (selling_price - unit_cost) AS profit_per_kg,
    total_weight * (selling_price - unit_cost) AS total_profit,
    ((selling_price - unit_cost) / selling_price * 100) AS profit_margin_percent
FROM produits_finis_stock
WHERE id = 1;
```

**النتيجة:**
```
ref_article: ART-001
total_weight: 4,047 كغ
cmup: 50.63 درهم/كغ
selling_price: 65 درهم/كغ
profit_per_kg: 14.37 درهم
total_profit: 58,155.39 درهم
profit_margin: 22.1%
```

---

## 📝 دليل التنفيذ

### المرحلة 1: إعداد البيئة (يوم 1)

#### 1.1 قاعدة البيانات
```bash
# إنشاء قاعدة البيانات
mysql -u root -p

CREATE DATABASE production_cmup CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE production_cmup;

# تنفيذ جميع جداول CREATE TABLE
# ... (الـ 15 جدول)

# تنفيذ الـ Triggers
# ... (الـ Triggers التلقائية)
```

#### 1.2 Backend (PHP)
```bash
# هيكل المجلدات
mkdir -p api/config api/fonderie api/extrusion api/peinture api/cmup api/stock

# إنشاء الملفات
touch api/config/database.php
touch api/.htaccess
```

#### 1.3 Frontend (Flutter)
```bash
# إنشاء المشروع
flutter create production_app
cd production_app

# إضافة Dependencies
flutter pub add http provider
```

---

### المرحلة 2: تطوير الـ Backend (أيام 2-4)

#### اليوم 2: Fonderie API
- ✅ `create.php`
- ✅ `read.php`
- ✅ `update.php`
- ✅ `delete.php`
- ✅ `get_cmup.php`

#### اليوم 3: Extrusion API
- ✅ `create.php`
- ✅ `read.php`
- ✅ `get_billetes.php`

#### اليوم 4: Peinture API
- ✅ `create.php`
- ✅ `read.php`

---

### المرحلة 3: تطوير الـ Frontend (أيام 5-8)

#### اليوم 5: Services Layer
- ✅ `api_service.dart`
- ✅ `fonderie_service.dart`
- ✅ `extrusion_service.dart`
- ✅ `peinture_service.dart`

#### اليوم 6-7: Screens
- ✅ تحديث `fonderie_screen.dart`
- ✅ تحديث `extrusion_screen.dart`
- ✅ تحديث `peinture_screen.dart`

#### اليوم 8: Dashboard
- ✅ شاشة Dashboard الرئيسية
- ✅ إحصائيات ورسوم بيانية

---

### المرحلة 4: الاختبار (أيام 9-10)

#### اليوم 9: Unit Tests
```dart
// test/services/fonderie_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FonderieService Tests', () {
    test('Create fonderie operation', () async {
      // Test implementation
    });
  });
}
```

#### اليوم 10: Integration Tests
- اختبار السيناريوهات الكاملة
- اختبار حسابات CMUP
- اختبار حركة المخزون

---

### المرحلة 5: التحسينات (أيام 11-12)

- ✅ تحسين الأداء
- ✅ معالجة الأخطاء
- ✅ إضافة Validations
- ✅ UI/UX improvements

---

## 🔐 الأمان (Security)

### 1. حماية SQL Injection
```php
// ✅ صحيح
$stmt = $db->prepare("SELECT * FROM users WHERE id = :id");
$stmt->bindParam(":id", $user_id);

// ❌ خطأ
$query = "SELECT * FROM users WHERE id = $user_id";
```

### 2. CORS Headers
```php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
```

### 3. Input Validation
```php
// التحقق من البيانات
if (empty($data->ref_fondrie) || strlen($data->ref_fondrie) > 50) {
    http_response_code(400);
    echo json_encode(["error" => "ref_fondrie غير صالح"]);
    exit();
}
```

---

## 📊 التقارير المطلوبة

### 1. تقرير التكاليف الشهري
```sql
SELECT 
    w.workshop,
    SUM(c.production_value) AS total_cost,
    AVG(c.cmup) AS avg_cmup,
    COUNT(*) AS operations_count
FROM cmup_calculations c
JOIN production_cycles pc ON c.cycle_id = pc.id
WHERE pc.cycle_name = 'يناير 2025'
GROUP BY c.workshop;
```

### 2. تقرير الربحية
```sql
SELECT 
    pf.ref_article,
    a.article_name,
    SUM(pf.total_weight) AS total_sold,
    SUM(pf.total_weight * pf.unit_cost) AS total_cost,
    SUM(pf.total_weight * pf.selling_price) AS total_revenue,
    SUM(pf.total_weight * (pf.selling_price - pf.unit_cost)) AS total_profit
FROM produits_finis_stock pf
JOIN articles a ON pf.ref_article = a.ref_article
WHERE pf.status = 'sold'
GROUP BY pf.ref_article;
```

### 3. تقرير المخزون
```sql
SELECT 
    'Billetes' AS product_type,
    ref_article,
    SUM(remaining_quantity) AS total_qty,
    AVG(unit_cost) AS avg_cost
FROM billetes_stock
WHERE status = 'available'
GROUP BY ref_article

UNION ALL

SELECT 
    'Produits Finis',
    ref_article,
    SUM(remaining_quantity),
    AVG(unit_cost)
FROM produits_finis_stock
WHERE status = 'available'
GROUP BY ref_article;
```

---

## ✅ Checklist النهائي

### قاعدة البيانات
- [ ] إنشاء جميع الجداول (15)
- [ ] إضافة الـ Triggers (3)
- [ ] إدخال بيانات تجريبية
- [ ] اختبار العلاقات (Foreign Keys)

### Backend API
- [ ] `config/database.php`
- [ ] Fonderie (5 endpoints)
- [ ] Extrusion (3 endpoints)
- [ ] Peinture (2 endpoints)
- [ ] CMUP (2 endpoints)
- [ ] اختبار جميع الـ endpoints

### Frontend Flutter
- [ ] API Services (4 ملفات)
- [ ] Fonderie Screen (كامل)
- [ ] Extrusion Screen (كامل)
- [ ] Peinture Screen (كامل)
- [ ] Dashboard Screen
- [ ] Reports Screen

### الاختبار
- [ ] Unit Tests
- [ ] Integration Tests
- [ ] UI Tests
- [ ] Performance Tests

### التوثيق
- [x] وثائق المشروع الكاملة (هذا الملف)
- [ ] API Documentation
- [ ] User Manual
- [ ] Developer Guide

---

## 📞 الدعم والمساعدة

للأسئلة أو المشاكل:
1. راجع هذا الملف أولاً
2. تحقق من الأمثلة العملية
3. اختبر الـ SQL Queries في phpMyAdmin
4. استخدم Postman لاختبار الـ API

---

## 🎓 الخلاصة

هذا النظام يقوم بـ:
1. ✅ حساب تكاليف الإنتاج عبر 3 مراحل
2. ✅ تطبيق CMUP تلقائياً
3. ✅ إدارة 3 أنواع من المخزون
4. ✅ تتبع النفايات وإعادة استخدامها
5. ✅ حساب الربحية
6. ✅ توليد التقارير

**الهدف النهائي:** معرفة التكلفة الحقيقية لكل كيلوغرام من المنتج النهائي، وحساب هامش الربح بدقة.

---

**تاريخ آخر تحديث:** 2025-01-15  
**الإصدار:** 1.0  
**المؤلف:** نظام CMUP - وثائق المشروع الكاملة

---

*هذا الملف يحتوي على كامل المعلومات المطلوبة لإكمال المشروع بنجاح. حظاً موفقاً! 🚀*