import 'dart:convert';
import 'package:amrts_manager/model/api_services.dart';
import 'package:http/http.dart' as http;

class InventorySpfApiService {
  static final String baseUrl =
      ApiServices.baseUrl ?? 'http://localhost/amrts_manager';

  /// Get all inventory SPF items with their operations
  static Future<Map<String, dynamic>> getAllInventorySpf() async {
    try {
      final url = Uri.parse('$baseUrl/api/inventory_spf/get_all.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get specific inventory SPF item by ref_code
  static Future<Map<String, dynamic>> getInventorySpfByRef(
    String refCode,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/inventory_spf/get_by_ref.php?ref=$refCode',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Item not found'};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Create new inventory SPF entry
  static Future<Map<String, dynamic>> createInventorySpf(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/inventory_spf/create.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'message': 'Failed to create item: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Update existing inventory SPF entry
  static Future<Map<String, dynamic>> updateInventorySpf(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/inventory_spf/update.php');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Item not found'};
      } else {
        return {
          'success': false,
          'message': 'Failed to update item: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Delete inventory SPF entry by ref_code
  static Future<Map<String, dynamic>> deleteInventorySpf(String refCode) async {
    try {
      final url = Uri.parse('$baseUrl/api/inventory_spf/delete.php');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ref_code': refCode}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Item not found'};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete item: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
