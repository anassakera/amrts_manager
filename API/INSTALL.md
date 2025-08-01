# دليل التثبيت - AMRTS Manager API

## المتطلبات الأساسية

### البرامج المطلوبة
- **PHP** 7.4 أو أحدث
- **MySQL** 5.7 أو أحدث (أو MariaDB 10.2+)
- **Apache** أو **Nginx** web server
- **Composer** (اختياري، لإدارة التبعيات)

### إضافات PHP المطلوبة
- PDO
- PDO MySQL
- JSON
- cURL
- OpenSSL

## خطوات التثبيت

### 1. تحضير البيئة

#### على Windows (XAMPP/WAMP)
1. قم بتثبيت XAMPP أو WAMP
2. تأكد من تفعيل إضافات PHP المطلوبة
3. انسخ مجلد API إلى مجلد `htdocs` (XAMPP) أو `www` (WAMP)

#### على Linux (Ubuntu/Debian)
```bash
# تثبيت Apache و PHP و MySQL
sudo apt update
sudo apt install apache2 php mysql-server php-mysql php-curl php-json

# تفعيل mod_rewrite
sudo a2enmod rewrite
sudo systemctl restart apache2

# نسخ الملفات
sudo cp -r API /var/www/html/
sudo chown -R www-data:www-data /var/www/html/API
```

#### على macOS
```bash
# تثبيت Homebrew (إذا لم يكن مثبتاً)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# تثبيت PHP و MySQL
brew install php mysql

# تشغيل الخدمات
brew services start mysql
brew services start php
```

### 2. إعداد قاعدة البيانات

#### إنشاء قاعدة البيانات
```bash
# الدخول إلى MySQL
mysql -u root -p

# إنشاء قاعدة البيانات
CREATE DATABASE amrts_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# إنشاء مستخدم جديد (اختياري)
CREATE USER 'amrts_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON amrts_manager.* TO 'amrts_user'@'localhost';
FLUSH PRIVILEGES;

# الخروج من MySQL
EXIT;
```

#### استيراد هيكل قاعدة البيانات
```bash
# استيراد ملف قاعدة البيانات
mysql -u root -p amrts_manager < database/schema.sql
```

### 3. تكوين API

#### تعديل إعدادات قاعدة البيانات
```php
// ملف config/database.php
private $host = "localhost";
private $db_name = "amrts_manager";
private $username = "root"; // أو amrts_user إذا أنشأت مستخدم جديد
private $password = ""; // أو your_password
```

#### إعداد ملف .env (اختياري)
```bash
# نسخ ملف النموذج
cp env.example .env

# تعديل المتغيرات حسب إعداداتك
nano .env
```

### 4. اختبار التثبيت

#### اختبار الاتصال بقاعدة البيانات
```bash
# تشغيل ملف الاختبار
php test_api.php
```

#### اختبار API endpoints
```bash
# اختبار قراءة الفواتير
curl -X GET "http://localhost/API/api/invoices/read.php"

# اختبار إنشاء فاتورة جديدة
curl -X POST "http://localhost/API/api/invoices/create.php" \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Test Client",
    "invoice_number": "TEST-001",
    "total_amount": 1000.00
  }'
```

## إعدادات الأمان

### 1. حماية ملفات الإعدادات
```apache
# في ملف .htaccess
<Files "database.php">
    Order Deny,Allow
    Deny from all
</Files>
```

### 2. تفعيل HTTPS (للإنتاج)
```apache
# إعادة توجيه HTTP إلى HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

### 3. إعداد CORS (للإنتاج)
```php
// في ملف config/cors.php
header("Access-Control-Allow-Origin: https://yourdomain.com");
```

## استكشاف الأخطاء

### مشاكل شائعة وحلولها

#### 1. خطأ في الاتصال بقاعدة البيانات
```
Connection error: SQLSTATE[HY000] [1045] Access denied for user
```
**الحل:** تأكد من صحة اسم المستخدم وكلمة المرور في `config/database.php`

#### 2. خطأ 404 عند الوصول للAPI
```
404 Not Found
```
**الحل:** تأكد من:
- وجود ملف `.htaccess` في مجلد API
- تفعيل mod_rewrite في Apache
- صحة مسار الملفات

#### 3. خطأ في CORS
```
Access to fetch at 'http://localhost/API/...' from origin '...' has been blocked by CORS policy
```
**الحل:** تأكد من تضمين ملف `config/cors.php` في جميع endpoints

#### 4. خطأ في ترميز النصوص العربية
```
????? ???????
```
**الحل:** تأكد من:
- تعيين ترميز UTF-8 في قاعدة البيانات
- إضافة `header("Content-Type: application/json; charset=UTF-8");`

## الترقية

### ترقية قاعدة البيانات
```bash
# نسخ احتياطي للبيانات الحالية
mysqldump -u root -p amrts_manager > backup_$(date +%Y%m%d_%H%M%S).sql

# تطبيق التحديثات الجديدة
mysql -u root -p amrts_manager < database/updates.sql
```

### ترقية الكود
```bash
# نسخ احتياطي للملفات
cp -r API API_backup_$(date +%Y%m%d_%H%M%S)

# استبدال الملفات الجديدة
# (احتفظ بملفات الإعدادات المخصصة)
```

## الدعم

للمساعدة والدعم التقني:
- 📧 البريد الإلكتروني: info@amrtech.com
- 📱 الهاتف: +212123456789
- 🌐 الموقع: https://amrtech.com

## الترخيص

هذا المشروع مرخص تحت رخصة MIT. راجع ملف LICENSE للتفاصيل. 