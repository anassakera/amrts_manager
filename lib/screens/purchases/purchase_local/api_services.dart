// ============================================
// FILE: lib/screens/purchases/purchase_local/api_services.dart
// PURPOSE: API service for Purchase Local (Articles Stock)
// ============================================

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class PurchaseApiService {
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
      throw Exception('خطأ في الخادم - حاول مرة أخرى لاحقاً');
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
