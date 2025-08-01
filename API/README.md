# AMRTS Manager API

API backend لنظام إدارة المشتريات والمبيعات والمخزون والإنتاج والمعاملات المالية.

## المتطلبات

- PHP 7.4 أو أحدث
- MySQL 5.7 أو أحدث
- Apache/Nginx web server

## التثبيت

1. انسخ مجلد API إلى مجلد web server الخاص بك
2. قم بإنشاء قاعدة البيانات باستخدام ملف `database/schema.sql`
3. عدّل إعدادات قاعدة البيانات في `config/database.php`

## إعداد قاعدة البيانات

```sql
-- استيراد ملف قاعدة البيانات
mysql -u root -p < database/schema.sql
```

## هيكل API

### الفواتير (Invoices)

#### GET /api/invoices/read.php
الحصول على جميع الفواتير

#### POST /api/invoices/create.php
إنشاء فاتورة جديدة
```json
{
    "client_name": "اسم العميل",
    "invoice_number": "رقم الفاتورة",
    "date": "2025-01-27 11:45:00",
    "is_local": true,
    "total_amount": 1250.00,
    "status": "Pending"
}
```

#### GET /api/invoices/read_one.php?id={id}
الحصول على فاتورة واحدة

#### PUT /api/invoices/update.php
تحديث فاتورة
```json
{
    "id": 1,
    "client_name": "اسم العميل المحدث",
    "status": "Terminée"
}
```

#### DELETE /api/invoices/delete.php
حذف فاتورة
```json
{
    "id": 1
}
```

#### GET /api/invoices/search.php?s={keywords}
البحث في الفواتير

### عناصر الفواتير (Invoice Items)

#### GET /api/invoice_items/read.php?invoice_id={id}
الحصول على عناصر فاتورة معينة

#### POST /api/invoice_items/create.php
إضافة عنصر فاتورة جديد
```json
{
    "invoice_id": 1,
    "ref_fournisseur": "REF001",
    "articles": "FIRE PLATE 10m",
    "qte": 10,
    "poids": 10.0,
    "pu_pieces": 10.0,
    "exchange_rate": 11.0,
    "mt": 100.0,
    "prix_achat": 110.0,
    "autres_charges": 7.0,
    "cu_ht": 117.0
}
```

### المنتجات (Products)

#### GET /api/products/read.php
الحصول على جميع المنتجات مع إحصائيات المخزون

#### POST /api/products/create.php
إضافة منتج جديد
```json
{
    "name": "اسم المنتج",
    "description": "وصف المنتج",
    "category": "فئة المنتج",
    "unit_price": 150.00,
    "cost_price": 120.00,
    "quantity_in_stock": 50,
    "min_quantity": 10,
    "supplier_id": 1
}
```

### الموردين (Suppliers)

#### GET /api/suppliers/read.php
الحصول على جميع الموردين

#### POST /api/suppliers/create.php
إضافة مورد جديد
```json
{
    "name": "اسم المورد",
    "email": "email@example.com",
    "phone": "+212123456789",
    "address": "عنوان المورد",
    "contact_person": "الشخص المسؤول"
}
```

### المعاملات المالية (Financial Transactions)

#### GET /api/financial_transactions/read.php
الحصول على جميع المعاملات المالية مع الإحصائيات

#### POST /api/financial_transactions/create.php
إضافة معاملة مالية جديدة
```json
{
    "type": "expense",
    "category": "Purchase",
    "amount": 1250.00,
    "description": "شراء فاتورة FA-001",
    "date": "2025-01-27",
    "reference": "INV-001"
}
```

## رموز الاستجابة

- `200` - نجح الطلب
- `201` - تم إنشاء العنصر بنجاح
- `400` - بيانات غير صحيحة
- `404` - العنصر غير موجود
- `503` - خطأ في الخدمة

## أمثلة الاستخدام

### باستخدام cURL

```bash
# الحصول على جميع الفواتير
curl -X GET "http://localhost/api/invoices/read.php"

# إنشاء فاتورة جديدة
curl -X POST "http://localhost/api/invoices/create.php" \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "AMR TECH SOLUTION",
    "invoice_number": "FA-004",
    "total_amount": 1500.00
  }'

# البحث في الفواتير
curl -X GET "http://localhost/api/invoices/search.php?s=AMR"
```

### باستخدام JavaScript/Fetch

```javascript
// الحصول على جميع الفواتير
fetch('http://localhost/api/invoices/read.php')
  .then(response => response.json())
  .then(data => console.log(data));

// إنشاء فاتورة جديدة
fetch('http://localhost/api/invoices/create.php', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    client_name: 'AMR TECH SOLUTION',
    invoice_number: 'FA-004',
    total_amount: 1500.00
  })
})
.then(response => response.json())
.then(data => console.log(data));
```

## الأمان

- تم تفعيل CORS للسماح بالاتصال من Flutter app
- يتم تنظيف جميع البيانات المدخلة لمنع SQL injection
- استخدام Prepared Statements لجميع الاستعلامات

## الدعم

للمساعدة والدعم التقني، يرجى التواصل مع فريق التطوير. 