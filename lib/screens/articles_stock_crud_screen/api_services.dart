// ============================================
// API Services for Articles Stock CRUD
// ============================================

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class ArticlesStockApiService {
  // ==========================================
  // CONFIGURATION
  // ==========================================
  static Future<String> _ensureBaseUrl() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }
    return ApiServices.baseUrl!;
  }

  static const Duration requestTimeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // ==========================================
  // PUBLIC API METHODS
  // ==========================================

  /// Load all articles with pagination
  Future<List<Map<String, dynamic>>> loadAllArticles({
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
            .map((article) => article as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل تحميل المواد');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in loadAllArticles: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Search and filter articles
  Future<List<Map<String, dynamic>>> searchArticles({
    String? searchQuery,
    String? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final body = {
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search_term': searchQuery,
        if (status != null) 'status': status,
        'page': page,
        'page_size': pageSize,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/articles/articles_stock/search.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((article) => article as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل البحث');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة البحث');
    } catch (e) {
      debugPrint('Error in searchArticles: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Create new article
  Future<Map<String, dynamic>> addArticle({
    required String refCode,
    required String materialName,
    required String materialType,
    required double unitPrice,
    String status = 'Disponible',
    int? minStockLevel,
    String createdBy = 'SYSTEM',
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      // Validate data
      _validateArticleData(
        refCode: refCode,
        materialName: materialName,
        materialType: materialType,
        unitPrice: unitPrice,
      );

      final body = {
        'ref_code': refCode,
        'material_name': materialName,
        'material_type': materialType,
        'unit_price': unitPrice,
        'status': status,
        if (minStockLevel != null) 'min_stock_level': minStockLevel,
        'created_by': createdBy,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/articles/articles_stock/create.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return result['data'] as Map<String, dynamic>;
      } else {
        throw Exception(result['error'] ?? 'فشلت الإضافة');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الإضافة');
    } catch (e) {
      debugPrint('Error in addArticle: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update existing article
  Future<Map<String, dynamic>> modifyArticle({
    required int id,
    required String refCode,
    required String materialName,
    required String materialType,
    required double unitPrice,
    required String status,
    int? minStockLevel,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      // Validate data
      _validateArticleData(
        refCode: refCode,
        materialName: materialName,
        materialType: materialType,
        unitPrice: unitPrice,
      );

      final body = {
        'id': id,
        'ref_code': refCode,
        'material_name': materialName,
        'material_type': materialType,
        'unit_price': unitPrice,
        'status': status,
        if (minStockLevel != null) 'min_stock_level': minStockLevel,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/articles/articles_stock/update.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return result['data'] as Map<String, dynamic>;
      } else {
        throw Exception(result['error'] ?? 'فشل التعديل');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة التعديل');
    } catch (e) {
      debugPrint('Error in modifyArticle: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Delete article
  Future<bool> removeArticle(int id, {bool permanent = false}) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final body = {'id': id, 'delete_mode': permanent ? 'hard' : 'soft'};

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/articles/articles_stock/delete.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);
      return result['success'] == true;
    } on TimeoutException {
      throw Exception('انتهت مهلة الحذف');
    } catch (e) {
      debugPrint('Error in removeArticle: $e');
      _handleError(e);
      rethrow;
    }
  }

  // ==========================================
  // VALIDATION METHODS
  // ==========================================

  void _validateArticleData({
    required String refCode,
    required String materialName,
    required String materialType,
    required double unitPrice,
  }) {
    if (refCode.trim().isEmpty) {
      throw Exception('الرجاء إدخال رمز المرجع');
    }

    if (refCode.length > 50) {
      throw Exception('رمز المرجع طويل جداً (الحد الأقصى 50 حرف)');
    }

    if (materialName.trim().isEmpty) {
      throw Exception('الرجاء إدخال اسم المادة');
    }

    if (materialName.length > 200) {
      throw Exception('اسم المادة طويل جداً (الحد الأقصى 200 حرف)');
    }

    if (materialType.trim().isEmpty) {
      throw Exception('الرجاء إدخال نوع المادة');
    }

    if (materialType.length > 50) {
      throw Exception('نوع المادة طويل جداً (الحد الأقصى 50 حرف)');
    }

    if (unitPrice < 0) {
      throw Exception('السعر يجب أن يكون رقماً موجباً');
    }
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
      throw Exception('خطأ في الخادم - حاول مرة أخرى لاحقاً');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
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
    } else if (errorString.contains('not found')) {
      throw Exception('المادة غير موجودة');
    } else if (errorString.contains('already exists')) {
      throw Exception('البيانات موجودة مسبقاً');
    }
  }
}
