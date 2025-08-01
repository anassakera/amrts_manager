<?php
/**
 * ملف اختبار بسيط للAPI
 * يمكن تشغيله من المتصفح أو من سطر الأوامر
 */

// إعدادات الاختبار
$base_url = 'http://localhost/API'; // عدّل هذا حسب إعداداتك
$test_results = [];

// دالة لاختبار API endpoint
function testEndpoint($method, $url, $data = null, $expected_status = 200) {
    global $base_url, $test_results;
    
    $full_url = $base_url . $url;
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, $full_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json'
            ]);
        }
    } elseif ($method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json'
            ]);
        }
    } elseif ($method === 'DELETE') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json'
            ]);
        }
    }
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    $result = [
        'method' => $method,
        'url' => $url,
        'expected_status' => $expected_status,
        'actual_status' => $http_code,
        'success' => $http_code == $expected_status,
        'response' => $response,
        'error' => $error
    ];
    
    $test_results[] = $result;
    
    return $result;
}

// بدء الاختبارات
echo "<h1>🧪 اختبار AMRTS Manager API</h1>\n";
echo "<p>وقت الاختبار: " . date('Y-m-d H:i:s') . "</p>\n";

// اختبار 1: قراءة الفواتير
echo "<h2>1. اختبار قراءة الفواتير</h2>\n";
$result = testEndpoint('GET', '/api/invoices/read.php');
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 2: إنشاء فاتورة جديدة
echo "<h2>2. اختبار إنشاء فاتورة جديدة</h2>\n";
$invoice_data = [
    'client_name' => 'Test Client',
    'invoice_number' => 'TEST-' . time(),
    'total_amount' => 1000.00,
    'status' => 'Pending'
];
$result = testEndpoint('POST', '/api/invoices/create.php', $invoice_data, 201);
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 3: قراءة الموردين
echo "<h2>3. اختبار قراءة الموردين</h2>\n";
$result = testEndpoint('GET', '/api/suppliers/read.php');
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 4: إنشاء مورد جديد
echo "<h2>4. اختبار إنشاء مورد جديد</h2>\n";
$supplier_data = [
    'name' => 'Test Supplier',
    'email' => 'test@supplier.com',
    'phone' => '+212123456789',
    'address' => 'Test Address'
];
$result = testEndpoint('POST', '/api/suppliers/create.php', $supplier_data, 201);
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 5: قراءة المنتجات
echo "<h2>5. اختبار قراءة المنتجات</h2>\n";
$result = testEndpoint('GET', '/api/products/read.php');
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 6: إنشاء منتج جديد
echo "<h2>6. اختبار إنشاء منتج جديد</h2>\n";
$product_data = [
    'name' => 'Test Product',
    'description' => 'Test product description',
    'category' => 'Test Category',
    'unit_price' => 100.00,
    'cost_price' => 80.00,
    'quantity_in_stock' => 50,
    'min_quantity' => 10
];
$result = testEndpoint('POST', '/api/products/create.php', $product_data, 201);
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 7: قراءة المعاملات المالية
echo "<h2>7. اختبار قراءة المعاملات المالية</h2>\n";
$result = testEndpoint('GET', '/api/financial_transactions/read.php');
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// اختبار 8: إنشاء معاملة مالية جديدة
echo "<h2>8. اختبار إنشاء معاملة مالية جديدة</h2>\n";
$transaction_data = [
    'type' => 'expense',
    'category' => 'Test Category',
    'amount' => 500.00,
    'description' => 'Test transaction',
    'date' => date('Y-m-d'),
    'reference' => 'TEST-' . time()
];
$result = testEndpoint('POST', '/api/financial_transactions/create.php', $transaction_data, 201);
echo "<p>النتيجة: " . ($result['success'] ? '✅ نجح' : '❌ فشل') . "</p>\n";
echo "<p>رمز الاستجابة: " . $result['actual_status'] . "</p>\n";

// عرض ملخص النتائج
echo "<h2>📊 ملخص النتائج</h2>\n";
$success_count = 0;
$total_count = count($test_results);

foreach ($test_results as $test) {
    if ($test['success']) {
        $success_count++;
    }
}

echo "<p>إجمالي الاختبارات: $total_count</p>\n";
echo "<p>الاختبارات الناجحة: $success_count</p>\n";
echo "<p>الاختبارات الفاشلة: " . ($total_count - $success_count) . "</p>\n";
echo "<p>نسبة النجاح: " . round(($success_count / $total_count) * 100, 2) . "%</p>\n";

if ($success_count == $total_count) {
    echo "<h3 style='color: green;'>🎉 جميع الاختبارات نجحت!</h3>\n";
} else {
    echo "<h3 style='color: red;'>⚠️ بعض الاختبارات فشلت</h3>\n";
}

echo "<hr>\n";
echo "<h3>تفاصيل الاختبارات:</h3>\n";
foreach ($test_results as $index => $test) {
    $status_icon = $test['success'] ? '✅' : '❌';
    echo "<p><strong>$status_icon اختبار " . ($index + 1) . ":</strong> " . $test['method'] . " " . $test['url'] . "</p>\n";
    echo "<p>رمز الاستجابة المتوقع: " . $test['expected_status'] . " | الفعلي: " . $test['actual_status'] . "</p>\n";
    if ($test['error']) {
        echo "<p style='color: red;'>خطأ: " . $test['error'] . "</p>\n";
    }
    echo "<br>\n";
}
?> 