<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

// التحقق من أن الطلب هو POST
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed'
    ]);
    exit;
}

try {
    // قراءة البيانات المرسلة
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Invalid JSON data');
    }
    
    $email = trim($input['email'] ?? '');
    $password = $input['password'] ?? '';
    
    // التحقق من البيانات المطلوبة
    if (empty($email) || empty($password)) {
        throw new Exception('Email and password are required');
    }
    
    // التحقق من صحة البريد الإلكتروني
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Invalid email format');
    }
    
    // الاتصال بقاعدة البيانات
    $database = new Database();
    $conn = $database->getConnection();
    
    // البحث عن المستخدم
    $query = "SELECT id, email, password_hash, full_name, role, is_active FROM users WHERE email = ? AND is_active = 1";
    $stmt = $database->executeQuery($query, [$email]);
    
    $user = $database->fetch($stmt);
    
    if (!$user) {
        throw new Exception('Invalid email or password');
    }
    
    // التحقق من كلمة المرور
    if (!password_verify($password, $user['password_hash'])) {
        throw new Exception('Invalid email or password');
    }
    
    // تحديث آخر تسجيل دخول
    $updateQuery = "UPDATE users SET last_login = GETDATE() WHERE id = ?";
    $database->executeQuery($updateQuery, [$user['id']]);
    
    // إنشاء token بسيط (في الإنتاج يجب استخدام JWT)
    $token = bin2hex(random_bytes(32));
    
    // إرجاع بيانات المستخدم (بدون كلمة المرور)
    unset($user['password_hash']);
    
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'data' => [
            'user' => $user,
            'token' => $token
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
