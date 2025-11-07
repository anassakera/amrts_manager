// ============================================
// FILE: lib/services/api_services.dart
// PURPOSE: Complete API service for Clients (HTTP + Business Logic)
// GENERATED FROM: client_curd_screen.dart
// ============================================

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amrts_manager/model/api_services.dart';

class ApiService {
  // ==========================================
  // CONFIGURATION
  // ==========================================
  static Future<String> _ensureBaseUrl() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }
    return ApiServices.baseUrl!;
  }
  // Base URL - CONFIGURE THIS TO YOUR SERVER
  // static const String baseUrl = 'http://your-domain.com/api';

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
  // PUBLIC API METHODS - CLIENTS
  // ==========================================

  /// Load all active clients with pagination
  ///
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [pageSize]: Items per page (default: 50)
  ///
  /// Returns: List of client maps in UI format
  /// Throws: Exception on error
  Future<List<Map<String, dynamic>>> loadAllClients({
    int page = 1,
    int pageSize = 50,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/clients/clients_read_all.php')
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
        // Convert API format to UI format
        return rawData
            .map((client) => _convertToUiFormat(client as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل تحميل العملاء');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب - تحقق من اتصال الإنترنت');
    } catch (e) {
      debugPrint('Error in loadAllClients: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Search and filter clients
  ///
  /// Parameters:
  /// - [searchQuery]: Text to search in name, ice, phone, address
  /// - [status]: true=active, false=inactive, null=all
  /// - [page]: Page number
  /// - [pageSize]: Items per page
  ///
  /// Returns: Filtered list of clients in UI format
  Future<List<Map<String, dynamic>>> searchClients({
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
            Uri.parse('$baseUrl/api/clients/clients_read_filtered.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawData = result['data'];
        return rawData
            .map((client) => _convertToUiFormat(client as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(result['error'] ?? 'فشل البحث');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة البحث');
    } catch (e) {
      debugPrint('Error in searchClients: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Get client details by ID
  ///
  /// Parameters:
  /// - [clientId]: Client ID
  ///
  /// Returns: Client details in UI format
  Future<Map<String, dynamic>> getClientDetails(int clientId) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/clients/clients_read_by_id.php?client_id=$clientId',
            ),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);

      if (result['success'] == true && result['data'] != null) {
        return _convertToUiFormat(result['data']);
      } else {
        throw Exception(result['error'] ?? 'العميل غير موجود');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الطلب');
    } catch (e) {
      debugPrint('Error in getClientDetails: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Create new client
  ///
  /// Parameters:
  /// - [clientName]: Required - Client name
  /// - [ice]: Optional - ICE or email
  /// - [phone]: Optional - Phone number
  /// - [address]: Optional - Address
  /// - [isActive]: Optional - Active status (default: true)
  ///
  /// Returns: Created client in UI format
  Future<Map<String, dynamic>> addClient({
    required String clientName,
    String? ice,
    String? phone,
    String? address,
    bool isActive = true,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      // Validate data before sending
      _validateClientName(clientName);

      final body = {
        'client_name': clientName,
        if (ice != null && ice.isNotEmpty) 'ice': ice,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        'is_active': isActive,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/clients/clients_create.php'),
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
      debugPrint('Error in addClient: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Update existing client
  ///
  /// Parameters:
  /// - [clientId]: Required - Client ID
  /// - [clientName]: Required - Client name
  /// - [ice]: Optional - ICE or email
  /// - [phone]: Optional - Phone number
  /// - [address]: Optional - Address
  /// - [isActive]: Optional - Active status
  ///
  /// Returns: Updated client in UI format
  Future<Map<String, dynamic>> modifyClient({
    required int clientId,
    required String clientName,
    String? ice,
    String? phone,
    String? address,
    bool isActive = true,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      // Validate data
      _validateClientName(clientName);

      final body = {
        'client_id': clientId,
        'client_name': clientName,
        if (ice != null && ice.isNotEmpty) 'ice': ice,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        'is_active': isActive,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/clients/clients_update.php'),
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
      debugPrint('Error in modifyClient: $e');
      _handleError(e);
      rethrow;
    }
  }

  /// Delete client (soft or hard delete)
  ///
  /// Parameters:
  /// - [clientId]: Client ID to delete
  /// - [permanent]: If true, permanently delete (hard delete)
  ///                If false, soft delete (deactivate) - Recommended
  ///
  /// Returns: true if successful
  Future<bool> removeClient(int clientId, {bool permanent = false}) async {
    final baseUrl = await _ensureBaseUrl();
    try {
      final body = {
        'client_id': clientId,
        'delete_mode': permanent ? 'hard' : 'soft',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/clients/clients_delete.php'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(requestTimeout);

      final result = _handleResponse(response);
      return result['success'] == true;
    } on TimeoutException {
      throw Exception('انتهت مهلة الحذف');
    } catch (e) {
      debugPrint('Error in removeClient: $e');
      _handleError(e);
      rethrow;
    }
  }

  // ==========================================
  // DATA CONVERSION METHODS
  // ==========================================

  /// Convert API client data to UI format (matching Flutter screen structure)
  Map<String, dynamic> _convertToUiFormat(Map<String, dynamic> apiData) {
    return {
      'client_id': apiData['client_id'], // Keep for updates/deletes
      'ClientName': apiData['client_name'] ?? '',
      'ice': apiData['ice'] ?? '',
      'Phone': apiData['phone'] ?? '',
      'Address': apiData['address'] ?? '',
      'IsActive': apiData['is_active'] == 1 || apiData['is_active'] == true,
      'created_at': apiData['created_at'],
      'updated_at': apiData['updated_at'],
    };
  }

  // ==========================================
  // VALIDATION METHODS
  // ==========================================

  /// Validate client name
  void _validateClientName(String clientName) {
    if (clientName.trim().isEmpty) {
      throw Exception('الرجاء إدخال اسم العميل');
    }

    if (clientName.length > 100) {
      throw Exception('اسم العميل طويل جداً (الحد الأقصى 100 حرف)');
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
      throw Exception('العميل غير موجود');
    } else if (errorString.contains('already exists')) {
      throw Exception('البيانات موجودة مسبقاً');
    }
    // Error is already an Exception, rethrow it
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Format DateTime to SQL date string
  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format DateTime to SQL datetime string
  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Parse SQL date string to DateTime
  DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('Error parsing date: $dateString');
      return null;
    }
  }
}
