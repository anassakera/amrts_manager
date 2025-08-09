<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

require_once '../../config/db_connection.php';
require_once '../../config/cors.php';

// التحقق من أن الطلب هو OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            handleGet($database);
            break;
        case 'POST':
            handlePost($database);
            break;
        case 'PUT':
            handlePut($database);
            break;
        case 'DELETE':
            handleDelete($database);
            break;
        default:
            http_response_code(405);
            echo json_encode([
                'success' => false,
                'message' => 'Method not allowed'
            ]);
            break;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

// دالة التعامل مع GET - جلب المستخدمين
function handleGet($database) {
    $id = $_GET['id'] ?? null;
    
    if ($id) {
        // جلب مستخدم واحد
        $query = "SELECT id, username, email, full_name, role, is_active, last_login, created_at, updated_at FROM users WHERE id = ?";
        $stmt = $database->executeQuery($query, [$id]);
        $user = $database->fetch($stmt);
        
        if (!$user) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'User not found'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $user
        ]);
    } else {
        // جلب جميع المستخدمين
        $query = "SELECT id, username, email, full_name, role, is_active, last_login, created_at, updated_at FROM users ORDER BY created_at DESC";
        $stmt = $database->executeQuery($query);
        $users = $database->fetchAll($stmt);
        
        echo json_encode([
            'success' => true,
            'data' => $users
        ]);
    }
}

// دالة التعامل مع POST - إنشاء مستخدم جديد
function handlePost($database) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid JSON data'
        ]);
        return;
    }
    
    // التحقق من البيانات المطلوبة
    $required_fields = ['username', 'email', 'password', 'full_name'];
    foreach ($required_fields as $field) {
        if (empty($input[$field])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => "Field '$field' is required"
            ]);
            return;
        }
    }
    
    $username = trim($input['username']);
    $email = trim($input['email']);
    $password = $input['password'];
    $full_name = trim($input['full_name']);
    $role = $input['role'] ?? 'user';
    $is_active = $input['is_active'] ?? true;
    
    // التحقق من صحة البريد الإلكتروني
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid email format'
        ]);
        return;
    }
    
    // التحقق من طول كلمة المرور
    if (strlen($password) < 6) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Password must be at least 6 characters'
        ]);
        return;
    }
    
    try {
        // التحقق من عدم وجود username أو email مكرر
        $checkQuery = "SELECT id FROM users WHERE username = ? OR email = ?";
        $checkStmt = $database->executeQuery($checkQuery, [$username, $email]);
        $existingUser = $database->fetch($checkStmt);
        
        if ($existingUser) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Username or email already exists'
            ]);
            return;
        }
        
        // تشفير كلمة المرور
        $password_hash = password_hash($password, PASSWORD_DEFAULT);
        
        // إنشاء المستخدم
        $query = "INSERT INTO users (username, email, password_hash, full_name, role, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, GETDATE(), GETDATE())";
        $stmt = $database->executeQuery($query, [$username, $email, $password_hash, $full_name, $role, $is_active ? 1 : 0]);
        
        // جلب المستخدم المُنشأ
        $userId = $database->conn;
        $getQuery = "SELECT id, username, email, full_name, role, is_active, last_login, created_at, updated_at FROM users WHERE id = @@IDENTITY";
        $getStmt = $database->executeQuery($getQuery);
        $newUser = $database->fetch($getStmt);
        
        echo json_encode([
            'success' => true,
            'message' => 'User created successfully',
            'data' => $newUser
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error creating user: ' . $e->getMessage()
        ]);
    }
}

// دالة التعامل مع PUT - تحديث مستخدم
function handlePut($database) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid JSON data'
        ]);
        return;
    }
    
    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'User ID is required'
        ]);
        return;
    }
    
    // التحقق من وجود المستخدم
    $checkQuery = "SELECT id FROM users WHERE id = ?";
    $checkStmt = $database->executeQuery($checkQuery, [$id]);
    $existingUser = $database->fetch($checkStmt);
    
    if (!$existingUser) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ]);
        return;
    }
    
    // تجهيز البيانات للتحديث
    $updateFields = [];
    $params = [];
    
    if (isset($input['username'])) {
        $username = trim($input['username']);
        if (!empty($username)) {
            // التحقق من عدم وجود username مكرر
            $checkUsernameQuery = "SELECT id FROM users WHERE username = ? AND id != ?";
            $checkUsernameStmt = $database->executeQuery($checkUsernameQuery, [$username, $id]);
            $existingUsername = $database->fetch($checkUsernameStmt);
            
            if ($existingUsername) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Username already exists'
                ]);
                return;
            }
            
            $updateFields[] = "username = ?";
            $params[] = $username;
        }
    }
    
    if (isset($input['email'])) {
        $email = trim($input['email']);
        if (!empty($email)) {
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid email format'
                ]);
                return;
            }
            
            // التحقق من عدم وجود email مكرر
            $checkEmailQuery = "SELECT id FROM users WHERE email = ? AND id != ?";
            $checkEmailStmt = $database->executeQuery($checkEmailQuery, [$email, $id]);
            $existingEmail = $database->fetch($checkEmailStmt);
            
            if ($existingEmail) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Email already exists'
                ]);
                return;
            }
            
            $updateFields[] = "email = ?";
            $params[] = $email;
        }
    }
    
    if (isset($input['password']) && !empty($input['password'])) {
        if (strlen($input['password']) < 6) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Password must be at least 6 characters'
            ]);
            return;
        }
        
        $password_hash = password_hash($input['password'], PASSWORD_DEFAULT);
        $updateFields[] = "password_hash = ?";
        $params[] = $password_hash;
    }
    
    if (isset($input['full_name'])) {
        $full_name = trim($input['full_name']);
        if (!empty($full_name)) {
            $updateFields[] = "full_name = ?";
            $params[] = $full_name;
        }
    }
    
    if (isset($input['role'])) {
        $role = trim($input['role']);
        if (!empty($role)) {
            $updateFields[] = "role = ?";
            $params[] = $role;
        }
    }
    
    if (isset($input['is_active'])) {
        $is_active = $input['is_active'] ? 1 : 0;
        $updateFields[] = "is_active = ?";
        $params[] = $is_active;
    }
    
    if (empty($updateFields)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'No fields to update'
        ]);
        return;
    }
    
    // إضافة updated_at
    $updateFields[] = "updated_at = GETDATE()";
    $params[] = $id;
    
    try {
        $query = "UPDATE users SET " . implode(', ', $updateFields) . " WHERE id = ?";
        $stmt = $database->executeQuery($query, $params);
        
        // جلب المستخدم المحدث
        $getQuery = "SELECT id, username, email, full_name, role, is_active, last_login, created_at, updated_at FROM users WHERE id = ?";
        $getStmt = $database->executeQuery($getQuery, [$id]);
        $updatedUser = $database->fetch($getStmt);
        
        echo json_encode([
            'success' => true,
            'message' => 'User updated successfully',
            'data' => $updatedUser
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error updating user: ' . $e->getMessage()
        ]);
    }
}

// دالة التعامل مع DELETE - حذف مستخدم
function handleDelete($database) {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'User ID is required'
        ]);
        return;
    }
    
    // التحقق من وجود المستخدم
    $checkQuery = "SELECT id, username FROM users WHERE id = ?";
    $checkStmt = $database->executeQuery($checkQuery, [$id]);
    $existingUser = $database->fetch($checkStmt);
    
    if (!$existingUser) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ]);
        return;
    }
    
    try {
        // حذف المستخدم
        $query = "DELETE FROM users WHERE id = ?";
        $stmt = $database->executeQuery($query, [$id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'User deleted successfully',
            'data' => [
                'id' => $id,
                'username' => $existingUser['username']
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error deleting user: ' . $e->getMessage()
        ]);
    }
}
?>
