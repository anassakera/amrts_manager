import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class FonderieApiService {
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
  ///
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [pageSize]: Items per page (default: 50, max: 100)
  ///
  /// Returns: List of article stock maps
  /// Throws: Exception on error
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
  // FONDRIES API METHODS
  // ==========================================

  /// Create a new fondrie with items
  ///
  /// Parameters:
  /// - [fondrieData]: Map containing fondrie data with items array
  ///
  /// Returns: Created fondrie data
  /// Throws: Exception on error
  Future<Map<String, dynamic>> createFondrie(
    Map<String, dynamic> fondrieData,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/fondries/create.php');

      final response = await http
          .post(uri, headers: _headers, body: json.encode(fondrieData))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      } else {
        throw Exception(result['message'] ?? 'فشل إنشاء الفُندرية');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in createFondrie: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Get all fondries with their items
  ///
  /// Returns: List of fondries with items
  /// Throws: Exception on error
  Future<List<Map<String, dynamic>>> getAllFondries() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/fondries/get_all.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((fondrie) => Map<String, dynamic>.from(fondrie))
            .toList();
      } else {
        throw Exception(result['message'] ?? 'فشل تحميل الفُندريات');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getAllFondries: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Get a specific fondrie by reference
  ///
  /// Parameters:
  /// - [refFondrie]: Reference of the fondrie to retrieve
  ///
  /// Returns: Fondrie data with items
  /// Throws: Exception on error
  Future<Map<String, dynamic>> getFondrieByRef(String refFondrie) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/fondries/get_by_ref.php',
      ).replace(queryParameters: {'ref_fondrie': refFondrie});

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      } else {
        throw Exception(result['message'] ?? 'فشل تحميل الفُندرية');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getFondrieByRef: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update an existing fondrie
  ///
  /// Parameters:
  /// - [fondrieData]: Map containing fondrie data with items array
  ///
  /// Returns: Updated fondrie data
  /// Throws: Exception on error
  Future<Map<String, dynamic>> updateFondrie(
    Map<String, dynamic> fondrieData,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/fondries/update.php');

      final response = await http
          .put(uri, headers: _headers, body: json.encode(fondrieData))
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      } else {
        throw Exception(result['message'] ?? 'فشل تحديث الفُندرية');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in updateFondrie: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Delete a fondrie by reference
  ///
  /// Parameters:
  /// - [refFondrie]: Reference of the fondrie to delete
  ///
  /// Returns: Success status
  /// Throws: Exception on error
  Future<bool> deleteFondrie(String refFondrie) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/fondries/delete.php');

      final response = await http
          .delete(
            uri,
            headers: _headers,
            body: json.encode({'ref_fondrie': refFondrie}),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return true;
      } else {
        throw Exception(result['message'] ?? 'فشل حذف الفُندرية');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in deleteFondrie: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update the status of a foundry item and sync with inventory
  ///
  /// Parameters:
  /// - [refFondrie]: The foundry reference
  /// - [itemId]: The ID of the item being updated
  /// - [oldStatus]: The previous status
  /// - [newStatus]: The new status
  /// - [itemData]: The full data of the item (for calculations)
  ///
  /// Returns: Success status
  Future<Map<String, dynamic>> updateFoundryItemStatus({
    required String refFondrie,
    required int itemId,
    required String oldStatus,
    required String newStatus,
    required Map<String, dynamic> itemData,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/fondries/update_status.php');

      final body = {
        'ref_fondrie': refFondrie,
        'item_id': itemId,
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
      debugPrint('Error in updateFoundryItemStatus: $e');
      _handleError(e);
      rethrow;
    }
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

  /// Get the next ref_fondrie for a new fonderie
  ///
  /// Format: FO-MM-NNNNN
  /// - FO: Operation prefix
  /// - MM: Current month
  /// - NNNNN: Sequential number from database
  ///
  /// Returns: Next ref_fondrie string
  Future<String> getNextRefFondrie() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/fondries/get_next_ref.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return result['data']['next_ref_fondrie'] as String;
      } else {
        throw Exception(
          result['message'] ?? 'فشل الحصول على رقم الفُندرية التالي',
        );
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getNextRefFondrie: $e');
      // Fallback: generate locally if API fails
      final now = DateTime.now();
      final year = now.year.toString().substring(2); // "25" for 2025
      final month = now.month.toString().padLeft(2, '0');
      return 'FO-$year-$month-00001';
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
            throw Exception(data['error'] ?? 'خطأ غير معروف من الخادم');
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
      debugPrint('Server Error (500): ${response.body}');
      if (response.body.contains('Scrap item not found')) {
        throw Exception('المخزن فارغ');
      }
      throw Exception('خطأ في الخادم: ${response.body}');
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
    } else if (errorString.contains('not found')) {
      throw Exception('المادة غير موجودة');
    }
    // Error is already an Exception, rethrow it
  }
}
