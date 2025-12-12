import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class ExtrusionApiService {
  static const Duration _requestTimeout = Duration(seconds: 30);
  static Future<http.Response> _onTimeout() {
    throw TimeoutException('La requÃªte a dÃ©passÃ© le dÃ©lai autorisÃ©.');
  }

  // ==========================================
  // CONFIGURATION
  // ==========================================
  static Future<String> _ensureBaseUrl() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }
    return ApiServices.baseUrl!;
  }

  // Timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  // Common headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // ==========================================
  // PUBLIC API METHODS - ARTICLES STOCK
  // ==========================================

  /// Load all articles stock with pagination
  Future<List<Map<String, dynamic>>> getAllArticlesStock({
    int page = 1,
    int pageSize = 50,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/articles/articles_stock/get_all.php')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'page_size': pageSize.toString(),
            },
          );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((article) => Map<String, dynamic>.from(article))
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل تحميل المواد');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getAllArticlesStock: $e');
      _handleError(e);
      rethrow;
    }
  }

  // ==========================================
  // EXTRUSION API METHODS
  // ==========================================

  /// Create a new extrusion order with all related data
  ///
  /// Parameters:
  /// - [extrusionData]: Map containing header, production, arrets, and culot
  ///
  /// Expected structure:
  /// {
  ///   "header": {
  ///     "numero": "EXT001",
  ///     "date": "2025-11-30",
  ///     "horaire": "Morning",
  ///     "equipe": 1,
  ///     "conducteur": "Ahmed",
  ///     "dressage": "Mohamed",
  ///     "presse": 1
  ///   },
  ///   "production": [...],
  ///   "arrets": [...],
  ///   "culot": {...}
  /// }
  Future<Map<String, dynamic>> createExtrusion(
    Map<String, dynamic> extrusionData,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/extrusion/create.php');

      final response = await http
          .post(uri, headers: _headers, body: json.encode(extrusionData))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل إنشاء أمر الإنتاج');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in createExtrusion: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Get all extrusion orders with complete data
  ///
  /// Returns: List of extrusions with production, arrets, and culot
  Future<List<Map<String, dynamic>>> getAllExtrusions() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/extrusion/get_all.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((extrusion) => Map<String, dynamic>.from(extrusion))
            .toList();
      } else {
        throw Exception(result['message'] ?? 'فشل تحميل أوامر الإنتاج');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getAllExtrusions: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Get a specific extrusion order by numero
  ///
  /// Parameters:
  /// - [numero]: The extrusion order numero (e.g., "EXT001")
  Future<Map<String, dynamic>> getExtrusionByRef(String numero) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/extrusion/get_by_ref.php',
      ).replace(queryParameters: {'numero': numero});

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      } else {
        throw Exception(result['message'] ?? 'فشل تحميل أمر الإنتاج');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getExtrusionByRef: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update an existing extrusion order
  ///
  /// Parameters:
  /// - [extrusionData]: Complete extrusion data with header, production, arrets, culot
  ///
  /// Note: Does NOT update item status. Use updateProductionItemStatus for that.
  Future<Map<String, dynamic>> updateExtrusion(
    Map<String, dynamic> extrusionData,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/extrusion/update.php');

      final response = await http
          .post(uri, headers: _headers, body: json.encode(extrusionData))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل تحديث أمر الإنتاج');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in updateExtrusion: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Delete an extrusion order
  ///
  /// Parameters:
  /// - [numero]: The extrusion numero to delete
  ///
  /// Note: Automatically rolls back inventory if any completed items exist
  Future<bool> deleteExtrusion(String numero) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/extrusion/delete.php',
      ).replace(queryParameters: {'numero': numero});

      final response = await http
          .delete(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return true;
      } else {
        throw Exception(result['message'] ?? 'فشل حذف أمر الإنتاج');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in deleteExtrusion: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update the status of a production item and sync with inventory
  ///
  /// Parameters:
  /// - [productionId]: The ID of the production item
  /// - [oldStatus]: The previous status ('in_progress' or 'completed')
  /// - [newStatus]: The new status ('in_progress' or 'completed')
  /// - [itemData]: Complete item data for inventory calculations
  ///
  /// Required itemData fields:
  /// - ref: Product reference
  /// - prut_kg: Raw weight in kg
  /// - nbr_barres: Number of bars produced
  /// - p_barre_reel: Actual weight per bar
  /// - net_kg: Net weight
  /// - etirage_kg: Etirage waste in kg
  /// - culot_kg: Culot waste in kg
  /// - CU_EXTRUSION: Unit cost of extrusion
  /// - product_name: Product name
  ///
  Future<Map<String, dynamic>> updateProductionItemStatus({
    required int productionId,
    required String oldStatus,
    required String newStatus,
    required Map<String, dynamic> itemData,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/extrusion/update_status.php');

      final body = {
        'production_id': productionId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'item_data': itemData,
      };

      final response = await http
          .post(uri, headers: _headers, body: json.encode(body))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل تحديث حالة العنصر');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in updateProductionItemStatus: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Create a single production item
  ///
  /// Parameters:
  /// - [extrusionId]: The ID of the parent extrusion order
  /// - [itemData]: Complete item data to be saved
  ///
  /// Returns: Map with success status and new item ID
  Future<Map<String, dynamic>> createProductionItem({
    required int extrusionId,
    required Map<String, dynamic> itemData,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/extrusion/insert_into_production_data_extrusion.php',
      );

      final body = {
        'operation': 'create',
        'extrusion_id': extrusionId,
        ...itemData, // Spread all item data
      };

      final response = await http
          .post(uri, headers: _headers, body: json.encode(body))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل إنشاء العنصر');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in createProductionItem: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Retrieve active articles for dropdowns.
  /// Returns list with 'ref_code' and 'product_name' fields.
  static Future<List<Map<String, dynamic>>> fetchArticles() async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse('$baseUrl/api/articles/articles_read_all.php');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    final data = parsed['data'];

    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_normalizeArticle)
        .toList();
  }

  /// Normalize article data to use consistent field names.
  /// Maps 'Référence' to 'ref_code' and 'Désignation' to 'product_name'.
  static Map<String, dynamic> _normalizeArticle(Map<String, dynamic> article) {
    final reference = article['Référence'] ?? '';
    final designation = article['Désignation'] ?? '';

    return {
      ...article,
      'ref_code': reference, // For dropdown value
      'product_name': designation, // For display and auto-fill
      'Poids': _toDouble(article['Poids']),
      'Price': _toDouble(article['Price']),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Update a single production item
  ///
  /// Parameters:
  /// - [productionId]: The ID of the production item to update
  /// - [extrusionId]: The ID of the parent extrusion order
  /// - [itemData]: Complete item data to be updated
  ///
  /// Returns: Map with success status and updated item ID
  Future<Map<String, dynamic>> updateProductionItem({
    required int productionId,
    required int extrusionId,
    required Map<String, dynamic> itemData,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/extrusion/insert_into_production_data_extrusion.php',
      );

      final body = {
        'operation': 'update',
        'id': productionId,
        'extrusion_id': extrusionId,
        ...itemData, // Spread all item data
      };

      final response = await http
          .post(uri, headers: _headers, body: json.encode(body))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل تحديث العنصر');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in updateProductionItem: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Delete a single production item
  ///
  /// Parameters:
  /// - [productionId]: The ID of the production item to delete
  /// - [extrusionId]: The ID of the parent extrusion order
  ///
  /// Returns: Map with success status
  ///
  /// Note: Cannot delete completed items
  Future<Map<String, dynamic>> deleteProductionItem({
    required int productionId,
    required int extrusionId,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/extrusion/insert_into_production_data_extrusion.php',
      );

      final body = {
        'operation': 'delete',
        'id': productionId,
        'extrusion_id': extrusionId,
      };

      final response = await http
          .post(uri, headers: _headers, body: json.encode(body))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل حذف العنصر');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in deleteProductionItem: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Save a single production item (backward compatibility - uses create)
  ///
  /// Parameters:
  /// - [extrusionId]: The ID of the parent extrusion order
  /// - [itemData]: Complete item data to be saved
  ///
  /// Returns: Map with success status and new item ID
  @Deprecated('Use createProductionItem instead')
  Future<Map<String, dynamic>> saveProductionItem({
    required int extrusionId,
    required Map<String, dynamic> itemData,
  }) async {
    return createProductionItem(extrusionId: extrusionId, itemData: itemData);
  }

  // ==========================================
  // COSTS API METHODS
  // ==========================================

  Future<Map<String, dynamic>> getCosts() async {
    final baseUrl = await _ensureBaseUrl();
    final String apiUrl = "$baseUrl/api/costs/costs_api.php";

    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server Error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Error: $e"};
    }
  }

  /// Get the next numero for a new extrusion order
  ///
  /// Format: EX-YY-MM-NNNNN
  /// - EX: Operation prefix
  /// - YY: Current year (last 2 digits)
  /// - MM: Current month
  /// - NNNNN: Sequential number from database
  ///
  /// Returns: Map with next_numero, year, month, and sequence
  Future<String> getNextNumero() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/extrusion/get_next_numero.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return result['data']['next_numero'] as String;
      } else {
        throw Exception(
          result['message'] ?? 'فشل الحصول على رقم الفاتورة التالي',
        );
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getNextNumero: $e');
      // Fallback: generate locally if API fails
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      return 'EX-$year-$month-00001';
    }
  }

  // ==========================================
  // HTTP RESPONSE HANDLING
  // ==========================================

  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
          // Check for errors array or single error
          if (data['errors'] != null && data['errors'] is List) {
            final errors = (data['errors'] as List).join(', ');
            throw Exception(errors);
          } else {
            throw Exception(
              data['message'] ?? data['error'] ?? 'خطأ غير معروف من الخادم',
            );
          }
        }
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('فشل تحليل البيانات من الخادم');
      }
    } else if (response.statusCode == 404) {
      throw Exception('API endpoint not found - تحقق من عنوان الخادم');
    } else if (response.statusCode == 405) {
      throw Exception('طريقة الطلب غير مسموحة');
    } else if (response.statusCode == 500) {
      // Try to parse error details from response body
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final errorMsg =
            errorData['error'] ?? errorData['message'] ?? 'خطأ في الخادم';
        throw Exception(errorMsg);
      } catch (e) {
        // If parsing failed, check if e is already the formatted exception
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        // Otherwise show the response body
        throw Exception(
          'خطأ في الخادم - حاول مرة أخرى لاحقاً\nResponse: ${response.body}',
        );
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  // ==========================================
  // ERROR HANDLING
  // ==========================================

  /// Handle and translate errors to user-friendly messages
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
    // Remove generic 'not found' check to allow specific server errors to pass through
    // Error is already an Exception, rethrow it
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    // debugPrint(
    //   '[SalesApiService] ${response.request?.url} '
    //   '→ ${response.statusCode}',
    // );

    if (response.body.isEmpty) {
      throw Exception('Réponse vide reçue du serveur.');
    }

    // طباعة الـ response للتشخيص
    // debugPrint('[SalesApiService] Response body: ${response.body}');

    // التحقق من أن الـ response هو JSON وليس HTML
    if (response.body.trim().startsWith('<')) {
      throw Exception(
        'Le serveur a retourné du HTML au lieu de JSON. '
        'Vérifiez l\'URL de l\'API ou les erreurs PHP sur le serveur.',
      );
    }

    try {
      final dynamic decodedBody = json.decode(response.body);
      if (decodedBody is! Map<String, dynamic>) {
        throw Exception('Format de réponse inattendu.');
      }

      final success = decodedBody['success'] == true;
      if (response.statusCode >= 200 && response.statusCode < 300 && success) {
        return decodedBody;
      }

      final message =
          decodedBody['message'] ??
          decodedBody['error'] ??
          response.reasonPhrase ??
          'Une erreur est survenue.';
      throw Exception(message.toString());
    } on FormatException catch (e) {
      throw Exception(
        'Erreur de format JSON: ${e.message}. '
        'Le serveur a peut-être retourné une erreur PHP.',
      );
    }
  }
}
