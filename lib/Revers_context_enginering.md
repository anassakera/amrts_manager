```markdown
# 🔄 Reverse Context Engineering System
## Advanced Flutter-to-Backend Generator

---

## 📘 System Overview

This system performs **reverse engineering** on Flutter screen files to automatically generate:
- Complete database schemas (SQL Server)
- Optimized SQL queries for all CRUD operations
- Production-ready PHP API files
- Dart service layer integration code

**Input:** Any Flutter screen file (`.dart`)
**Output:** Complete backend infrastructure

---

## 🎯 Instructions for AI Model

You are tasked with analyzing Flutter screen code and generating a complete backend system. Follow these phases precisely:

---

## 📊 PHASE 1: Deep Code Analysis

### 1.1 Data Structure Extraction

**Identify all data models in the code:**

```dart
// Example patterns to detect:
List<Map<String, dynamic>> _dataList = [];
final Map<String, dynamic> _dataItem = {};
```

**Extract:**
- Variable names (e.g., `_commandes`, `_users`, `_products`)
- Data structure (Map keys and their types)
- Nested relationships (items within items)
- Field naming patterns

**Output Format:**
```json
{
  "primary_entity": "entity_name",
  "main_fields": [
    {"name": "field1", "type": "string", "nullable": false},
    {"name": "field2", "type": "number", "nullable": true}
  ],
  "nested_entities": [
    {
      "name": "child_entity",
      "relationship": "one_to_many",
      "fields": [...]
    }
  ]
}
```

---

### 1.2 CRUD Operations Detection

**Search for method patterns:**

| Pattern | Operation | HTTP Method |
|---------|-----------|-------------|
| `_add*()`, `_create*()`, `_insert*()` | CREATE | POST |
| `_get*()`, `_fetch*()`, `_load*()`, `_view*()` | READ | GET/POST |
| `_edit*()`, `_update*()`, `_modify*()` | UPDATE | POST |
| `_delete*()`, `_remove*()` | DELETE | POST |

**Extract:**
- Method names
- Parameters passed
- Data being manipulated
- Return types expected

---

### 1.3 Business Logic Analysis

**Detect special operations:**

```dart
// Aggregation functions
_calculate*()
_getStats()
_getTotal()

// Filtering operations
_getFiltered*()
where() clauses
_search*()

// Date range filters
DateTime? _startDate
DateTime? _endDate
```

**Extract:**
- Calculation formulas (SUM, COUNT, AVG, etc.)
- Filter conditions (LIKE, BETWEEN, IN, etc.)
- Sorting requirements (ORDER BY)
- Grouping logic (GROUP BY)

---

### 1.4 UI Component Mapping

**Identify data display patterns:**

```dart
// List views → Need pagination support
ListView.builder()
GridView.builder()

// Search bars → Need full-text search queries
TextField with onChanged
_searchController

// Date pickers → Need date range queries
showDatePicker()

// Dropdowns → Need lookup tables
DropdownButton()
```

---

## 🗄️ PHASE 2: Database Schema Generation

### 2.1 Table Structure Rules

**Naming Convention:**
- Tables: `snake_case` (e.g., `sales_orders`, `product_items`)
- Primary Keys: `{table_singular}_id` or `{field}_ref`
- Foreign Keys: `{parent_table_singular}_id`

**Field Type Mapping:**

| Dart Type | SQL Server Type | Notes |
|-----------|----------------|-------|
| String | NVARCHAR(length) | Default 100, adjust based on content |
| int | INT | Use BIGINT for IDs |
| double | DECIMAL(10,2) | Adjust precision as needed |
| DateTime | DATETIME2 | More precise than DATETIME |
| bool | BIT | 0 or 1 |
| List/Map | NVARCHAR(MAX) | Store as JSON if needed |

---

### 2.2 Schema Template

```sql
-- ============================================
-- AUTO-GENERATED DATABASE SCHEMA
-- Source: {screen_file_name}
-- Generated: {timestamp}
-- ============================================

-- Main Entity Table
CREATE TABLE {main_table_name} (
    {primary_key} {key_type} PRIMARY KEY,
    {field1} {type1} NOT NULL,
    {field2} {type2} NULL,
    {field3} {type3} DEFAULT {default_value},
    
    -- Audit Fields (always include)
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by NVARCHAR(100) NULL,
    updated_at DATETIME2 DEFAULT GETDATE(),
    updated_by NVARCHAR(100) NULL,
    is_active BIT DEFAULT 1,
    
    -- Constraints
    CONSTRAINT CK_{table}_{field} CHECK ({condition}),
    CONSTRAINT UQ_{table}_{field} UNIQUE ({field})
);

-- Child/Related Entity Table (if nested data exists)
CREATE TABLE {child_table_name} (
    {child_primary_key} INT IDENTITY(1,1) PRIMARY KEY,
    {foreign_key} {parent_key_type} NOT NULL,
    {child_field1} {type1},
    {child_field2} {type2},
    
    -- Audit Fields
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign Key Constraint
    CONSTRAINT FK_{child_table}_{parent_table} 
        FOREIGN KEY ({foreign_key}) 
        REFERENCES {parent_table}({parent_key})
        ON DELETE CASCADE  -- or SET NULL based on business logic
        ON UPDATE CASCADE
);

-- Performance Indexes
CREATE INDEX IDX_{table}_{field1} ON {table}({field1});
CREATE INDEX IDX_{table}_{field2} ON {table}({field2});
CREATE INDEX IDX_{table}_{date_field} ON {table}({date_field}) 
    WHERE is_active = 1; -- Filtered index for active records

-- Full-Text Search Index (if search functionality exists)
CREATE FULLTEXT INDEX ON {table}({text_field1}, {text_field2})
    KEY INDEX {primary_key_index};

-- Composite Index (for common filter combinations)
CREATE INDEX IDX_{table}_composite 
    ON {table}({filter_field1}, {filter_field2}, {date_field});
```

---

### 2.3 Schema Generation Rules

**CRITICAL RULES:**
1. **Always add audit fields** (created_at, updated_at, created_by, updated_by)
2. **Add is_active/is_deleted** for soft delete support
3. **Index all foreign keys** automatically
4. **Index date fields** used in filtering
5. **Index search fields** (text fields in WHERE clauses)
6. **Use CASCADE carefully** - analyze business logic first
7. **Add CHECK constraints** for data validation
8. **Consider partitioning** for large tables (optional, comment out)

---

## 🔍 PHASE 3: SQL Queries Generation

### 3.1 Query Naming Convention

```
{entity}_{operation}_{variant}.sql

Examples:
- customer_read_all.sql
- customer_read_filtered.sql
- customer_read_by_id.sql
- customer_create.sql
- customer_update.sql
- customer_delete.sql
- customer_stats_summary.sql
```

---

### 3.2 READ Queries Templates

#### **A) Read All (Basic List)**

```sql
-- ============================================
-- Query: {entity}_read_all.sql
-- Purpose: Fetch all {entity} records with related data
-- HTTP Method: GET
-- Parameters: None (or pagination params)
-- ============================================

SELECT 
    main.{pk_field},
    main.{field1},
    main.{field2},
    main.{field3},
    main.{date_field},
    
    -- Nested JSON for related records
    (
        SELECT 
            child.{child_field1},
            child.{child_field2},
            child.{child_field3}
        FROM {child_table} AS child
        WHERE child.{fk_field} = main.{pk_field}
        FOR JSON PATH
    ) AS {child_relation_name}
    
FROM {main_table} AS main
WHERE main.is_active = 1
ORDER BY main.{date_field} DESC
FOR JSON PATH, ROOT('{entity_plural}');
```

#### **B) Read with Filters**

```sql
-- ============================================
-- Query: {entity}_read_filtered.sql
-- Purpose: Search and filter {entity} records
-- HTTP Method: POST
-- Parameters: @search_term, @date_from, @date_to, @status, @page, @page_size
-- ============================================

DECLARE @offset INT = (@page - 1) * @page_size;

SELECT 
    main.{pk_field},
    main.{field1},
    main.{field2},
    
    -- Nested data
    (
        SELECT * FROM {child_table} child
        WHERE child.{fk_field} = main.{pk_field}
        FOR JSON PATH
    ) AS {child_relation_name}
    
FROM {main_table} AS main
WHERE 
    main.is_active = 1
    
    -- Text search (multiple fields)
    AND (
        @search_term IS NULL 
        OR @search_term = ''
        OR main.{text_field1} LIKE '%' + @search_term + '%'
        OR main.{text_field2} LIKE '%' + @search_term + '%'
    )
    
    -- Date range filter
    AND (
        @date_from IS NULL 
        OR main.{date_field} >= @date_from
    )
    AND (
        @date_to IS NULL 
        OR main.{date_field} <= DATEADD(DAY, 1, @date_to)
    )
    
    -- Status/Category filter
    AND (
        @status IS NULL 
        OR main.{status_field} = @status
    )

ORDER BY main.{date_field} DESC
OFFSET @offset ROWS
FETCH NEXT @page_size ROWS ONLY
FOR JSON PATH;

-- Total count query (for pagination)
SELECT COUNT(*) AS total_count
FROM {main_table} AS main
WHERE [same WHERE conditions as above];
```

#### **C) Read Single Record**

```sql
-- ============================================
-- Query: {entity}_read_by_id.sql
-- Purpose: Fetch single {entity} with all details
-- HTTP Method: GET or POST
-- Parameters: @{pk_field}
-- ============================================

SELECT 
    main.*,
    
    -- Include all related data
    (
        SELECT * FROM {child_table} child
        WHERE child.{fk_field} = main.{pk_field}
        FOR JSON PATH
    ) AS {child_relation_name},
    
    -- Include lookup data if exists
    lookup.{lookup_field1},
    lookup.{lookup_field2}
    
FROM {main_table} AS main
LEFT JOIN {lookup_table} AS lookup 
    ON main.{fk_lookup} = lookup.{lookup_pk}
WHERE 
    main.{pk_field} = @{pk_field}
    AND main.is_active = 1
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
```

#### **D) Statistics/Aggregation Query**

```sql
-- ============================================
-- Query: {entity}_stats_summary.sql
-- Purpose: Calculate statistics and aggregations
-- HTTP Method: POST
-- Parameters: @date_from, @date_to, @group_by_field
-- ============================================

SELECT 
    -- Aggregations
    COUNT(DISTINCT main.{pk_field}) AS total_records,
    SUM(child.{numeric_field1}) AS sum_{field1},
    AVG(child.{numeric_field2}) AS avg_{field2},
    MAX(main.{date_field}) AS latest_date,
    MIN(main.{date_field}) AS earliest_date,
    
    -- Distinct counts
    COUNT(DISTINCT child.{category_field}) AS unique_categories,
    
    -- Conditional counts
    SUM(CASE WHEN child.{status_field} = 'completed' THEN 1 ELSE 0 END) AS completed_count,
    SUM(CASE WHEN child.{status_field} = 'pending' THEN 1 ELSE 0 END) AS pending_count,
    
    -- Grouping field (if applicable)
    main.{group_field}
    
FROM {main_table} AS main
INNER JOIN {child_table} AS child 
    ON main.{pk_field} = child.{fk_field}
WHERE 
    main.is_active = 1
    AND (
        @date_from IS NULL 
        OR main.{date_field} >= @date_from
    )
    AND (
        @date_to IS NULL 
        OR main.{date_field} <= DATEADD(DAY, 1, @date_to)
    )
GROUP BY main.{group_field}  -- Remove if no grouping needed
FOR JSON PATH;
```

---

### 3.3 CREATE Query Template

```sql
-- ============================================
-- Query: {entity}_create.sql
-- Purpose: Insert new {entity} with related records
-- HTTP Method: POST
-- Parameters: All required fields + JSON array for child records
-- Transaction: Required
-- ============================================

BEGIN TRANSACTION;
BEGIN TRY

    -- Step 1: Insert main record
    INSERT INTO {main_table} (
        {field1},
        {field2},
        {field3},
        created_at,
        created_by,
        is_active
    )
    VALUES (
        @{field1},
        @{field2},
        @{field3},
        GETDATE(),
        @user_id,  -- From authentication
        1
    );
    
    -- Get generated ID
    DECLARE @new_id {pk_type} = SCOPE_IDENTITY();  -- or @@IDENTITY for non-identity PKs
    
    -- Step 2: Insert child records (if JSON array provided)
    IF @child_records_json IS NOT NULL AND @child_records_json != ''
    BEGIN
        INSERT INTO {child_table} (
            {fk_field},
            {child_field1},
            {child_field2},
            {child_field3},
            created_at
        )
        SELECT 
            @new_id,
            {child_field1},
            {child_field2},
            {child_field3},
            GETDATE()
        FROM OPENJSON(@child_records_json)
        WITH (
            {child_field1} {type1} '$.{json_key1}',
            {child_field2} {type2} '$.{json_key2}',
            {child_field3} {type3} '$.{json_key3}'
        );
    END
    
    -- Step 3: Return the created record with all data
    SELECT 
        main.*,
        (
            SELECT * FROM {child_table} child
            WHERE child.{fk_field} = main.{pk_field}
            FOR JSON PATH
        ) AS {child_relation_name}
    FROM {main_table} AS main
    WHERE main.{pk_field} = @new_id
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    -- Return error details
    SELECT 
        ERROR_NUMBER() AS error_number,
        ERROR_MESSAGE() AS error_message,
        ERROR_LINE() AS error_line
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
END CATCH;
```

---

### 3.4 UPDATE Query Template

```sql
-- ============================================
-- Query: {entity}_update.sql
-- Purpose: Update existing {entity} and related records
-- HTTP Method: POST
-- Parameters: @{pk_field} + all updatable fields + child records JSON
-- Transaction: Required
-- ============================================

BEGIN TRANSACTION;
BEGIN TRY

    -- Step 1: Verify record exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM {main_table} 
        WHERE {pk_field} = @{pk_field} AND is_active = 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 'Record not found' AS error_message FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
        RETURN;
    END
    
    -- Step 2: Update main record
    UPDATE {main_table}
    SET 
        {field1} = @{field1},
        {field2} = @{field2},
        {field3} = @{field3},
        updated_at = GETDATE(),
        updated_by = @user_id
    WHERE {pk_field} = @{pk_field};
    
    -- Step 3: Handle child records
    IF @update_mode = 'replace'
    BEGIN
        -- Delete existing child records
        DELETE FROM {child_table} WHERE {fk_field} = @{pk_field};
        
        -- Insert new child records
        IF @child_records_json IS NOT NULL AND @child_records_json != ''
        BEGIN
            INSERT INTO {child_table} (
                {fk_field},
                {child_field1},
                {child_field2}
            )
            SELECT 
                @{pk_field},
                {child_field1},
                {child_field2}
            FROM OPENJSON(@child_records_json)
            WITH (
                {child_field1} {type1} '$.{json_key1}',
                {child_field2} {type2} '$.{json_key2}'
            );
        END
    END
    ELSE IF @update_mode = 'merge'
    BEGIN
        -- Implement MERGE logic here if needed
        MERGE {child_table} AS target
        USING (
            SELECT 
                {child_field1},
                {child_field2}
            FROM OPENJSON(@child_records_json)
            WITH (
                {child_id} INT '$.id',
                {child_field1} {type1} '$.{json_key1}'
            )
        ) AS source
        ON target.{child_pk} = source.{child_id}
        WHEN MATCHED THEN
            UPDATE SET {child_field1} = source.{child_field1}
        WHEN NOT MATCHED THEN
            INSERT ({fk_field}, {child_field1})
            VALUES (@{pk_field}, source.{child_field1});
    END
    
    -- Step 4: Return updated record
    SELECT 
        main.*,
        (
            SELECT * FROM {child_table} child
            WHERE child.{fk_field} = main.{pk_field}
            FOR JSON PATH
        ) AS {child_relation_name}
    FROM {main_table} AS main
    WHERE main.{pk_field} = @{pk_field}
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    SELECT 
        ERROR_NUMBER() AS error_number,
        ERROR_MESSAGE() AS error_message
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
END CATCH;
```

---

### 3.5 DELETE Query Template

```sql
-- ============================================
-- Query: {entity}_delete.sql
-- Purpose: Delete {entity} (soft or hard delete)
-- HTTP Method: POST
-- Parameters: @{pk_field}, @delete_mode ('soft' or 'hard')
-- Transaction: Required for hard delete
-- ============================================

BEGIN TRANSACTION;
BEGIN TRY

    -- Verify record exists
    IF NOT EXISTS (SELECT 1 FROM {main_table} WHERE {pk_field} = @{pk_field})
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 'Record not found' AS error_message FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
        RETURN;
    END
    
    IF @delete_mode = 'soft'
    BEGIN
        -- Soft delete (recommended)
        UPDATE {main_table}
        SET 
            is_active = 0,
            updated_at = GETDATE(),
            updated_by = @user_id
        WHERE {pk_field} = @{pk_field};
        
        -- Optionally soft delete child records too
        UPDATE {child_table}
        SET is_active = 0, updated_at = GETDATE()
        WHERE {fk_field} = @{pk_field};
    END
    ELSE IF @delete_mode = 'hard'
    BEGIN
        -- Hard delete (permanent)
        -- Child records deleted automatically if ON DELETE CASCADE is set
        -- Otherwise delete manually:
        DELETE FROM {child_table} WHERE {fk_field} = @{pk_field};
        DELETE FROM {main_table} WHERE {pk_field} = @{pk_field};
    END
    
    -- Return success message
    SELECT 
        'success' AS status,
        @{pk_field} AS deleted_id,
        @delete_mode AS delete_mode
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    SELECT 
        ERROR_NUMBER() AS error_number,
        ERROR_MESSAGE() AS error_message
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
END CATCH;
```

---

## ⚙️ PHASE 4: PHP API Files Generation

### 4.1 Folder Structure Convention

```
📁 my_app/
├── 📁 config/
│   ├── database.php          (Connection config)
│   └── cors.php              (CORS headers)
│
├── 📁 {entity_name}/          (One folder per entity)
│   ├── {entity}_read_all.php
│   ├── {entity}_read_filtered.php
│   ├── {entity}_read_by_id.php
│   ├── {entity}_create.php
│   ├── {entity}_update.php
│   ├── {entity}_delete.php
│   └── {entity}_stats.php
│
├── 📁 auth/
│   ├── login.php
│   └── validate_token.php
│
├── .htaccess
└── index.php                 (Protection file)
```

---

### 4.2 PHP File Template (Generic)

```php
<?php
/**
 * ================================================
 * API: {Entity Name} - {Operation}
 * ================================================
 * Purpose: {Brief description}
 * Method: {HTTP_METHOD}
 * Authentication: {Required/Optional}
 * 
 * Request Parameters:
 * - param1 (type): Description
 * - param2 (type): Description
 * 
 * Response Format:
 * {
 *   "success": true,
 *   "data": [...],
 *   "message": "Success message"
 * }
 * 
 * Generated: {timestamp}
 * Source Screen: {screen_file_name}
 * ================================================
 */

// Headers
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: {HTTP_METHOD}');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once __DIR__ . '/../config/database.php';

// Validate HTTP method
$allowed_method = '{HTTP_METHOD}';  // GET, POST, PUT, DELETE
if ($_SERVER['REQUEST_METHOD'] !== $allowed_method) {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error' => 'Method not allowed. Use ' . $allowed_method,
        'received_method' => $_SERVER['REQUEST_METHOD']
    ]);
    exit;
}

try {
    // ===== AUTHENTICATION (Optional - uncomment if needed) =====
    // $headers = getallheaders();
    // if (!isset($headers['Authorization'])) {
    //     throw new Exception('Authorization token required');
    // }
    // $token = str_replace('Bearer ', '', $headers['Authorization']);
    // Validate token here...
    
    // ===== PARAMETER EXTRACTION =====
    $input_method = '{HTTP_METHOD}' === 'GET' ? $_GET : $_POST;
    
    // Extract parameters
    ${param1} = isset($input_method['{param1}']) ? $input_method['{param1}'] : null;
    ${param2} = isset($input_method['{param2}']) ? $input_method['{param2}'] : null;
    ${param3} = isset($input_method['{param3}']) ? $input_method['{param3}'] : null;
    
    // ===== PARAMETER VALIDATION =====
    $errors = [];
    
    if (empty(${required_param})) {
        $errors[] = '{required_param} is required';
    }
    
    if (isset(${numeric_param}) && !is_numeric(${numeric_param})) {
        $errors[] = '{numeric_param} must be a number';
    }
    
    if (isset(${date_param}) && !strtotime(${date_param})) {
        $errors[] = '{date_param} must be a valid date';
    }
    
    if (!empty($errors)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'errors' => $errors
        ]);
        exit;
    }
    
    // ===== SQL QUERY EXECUTION =====
    $query = "
        {SQL_QUERY_HERE}
    ";
    
    // Prepare parameters array
    $params = array(
        ${param1},
        ${param2},
        ${param3}
        // Add more as needed
    );
    
    // Remove null parameters if not needed
    $params = array_filter($params, function($value) {
        return $value !== null;
    });
    
    // Execute query
    $stmt = sqlsrv_query($conn, $query, $params);
    
    if ($stmt === false) {
        $errors = sqlsrv_errors();
        $error_message = 'Database query failed';
        
        if (isset($errors[0]['message'])) {
            $error_message = $errors[0]['message'];
        }
        
        throw new Exception($error_message);
    }
    
    // ===== FETCH RESULTS =====
    $result = [];
    
    while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
        // Handle JSON fields if present
        foreach ($row as $key => $value) {
            if (is_string($value) && (strpos($value, '[') === 0 || strpos($value, '{') === 0)) {
                $row[$key] = json_decode($value, true);
            }
            
            // Handle datetime fields
            if ($value instanceof DateTime) {
                $row[$key] = $value->format('Y-m-d H:i:s');
            }
        }
        
        $result[] = $row;
    }
    
    // ===== RESPONSE =====
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $result,
        'count' => count($result),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    // Error handling
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s'),
        // Include stack trace in development only
        // 'trace' => $e->getTraceAsString()
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} finally {
    // Clean up
    if (isset($stmt) && $stmt !== false) {
        sqlsrv_free_stmt($stmt);
    }
    
    if (isset($conn) && $conn !== false) {
        sqlsrv_close($conn);
    }
}
?>
```

---

### 4.3 Special PHP Templates

#### **A) CREATE with Transaction**

```php
<?php
// ... (same headers and validation as above)

try {
    // BEGIN TRANSACTION
    sqlsrv_begin_transaction($conn);
    
    // Query 1: Insert main record
    $query_main = "INSERT INTO {table} (...) VALUES (...)";
    $stmt_main = sqlsrv_query($conn, $query_main, $params_main);
    
    if ($stmt_main === false) {
        throw new Exception('Failed to insert main record');
    }
    
    // Get inserted ID
    $query_id = "SELECT SCOPE_IDENTITY() AS new_id";
    $stmt_id = sqlsrv_query($conn, $query_id);
    $row_id = sqlsrv_fetch_array($stmt_id, SQLSRV_FETCH_ASSOC);
    $new_id = $row_id['new_id'];
    
    // Query 2: Insert child records (if JSON provided)
    if (!empty($_POST['{child_json_param}'])) {
        $child_json = $_POST['{child_json_param}'];
        
        $query_child = "
            INSERT INTO {child_table} (...)
            SELECT ... FROM OPENJSON(?) WITH (...)
        ";
        
        $stmt_child = sqlsrv_query($conn, $query_child, array($child_json));
        
        if ($stmt_child === false) {
            throw new Exception('Failed to insert child records');
        }
    }
    
    // COMMIT
    sqlsrv_commit($conn);
    
    // Return created record
    echo json_encode([
        'success' => true,
        'message' => 'Record created successfully',
        'id' => $new_id
    ]);
    
} catch (Exception $e) {
    // ROLLBACK on error
    if (isset($conn)) {
        sqlsrv_rollback($conn);
    }
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
```

#### **B) READ with Pagination**

```php
<?php
// ... (same headers)

try {
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $page_size = isset($_GET['page_size']) ? (int)$_GET['page_size'] : 20;
    
    // Validate pagination
    if ($page < 1) $page = 1;
    if ($page_size < 1 || $page_size > 100) $page_size = 20;
    
    // Query with pagination
    $query = "
        SELECT * FROM {table}
        WHERE {conditions}
        ORDER BY {order_field} DESC
        OFFSET (? - 1) * ? ROWS
        FETCH NEXT ? ROWS ONLY
        FOR JSON PATH
    ";
    
    $params = array($page, $page_size, $page_size);
    
    // Execute query
    $stmt = sqlsrv_query($conn, $query, $params);
    
    // Get total count
    $query_count = "SELECT COUNT(*) AS total FROM {table} WHERE {conditions}";
    $stmt_count = sqlsrv_query($conn, $query_count);
    $row_count = sqlsrv_fetch_array($stmt_count, SQLSRV_FETCH_ASSOC);
    $total_records = $row_count['total'];
    $total_pages = ceil($total_records / $page_size);
    
    // Fetch data
    $json_result = '';
    while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
        $json_result .= $row[0];
    }
    
    $data = json_decode($json_result, true);
    
    // Response with pagination metadata
    echo json_encode([
        'success' => true,
        'data' => $data,
        'pagination' => [
            'current_page' => $page,
            'page_size' => $page_size,
            'total_records' => $total_records,
            'total_pages' => $total_pages,
            'has_next' => $page < $total_pages,
            'has_previous' => $page > 1
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
```

#### **C) File Upload Handler**

```php
<?php
// Special template for handling file uploads (images, PDFs, etc.)

header('Content-Type: application/json; charset=UTF-8');
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

try {
    // Validate file upload
    if (!isset($_FILES['{file_field_name}']) || $_FILES['{file_field_name}']['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('File upload failed');
    }
    
    $file = $_FILES['{file_field_name}'];
    
    // Validate file type
    $allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
    if (!in_array($file['type'], $allowed_types)) {
        throw new Exception('Invalid file type. Allowed: JPEG, PNG, GIF, PDF');
    }
    
    // Validate file size (10MB max)
    $max_size = 10 * 1024 * 1024;
    if ($file['size'] > $max_size) {
        throw new Exception('File too large. Max size: 10MB');
    }
    
    // Generate unique filename
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $new_filename = uniqid('{entity}_', true) . '.' . $extension;
    $upload_dir = __DIR__ . '/../uploads/{entity}/';
    
    // Create directory if not exists
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    $upload_path = $upload_dir . $new_filename;
    
    // Move uploaded file
    if (!move_uploaded_file($file['tmp_name'], $upload_path)) {
        throw new Exception('Failed to save file');
    }
    
    // Save file info to database
    $query = "
        INSERT INTO {entity}_files (
            {entity_id}, 
            file_name, 
            file_path, 
            file_size, 
            file_type,
            uploaded_at
        ) VALUES (?, ?, ?, ?, ?, GETDATE())
    ";
    
    $params = array(
        $_POST['{entity_id}'],
        $file['name'],
        'uploads/{entity}/' . $new_filename,
        $file['size'],
        $file['type']
    );
    
    $stmt = sqlsrv_query($conn, $query, $params);
    
    if ($stmt === false) {
        // Delete uploaded file if DB insert fails
        unlink($upload_path);
        throw new Exception('Failed to save file info to database');
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'File uploaded successfully',
        'file' => [
            'name' => $file['name'],
            'path' => 'uploads/{entity}/' . $new_filename,
            'size' => $file['size'],
            'type' => $file['type']
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
```

---

## 💙 PHASE 5: Dart Integration Code Generation

### 5.1 ApiService Class Structure

```dart
// ============================================
// FILE: lib/services/api_service.dart
// PURPOSE: HTTP client for {entity} operations
// GENERATED FROM: {screen_file_name}
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL - CONFIGURE THIS
  static const String baseUrl = 'https://your-domain.com/api';
  
  // Timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Common headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    // Add authentication header if needed
    // 'Authorization': 'Bearer ${getToken()}',
  };
  
  // ==========================================
  // {ENTITY} OPERATIONS
  // ==========================================
  
  /// Fetch all {entity} records
  /// 
  /// Returns: List of {entity} objects
  /// Throws: Exception on error
  Future<Map<String, dynamic>> fetch{EntityCamelCase}List({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_read_all.php?page=$page&page_size=$pageSize'),
        headers: _headers,
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } on TimeoutException {
      throw Exception('Request timeout - check your internet connection');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Search and filter {entity} records
  /// 
  /// Parameters:
  /// - [searchQuery]: Text to search for
  /// - [dateFrom]: Start date filter
  /// - [dateTo]: End date filter
  /// - [status]: Status filter
  /// 
  /// Returns: Filtered list of {entity} objects
  Future<Map<String, dynamic>> fetch{EntityCamelCase}Filtered({
    String? searchQuery,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final body = {
        if (searchQuery != null && searchQuery.isNotEmpty) 
          'search_term': searchQuery,
        if (dateFrom != null) 
          'date_from': _formatDate(dateFrom),
        if (dateTo != null) 
          'date_to': _formatDate(dateTo),
        if (status != null) 
          'status': status,
        'page': page,
        'page_size': pageSize,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_read_filtered.php'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } catch (e) {
      throw Exception('Failed to fetch filtered {entity}: $e');
    }
  }
  
  /// Get single {entity} by ID
  /// 
  /// Parameters:
  /// - [{pkField}]: Primary key value
  /// 
  /// Returns: Single {entity} object
  Future<Map<String, dynamic>> fetch{EntityCamelCase}ById({
    required String {pkField},
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_read_by_id.php'),
        headers: _headers,
        body: json.encode({
          '{pk_field}': {pkField},
        }),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } catch (e) {
      throw Exception('Failed to fetch {entity}: $e');
    }
  }
  
  /// Get {entity} statistics
  /// 
  /// Parameters:
  /// - [dateFrom]: Start date for stats calculation
  /// - [dateTo]: End date for stats calculation
  /// 
  /// Returns: Statistics object
  Future<Map<String, dynamic>> fetch{EntityCamelCase}Stats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final body = {
        if (dateFrom != null) 'date_from': _formatDate(dateFrom),
        if (dateTo != null) 'date_to': _formatDate(dateTo),
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_stats.php'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
  
  /// Create new {entity}
  /// 
  /// Parameters:
  /// - [data]: Map containing all required fields
  /// - [childRecords]: Optional list of child records
  /// 
  /// Returns: Created {entity} object with generated ID
  Future<Map<String, dynamic>> create{EntityCamelCase}({
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? childRecords,
  }) async {
    try {
      final body = {
        ...data,
        if (childRecords != null && childRecords.isNotEmpty)
          '{child_records_json}': json.encode(childRecords),
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_create.php'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } catch (e) {
      throw Exception('Failed to create {entity}: $e');
    }
  }
  
  /// Update existing {entity}
  /// 
  /// Parameters:
  /// - [{pkField}]: Primary key of record to update
  /// - [data]: Map containing fields to update
  /// - [childRecords]: Optional updated child records
  /// - [updateMode]: 'replace' or 'merge' for child records
  /// 
  /// Returns: Updated {entity} object
  Future<Map<String, dynamic>> update{EntityCamelCase}({
    required String {pkField},
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? childRecords,
    String updateMode = 'replace',
  }) async {
    try {
      final body = {
        '{pk_field}': {pkField},
        ...data,
        'update_mode': updateMode,
        if (childRecords != null && childRecords.isNotEmpty)
          '{child_records_json}': json.encode(childRecords),
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_update.php'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } catch (e) {
      throw Exception('Failed to update {entity}: $e');
    }
  }
  
  /// Delete {entity}
  /// 
  /// Parameters:
  /// - [{pkField}]: Primary key of record to delete
  /// - [deleteMode]: 'soft' (recommended) or 'hard' (permanent)
  /// 
  /// Returns: Success status
  Future<Map<String, dynamic>> delete{EntityCamelCase}({
    required String {pkField},
    String deleteMode = 'soft',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/{entity_folder}/{entity}_delete.php'),
        headers: _headers,
        body: json.encode({
          '{pk_field}': {pkField},
          'delete_mode': deleteMode,
        }),
      ).timeout(requestTimeout);
      
      return _handleResponse(response);
      
    } catch (e) {
      throw Exception('Failed to delete {entity}: $e');
    }
  }
  
  // ==========================================
  // HELPER METHODS
  // ==========================================
  
  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Unknown server error');
      }
    } else if (response.statusCode == 404) {
      throw Exception('API endpoint not found');
    } else if (response.statusCode == 405) {
      throw Exception('Method not allowed');
    } else if (response.statusCode == 500) {
      throw Exception('Server error - please try again later');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
  
  /// Format DateTime to SQL date string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Format DateTime to SQL datetime string
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
```

---

### 5.2 Business Logic Layer (Service)

```dart
// ============================================
// FILE: lib/services/{entity}_service.dart
// PURPOSE: Business logic for {entity} operations
// ============================================

import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/{entity}_model.dart'; // Optional: if using model classes

class {EntityCamelCase}Service {
  final ApiService _apiService = ApiService();
  
  // ==========================================
  // PUBLIC METHODS
  // ==========================================
  
  /// Load all {entity} records with pagination
  Future<List<{EntityCamelCase}>> loadAll{EntityCamelCase}({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _apiService.fetch{EntityCamelCase}List(
        page: page,
        pageSize: pageSize,
      );
      
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        
        // Convert to model objects (optional)
        return rawData
            .map((json) => {EntityCamelCase}.fromJson(json))
            .toList();
            
        // OR return as Map list:
        // return rawData.cast<Map<String, dynamic>>();
      } else {
        throw Exception(result['error'] ?? 'Failed to load {entity}');
      }
      
    } catch (e) {
      debugPrint('Error in loadAll{EntityCamelCase}: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  /// Search {entity} with filters
  Future<List<{EntityCamelCase}>> search{EntityCamelCase}({
    String? searchQuery,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
  }) async {
    try {
      final result = await _apiService.fetch{EntityCamelCase}Filtered(
        searchQuery: searchQuery,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
      );
      
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((json) => {EntityCamelCase}.fromJson(json))
            .toList();
      } else {
        throw Exception(result['error'] ?? 'Search failed');
      }
      
    } catch (e) {
      debugPrint('Error in search{EntityCamelCase}: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  /// Get {entity} details by ID
  Future<{EntityCamelCase}> get{EntityCamelCase}Details(String id) async {
    try {
      final result = await _apiService.fetch{EntityCamelCase}ById(
        {pkField}: id,
      );
      
      if (result['success'] == true && result['data'] != null) {
        return {EntityCamelCase}.fromJson(result['data']);
      } else {
        throw Exception(result['error'] ?? '{Entity} not found');
      }
      
    } catch (e) {
      debugPrint('Error in get{EntityCamelCase}Details: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  /// Calculate statistics
  Future<Map<String, dynamic>> calculate{EntityCamelCase}Stats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final result = await _apiService.fetch{EntityCamelCase}Stats(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      
      if (result['success'] == true && result['data'] != null) {
        return result['data'];
      } else {
        throw Exception(result['error'] ?? 'Failed to calculate statistics');
      }
      
    } catch (e) {
      debugPrint('Error in calculate{EntityCamelCase}Stats: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  /// Create new {entity}
  Future<{EntityCamelCase}> add{EntityCamelCase}({
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? childRecords,
  }) async {
    try {
      // Validate data before sending
      _validateCreate(data);
      
      final result = await _apiService.create{EntityCamelCase}(
        data: data,
        childRecords: childRecords,
      );
      
      if (result['success'] == true && result['data'] != null) {
        return {EntityCamelCase}.fromJson(result['data']);
      } else {
        throw Exception(result['error'] ?? 'Failed to create {entity}');
      }
      
    } catch (e) {
      debugPrint('Error in add{EntityCamelCase}: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  /// Update existing {entity}
  Future<{EntityCamelCase}> modify{EntityCamelCase}({
    required String id,
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? childRecords,
  }) async {
    try {
      // Validate data
      _validateUpdate(data);
      
      final result = await _apiService.update{EntityCamelCase}(
        {pkField}: id,
        data: data,
        childRecords: childRecords,
      );
      
      if (result['success'] == true && result['data'] != null) {
        return {EntityCamelCase}.fromJson(result['data']);
      } else {
        throw Exception(result['error'] ?? 'Failed to update {entity}');
      }
      
    } catch (e) {
      debugPrint('Error in modify{EntityCamelCase}: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  /// Delete {entity}
  Future<bool> remove{EntityCamelCase}(String id, {bool permanent = false}) async {
    try {
      final result = await _apiService.delete{EntityCamelCase}(
        {pkField}: id,
        deleteMode: permanent ? 'hard' : 'soft',
      );
      
      return result['success'] == true;
      
    } catch (e) {
      debugPrint('Error in remove{EntityCamelCase}: $e');
      _handleError(e);
      rethrow;
    }
  }
  
  // ==========================================
  // VALIDATION METHODS
  // ==========================================
  
  void _validateCreate(Map<String, dynamic> data) {
    // Add validation logic here
    if (data['{required_field}'] == null || data['{required_field}'].toString().isEmpty) {
      throw Exception('{Required field} is required');
    }
    
    // Add more validation rules
  }
  
  void _validateUpdate(Map<String, dynamic> data) {
    // Add validation logic here
  }
  
  // ==========================================
  // ERROR HANDLING
  // ==========================================
  
  void _handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } else if (errorString.contains('network')) {
      throw Exception('خطأ في الشبكة - تحقق من الاتصال');
    } else if (errorString.contains('socket')) {
      throw Exception('فشل الاتصال بالخادم');
    } else if (errorString.contains('format')) {
      throw Exception('خطأ في صيغة البيانات');
    }
    // Error is already an Exception, rethrow it
  }
}
```

---

### 5.3 Optional: Model Class Generation

```dart
// ============================================
// FILE: lib/models/{entity}_model.dart
// PURPOSE: Data model for {entity}
// ============================================

class {EntityCamelCase} {
  final String {pkField};
  final String {field1};
  final int {field2};
  final double {field3};
  final DateTime {dateField};
  final List<{ChildEntity}>? {childRelation};
  
  {EntityCamelCase}({
    required this.{pkField},
    required this.{field1},
    required this.{field2},
    required this.{field3},
    required this.{dateField},
    this.{childRelation},
  });
  
  /// Create from JSON
  factory {EntityCamelCase}.fromJson(Map<String, dynamic> json) {
    return {EntityCamelCase}(
      {pkField}: json['{pk_field}'] as String,
      {field1}: json['{field1}'] as String? ?? '',
      {field2}: json['{field2}'] as int? ?? 0,
      {field3}: (json['{field3}'] as num?)?.toDouble() ?? 0.0,
      {dateField}: DateTime.parse(json['{date_field}'] as String),
      {childRelation}: json['{child_relation}'] != null
          ? (json['{child_relation}'] as List)
              .map((item) => {ChildEntity}.fromJson(item))
              .toList()
          : null,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '{pk_field}': {pkField},
      '{field1}': {field1},
      '{field2}': {field2},
      '{field3}': {field3},
      '{date_field}': {dateField}.toIso8601String(),
      if ({childRelation} != null)
        '{child_relation}': {childRelation}!.map((item) => item.toJson()).toList(),
    };
  }
  
  /// Create a copy with modified fields
  {EntityCamelCase} copyWith({
    String? {pkField},
    String? {field1},
    int? {field2},
    double? {field3},
    DateTime? {dateField},
    List<{ChildEntity}>? {childRelation},
  }) {
    return {EntityCamelCase}(
      {pkField}: {pkField} ?? this.{pkField},
      {field1}: {field1} ?? this.{field1},
      {field2}: {field2} ?? this.{field2},
      {field3}: {field3} ?? this.{field3},
      {dateField}: {dateField} ?? this.{dateField},
      {childRelation}: {childRelation} ?? this.{childRelation},
    );
  }
  
  @override
  String toString() {
    return '{EntityCamelCase}({pkField}: ${pkField}, {field1}: ${field1})';
  }
}

/// Child entity model
class {ChildEntity} {
  final int id;
  final String {childField1};
  final double {childField2};
  
  {ChildEntity}({
    required this.id,
    required this.{childField1},
    required this.{childField2},
  });
  
  factory {ChildEntity}.fromJson(Map<String, dynamic> json) {
    return {ChildEntity}(
      id: json['id'] as int,
      {childField1}: json['{child_field1}'] as String,
      {childField2}: (json['{child_field2}'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '{child_field1}': {childField1},
      '{child_field2}': {childField2},
    };
  }
}
```

---

## 📋 PHASE 6: Output Organization

### 6.1 Output Structure

```json
{
  "analysis": {
    "screen_file": "{screen_file_name}",
    "entity_name": "{detected_entity_name}",
    "operations_detected": [
      {"type": "CREATE", "method_name": "_add{Entity}"},
      {"type": "READ", "method_name": "_get{Entity}"},
      {"type": "UPDATE", "method_name": "_edit{Entity}"},
      {"type": "DELETE", "method_name": "_delete{Entity}"},
      {"type": "STATS", "method_name": "_calculateStats"}
    ],
    "data_structure": {
      "main_entity": {
        "fields": [
          {"name": "{field1}", "type": "string"},
          {"name": "{field2}", "type": "int"}
        ]
      },
      "nested_entities": [
        {
          "name": "{child_entity}",
          "relationship": "one_to_many",
          "fields": [...]
        }
      ]
    },
    "filters_detected": {
      "search": true,
      "date_range": true,
      "status": false
    }
  },
  
  "database": {
    "schema_file": "{entity}_schema.sql",
    "tables": [
      {
        "name": "{main_table}",
        "primary_key": "{pk_field}",
        "fields": [...]
      },
      {
        "name": "{child_table}",
        "foreign_keys": [
          {"field": "{fk_field}", "references": "{main_table}({pk_field})"}
        ]
      }
    ],
    "indexes": [
      "IDX_{table}_{field1}",
      "IDX_{table}_{date_field}"
    ]
  },
  
  "sql_queries": {
    "read_all": "{entity}_read_all.sql",
    "read_filtered": "{entity}_read_filtered.sql",
    "read_by_id": "{entity}_read_by_id.sql",
    "stats": "{entity}_stats.sql",
    "create": "{entity}_create.sql",
    "update": "{entity}_update.sql",
    "delete": "{entity}_delete.sql"
  },
  
  "php_apis": {
    "folder": "{entity}",
    "files": [
      "{entity}_read_all.php",
      "{entity}_read_filtered.php",
      "{entity}_read_by_id.php",
      "{entity}_create.php",
      "{entity}_update.php",
      "{entity}_delete.php",
      "{entity}_stats.php"
    ]
  },
  
  "dart_code": {
    "api_service_methods": "Append to existing ApiService class",
    "business_logic_service": "{entity}_service.dart",
    "model_class": "{entity}_model.dart (optional)"
  },
  
  "integration_guide": {
    "steps": [
      "1. Run {entity}_schema.sql in SQL Server",
      "2. Upload PHP files to server/{entity}/",
      "3. Add ApiService methods to existing class",
      "4. Create {entity}_service.dart in lib/services/",
      "5. (Optional) Create model class",
      "6. Update screen to use new service"
    ]
  }
}
```

---

### 6.2 Delivery Format

**For each entity detected, generate:**

1. **📄 `{entity}_analysis.md`** - Detailed analysis report
2. **🗄️ `{entity}_schema.sql`** - Complete database schema
3. **📁 `queries/`** folder containing:
   - `{entity}_read_all.sql`
   - `{entity}_read_filtered.sql`
   - `{entity}_read_by_id.sql`
   - `{entity}_stats.sql`
   - `{entity}_create.sql`
   - `{entity}_update.sql`
   - `{entity}_delete.sql`
4. **📁 `php_apis/`** folder containing:
   - Complete PHP files ready to upload
5. **💙 `dart_integration/`** folder containing:
   - `api_service_additions.dart` - Methods to add
   - `{entity}_service.dart` - Complete business logic
   - `{entity}_model.dart` - Model class (optional)
6. **📖 `integration_guide.md`** - Step-by-step integration instructions

---

## 🎯 Usage Instructions for Engineer

### How to use this system:

```markdown
I have a Flutter screen file. Please apply Reverse Context Engineering.

**Screen File:** {screen_name}.dart

**Content:**
[Paste your entire Flutter screen code here]

**Additional Requirements (Optional):**
- Authentication: [Yes/No]
- Soft Delete: [Yes/No]
- Audit Trail: [Yes/No]
- File Upload Support: [Yes/No]
- Full-Text Search: [Yes/No]
- Custom Business Rules: [Describe any special logic]

Please generate:
1. Complete database schema
2. All necessary SQL queries
3. PHP API files
4. Dart integration code
5. Integration guide
```

---

## ✅ Quality Checklist for AI

Before delivering the generated code, verify:

### Database Schema:
- [ ] All field types are appropriate
- [ ] Primary keys are defined
- [ ] Foreign key relationships are correct
- [ ] Indexes are created for filter/search fields
- [ ] Audit fields are included
- [ ] Constraints are logical

### SQL Queries:
- [ ] Queries match detected operations
- [ ] Parameters are in correct order
- [ ] FOR JSON PATH is used for complex data
- [ ] Pagination is implemented where needed
- [ ] Error handling is included
- [ ] Transactions are used for multi-table operations

### PHP APIs:
- [ ] HTTP methods match operation types (GET for read, POST for others)
- [ ] All parameters are validated
- [ ] SQL injection protection via parameterized queries
- [ ] Transactions are properly handled (BEGIN, COMMIT, ROLLBACK)
- [ ] Error messages are informative but not exposing sensitive info
- [ ] JSON responses follow consistent structure
- [ ] CORS headers are properly set
- [ ] File upload validation (if applicable)
- [ ] Authentication checks (if required)
- [ ] DateTime objects are formatted correctly

### Dart Code:
- [ ] Method names follow camelCase convention
- [ ] Parameter types are correct
- [ ] Timeout handling is implemented
- [ ] Error messages are user-friendly and localized
- [ ] Null safety is respected
- [ ] HTTP methods match backend expectations
- [ ] JSON encoding/decoding is correct
- [ ] Model classes have proper fromJson/toJson methods

### Integration:
- [ ] All file paths are correct and consistent
- [ ] Naming conventions are uniform across all layers
- [ ] Foreign key relationships match between layers
- [ ] API endpoints match between Dart and PHP
- [ ] Parameter names match between Dart and PHP
- [ ] Response structures are consistent

---

## 🔧 Advanced Features & Customizations

### Feature 1: Authentication Integration

If authentication is required, add to PHP files:

```php
// Add at the beginning of each PHP file after headers
require_once __DIR__ . '/../auth/validate_token.php';

$headers = getallheaders();
if (!isset($headers['Authorization'])) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'Authentication required',
        'code' => 'AUTH_REQUIRED'
    ]);
    exit;
}

$token = str_replace('Bearer ', '', $headers['Authorization']);
$user = validateToken($token); // Implement this function

if (!$user) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'Invalid or expired token',
        'code' => 'AUTH_INVALID'
    ]);
    exit;
}

// Store user ID for audit fields
$current_user_id = $user['user_id'];
```

And in Dart ApiService:

```dart
class ApiService {
  String? _authToken;
  
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
}
```

---

### Feature 2: Caching Layer

Add to Dart service:

```dart
class {EntityCamelCase}Service {
  // Cache storage
  final Map<String, CachedData> _cache = {};
  final Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Load with cache
  Future<List<{EntityCamelCase}>> loadAll{EntityCamelCase}Cached() async {
    final cacheKey = 'all_{entity}';
    
    // Check cache
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now().isBefore(cached.expiryTime)) {
        debugPrint('Loading from cache: $cacheKey');
        return cached.data as List<{EntityCamelCase}>;
      }
    }
    
    // Fetch from API
    final data = await loadAll{EntityCamelCase}();
    
    // Store in cache
    _cache[cacheKey] = CachedData(
      data: data,
      expiryTime: DateTime.now().add(_cacheExpiry),
    );
    
    return data;
  }
  
  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
  
  /// Clear specific cache entry
  void clearCacheFor(String key) {
    _cache.remove(key);
  }
}

class CachedData {
  final dynamic data;
  final DateTime expiryTime;
  
  CachedData({required this.data, required this.expiryTime});
}
```

---

### Feature 3: Batch Operations

For bulk operations, add to SQL:

```sql
-- ============================================
-- Query: {entity}_batch_create.sql
-- Purpose: Insert multiple {entity} records at once
-- ============================================

BEGIN TRANSACTION;
BEGIN TRY

    -- Insert multiple records from JSON array
    INSERT INTO {main_table} (
        {field1},
        {field2},
        {field3},
        created_at,
        created_by
    )
    SELECT 
        {field1},
        {field2},
        {field3},
        GETDATE(),
        @user_id
    FROM OPENJSON(@records_json)
    WITH (
        {field1} {type1} '$.{field1}',
        {field2} {type2} '$.{field2}',
        {field3} {type3} '$.{field3}'
    );
    
    -- Return inserted records
    SELECT 
        *
    FROM {main_table}
    WHERE created_at >= DATEADD(SECOND, -1, GETDATE())
    FOR JSON PATH;
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    SELECT 
        ERROR_NUMBER() AS error_number,
        ERROR_MESSAGE() AS error_message
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    
END CATCH;
```

---

### Feature 4: Export to Excel/PDF

Add to PHP:

```php
<?php
/**
 * Export {entity} data to Excel
 */

require_once __DIR__ . '/../config/database.php';

// For Excel export, consider using PHPSpreadsheet library
// This is a CSV export example

header('Content-Type: text/csv; charset=UTF-8');
header('Content-Disposition: attachment; filename="{entity}_export_' . date('Y-m-d_His') . '.csv"');

try {
    // Get filters from GET parameters
    $date_from = $_GET['date_from'] ?? null;
    $date_to = $_GET['date_to'] ?? null;
    
    $query = "
        SELECT 
            {field1},
            {field2},
            {field3},
            {date_field}
        FROM {main_table}
        WHERE 
            is_active = 1
            AND (? IS NULL OR {date_field} >= ?)
            AND (? IS NULL OR {date_field} <= ?)
        ORDER BY {date_field} DESC
    ";
    
    $params = array($date_from, $date_from, $date_to, $date_to);
    $stmt = sqlsrv_query($conn, $query, $params);
    
    // Output CSV header
    $output = fopen('php://output', 'w');
    fputcsv($output, array('{Field1}', '{Field2}', '{Field3}', '{Date}'));
    
    // Output data rows
    while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
        // Format dates
        if ($row['{date_field}'] instanceof DateTime) {
            $row['{date_field}'] = $row['{date_field}']->format('Y-m-d H:i:s');
        }
        
        fputcsv($output, $row);
    }
    
    fclose($output);
    
} catch (Exception $e) {
    http_response_code(500);
    echo 'Error: ' . $e->getMessage();
}

sqlsrv_free_stmt($stmt);
sqlsrv_close($conn);
?>
```

---

### Feature 5: Real-time Notifications

Add WebSocket support or polling mechanism:

```dart
// In Dart service
class {EntityCamelCase}Service {
  Timer? _pollingTimer;
  final _changesController = StreamController<List<{EntityCamelCase}>>.broadcast();
  
  Stream<List<{EntityCamelCase}>> get changesStream => _changesController.stream;
  
  /// Start polling for changes every X seconds
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(interval, (timer) async {
      try {
        final data = await loadAll{EntityCamelCase}();
        _changesController.add(data);
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }
  
  void stopPolling() {
    _pollingTimer?.cancel();
  }
  
  void dispose() {
    stopPolling();
    _changesController.close();
  }
}
```

---

### Feature 6: Offline Support

Add local database caching:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseHelper {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), '{entity}_local.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE {entity}_cache (
            {pk_field} TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
  
  /// Save to local database
  Future<void> saveLocally({EntityCamelCase} item) async {
    final db = await database;
    await db.insert(
      '{entity}_cache',
      {
        '{pk_field}': item.{pkField},
        'data': json.encode(item.toJson()),
        'synced': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Load from local database
  Future<List<{EntityCamelCase}>> loadLocally() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('{entity}_cache');
    
    return maps.map((map) {
      final data = json.decode(map['data']);
      return {EntityCamelCase}.fromJson(data);
    }).toList();
  }
  
  /// Sync local changes to server
  Future<void> syncToServer(ApiService apiService) async {
    final db = await database;
    final unsynced = await db.query(
      '{entity}_cache',
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    for (var record in unsynced) {
      try {
        final data = json.decode(record['data']);
        await apiService.create{EntityCamelCase}(data: data);
        
        // Mark as synced
        await db.update(
          '{entity}_cache',
          {'synced': 1},
          where: '{pk_field} = ?',
          whereArgs: [record['{pk_field}']],
        );
      } catch (e) {
        debugPrint('Sync error for ${record['{pk_field}']}: $e');
      }
    }
  }
}
```

---

### Feature 7: Data Validation Rules

Add comprehensive validation:

```dart
class {EntityCamelCase}Validator {
  static String? validate{Field1}(String? value) {
    if (value == null || value.isEmpty) {
      return '{Field1} is required';
    }
    if (value.length < 3) {
      return '{Field1} must be at least 3 characters';
    }
    if (value.length > 100) {
      return '{Field1} cannot exceed 100 characters';
    }
    return null;
  }
  
  static String? validate{NumericField}(String? value) {
    if (value == null || value.isEmpty) {
      return '{NumericField} is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return '{NumericField} cannot be negative';
    }
    if (number > 1000000) {
      return '{NumericField} is too large';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
  
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Both dates are required';
    }
    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }
    return null;
  }
  
  /// Validate entire entity
  static Map<String, String> validateEntity(Map<String, dynamic> data) {
    Map<String, String> errors = {};
    
    final field1Error = validate{Field1}(data['{field1}']);
    if (field1Error != null) errors['{field1}'] = field1Error;
    
    final field2Error = validate{NumericField}(data['{field2}']?.toString());
    if (field2Error != null) errors['{field2}'] = field2Error;
    
    // Add more validations
    
    return errors;
  }
}
```

---

## 🚀 Performance Optimization Tips

### Database Level:

```sql
-- Add computed columns for frequently calculated values
ALTER TABLE {main_table}
ADD {computed_field} AS (
    -- Calculation expression
) PERSISTED;

-- Add filtered index for common queries
CREATE INDEX IDX_{table}_active_recent
ON {main_table}({date_field}, {status_field})
WHERE is_active = 1 AND {date_field} >= DATEADD(MONTH, -3, GETDATE());

-- Use table partitioning for large tables
CREATE PARTITION FUNCTION PF_{table}_date(DATE)
AS RANGE RIGHT FOR VALUES 
('2023-01-01', '2023-06-01', '2024-01-01', '2024-06-01', '2025-01-01');

CREATE PARTITION SCHEME PS_{table}_date
AS PARTITION PF_{table}_date
ALL TO ([PRIMARY]);

-- Create table on partition scheme
CREATE TABLE {main_table} (
    -- columns
) ON PS_{table}_date({date_field});
```

### PHP Level:

```php
// Enable output compression
ob_start('ob_gzhandler');

// Use prepared statement caching
$stmt = sqlsrv_prepare($conn, $query, $params);

// Implement query result caching
$cache_key = md5($query . serialize($params));
$cache_file = __DIR__ . '/../cache/' . $cache_key . '.json';

if (file_exists($cache_file) && (time() - filemtime($cache_file)) < 300) {
    // Use cached result (5 minutes)
    echo file_get_contents($cache_file);
    exit;
}

// Execute query and cache result
$result = /* query execution */;
file_put_contents($cache_file, json_encode($result));
```

### Dart Level:

```dart
// Use compute for heavy processing
import 'package:flutter/foundation.dart';

Future<List<{EntityCamelCase}>> parseInBackground(String jsonString) async {
  return await compute(_parseJson, jsonString);
}

List<{EntityCamelCase}> _parseJson(String jsonString) {
  final List<dynamic> list = json.decode(jsonString);
  return list.map((item) => {EntityCamelCase}.fromJson(item)).toList();
}

// Implement lazy loading for lists
class LazyLoadedList extends StatefulWidget {
  @override
  State<LazyLoadedList> createState() => _LazyLoadedListState();
}

class _LazyLoadedListState extends State<LazyLoadedList> {
  final ScrollController _scrollController = ScrollController();
  List<{EntityCamelCase}> _items = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }
  
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newItems = await service.loadAll{EntityCamelCase}(
        page: _currentPage,
        pageSize: 20,
      );
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

## 📊 Monitoring & Logging

### Add logging to PHP:

```php
<?php
function logApiRequest($endpoint, $method, $params, $response, $duration) {
    $log_entry = [
        'timestamp' => date('Y-m-d H:i:s'),
        'endpoint' => $endpoint,
        'method' => $method,
        'params' => $params,
        'response_status' => $response['success'] ? 'success' : 'error',
        'duration_ms' => round($duration * 1000, 2),
        'ip_address' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
    ];
    
    $log_file = __DIR__ . '/../logs/api_' . date('Y-m-d') . '.log';
    file_put_contents(
        $log_file,
        json_encode($log_entry) . PHP_EOL,
        FILE_APPEND
    );
}

// Usage in API file
$start_time = microtime(true);

try {
    // API logic here
    $response = ['success' => true, 'data' => $result];
    echo json_encode($response);
    
} catch (Exception $e) {
    $response = ['success' => false, 'error' => $e->getMessage()];
    echo json_encode($response);
    
} finally {
    $duration = microtime(true) - $start_time;
    logApiRequest($_SERVER['PHP_SELF'], $_SERVER['REQUEST_METHOD'], $_POST, $response, $duration);
}
?>
```

---

## 🎓 Final Notes for Engineer

### Best Practices:

1. **Always test generated code** in development environment first
2. **Review SQL queries** for performance before production
3. **Implement proper error handling** at all layers
4. **Use version control** to track changes
5. **Document any customizations** you make to generated code
6. **Set up automated backups** before deploying
7. **Monitor API performance** and optimize slow endpoints
8. **Implement rate limiting** to prevent abuse
9. **Use HTTPS** in production for all API calls
10. **Keep sensitive data encrypted** (passwords, tokens, etc.)

### Security Checklist:

- [ ] SQL injection protection (parameterized queries)
- [ ] XSS protection (input sanitization)
- [ ] CSRF protection (tokens for state-changing operations)
- [ ] Authentication on sensitive endpoints
- [ ] Rate limiting implemented
- [ ] Input validation on both client and server
- [ ] Secure password storage (hashing)
- [ ] HTTPS enforced
- [ ] Error messages don't expose sensitive info
- [ ] File upload restrictions (type, size, location)

---

## 🎯 Example Usage

To use this system, provide:

```
Apply Reverse Context Engineering to the following Flutter screen:

[Paste sales_screen.dart or any other screen]

Generate complete backend infrastructure.
```

The AI will then deliver all SQL schemas, queries, PHP APIs, and Dart integration code automatically.

---

**End of Reverse Context Engineering System Documentation**
```

---

## 📝 Summary

This comprehensive markdown file provides:

✅ **Complete workflow** from Flutter screen analysis to full backend generation  
✅ **Generic templates** that work for any entity/screen  
✅ **SQL Server specific** queries and patterns  
✅ **Production-ready PHP** with error handling, transactions, and security  
✅ **Clean Dart code** with proper architecture (API layer + Business logic)  
✅ **Advanced features** (caching, offline support, batch operations, validation)  
✅ **Performance optimization** tips for all layers  
✅ **Security best practices** and monitoring  
✅ **Quality checklists** to ensure nothing is missed
