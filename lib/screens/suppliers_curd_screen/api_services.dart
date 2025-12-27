// ============================================
// FILE: lib/screens/suppliers_curd_screen/api_services.dart
// PURPOSE: Complete API service for Suppliers (HTTP + Business Logic)
// ============================================

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class SupplierApiService {
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
  // PUBLIC API METHODS - SUPPLIERS
  // ==========================================

  /// Load all active suppliers with pagination
  Future<List<Map<String, dynamic>>> loadAllSuppliers({
    int page = 1,
    int pageSize = 50,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/suppliers/suppliers_read_all.php')
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
            .map(
              (supplier) =>
                  _convertToUiFormat(supplier as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل تحميل الموردين');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in loadAllSuppliers: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Search and filter suppliers
  Future<List<Map<String, dynamic>>> searchSuppliers({
    String? searchQuery,
    bool? status,
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
            Uri.parse('$baseUrl/api/suppliers/suppliers_read_filtered.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map(
              (supplier) =>
                  _convertToUiFormat(supplier as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل البحث');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة البحث');
    } catch (e) {
      debugPrint('Error in searchSuppliers: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Create new supplier
  Future<Map<String, dynamic>> addSupplier({
    required String accountCode,
    required String supplierName,
    String? ice,
    String? phone,
    String? address,
    bool isActive = true,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      _validateSupplierName(supplierName);
      _validateAccountCode(accountCode);

      final body = {
        'account_code': accountCode,
        'supplier_name': supplierName,
        if (ice != null && ice.isNotEmpty) 'ice': ice,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        'is_active': isActive,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/suppliers/suppliers_create.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return _convertToUiFormat(result['data']);
      } else {
        throw Exception(result['error'] ?? 'فشلت الإضافة');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الإضافة');
    } catch (e) {
      debugPrint('Error in addSupplier: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update existing supplier
  Future<Map<String, dynamic>> modifySupplier({
    required int supplierId,
    required String accountCode,
    required String supplierName,
    String? ice,
    String? phone,
    String? address,
    bool isActive = true,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      _validateSupplierName(supplierName);
      _validateAccountCode(accountCode);

      final body = {
        'supplier_id': supplierId,
        'account_code': accountCode,
        'supplier_name': supplierName,
        if (ice != null && ice.isNotEmpty) 'ice': ice,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        'is_active': isActive,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/suppliers/suppliers_update.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return _convertToUiFormat(result['data']);
      } else {
        throw Exception(result['error'] ?? 'فشل التعديل');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة التعديل');
    } catch (e) {
      debugPrint('Error in modifySupplier: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Delete supplier (soft or hard delete)
  Future<bool> removeSupplier(int supplierId, {bool permanent = false}) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final body = {
        'supplier_id': supplierId,
        'delete_mode': permanent ? 'hard' : 'soft',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/suppliers/suppliers_delete.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);
      return result['success'] == true;
    } on TimeoutException {
      throw Exception('انتهت مهلة الحذف');
    } catch (e) {
      debugPrint('Error in removeSupplier: $e');
      _handleError(e);
      rethrow;
    }
  }

  // ==========================================
  // DATA CONVERSION METHODS
  // ==========================================

  Map<String, dynamic> _convertToUiFormat(Map<String, dynamic> apiData) {
    return {
      'supplier_id': apiData['supplier_id'],
      'account_code': apiData['account_code'] ?? '',
      'supplier_name': apiData['supplier_name'] ?? '',
      'ice': apiData['ice'] ?? '',
      'phone': apiData['phone'] ?? '',
      'address': apiData['address'] ?? '',
      'is_active': apiData['is_active'] == 1 || apiData['is_active'] == true,
      'created_at': apiData['created_at'],
      'updated_at': apiData['updated_at'],
    };
  }

  // ==========================================
  // VALIDATION METHODS
  // ==========================================

  void _validateSupplierName(String supplierName) {
    if (supplierName.trim().isEmpty) {
      throw Exception('الرجاء إدخال اسم المورد');
    }
    if (supplierName.length > 100) {
      throw Exception('اسم المورد طويل جداً (الحد الأقصى 100 حرف)');
    }
  }

  void _validateAccountCode(String accountCode) {
    if (accountCode.trim().isEmpty) {
      throw Exception('الرجاء إدخال رمز الحساب');
    }
    if (accountCode.length > 20) {
      throw Exception('رمز الحساب طويل جداً (الحد الأقصى 20 حرف)');
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
      throw Exception('المورد غير موجود');
    } else if (errorString.contains('already exists')) {
      throw Exception('البيانات موجودة مسبقاً');
    }
  }
}
