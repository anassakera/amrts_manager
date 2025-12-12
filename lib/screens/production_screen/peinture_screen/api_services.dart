import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class PeintureApiService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  // ==========================================
  // CONFIGURATION
  // ==========================================
  static Future<String> _ensureBaseUrl() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }
    return ApiServices.baseUrl!;
  }

  // Common headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // ==========================================
  // PEINTURE API METHODS
  // ==========================================

  /// Create a new peinture production record with all items
  Future<Map<String, dynamic>> createPeinture(
    Map<String, dynamic> peintureData,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/peinture/create.php');

      final response = await http
          .post(uri, headers: _headers, body: json.encode(peintureData))
          .timeout(_requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل إنشاء فيشة الطلاء');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in createPeinture: $e');
      rethrow;
    }
  }

  /// Get all peinture records with complete data
  Future<List<Map<String, dynamic>>> getAllPeintures() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/peinture/get_all.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((peinture) => Map<String, dynamic>.from(peinture))
            .toList();
      } else {
        throw Exception(result['message'] ?? 'فشل تحميل بيانات الطلاء');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getAllPeintures: $e');
      rethrow;
    }
  }

  /// Get a specific peinture record by numero
  Future<Map<String, dynamic>> getPeintureByRef(String numero) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse(
        '$baseUrl/api/peinture/get_by_ref.php',
      ).replace(queryParameters: {'ref': numero});

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      } else {
        throw Exception(result['message'] ?? 'فشل تحميل فيشة الطلاء');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getPeintureByRef: $e');
      rethrow;
    }
  }

  /// Update an existing peinture record
  Future<Map<String, dynamic>> updatePeinture(
    Map<String, dynamic> peintureData,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/peinture/update.php');

      final response = await http
          .post(uri, headers: _headers, body: json.encode(peintureData))
          .timeout(_requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return result;
      } else {
        throw Exception(result['message'] ?? 'فشل تحديث فيشة الطلاء');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in updatePeinture: $e');
      rethrow;
    }
  }

  /// Delete a peinture record
  Future<bool> deletePeinture(String numero) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/peinture/delete.php');

      final response = await http
          .post(
            uri,
            headers: _headers,
            body: json.encode({'ref_peinture': numero}),
          )
          .timeout(_requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true) {
        return true;
      } else {
        throw Exception(result['message'] ?? 'فشل حذف فيشة الطلاء');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in deletePeinture: $e');
      rethrow;
    }
  }

  /// Update the status of a production item and sync with inventory
  ///
  /// When status changes to 'completed':
  /// - Deducts from SSF (Semi-Finished Stock)
  /// - Adds to SPF (Finished Products Stock)
  ///
  /// When status changes back to 'in_progress':
  /// - Rolls back inventory changes
  Future<Map<String, dynamic>> updateProductionItemStatus({
    required int productionId,
    required String oldStatus,
    required String newStatus,
    required Map<String, dynamic> itemData,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/peinture/update_status.php');

      final body = {
        'production_id': productionId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'item_data': itemData,
      };

      // === DEBUG LOGGING ===
      debugPrint('=== updateProductionItemStatus CALLED ===');
      debugPrint('URL: $uri');
      debugPrint(
        'productionId: $productionId (type: ${productionId.runtimeType})',
      );
      debugPrint('oldStatus: $oldStatus');
      debugPrint('newStatus: $newStatus');
      debugPrint('itemData.ref: ${itemData['ref']}');
      debugPrint(
        'itemData.id: ${itemData['id']} (type: ${itemData['id']?.runtimeType})',
      );
      debugPrint('Full body: ${json.encode(body)}');
      // === END DEBUG ===

      final response = await http
          .post(uri, headers: _headers, body: json.encode(body))
          .timeout(_requestTimeout);

      // === DEBUG RESPONSE ===
      debugPrint('Response statusCode: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      // Parse response to check for debug_trace
      try {
        final responseData = json.decode(response.body);
        if (responseData['debug_trace'] != null) {
          debugPrint('=== PHP DEBUG TRACE ===');
          for (var log in responseData['debug_trace']) {
            debugPrint('  → $log');
          }
          debugPrint('=== END PHP DEBUG TRACE ===');
        }
      } catch (_) {}
      // === END DEBUG ===

      final result = _handleResponse(response);

      if (result['success'] == true) {
        debugPrint('SUCCESS: Status updated successfully');
        return result;
      } else {
        debugPrint('FAILED: ${result['message']}');
        throw Exception(result['message'] ?? 'فشل تحديث حالة العنصر');
      }
    } on TimeoutException {
      debugPrint('ERROR: Request timeout');
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('ERROR in updateProductionItemStatus: $e');
      rethrow;
    }
  }

  /// Get the next numero for a new peinture record
  ///
  /// Format: PE-YY-MM-NNNNN
  Future<String> getNextNumero() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/peinture/get_next_numero.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return result['data']['next_numero'] as String;
      } else {
        throw Exception(result['message'] ?? 'فشل الحصول على الرقم التالي');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in getNextNumero: $e');
      // Fallback: generate locally if API fails
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      return 'PE-$year-$month-00001';
    }
  }

  // ==========================================
  // EXTERNAL DATA APIs (Articles, Colors, Costs)
  // ==========================================

  /// Get all articles for dropdown (Réf, Désignation, Poids, Price)
  Future<List<Map<String, dynamic>>> getArticles() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/articles/articles_read_all.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);

      final result = _handleExternalResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((article) => Map<String, dynamic>.from(article))
            .toList();
      } else {
        return [];
      }
    } on TimeoutException {
      debugPrint('Timeout fetching articles');
      return [];
    } catch (e) {
      debugPrint('Error in getArticles: $e');
      return [];
    }
  }

  /// Get all colors for dropdown (color_id, Couleur, color_code)
  Future<List<Map<String, dynamic>>> getColors() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/colors/colors_read_all.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);

      final result = _handleExternalResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((color) => Map<String, dynamic>.from(color))
            .toList();
      } else {
        return [];
      }
    } on TimeoutException {
      debugPrint('Timeout fetching colors');
      return [];
    } catch (e) {
      debugPrint('Error in getColors: $e');
      return [];
    }
  }

  /// Get costs for current month (CU_PEINTURE)
  Future<double> getCuPeinture() async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/costs/costs_api.php');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          final cuPeinture = result['data']['CU_PEINTURE'];
          if (cuPeinture != null) {
            return double.tryParse(cuPeinture.toString()) ?? 0.0;
          }
        }
      }
      return 0.0;
    } on TimeoutException {
      debugPrint('Timeout fetching costs');
      return 0.0;
    } catch (e) {
      debugPrint('Error in getCuPeinture: $e');
      return 0.0;
    }
  }

  /// Handle response from external APIs (formatResponse style)
  Map<String, dynamic> _handleExternalResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } catch (e) {
        return {'success': false, 'data': []};
      }
    }
    return {'success': false, 'data': []};
  }

  // ==========================================
  // HTTP RESPONSE HANDLING
  // ==========================================

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
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
      throw Exception('API endpoint not found');
    } else if (response.statusCode == 405) {
      throw Exception('طريقة الطلب غير مسموحة');
    } else if (response.statusCode == 500) {
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final errorMsg =
            errorData['error'] ?? errorData['message'] ?? 'خطأ في الخادم';
        throw Exception(errorMsg);
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception(
          'خطأ في الخادم - حاول مرة أخرى لاحقاً\nResponse: ${response.body}',
        );
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}
