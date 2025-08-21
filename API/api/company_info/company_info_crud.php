<?php
// company_crud.php
header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/db_connection.php';

/**
 * Enhanced Company CRUD API for Single Company Setup
 * 
 * This API is designed for a single company configuration where only one company record
 * is allowed in the database. The CompanyID is always 1.
 * 
 * Supported Actions:
 * - action=create (POST): Create new company (only if no company exists)
 * - action=read (GET): Get company info (without logo binary)
 * - action=read_single (GET) + CompanyID: Get single company (logo as base64)
 * - action=update (POST): Update company (requires CompanyID)
 * - action=delete (POST): Delete company (requires CompanyID)
 * 
 * Logo handling:
 * - Multipart form-data with file input named "logo"
 * - JSON body with "logo_base64" field
 */

// Error codes for consistent error handling
const ERROR_CODES = [
    'MISSING_ACTION' => 1001,
    'INVALID_ACTION' => 1002,
    'MISSING_REQUIRED_FIELD' => 2001,
    'INVALID_DATA_FORMAT' => 2002,
    'DUPLICATE_ENTRY' => 2003,
    'RECORD_NOT_FOUND' => 2004,
    'FILE_UPLOAD_ERROR' => 3001,
    'INVALID_BASE64' => 3002,
    'DATABASE_ERROR' => 4001,
    'VALIDATION_ERROR' => 5001,
    'SINGLE_COMPANY_VIOLATION' => 5002,
    'SERVER_ERROR' => 9999
];

class CompanyAPI {
    private $database;
    private $conn;
    
    public function __construct() {
        try {
            $this->database = new Database();
            $this->conn = $this->database->getConnection();
            
            if (!$this->conn) {
                throw new Exception('Database connection failed');
            }
        } catch (Exception $e) {
            $this->jsonErrorResponse('Database connection failed', ERROR_CODES['DATABASE_ERROR'], $e->getMessage());
        }
    }
    
    /**
     * Send JSON success response
     */
    private function jsonSuccessResponse($data = null, $message = 'Success') {
        $response = [
            'success' => true,
            'message' => $message,
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        if ($data !== null) {
            $response['data'] = $data;
        }
        
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    /**
     * Send JSON error response
     */
    private function jsonErrorResponse($message, $errorCode = ERROR_CODES['SERVER_ERROR'], $details = null) {
        $response = [
            'success' => false,
            'error' => [
                'message' => $message,
                'code' => $errorCode,
                'timestamp' => date('Y-m-d H:i:s')
            ]
        ];
        
        if ($details !== null && !empty($details)) {
            $response['error']['details'] = $details;
        }
        
        http_response_code($this->getHttpStatusFromErrorCode($errorCode));
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    /**
     * Get appropriate HTTP status code based on error code
     */
    private function getHttpStatusFromErrorCode($errorCode) {
        switch ($errorCode) {
            case ERROR_CODES['MISSING_ACTION']:
            case ERROR_CODES['INVALID_ACTION']:
            case ERROR_CODES['MISSING_REQUIRED_FIELD']:
            case ERROR_CODES['INVALID_DATA_FORMAT']:
            case ERROR_CODES['VALIDATION_ERROR']:
            case ERROR_CODES['SINGLE_COMPANY_VIOLATION']:
                return 400; // Bad Request
            case ERROR_CODES['RECORD_NOT_FOUND']:
                return 404; // Not Found
            case ERROR_CODES['DUPLICATE_ENTRY']:
                return 409; // Conflict
            case ERROR_CODES['FILE_UPLOAD_ERROR']:
            case ERROR_CODES['INVALID_BASE64']:
                return 422; // Unprocessable Entity
            case ERROR_CODES['DATABASE_ERROR']:
                return 503; // Service Unavailable
            default:
                return 500; // Internal Server Error
        }
    }
    
    /**
     * Get JSON input from request body
     */
    private function getJsonInput() {
        try {
            $raw = file_get_contents('php://input');
            if (empty($raw)) {
                return [];
            }
            
            $decoded = json_decode($raw, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new Exception('Invalid JSON format: ' . json_last_error_msg());
            }
            
            return $decoded ?: [];
        } catch (Exception $e) {
            $this->jsonErrorResponse('Invalid JSON input', ERROR_CODES['INVALID_DATA_FORMAT'], $e->getMessage());
        }
    }
    
    /**
     * Validate required fields
     */
    private function validateRequired($data, $requiredFields) {
        $missing = [];
        foreach ($requiredFields as $field) {
            if (!isset($data[$field]) || trim($data[$field]) === '') {
                $missing[] = $field;
            }
        }
        
        if (!empty($missing)) {
            $this->jsonErrorResponse(
                'Missing required fields: ' . implode(', ', $missing),
                ERROR_CODES['MISSING_REQUIRED_FIELD'],
                ['missing_fields' => $missing]
            );
        }
    }
    
    /**
     * Validate email format
     */
    private function validateEmail($email) {
        if (!empty($email) && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->jsonErrorResponse('Invalid email format', ERROR_CODES['VALIDATION_ERROR']);
        }
    }
    
    /**
     * Validate ICE format (Morocco specific)
     */
    private function validateICE($ice) {
        if (!empty($ice) && !preg_match('/^[0-9]{15}$/', $ice)) {
            $this->jsonErrorResponse(
                'ICE must be exactly 15 digits',
                ERROR_CODES['VALIDATION_ERROR'],
                ['field' => 'ice', 'format' => '15 digits required']
            );
        }
    }
    
    /**
     * Check if company already exists
     */
    private function companyExists() {
        $sql = "SELECT COUNT(*) as count FROM CompanyInfo";
        $stmt = $this->database->executeQuery($sql);
        $result = $this->database->fetch($stmt);
        return ($result['count'] > 0);
    }
    
    /**
     * Handle file upload or base64 logo
     */
    private function processLogo($input) {
        $logoData = null;
        
        // Handle file upload
        if (!empty($_FILES['logo'])) {
            $file = $_FILES['logo'];
            
            // Check for upload errors
            if ($file['error'] !== UPLOAD_ERR_OK) {
                $uploadErrors = [
                    UPLOAD_ERR_INI_SIZE => 'File too large (exceeds upload_max_filesize)',
                    UPLOAD_ERR_FORM_SIZE => 'File too large (exceeds MAX_FILE_SIZE)',
                    UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
                    UPLOAD_ERR_NO_FILE => 'No file was uploaded',
                    UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
                    UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
                    UPLOAD_ERR_EXTENSION => 'File upload stopped by extension'
                ];
                
                $errorMsg = $uploadErrors[$file['error']] ?? 'Unknown upload error';
                $this->jsonErrorResponse($errorMsg, ERROR_CODES['FILE_UPLOAD_ERROR']);
            }
            
            // Validate file type
            $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mimeType = finfo_file($finfo, $file['tmp_name']);
            finfo_close($finfo);
            
            if (!in_array($mimeType, $allowedTypes)) {
                $this->jsonErrorResponse(
                    'Invalid file type. Allowed types: JPEG, PNG, GIF, WEBP',
                    ERROR_CODES['VALIDATION_ERROR'],
                    ['allowed_types' => $allowedTypes, 'provided_type' => $mimeType]
                );
            }
            
            // Validate file size (max 5MB)
            $maxSize = 5 * 1024 * 1024; // 5MB
            if ($file['size'] > $maxSize) {
                $this->jsonErrorResponse(
                    'File too large. Maximum size: 5MB',
                    ERROR_CODES['VALIDATION_ERROR'],
                    ['max_size' => $maxSize, 'file_size' => $file['size']]
                );
            }
            
            if (is_uploaded_file($file['tmp_name'])) {
                $logoData = file_get_contents($file['tmp_name']);
            }
        }
        // Handle base64 input
        elseif (!empty($input['logo_base64'])) {
            $base64Data = $input['logo_base64'];
            
            // Remove data URL prefix if present
            if (strpos($base64Data, 'data:') === 0) {
                $base64Data = substr($base64Data, strpos($base64Data, ',') + 1);
            }
            
            $decoded = base64_decode($base64Data, true);
            if ($decoded === false) {
                $this->jsonErrorResponse('Invalid base64 logo data', ERROR_CODES['INVALID_BASE64']);
            }
            
            // Validate decoded data size (max 5MB)
            $maxSize = 5 * 1024 * 1024;
            if (strlen($decoded) > $maxSize) {
                $this->jsonErrorResponse(
                    'Logo data too large. Maximum size: 5MB',
                    ERROR_CODES['VALIDATION_ERROR']
                );
            }
            
            $logoData = $decoded;
        }
        // Handle remove logo request
        elseif (array_key_exists('remove_logo', $input) && $input['remove_logo'] === true) {
            // Return null to indicate logo should be removed
            $logoData = null;
        }
        
        return $logoData;
    }
    
    /**
     * Create new company (only if no company exists)
     */
    public function create() {
        try {
            // Check if company already exists
            if ($this->companyExists()) {
                $this->jsonErrorResponse(
                    'Company already exists. Only one company is allowed in this system.',
                    ERROR_CODES['SINGLE_COMPANY_VIOLATION'],
                    ['existing_company_id' => 1]
                );
            }
            
            $input = $this->getJsonInput();
            
            // Get data from POST or JSON input
            $data = [
                'legalName' => $_POST['legalName'] ?? $input['legalName'] ?? null,
                'tradeName' => $_POST['tradeName'] ?? $input['tradeName'] ?? null,
                'ice' => $_POST['ice'] ?? $input['ice'] ?? null,
                'rc' => $_POST['rc'] ?? $input['rc'] ?? null,
                'ifNumber' => $_POST['ifNumber'] ?? $input['ifNumber'] ?? null,
                'cnss' => $_POST['cnss'] ?? $input['cnss'] ?? null,
                'address' => $_POST['address'] ?? $input['address'] ?? null,
                'city' => $_POST['city'] ?? $input['city'] ?? null,
                'country' => $_POST['country'] ?? $input['country'] ?? 'Morocco',
                'phone' => $_POST['phone'] ?? $input['phone'] ?? null,
                'email' => $_POST['email'] ?? $input['email'] ?? null,
                'website' => $_POST['website'] ?? $input['website'] ?? null
            ];
            
            // Validate required fields
            $this->validateRequired($data, ['legalName', 'ice']);
            
            // Validate formats
            $this->validateICE($data['ice']);
            $this->validateEmail($data['email']);
            
            // Process logo
            $logoData = $this->processLogo($input);
            
            // Prepare SQL based on logo presence
            if ($logoData !== null) {
                $sql = "INSERT INTO CompanyInfo 
                    (LegalName, TradeName, Logo, ICE, RC, ifNumber, CNSS, Address, City, Country, Phone, Email, Website, CreatedAt) 
                    VALUES (?, ?, CONVERT(varbinary(max), ?), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())";
                $params = [
                    $data['legalName'], $data['tradeName'], $logoData, $data['ice'],
                    $data['rc'], $data['ifNumber'], $data['cnss'], $data['address'],
                    $data['city'], $data['country'], $data['phone'], $data['email'], $data['website']
                ];
            } else {
                $sql = "INSERT INTO CompanyInfo 
                    (LegalName, TradeName, Logo, ICE, RC, ifNumber, CNSS, Address, City, Country, Phone, Email, Website, CreatedAt) 
                    VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())";
                $params = [
                    $data['legalName'], $data['tradeName'], $data['ice'],
                    $data['rc'], $data['ifNumber'], $data['cnss'], $data['address'],
                    $data['city'], $data['country'], $data['phone'], $data['email'], $data['website']
                ];
            }
            
            $this->database->executeQuery($sql, $params);
            
            // Get the inserted CompanyID
            $lastIdSql = "SELECT SCOPE_IDENTITY() as CompanyID";
            $lastIdStmt = $this->database->executeQuery($lastIdSql);
            $lastIdResult = $this->database->fetch($lastIdStmt);
            $companyId = $lastIdResult['CompanyID'];
            
            $this->jsonSuccessResponse(
                ['CompanyID' => $companyId],
                'Company created successfully'
            );
            
        } catch (Exception $e) {
            $this->jsonErrorResponse(
                'Failed to create company',
                ERROR_CODES['DATABASE_ERROR'],
                $e->getMessage()
            );
        }
    }
    
    /**
     * Read company info (without logo binary)
     */
    public function read() {
        try {
            $sql = "SELECT CompanyID, LegalName, TradeName, ICE, RC, ifNumber, CNSS, 
                           Address, City, Country, Phone, Email, Website, CreatedAt, UpdatedAt 
                    FROM CompanyInfo ORDER BY CompanyID DESC";
            
            $stmt = $this->database->executeQuery($sql);
            $rows = $this->database->fetchAll($stmt);
            
            $this->jsonSuccessResponse($rows, 'Company information retrieved successfully');
            
        } catch (Exception $e) {
            $this->jsonErrorResponse(
                'Failed to retrieve company information',
                ERROR_CODES['DATABASE_ERROR'],
                $e->getMessage()
            );
        }
    }
    
    /**
     * Read single company (with logo as base64)
     */
    public function readSingle() {
        try {
            $id = $_GET['CompanyID'] ?? null;
            
            if (!$id || !is_numeric($id)) {
                $this->jsonErrorResponse(
                    'Valid CompanyID is required',
                    ERROR_CODES['MISSING_REQUIRED_FIELD']
                );
            }
            
            $sql = "SELECT CompanyID, LegalName, TradeName, Logo, ICE, RC, ifNumber, CNSS, 
                           Address, City, Country, Phone, Email, Website, CreatedAt, UpdatedAt 
                    FROM CompanyInfo WHERE CompanyID = ?";
            
            $stmt = $this->database->executeQuery($sql, [$id]);
            $row = $this->database->fetch($stmt);
            
            if (!$row) {
                $this->jsonErrorResponse(
                    'Company not found',
                    ERROR_CODES['RECORD_NOT_FOUND'],
                    ['CompanyID' => $id]
                );
            }
            
            // Convert logo to base64 if present
            if (isset($row['Logo']) && $row['Logo'] !== null) {
                $logo = $row['Logo'];
                if (is_resource($logo)) {
                    $contents = stream_get_contents($logo);
                    $row['logo_base64'] = base64_encode($contents);
                } else {
                    $row['logo_base64'] = base64_encode($logo);
                }
            } else {
                $row['logo_base64'] = null;
            }
            
            unset($row['Logo']);
            
            $this->jsonSuccessResponse($row, 'Company retrieved successfully');
            
        } catch (Exception $e) {
            $this->jsonErrorResponse(
                'Failed to retrieve company',
                ERROR_CODES['DATABASE_ERROR'],
                $e->getMessage()
            );
        }
    }
    
    /**
     * Update company
     */
    public function update() {
        try {
            $input = $this->getJsonInput();
            $id = $_POST['CompanyID'] ?? $input['CompanyID'] ?? null;
            
            if (!$id || !is_numeric($id)) {
                $this->jsonErrorResponse(
                    'Valid CompanyID is required',
                    ERROR_CODES['MISSING_REQUIRED_FIELD']
                );
            }
            
            // Check if company exists
            $checkSql = "SELECT CompanyID FROM CompanyInfo WHERE CompanyID = ?";
            $checkStmt = $this->database->executeQuery($checkSql, [$id]);
            $existing = $this->database->fetch($checkStmt);
            
            if (!$existing) {
                $this->jsonErrorResponse(
                    'Company not found',
                    ERROR_CODES['RECORD_NOT_FOUND'],
                    ['CompanyID' => $id]
                );
            }
            
            // Define allowed fields for update
            $allowedFields = [
                'legalName' => 'LegalName',
                'tradeName' => 'TradeName',
                'ice' => 'ICE',
                'rc' => 'RC',
                'ifNumber' => 'ifNumber',
                'cnss' => 'CNSS',
                'address' => 'Address',
                'city' => 'City',
                'country' => 'Country',
                'phone' => 'Phone',
                'email' => 'Email',
                'website' => 'Website'
            ];
            
            $updateFields = [];
            $params = [];
            
            // Process regular fields
            foreach ($allowedFields as $inputKey => $dbColumn) {
                $value = $_POST[$inputKey] ?? $input[$inputKey] ?? null;
                
                // Only include non-empty fields in update
                if ($value !== null && !empty(trim($value))) {
                    // Validate specific fields
                    if ($inputKey === 'ice') {
                        $this->validateICE($value);
                    }
                    
                    if ($inputKey === 'email') {
                        $this->validateEmail($value);
                    }
                    
                    $updateFields[] = "$dbColumn = ?";
                    $params[] = $value;
                }
            }
            
            // Handle logo update
            $logoProvided = false;
            if (!empty($_FILES['logo']) || array_key_exists('logo_base64', $input) || array_key_exists('remove_logo', $input)) {
                $logoData = $this->processLogo($input);
                $logoProvided = true;
                
                if ($logoData !== null) {
                    $updateFields[] = "Logo = CONVERT(varbinary(max), ?)";
                    $params[] = $logoData;
                } else {
                    $updateFields[] = "Logo = NULL";
                }
            }
            
            // Check if we have fields to update
            if (empty($updateFields)) {
                $this->jsonErrorResponse(
                    'No fields provided for update',
                    ERROR_CODES['MISSING_REQUIRED_FIELD']
                );
            }
            
            // Ensure required fields are not being set to empty
            $legalNameValue = $_POST['legalName'] ?? $input['legalName'] ?? null;
            $iceValue = $_POST['ice'] ?? $input['ice'] ?? null;
            
            if ($legalNameValue !== null && empty(trim($legalNameValue))) {
                $this->jsonErrorResponse(
                    'Legal name cannot be empty',
                    ERROR_CODES['VALIDATION_ERROR']
                );
            }
            
            if ($iceValue !== null && empty(trim($iceValue))) {
                $this->jsonErrorResponse(
                    'ICE cannot be empty',
                    ERROR_CODES['VALIDATION_ERROR']
                );
            }
            
            // Add WHERE parameter
            $params[] = $id;
            
            $sql = "UPDATE CompanyInfo SET " . implode(', ', $updateFields) . ", UpdatedAt = GETDATE() WHERE CompanyID = ?";
            $this->database->executeQuery($sql, $params);
            
            $this->jsonSuccessResponse(
                ['CompanyID' => $id],
                'Company updated successfully'
            );
            
        } catch (Exception $e) {
            $this->jsonErrorResponse(
                'Failed to update company',
                ERROR_CODES['DATABASE_ERROR'],
                $e->getMessage()
            );
        }
    }
    
    /**
     * Delete company
     */
    public function delete() {
        try {
            $input = $this->getJsonInput();
            $id = $_POST['CompanyID'] ?? $input['CompanyID'] ?? null;
            
            if (!$id || !is_numeric($id)) {
                $this->jsonErrorResponse(
                    'Valid CompanyID is required',
                    ERROR_CODES['MISSING_REQUIRED_FIELD']
                );
            }
            
            // Check if company exists
            $checkSql = "SELECT CompanyID FROM CompanyInfo WHERE CompanyID = ?";
            $checkStmt = $this->database->executeQuery($checkSql, [$id]);
            $existing = $this->database->fetch($checkStmt);
            
            if (!$existing) {
                $this->jsonErrorResponse(
                    'Company not found',
                    ERROR_CODES['RECORD_NOT_FOUND'],
                    ['CompanyID' => $id]
                );
            }
            
            $sql = "DELETE FROM CompanyInfo WHERE CompanyID = ?";
            $this->database->executeQuery($sql, [$id]);
            
            $this->jsonSuccessResponse(
                ['CompanyID' => $id],
                'Company deleted successfully'
            );
            
        } catch (Exception $e) {
            $this->jsonErrorResponse(
                'Failed to delete company',
                ERROR_CODES['DATABASE_ERROR'],
                $e->getMessage()
            );
        }
    }
    
    /**
     * Main handler
     */
    public function handleRequest() {
        try {
            $action = $_REQUEST['action'] ?? null;
            
            if (!$action) {
                $this->jsonErrorResponse(
                    'Action parameter is required',
                    ERROR_CODES['MISSING_ACTION']
                );
            }
            
            // Validate HTTP method for certain actions
            $method = $_SERVER['REQUEST_METHOD'];
            if (in_array($action, ['create', 'update', 'delete']) && $method !== 'POST') {
                $this->jsonErrorResponse(
                    "Action '$action' requires POST method",
                    ERROR_CODES['INVALID_ACTION'],
                    ['required_method' => 'POST', 'provided_method' => $method]
                );
            }
            
            switch ($action) {
                case 'create':
                    $this->create();
                    break;
                case 'read':
                    $this->read();
                    break;
                case 'read_single':
                    $this->readSingle();
                    break;
                case 'update':
                    $this->update();
                    break;
                case 'delete':
                    $this->delete();
                    break;
                default:
                    $this->jsonErrorResponse(
                        'Invalid action',
                        ERROR_CODES['INVALID_ACTION'],
                        ['provided_action' => $action, 'valid_actions' => ['create', 'read', 'read_single', 'update', 'delete']]
                    );
            }
            
        } catch (Exception $e) {
            $this->jsonErrorResponse(
                'Unexpected server error',
                ERROR_CODES['SERVER_ERROR'],
                $e->getMessage()
            );
        }
    }
}

// Initialize and handle request
try {
    $api = new CompanyAPI();
    $api->handleRequest();
} catch (Exception $e) {
    // Final fallback error response
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => [
            'message' => 'Critical server error',
            'code' => ERROR_CODES['SERVER_ERROR'],
            'timestamp' => date('Y-m-d H:i:s')
        ]
    ], JSON_UNESCAPED_UNICODE);
}
?>