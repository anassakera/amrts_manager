import 'dart:convert';
import 'package:amrts_manager/model/api_services.dart';
import 'package:http/http.dart' as http;

class InventorySsfApiService {
  static final String baseUrl =
      ApiServices.baseUrl ?? 'http://localhost/amrts_manager';

  /// Get all inventory SSF items grouped by ref_code
  static Future<Map<String, dynamic>> getAllInventorySsf() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory_ssf/get_all.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List rawData = data['data'] ?? [];

        final List<Map<String, dynamic>> processedData = rawData.map((item) {
          return _processInventoryItem(item);
        }).toList();

        return {'success': data['success'] ?? false, 'data': processedData};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch inventory data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Process and normalize inventory item data
  static Map<String, dynamic> _processInventoryItem(dynamic item) {
    final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);

    final processed = {
      'ref_code': itemMap['ref_code']?.toString() ?? '',
      'total_quantity': _toDouble(itemMap['total_quantity']),
      'total_weight': _toDouble(itemMap['total_weight']),
      'total_amount': _toDouble(itemMap['total_amount']),
      'operations_count': _toInt(itemMap['operations_count']),
      'status': itemMap['status']?.toString() ?? 'Disponible',
      'items': [],
    };

    if (itemMap['items'] != null && itemMap['items'] is List) {
      processed['items'] = (itemMap['items'] as List).map((subItem) {
        final Map<String, dynamic> subItemMap = Map<String, dynamic>.from(
          subItem,
        );
        return {
          'id': _toInt(subItemMap['id']),
          'date': subItemMap['date']?.toString() ?? '',
          'doc_ref': subItemMap['doc_ref']?.toString() ?? '',
          'product_ref': subItemMap['product_ref']?.toString() ?? '',
          'product_name': subItemMap['product_name']?.toString() ?? '',
          'quantity': _toDouble(subItemMap['quantity']),
          'weight_per_unit': _toDouble(subItemMap['weight_per_unit']),
          'total_weight': _toDouble(subItemMap['total_weight']),
          'unit_cost': _toDouble(subItemMap['unit_cost']),
          'product_type': subItemMap['product_type']?.toString() ?? 'BILLET',
          'source': subItemMap['source']?.toString() ?? '',
          'status': subItemMap['status']?.toString() ?? 'Disponible',
        };
      }).toList();
    }

    return processed;
  }

  /// Convert value to double safely
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convert value to int safely
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Get inventory SSF items by ref_code
  static Future<Map<String, dynamic>> getInventorySsfByRef(
    String refCode,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/inventory_ssf/get_by_ref.php?ref_code=$refCode',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': data['success'] ?? false, 'data': data['data']};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No items found with ref_code: $refCode',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch inventory data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Create new inventory SSF items
  static Future<Map<String, dynamic>> createInventorySsf(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/inventory_ssf/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Created successfully',
          'data': responseData['data'],
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to create: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Update inventory SSF items
  static Future<Map<String, dynamic>> updateInventorySsf(
    Map<String, dynamic> data,
  ) async {
    try {
      final request = http.Request(
        'PUT',
        Uri.parse('$baseUrl/api/inventory_ssf/update.php'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode(data);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Updated successfully',
          'data': responseData['data'],
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to update: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Delete inventory SSF items by ref_code
  static Future<Map<String, dynamic>> deleteInventorySsf(String refCode) async {
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/api/inventory_ssf/delete.php'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({'ref_code': refCode});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Deleted successfully',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No items found with ref_code: $refCode',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to delete: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
