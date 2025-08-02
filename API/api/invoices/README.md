# API الفواتير - Invoices API

## نظرة عامة
هذا API يوفر خدمات كاملة لإدارة الفواتير في نظام AMR TECH SOLUTION.

## الجداول المستخدمة
1. **invoices** - جدول الفواتير الرئيسي
2. **invoice_items** - جدول عناصر الفاتورة
3. **invoice_summary** - جدول ملخص الفاتورة

## نقاط النهاية (Endpoints)

### 1. جلب جميع الفواتير
```
GET /api/invoices/get_all.php
```
**الاستجابة:**
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "clientName": "AMR TECH SOLUTION",
      "invoiceNumber": "FA-001",
      "date": "27/7/2025 | 11:45",
      "isLocal": true,
      "totalAmount": 0.0,
      "status": "Terminée",
      "items": [...],
      "summary": {...}
    }
  ]
}
```

### 2. جلب فاتورة واحدة
```
GET /api/invoices/get_by_id.php?id={invoice_id}
```

### 3. إنشاء فاتورة جديدة
```
POST /api/invoices/create.php
Content-Type: application/json

{
  "id": "unique_id",
  "clientName": "اسم العميل",
  "invoiceNumber": "رقم الفاتورة",
  "date": "التاريخ",
  "isLocal": true,
  "totalAmount": 0.0,
  "status": "الحالة",
  "items": [...],
  "summary": {...}
}
```

### 4. تحديث فاتورة
```
PUT /api/invoices/update.php
Content-Type: application/json

{
  "id": "invoice_id",
  "clientName": "اسم العميل المحدث",
  ...
}
```

### 5. حذف فاتورة
```
DELETE /api/invoices/delete.php?id={invoice_id}
```

### 6. البحث في الفواتير
```
GET /api/invoices/search.php?q={search_query}
```

### 7. تحديث حالة الفاتورة
```
PUT /api/invoices/update_status.php
Content-Type: application/json

{
  "id": "invoice_id",
  "status": "الحالة الجديدة"
}
```

### 8. تحديث نوع الفاتورة
```
PUT /api/invoices/update_type.php
Content-Type: application/json

{
  "id": "invoice_id",
  "isLocal": true/false
}
```

## هيكل البيانات

### الفاتورة الرئيسية
```json
{
  "id": "string",
  "clientName": "string",
  "invoiceNumber": "string",
  "date": "string",
  "isLocal": "boolean",
  "totalAmount": "number",
  "status": "string"
}
```

### عناصر الفاتورة
```json
{
  "refFournisseur": "string",
  "articles": "string",
  "qte": "number",
  "poids": "number",
  "puPieces": "number",
  "exchangeRate": "number",
  "mt": "number",
  "prixAchat": "number",
  "autresCharges": "number",
  "cuHt": "number"
}
```

### ملخص الفاتورة
```json
{
  "factureNumber": "string",
  "transit": "number",
  "droitDouane": "number",
  "chequeChange": "number",
  "freiht": "number",
  "autres": "number",
  "total": "number",
  "txChange": "number",
  "poidsTotal": "number"
}
```

## رموز الحالة
- `200` - نجح الطلب
- `400` - خطأ في البيانات المرسلة
- `404` - الفاتورة غير موجودة
- `405` - طريقة الطلب غير مسموحة
- `500` - خطأ في الخادم

## ملاحظات مهمة
1. جميع الطلبات تدعم CORS
2. البيانات تُرجع بتنسيق JSON
3. جميع العمليات محمية ضد SQL Injection
4. يتم استخدام المعاملات (Transactions) لضمان سلامة البيانات 