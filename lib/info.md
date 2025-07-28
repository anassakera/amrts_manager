بالتأكيد، لقد فهمت طلبك بتحويل الإجابة السابقة إلى ملف PDF دون أي تعديل أو نقصان.

بصفتي نموذجًا لغويًا، ليس لدي القدرة على إنشاء وتصدير ملفات مثل PDF مباشرة. ولكن، يمكنني أن أقدم لك النص الكامل والمنسق للإجابة السابقة، بحيث يمكنك نسخه بسهولة وحفظه كملف PDF بنفسك.

**الطريقة:**
1.  **انسخ** كل النص الموجود في الأسفل (بدءًا من "مخطط ترقية النظام").
2.  **الصقه** في محرر مستندات مثل Microsoft Word أو Google Docs.
3.  من المحرر، اختر **ملف > حفظ باسم (File > Save As)** ثم اختر صيغة PDF، أو اختر **ملف > طباعة (File > Print)** ثم حدد "الطباعة إلى PDF" (Print to PDF).

إليك النص الكامل وغير المعدّل:

---

### **مخطط ترقية النظام: من البنية الحالية إلى بنية محصنة وقابلة للتوسع**

سأقوم بتفكيك كل قسم من أسئلتك، وتقديم حل هندسي متكامل لكل منها.

---

## ✅ **القسم الأول: أمان بنية ملفات PHP API وهيكلتها**

### 1️⃣ **الإشعال (Ignition): نقطة الفشل الشائعة**

الخطأ الكارثي الأكثر شيوعًا: وضع ملف `database.php` المحتوي على كلمات المرور داخل مجلد `public_html`، ثم رفع المشروع على Git بالخطأ. في غضون دقائق، تقوم البوتات بمسح GitHub بحثًا عن هذه الملفات، ويتم اختراق قاعدة بياناتك بالكامل. `.htaccess` وحده لا يكفي لمنع كل أنواع هجمات استعراض المسارات (Path Traversal).

### 2️⃣ **التفكيك والبلورة (Deconstruction & Crystallization)**

- **الخطأ المفاهيمي:** الاعتقاد بأن "إخفاء" الملفات بقواعد `.htaccess` كافٍ. الأمان الحقيقي يأتي من "العزل" الهيكلي.
- **التشبيه التقني:** مطعم.
  - `public_html`: هي صالة الطعام. العملاء (تطبيق Flutter) يدخلون من هنا فقط.
  - **خارج `public_html`**: هو المطبخ. هنا توجد الوصفات السرية (ملفات `config`)، والمنطق الحساس (ملفات `Base` أو `Core`)، والطهاة (منطق الأكواد). لا يُسمح لأي عميل بالدخول إلى المطبخ أبدًا.
  - `public_html/index.php`: هو النادل (Front Controller). هو الوحيد الذي يتلقى الطلبات من صالة الطعام، ويدخل المطبخ ليحضرها، ثم يعود بها للعميل.

### 3️⃣ **الهندسة (Engineering): إعادة هيكلة المشروع**

هذا هو المخطط الجديد الذي يجيب على جميع أسئلتك (1-5 و 7-8) ويوفر أمانًا حقيقيًا بدون إطار عمل.

**الهيكلة الجديدة للملفات على VPS:**

```
/home/your_user/
├── src/                  # "المطبخ": هذا المجلد خارج الوصول العام
│   ├── config/
│   │   └── database.php      # (CHMOD 600) آمن تمامًا هنا
│   ├── core/
│   │   ├── BaseController.php # منطق مشترك للاستجابات (JSON, Headers)
│   │   ├── AuthMiddleware.php # منطق التحقق من التوكن
│   │   └── ...
│   ├── endpoints/
│   │   ├── invoices/
│   │   │   ├── CreateInvoice.php
│   │   │   └── GetInvoice.php
│   │   └── auth/
│   │       ├── Login.php
│   │       └── Register.php
│
└── public_html/          # "صالة الطعام": يمكن الوصول إليها عبر الويب
    ├── uploads/              # مجلد الصور المرفوعة
    ├── .htaccess             # ملف التوجيه والحماية
    └── index.php             # نقطة الدخول الوحيدة (Front Controller)
```

**1. كود `public_html/index.php` (النادل / The Front Controller):**

```php
<?php
// تفعيل عرض الأخطاء أثناء التطوير فقط
ini_set('display_errors', 0); // في الإنتاج يجب أن يكون 0
error_reporting(E_ALL);

// تحديد المسار الأساسي للمشروع خارج الويب
define('ROOT_PATH', dirname(__DIR__));

// تضمين الإعدادات الأساسية
require_once ROOT_PATH . '/src/config/database.php';
require_once ROOT_PATH . '/src/core/BaseController.php';

// تحليل الطلب (بشكل مبسط)
$request_uri = $_SERVER['REQUEST_URI'];
$endpoint = trim(parse_url($request_uri, PHP_URL_PATH), '/');

// مثال بسيط لنظام التوجيه (Routing)
$routes = [
    'api/invoices/create' => ROOT_PATH . '/src/endpoints/invoices/CreateInvoice.php',
    'api/auth/login'      => ROOT_PATH . '/src/endpoints/auth/Login.php',
];

if (array_key_exists($endpoint, $routes)) {
    require_once $routes[$endpoint];
} else {
    // إرسال استجابة "غير موجود"
    http_response_code(404);
    echo json_encode(['error' => 'Endpoint Not Found']);
    exit;
}
```

**2. كود `.htaccess` المحسّن في `public_html`:**

```apache
# تعطيل عرض محتوى المجلدات تمامًا
Options -Indexes

<IfModule mod_rewrite.c>
    RewriteEngine On

    # توجيه كل الطلبات إلى index.php
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php [QSA,L]
</IfModule>

# حماية ملف htaccess نفسه
<Files .htaccess>
    Require all denied
</Files>
```

**3. صلاحيات الملفات والمجلدات (`chmod`):**

- **`src/config/database.php`**: `600` (فقط المالك يمكنه القراءة والكتابة).
- **باقي ملفات `.php`**: `644` (المالك يقرأ ويكتب، الآخرون يقرأون فقط).
- **المجلدات (مثل `src`, `config`)**: `755` (المالك يفعل كل شيء، الآخرون يقرأون وينفذون).

بهذه البنية، أنت لا تحتاج إلى `index.php` فارغ في كل مجلد، لأن الوصول إلى المجلدات الفرعية خارج `public_html` مستحيل من الأساس عبر الويب.

---

## 🔐 **القسم الثاني: التحقق والصلاحيات (Authentication & Access Security)**

### 1️⃣ **الإشعال (Ignition): نقطة الفشل الشائعة**

لقد قمت ببناء نظام تسجيل دخول، وهو يعمل. لكنك تكتشف أن أي شخص ينجح في استخراج رابط API من تطبيق Flutter (وهو أمر سهل) يمكنه استدعاء نقاط النهاية (Endpoints) الحساسة مباشرة، مثل `delete_invoice.php?id=123`. نظامك لا يميز بين مستخدم قام بتسجيل الدخول وبين طلب عشوائي من الإنترنت.

### 2️⃣ **التفكيك والبلورة (Deconstruction & Crystallization)**

- **الخطأ المفاهيمي:** الخلط بين **المصادقة (Authentication)** - "من أنت؟" و **التفويض (Authorization)** - "ماذا يُسمح لك أن تفعل؟". نظامك الحالي يقوم بالمصادقة مرة واحدة عند تسجيل الدخول، ثم ينسى كل شيء.
- **التشبيه التقني:** بطاقة هوية لدخول مبنى آمن.
  - **نظامك الحالي (Email/Password):** مثل حارس أمن يسألك عن اسمك عند البوابة الرئيسية مرة واحدة ثم يتركك تتجول في كل الغرف، بما فيها غرفة الخوادم.
  - **الحل المقترح (JWT - JSON Web Tokens):** عند البوابة الرئيسية، وبعد التحقق من هويتك، يعطيك الحارس **بطاقة إلكترونية (Token)**. هذه البطاقة يجب أن تُظهرها عند باب كل غرفة تدخلها. بعض البطاقات تفتح الأبواب العادية (صلاحيات المستخدم العادي)، وبعضها يفتح غرفة الخوادم (صلاحيات المدير). إذا سُرقت البطاقة، تنتهي صلاحيتها بعد 15 دقيقة تلقائيًا.

### 3️⃣ **الهندسة (Engineering): تطبيق نظام JWT**

هذا المخطط يجيب على أسئلتك (1-5).

**الخطوات التنفيذية:**

1.  **تثبيت مكتبة JWT لـ PHP (موصى به بشدة لتجنب الأخطاء الأمنية):**
    عبر `composer` (أداة إدارة الحزم في PHP، ضرورية للمشاريع الحديثة):
    ```bash
    composer require firebase/php-jwt
    ```

2.  **تعديل `src/endpoints/auth/Login.php`:**
    عندما يكون تسجيل الدخول ناجحًا، قم بإنشاء توكن بدلاً من إرجاع رسالة نجاح فقط.

    ```php
    // ... بعد التحقق من كلمة المرور
    if (password_verify($password, $user['password_hash'])) {
        $secret_key = 'YOUR_SUPER_SECRET_KEY_FROM_A_CONFIG_FILE'; // لا تكتبها هنا مباشرة
        $issuer_claim = "YOUR_APP_DOMAIN";
        $audience_claim = "YOUR_APP_DOMAIN";
        $issuedat_claim = time();
        $notbefore_claim = $issuedat_claim;
        $expire_claim = $issuedat_claim + 3600; // صلاحية لمدة ساعة

        $token_payload = array(
            "iss" => $issuer_claim,
            "aud" => $audience_claim,
            "iat" => $issuedat_claim,
            "nbf" => $notbefore_claim,
            "exp" => $expire_claim,
            "data" => array( // بيانات المستخدم التي تحتاجها
                "id" => $user['id'],
                "email" => $user['email'],
                "role" => $user['role'] // مهم جدًا للصلاحيات
            )
        );

        $jwt = JWT::encode($token_payload, $secret_key, 'HS256');

        // أرجع التوكن إلى تطبيق Flutter
        echo json_encode(array("token" => $jwt));
    }
    ```

3.  **في تطبيق Flutter:**
    - بعد تسجيل الدخول، قم بتخزين التوكن المستلم بشكل آمن باستخدام `flutter_secure_storage`. **لا تستخدم `SharedPreferences` أبدًا للتوكن**.
    - في `ApiService.dart`، أضف التوكن إلى **رأس الطلب (Header)** في كل استدعاء API.

    ```dart
    // في ApiService.dart
    Future<Response> getInvoices() async {
      String? token = await _secureStorage.read(key: 'jwt_token');

      return await http.get(
        Uri.parse('$baseUrl/invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token' // هنا الأمان
        },
      );
    }
    ```

4.  **إنشاء `src/core/AuthMiddleware.php` (حارس الأمن):**
    هذا الملف سيكون مسؤولاً عن حماية كل نقطة نهاية (Endpoint).

    ```php
    function protect_endpoint($allowed_roles = []) {
        // ... (كود للتحقق من وجود هيدر 'Authorization')
        // ... (كود لفصل 'Bearer' عن التوكن)
        try {
            $decoded_token = JWT::decode($jwt, $secret_key, ['HS256']);
            // التحقق من صلاحيات المستخدم (Role) إذا لزم الأمر
            if (!empty($allowed_roles) && !in_array($decoded_token->data->role, $allowed_roles)) {
                 http_response_code(403); // Forbidden
                 echo json_encode(["error" => "Access denied."]);
                 exit;
            }
            return $decoded_token->data; // إرجاع بيانات المستخدم للاستفادة منها
        } catch (Exception $e) {
            http_response_code(401); // Unauthorized
            echo json_encode(["error" => "Invalid token.", "message" => $e->getMessage()]);
            exit;
        }
    }
    ```

5.  **استخدام الحارس في نقاط النهاية:**
    في بداية أي ملف API حساس مثل `CreateInvoice.php`:

    ```php
    <?php
    require_once __DIR__ . '/../../core/AuthMiddleware.php';
    
    // حماية هذه النقطة، السماح للمدراء والمستخدمين بالوصول
    $userData = protect_endpoint(['admin', 'user']); 
    
    // الآن يمكنك استخدام $userData->id لإضافة فاتورة للمستخدم الصحيح
    // ... منطق إنشاء الفاتورة ...
    ```

هذا النظام يحل مشكلة تسريب `baseUrl` ومشكلة الصلاحيات. حتى لو عرف أحدهم الرابط، بدون توكن صالح، لن يتمكن من فعل أي شيء.

---

## 🧨 **القسم الثالث: الحماية من الهجمات الشائعة**

### 1️⃣ **الإشعال (Ignition): نقطة الفشل الشائعة**

أنت تستخدم **الاستعلامات المُعدة (Prepared Statements)** وتظن أنك محصن تمامًا ضد **حقن SQL (SQL Injection)**. لكن في أحد التقارير، قمت ببناء جزء من الاستعلام ديناميكيًا بناءً على طلب المستخدم، مثل: `ORDER BY $_GET['column']`. المهاجم يمرر قيمة خبيثة في `column` وينجح في حقن التعليمات.

### 2️⃣ **التفكيك والبلورة (Deconstruction & Crystallization)**

- **الخطأ المفاهيمي:** الاعتقاد بأن أداة واحدة (مثل Prepared Statements) تحمي من فئة كاملة من الهجمات. الأمن طبقات متعددة (Defense in Depth).
- **التشبيه التقني:** بناء قلعة.
  - **Prepared Statements:** هي الجدران الحجرية السميكة (تحمي من حقن البيانات).
  - **التحقق من صحة المدخلات (Input Validation):** هم الحراس على البوابة الذين يتأكدون من أن من يدخل هو شخص وليس عربة حصان طروادة (يحمي من XSS وحقن الأعمدة الديناميكية).
  - **سياسات رفع الملفات:** هو تفتيش أي بضائع تدخل القلعة للتأكد من عدم وجود أسلحة مخبأة (حماية من Shells المخبأة في الصور).
  - **CSRF Tokens / Authorization Header:** هو كلمة السر السرية التي لا يعرفها إلا الجنود المخلصون (حماية من الطلبات المزيفة).

### 3️⃣ **الهندسة (Engineering): طبقات الدفاع**

إجابات مباشرة وقابلة للتنفيذ لأسئلتك (1-8).

1.  **XSS مع JSON (سؤال 1):** نعم، الخطر قائم. تخيل أن مستخدمًا أدخل `<script>alert('XSS')</script>` كاسمه. أنت تخزنه في قاعدة البيانات. لاحقًا، قد تقوم ببناء لوحة تحكم ويب (ليست Flutter) تعرض هذا الاسم، وعندها سيتم تنفيذ السكريبت.
    - **الحل:** عند استقبال أي بيانات نصية، قم بتمريرها عبر `htmlspecialchars()` قبل تخزينها في قاعدة البيانات.
      ```php
      $username = htmlspecialchars($_POST['username'], ENT_QUOTES, 'UTF-8');
      ```

2.  **SQL Injection مع Prepared Statements (سؤال 2):** نعم، ممكن إذا كانت أجزاء من **هيكل الاستعلام (Query Structure)** ديناميكية، وليس فقط **البيانات (Data)**.
    - **الحل:** لا تستخدم أبدًا متغيرات من المستخدم مباشرة في أسماء الجداول أو الأعمدة. قم بإنشاء قائمة بيضاء (Whitelist) بالقيم المسموح بها.
      ```php
      // خطير جدًا
      // $orderBy = $_GET['sort_by'];
      // $sql = "SELECT * FROM users ORDER BY $orderBy";

      // آمن
      $allowed_columns = ['name', 'created_at', 'email'];
      $orderBy = $_GET['sort_by'] ?? 'name';
      if (!in_array($orderBy, $allowed_columns)) {
          die("Invalid sort column.");
      }
      $sql = "SELECT * FROM users ORDER BY $orderBy"; // الآن آمن
      ```

3.  **CSRF في REST API (سؤال 3):** استخدام هيدر `Authorization: Bearer <token>` هو دفاع ممتاز ضد CSRF. المتصفحات لا ترسل هذا الهيدر المخصص تلقائيًا مع الطلبات عبر المواقع (Cross-Site Requests)، على عكس الكوكيز. أنت آمن إلى حد كبير من هذا الهجوم طالما أنك تعتمد على هذا الهيدر للتحقق.

4.  **أمان رفع الملفات (سؤال 4-6):**
    - **الحل الهندسي المتكامل:**
      أ. **لا تثق باسم الملف أو نوع MIME الذي يرسله العميل أبدًا.**
      ب. **أعد تسمية الملف** إلى اسم عشوائي فريد (مثل `hash('sha256', time() . $original_name)`).
      ج. **تحقق من نوع الملف الحقيقي** على الخادم باستخدام `finfo_open`.
      د. **خزّن الملفات خارج `public_html`** إذا أمكن، أو في مجلد محصّن.
      هـ. **في مجلد `uploads` (إذا كان داخل `public_html`)، ضع ملف `.htaccess` مخصصًا:**
      ```apache
      # منع تنفيذ أي نوع من السكريبتات
      <FilesMatch "\.(php|phtml|php3|php4|php5|pl|py|jsp|asp|html|htm|shtml|sh|cgi)$">
          Require all denied
      </FilesMatch>

      # طريقة أقوى: أجبر المتصفح على تحميل الملفات بدلاً من عرضها
      ForceType application/octet-stream
      <FilesMatch "\.(jpg|jpeg|png|gif)$">
          ForceType none
      </FilesMatch>
      ```
    هذا يمنع تنفيذ صورة تحتوي على كود PHP.

5.  **حماية المجلدات (سؤال 7-8):** تم حلها بالكامل في القسم الأول عبر **بنية المطبخ/صالة الطعام** واستخدام `Options -Indexes` في ملف `.htaccess` الجذري. لا حاجة لملفات `index.php` متفرقة.

---

## 🔄 **القسم الرابع: أمان المزامنة بين SQL Server و MySQL**

### 1️⃣ **الإشعال (Ignition): نقطة الفشل الشائعة**

قمت بإعداد وصلة ODBC وفتحت منفذ قاعدة بيانات MySQL على الإنترنت للسماح بالاتصال من SQL Server المحلي. كل شيء يعمل، لكنك لم تدرك أن هذا المنفذ المفتوح الآن هدف لكل هجمات القوة الغاشمة (Brute-force attacks) على الإنترنت. بيانات اتصالك المخزنة في نص عادي على جهازك المحلي هي قنبلة موقوتة.

### 2️⃣ **التفكيك والبلورة (Deconstruction & Crystallization)**

- **الخطأ المفاهيمي:** التعامل مع اتصال عبر الإنترنت بنفس بساطة الاتصال المحلي. الاتصال عبر الإنترنت غير موثوق به وغير آمن افتراضيًا.
- **التشبيه التقني:** نقل أموال بين فرعين لبنك، أحدهما في مدينتك (المحلي) والآخر في مدينة بعيدة (الاستضافة).
  - **الطريقة الخطأ (ODBC المباشر):** وضع الأموال في سيارة عادية وإرسالها على الطريق السريع العام، مع إعطاء سائق السيارة مفتاح خزنة البنك الآخر.
  - **الطريقة الصحيحة (API كوسيط):** فرع البنك المحلي يتصل بفرع البنك البعيد عبر خط هاتف مشفر (HTTPS)، ويطلب منه "استعد لاستلام حوالة". ثم يقوم بإرسال البيانات عبر عربة مصفحة (طلب POST إلى API)، ويستخدم كلمة سر لمرة واحدة (API Key/Token) لتأكيد العملية. البنك البعيد هو من يضع الأموال في خزنته بنفسه. **المفتاح الخاص بالخزنة البعيدة لم يغادر موقعه أبدًا.**

### 3️⃣ **الهندسة (Engineering): نظام مزامنة آمن عبر API وسيط**

هذا المخطط يجيب على جميع أسئلتك (1-7).

**المبدأ: لا تقم بتوصيل قواعد البيانات مباشرة عبر الإنترنت أبدًا.**

1.  **أنشئ نقطة نهاية API خاصة بالمزامنة على خادمك (VPS):**
    - أنشئ ملفًا مثل `src/endpoints/sync/ReceiveStats.php`.
    - **حماية هذا الـ API:** يجب أن يكون محميًا بمفتاح API سري جداً (API Key) يتم إرساله في الهيدر. هذا المفتاح لا علاقة له بـ JWT الخاص بالمستخدمين.

    ```php
    // في ReceiveStats.php
    $expected_api_key = 'A_VERY_LONG_AND_RANDOM_SECRET_KEY';
    $submitted_key = $_SERVER['HTTP_X_API_KEY'] ?? '';

    if ($submitted_key !== $expected_api_key) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid API Key']);
        exit;
    }

    // استقبل بيانات JSON
    $json_data = file_get_contents('php://input');
    $stats = json_decode($json_data, true);

    // قم بمعالجة البيانات وتخزينها في MySQL
    // ...
    ```

2.  **على الخادم المحلي (الذي يشغل SQL Server):**
    - بدلاً من استخدام ODBC للاتصال المباشر، قم بإنشاء **سكريبت PowerShell أو Python** بسيط.
    - هذا السكريبت سيتم تشغيله بواسطة **SQL Server Agent** أو **Windows Task Scheduler**.

3.  **مهمة السكريبت المحلي:**
    أ. **الاتصال بـ SQL Server المحلي** واستخراج البيانات التي تريد مزامنتها (باستخدام `sqlcmd` أو مكتبات اتصال خاصة باللغة).
    ب. **تنسيق البيانات** على هيئة JSON.
    ج. **إرسال طلب POST** إلى الـ API الذي أنشأته في الخطوة 1 (`https://yourdomain.com/api/sync/receive-stats`).
    د. **تضمين مفتاح API السري** في رأس الطلب `X-API-KEY`.
    هـ. **تسجيل نتيجة العملية** (نجاح، فشل، عدد السجلات) في ملف log محلي أو في جدول خاص في SQL Server.

**لماذا هذا التصميم هو الأفضل؟**

- **عكس اتجاه الاتصال (سؤال 4):** النظام المحلي (الموثوق) هو من يبدأ الاتصال إلى النظام العام (غير الموثوق). هذا يعني أنك لست بحاجة لفتح أي منافذ واردة (Inbound Ports) على شبكتك المحلية.
- **لا توجد بيانات اعتماد مكشوفة (سؤال 5):** بيانات اعتماد MySQL تبقى بأمان على خادم VPS فقط. بيانات اعتماد SQL Server تبقى بأمان على الخادم المحلي فقط. مفتاح API هو السر الوحيد المشترك.
- **النقل مشفر (سؤال 3):** لأن الاتصال يتم عبر HTTPS، فإن البيانات مشفرة تلقائيًا أثناء النقل.
- **مزامنة التغييرات فقط (سؤال 7):** في السكريبت المحلي، قم بتعديل استعلام SQL ليختار فقط السجلات التي تم تعديلها منذ آخر مزامنة ناجحة. يمكنك تخزين `last_sync_timestamp` في جدول محلي.
  ```sql
  -- مثال لاستعلام SQL
  SELECT * FROM Invoices WHERE last_updated > @LastSyncTimestamp;
  ```

---

## 🧱 **القسم الخامس: العزل بين البيئات (Local vs Public)**

### 1️⃣ **الإشعال (Ignition): نقطة الفشل الشائعة**

أنت تعمل على ميزة جديدة في تطبيق Flutter على جهازك. نسيت تغيير `baseUrl` في `ApiService.dart` من الرابط العام إلى الرابط المحلي. قمت بإجراء اختباراتك، وأضفت وحذفت بيانات "وهمية"، لتكتشف لاحقًا أنك كنت تعدل وتحذف بيانات حقيقية من قاعدة بيانات الإنتاج.

### 2️⃣ **التفكيك والبلورة (Deconstruction & Crystallization)**

- **الخطأ المفاهيمي:** استخدام تكوين (Configuration) واحد لكل البيئات.
- **التشبيه التقني:** قمرة قيادة طائرة. هناك مفتاح "وضع المحاكاة" (Simulation Mode) ومفتاح "وضع الطيران الفعلي" (Flight Mode). لا يمكن أبدًا أن تختلط الأوامر بينهما. إذا كنت في وضع المحاكاة، يمكنك أن تفعل ما تشاء ولن تتحرك الطائرة الحقيقية. تغيير الوضع يتطلب إجراءً واعيًا.

### 3️⃣ **الهندسة (Engineering): الفصل التام باستخدام متغيرات البيئة (Environment Variables)**

هذا هو المعيار الصناعي لحل هذه المشكلة (يجيب على أسئلتك 1-4).

1.  **في تطبيق Flutter (لحل مشكلة `baseUrl`):**
    - لا تقم بكتابة `baseUrl` بشكل ثابت في الكود.
    - استخدم **`--dart-define`** لتمرير المتغيرات عند تشغيل التطبيق.
    - أنشئ ملفي إعدادات لتسهيل الأمر في `launch.json` (إذا كنت تستخدم VS Code):

      ```json
      // .vscode/launch.json
      "configurations": [
          {
              "name": "Run Dev",
              "request": "launch",
              "type": "dart",
              "program": "lib/main.dart",
              "args": [
                  "--dart-define=BASE_URL=http://localhost/my_project/public_html"
              ]
          },
          {
              "name": "Run Prod",
              "request": "launch",
              "type": "dart",
              "program": "lib/main.dart",
              "args": [
                  "--dart-define=BASE_URL=https://api.yourdomain.com"
              ]
          }
      ]
      ```
    - في كود Dart، اقرأ المتغير:
      ```dart
      const baseUrl = String.fromEnvironment('BASE_URL');
      ```
    - الآن، عندما تختار "Run Dev"، سيتصل التطبيق تلقائيًا بالخادم المحلي (XAMPP). وعندما تبني نسخة الإنتاج، استخدم define الخاص بالإنتاج.

2.  **على خادم PHP:**
    - لا تكتب إعدادات قاعدة البيانات مباشرة في `database.php`.
    - استخدم متغيرات البيئة الخاصة بالخادم. في CPanel، ابحث عن أداة تسمى "Setup Node.js App" أو ما شابه، والتي تسمح لك غالبًا بتعيين متغيرات البيئة (Environment Variables).
    - إذا لم تجد، يمكنك استخدام ملف `.env` مع مكتبة مثل `vlucas/phpdotenv`.
      - أنشئ ملف `.env` **خارج `public_html`**:
        ```
        DB_HOST=localhost
        DB_NAME=prod_db
        DB_USER=prod_user
        DB_PASS='super_secret_password'
        ```
      - في `database.php`، اقرأ هذه المتغيرات.
    - هذا يعزل تمامًا إعدادات الإنتاج عن الكود.

3.  **مزامنة مستخدم جديد عند انقطاع الإنترنت (سؤال 4):**
    - هذا يتطلب نمط **"صندوق الصادر" (Outbox Pattern)**.
    - عندما يتم إنشاء مستخدم جديد محليًا (أثناء انقطاع الاتصال بالإنترنت العام)، لا تحاول مزامنته فورًا.
    - بدلاً من ذلك، أضف سجلاً في جدول محلي اسمه `SyncQueue` (طابور المزامنة).
    - قم بإنشاء مهمة مجدولة (Scheduled Task) تعمل كل 5 دقائق للتحقق من جدول `SyncQueue`.
    - إذا وجدت سجلات، تحاول إرسالها إلى الـ API العام. إذا نجحت، تحذف السجل من الطابور.
    - هذا يضمن عدم فقدان أي بيانات تم إنشاؤها محليًا.