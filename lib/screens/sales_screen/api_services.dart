import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:amrts_manager/model/api_services.dart';

/// Dedicated API helper for the sales module.
class SalesApiService {
  static String get baseUrl =>
      ApiServices.baseUrl ?? 'http://192.168.1.254/amrts_manager';

  /// Fetch all sales orders with optional doc_type filter
  static Future<Map<String, dynamic>> fetchOrders({
    int page = 1,
    int pageSize = 20,
    String? docType,
  }) async {
    try {
      String url = '$baseUrl/api/sales_orders/get_all.php';
      if (docType != null) {
        url += '?doc_type=$docType';
      }

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final orders =
              (data['data'] as List?)?.map((order) {
                // Map API response to frontend format
                return _mapOrderToFrontend(order);
              }).toList() ??
              [];

          return {'orders': orders};
        }
        throw Exception(data['message'] ?? 'Failed to fetch orders');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchOrders error: $e');
      rethrow;
    }
  }

  /// Fetch a single order by ref_code or id
  static Future<Map<String, dynamic>> fetchOrderByRef(String refCode) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/sales_orders/get_by_id.php?ref_code=$refCode',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _mapOrderToFrontend(data['data']);
        }
        throw Exception(data['message'] ?? 'Order not found');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchOrderByRef error: $e');
      rethrow;
    }
  }

  /// Get next reference code for a document type
  static Future<String> getNextRefCode({String docType = 'BL'}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/sales_orders/get_next_ref.php?doc_type=$docType',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['ref_code'] ?? '';
        }
        throw Exception(data['message'] ?? 'Failed to get next ref');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('getNextRefCode error: $e');
      rethrow;
    }
  }

  /// Create a new sales order
  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> order,
  ) async {
    try {
      final payload = _mapOrderToBackend(order);

      debugPrint('createOrder payload: ${json.encode(payload)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sales_orders/create.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('createOrder response status: ${response.statusCode}');
      debugPrint('createOrder response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _mapOrderToFrontend(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to create order');
      }

      // Try to parse error message from response
      try {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('createOrder error: $e');
      rethrow;
    }
  }

  /// Update an existing sales order
  static Future<Map<String, dynamic>> updateOrder(
    Map<String, dynamic> order,
  ) async {
    try {
      final payload = _mapOrderToBackend(order);

      debugPrint('updateOrder payload: ${json.encode(payload)}');

      final response = await http
          .put(
            Uri.parse('$baseUrl/api/sales_orders/update.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('updateOrder response status: ${response.statusCode}');
      debugPrint('updateOrder response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _mapOrderToFrontend(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to update order');
      }

      // Try to parse error message from response
      try {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('updateOrder error: $e');
      rethrow;
    }
  }

  /// Delete a sales order
  static Future<void> deleteOrder(String refCode) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/sales_orders/delete.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'ref_code': refCode}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception(data['message'] ?? 'Failed to delete order');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('deleteOrder error: $e');
      rethrow;
    }
  }

  /// Fetch articles from the API
  static Future<List<Map<String, dynamic>>> fetchArticles() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/articles/articles_read_all.php'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // API returns data with French keys directly: Référence, Désignation, Poids, Price
          return (data['data'] as List?)?.map((article) {
                return {
                  'Référence': article['Référence']?.toString() ?? '',
                  'Désignation': article['Désignation']?.toString() ?? '',
                  'Poids': (article['Poids'] as num?)?.toDouble() ?? 0.0,
                  'Price': (article['Price'] as num?)?.toDouble() ?? 0.0,
                };
              }).toList() ??
              [];
        }
        throw Exception(data['message'] ?? 'Failed to fetch articles');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchArticles error: $e');
      rethrow;
    }
  }

  /// Check stock availability in SPF (Finished Products Inventory)
  /// Returns true if stock is available, false otherwise
  static Future<Map<String, dynamic>> checkStockSPF({
    required String productRef,
    required int requiredQty,
    String? color,
  }) async {
    try {
      final body = {
        'product_ref': productRef,
        'required_qty': requiredQty,
        if (color != null) 'color': color,
      };

      debugPrint('checkStockSPF request: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sales_orders/check_stock.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('checkStockSPF response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final responseData = data['data'];
          return {
            'available': responseData['available'] ?? false,
            'current_stock': responseData['current_stock'] ?? 0,
            'stored_quantity': responseData['stored_quantity'] ?? 0,
            'calculated_stock': responseData['calculated_stock'] ?? 0,
            'required': responseData['required'] ?? requiredQty,
            'product_ref': productRef,
            'found_name': responseData['found_name'] ?? '',
            'found_in_spf': responseData['found_in_spf'] ?? false,
          };
        }
        throw Exception(data['message'] ?? 'Failed to check stock');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('checkStockSPF error: $e');
      rethrow;
    }
  }

  /// Update stock in SPF (Finished Products Inventory)
  /// operationType: 'OUT' for sales (deduct), 'IN' for returns (add back)
  static Future<bool> updateStockSPF({
    required String productRef,
    required String productName,
    required int quantity,
    required String operationType,
    required String docRef,
    String? color,
    double? weightPerUnit,
    double? unitCost,
    double? sellingPrice,
  }) async {
    try {
      final body = {
        'product_ref': productRef,
        'product_name': productName,
        'quantity': quantity,
        'operation_type': operationType,
        'doc_ref': docRef,
        if (color != null) 'color': color,
        if (weightPerUnit != null) 'weight_per_unit': weightPerUnit,
        if (unitCost != null) 'unit_cost': unitCost,
        if (sellingPrice != null) 'selling_price': sellingPrice,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/inventory_spf/update.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('updateStockSPF error: $e');
      return false;
    }
  }

  /// Deduct stock from inventory when adding item to sales order
  static Future<Map<String, dynamic>> deductStock({
    required String productRef,
    required String productName,
    required int quantity,
    required String docRef,
    String? color,
    double? sellingPrice,
  }) async {
    try {
      final body = {
        'action': 'deduct',
        'product_ref': productRef,
        'product_name': productName,
        'quantity': quantity,
        'doc_ref': docRef,
        if (color != null && color.isNotEmpty) 'color': color,
        if (sellingPrice != null) 'selling_price': sellingPrice,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sales_orders/stock_operation.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? '',
        'new_stock': data['data']?['new_stock'] ?? 0,
      };
    } catch (e) {
      debugPrint('deductStock error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Restore stock to inventory when deleting item from sales order
  static Future<Map<String, dynamic>> restoreStock({
    required String productRef,
    required String docRef,
    String? color,
  }) async {
    try {
      final body = {
        'action': 'restore',
        'product_ref': productRef,
        'doc_ref': docRef,
        if (color != null && color.isNotEmpty) 'color': color,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sales_orders/stock_operation.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? '',
        'quantity_restored': data['data']?['quantity_restored'] ?? 0,
      };
    } catch (e) {
      debugPrint('restoreStock error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Map backend API response to frontend format
  static Map<String, dynamic> _mapOrderToFrontend(
    Map<String, dynamic> apiOrder,
  ) {
    final items =
        (apiOrder['sales_operations'] ?? apiOrder['items'] ?? []) as List;

    return {
      'id': apiOrder['id'],
      'Document_Ref': apiOrder['ref_code'] ?? '',
      'doc_type': apiOrder['doc_type'] ?? 'BL',
      'Client': apiOrder['client_name'] ?? '',
      'date': apiOrder['order_date'] ?? '',
      'total_items': apiOrder['total_items'] ?? items.length,
      'total_weight_consumed': apiOrder['total_weight_consumed'] ?? 0.0,
      'total_price': apiOrder['total_price'] ?? 0.0,
      'status': apiOrder['status'] ?? 'pending',
      'notes': apiOrder['notes'],
      'created_at': apiOrder['created_at'],
      'updated_at': apiOrder['updated_at'],
      'items': items.map((item) => _mapItemToFrontend(item)).toList(),
    };
  }

  /// Map backend item to frontend format
  static Map<String, dynamic> _mapItemToFrontend(Map<String, dynamic> apiItem) {
    return {
      'id': apiItem['id'],
      'Référence': apiItem['product_reference'] ?? '',
      'Désignation': apiItem['product_name'] ?? '',
      'Poids': (apiItem['default_weight'] as num?)?.toDouble() ?? 0.0,
      'Quantité': (apiItem['quantity'] as num?)?.toInt() ?? 0,
      'Couleur': apiItem['color'] ?? '',
      'Price': (apiItem['default_price'] as num?)?.toDouble() ?? 0.0,
      'total_price': (apiItem['total_price'] as num?)?.toDouble() ?? 0.0,
      'date': apiItem['item_date'] ?? '',
      'created_by': apiItem['created_by'],
      'updated_by': apiItem['updated_by'],
    };
  }

  /// Map frontend order to backend API format
  static Map<String, dynamic> _mapOrderToBackend(
    Map<String, dynamic> frontendOrder,
  ) {
    final items = (frontendOrder['items'] ?? []) as List;

    return {
      'id': frontendOrder['id'],
      'ref_code': frontendOrder['Document_Ref'] ?? '',
      'doc_type': frontendOrder['doc_type'] ?? 'BL',
      'client_name': frontendOrder['Client'] ?? '',
      'order_date': frontendOrder['date'] ?? '',
      'status': frontendOrder['status'] ?? 'pending',
      'notes': frontendOrder['notes'],
      'items': items.map((item) => _mapItemToBackend(item)).toList(),
    };
  }

  /// Map frontend item to backend API format
  static Map<String, dynamic> _mapItemToBackend(
    Map<String, dynamic> frontendItem,
  ) {
    final quantity = (frontendItem['Quantité'] as num?)?.toInt() ?? 0;
    final price = (frontendItem['Price'] as num?)?.toDouble() ?? 0.0;

    return {
      'id': frontendItem['id'],
      'product_reference': frontendItem['Référence'] ?? '',
      'product_name': frontendItem['Désignation'] ?? '',
      'color': frontendItem['Couleur'] ?? '',
      'default_weight': (frontendItem['Poids'] as num?)?.toDouble() ?? 0.0,
      'quantity': quantity,
      'default_price': price,
      'total_price': quantity * price,
      'item_date':
          frontendItem['date'] ?? DateTime.now().toString().split(' ')[0],
    };
  }
}
