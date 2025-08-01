<?php
require_once 'config/cors.php';
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMRTS Manager API</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            font-weight: 700;
        }
        
        .header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section h2 {
            color: #1e3a8a;
            font-size: 1.8rem;
            margin-bottom: 20px;
            border-bottom: 3px solid #3b82f6;
            padding-bottom: 10px;
        }
        
        .endpoint {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s ease;
        }
        
        .endpoint:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.1);
        }
        
        .method {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 6px;
            font-weight: bold;
            font-size: 0.9rem;
            margin-right: 10px;
        }
        
        .get { background: #10b981; color: white; }
        .post { background: #3b82f6; color: white; }
        .put { background: #f59e0b; color: white; }
        .delete { background: #ef4444; color: white; }
        
        .url {
            font-family: 'Courier New', monospace;
            background: #1f2937;
            color: #f9fafb;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 0.9rem;
        }
        
        .description {
            margin-top: 10px;
            color: #6b7280;
            line-height: 1.6;
        }
        
        .status {
            margin-top: 20px;
            padding: 20px;
            background: #ecfdf5;
            border: 1px solid #10b981;
            border-radius: 10px;
        }
        
        .status h3 {
            color: #065f46;
            margin-bottom: 10px;
        }
        
        .status ul {
            list-style: none;
            padding: 0;
        }
        
        .status li {
            padding: 5px 0;
            color: #047857;
        }
        
        .footer {
            background: #f8fafc;
            padding: 20px;
            text-align: center;
            color: #6b7280;
            border-top: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 AMRTS Manager API</h1>
            <p>API backend لنظام إدارة المشتريات والمبيعات والمخزون والإنتاج والمعاملات المالية</p>
        </div>
        
        <div class="content">
            <div class="section">
                <h2>📋 الفواتير (Invoices)</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/invoices/read.php</span>
                    <div class="description">الحصول على جميع الفواتير</div>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="url">/api/invoices/create.php</span>
                    <div class="description">إنشاء فاتورة جديدة</div>
                </div>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/invoices/read_one.php?id={id}</span>
                    <div class="description">الحصول على فاتورة واحدة</div>
                </div>
                
                <div class="endpoint">
                    <span class="method put">PUT</span>
                    <span class="url">/api/invoices/update.php</span>
                    <div class="description">تحديث فاتورة</div>
                </div>
                
                <div class="endpoint">
                    <span class="method delete">DELETE</span>
                    <span class="url">/api/invoices/delete.php</span>
                    <div class="description">حذف فاتورة</div>
                </div>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/invoices/search.php?s={keywords}</span>
                    <div class="description">البحث في الفواتير</div>
                </div>
            </div>
            
            <div class="section">
                <h2>📦 عناصر الفواتير (Invoice Items)</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/invoice_items/read.php?invoice_id={id}</span>
                    <div class="description">الحصول على عناصر فاتورة معينة</div>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="url">/api/invoice_items/create.php</span>
                    <div class="description">إضافة عنصر فاتورة جديد</div>
                </div>
            </div>
            
            <div class="section">
                <h2>🏪 المنتجات (Products)</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/products/read.php</span>
                    <div class="description">الحصول على جميع المنتجات مع إحصائيات المخزون</div>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="url">/api/products/create.php</span>
                    <div class="description">إضافة منتج جديد</div>
                </div>
            </div>
            
            <div class="section">
                <h2>👥 الموردين (Suppliers)</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/suppliers/read.php</span>
                    <div class="description">الحصول على جميع الموردين</div>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="url">/api/suppliers/create.php</span>
                    <div class="description">إضافة مورد جديد</div>
                </div>
            </div>
            
            <div class="section">
                <h2>💰 المعاملات المالية (Financial Transactions)</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="url">/api/financial_transactions/read.php</span>
                    <div class="description">الحصول على جميع المعاملات المالية مع الإحصائيات</div>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="url">/api/financial_transactions/create.php</span>
                    <div class="description">إضافة معاملة مالية جديدة</div>
                </div>
            </div>
            
            <div class="status">
                <h3>📊 رموز الاستجابة</h3>
                <ul>
                    <li><strong>200</strong> - نجح الطلب</li>
                    <li><strong>201</strong> - تم إنشاء العنصر بنجاح</li>
                    <li><strong>400</strong> - بيانات غير صحيحة</li>
                    <li><strong>404</strong> - العنصر غير موجود</li>
                    <li><strong>503</strong> - خطأ في الخدمة</li>
                </ul>
            </div>
        </div>
        
        <div class="footer">
            <p>© 2025 AMRTS Manager API - جميع الحقوق محفوظة</p>
            <p>للمساعدة والدعم التقني، يرجى التواصل مع فريق التطوير</p>
        </div>
    </div>
</body>
</html> 