import 'dart:convert';
import 'package:amrts_manager/model/api_services.dart';
import 'package:http/http.dart' as http;

class InventorySmpApiService {
  static final String baseUrl =
      ApiServices.baseUrl ?? 'http://localhost/amrts_manager';

  /// Get all inventory SMP items (with operations)
  static Future<Map<String, dynamic>> getAllInventorySmp() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory_smp/get_all.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List rawData = data['data'] ?? [];

        // معالجة البيانات - التنسيق الجديد يحتوي على inventory_smp_operations لكل عنصر
        final List<Map<String, dynamic>> processedData = rawData.map((item) {
          return _processInventoryItemWithOperations(item);
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

  /// Process inventory item with its operations
  static Map<String, dynamic> _processInventoryItemWithOperations(
    dynamic item,
  ) {
    final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);

    // معالجة البيانات الأساسية
    final processed = {
      'id': _toInt(itemMap['id']),
      'ref_code': itemMap['ref_code']?.toString() ?? '',
      'material_name': itemMap['material_name']?.toString() ?? '',
      'material_type': itemMap['material_type']?.toString() ?? '',
      'total_quantity': _toDouble(itemMap['total_quantity']),
      'CMUP': _toDouble(itemMap['CMUP']),
      'total_amount': _toDouble(itemMap['total_amount']),
      'operations_count': _toInt(itemMap['operations_count']),
      'last_updated': itemMap['last_updated']?.toString() ?? '',
      'status': itemMap['status']?.toString() ?? 'Disponible',
    };

    // معالجة العمليات
    if (itemMap['inventory_smp_operations'] != null &&
        itemMap['inventory_smp_operations'] is List) {
      processed['inventory_smp_operations'] =
          (itemMap['inventory_smp_operations'] as List).map((operation) {
            return _processOperation(operation);
          }).toList();
    } else {
      processed['inventory_smp_operations'] = [];
    }

    return processed;
  }

  /// Process single operation
  static Map<String, dynamic> _processOperation(dynamic operation) {
    final Map<String, dynamic> opMap = Map<String, dynamic>.from(operation);

    return {
      'id': _toInt(opMap['id']),
      'date': opMap['date']?.toString() ?? '',
      'n_facture': opMap['n_facture']?.toString() ?? '',
      'fournisseur': opMap['fournisseur']?.toString() ?? '',
      'ref_code': opMap['ref_code']?.toString() ?? '',
      'material_name': opMap['material_name']?.toString() ?? '',
      'quantite': _toDouble(opMap['quantite']),
      'prix_u': _toDouble(opMap['prix_u']),
      'total_amount': _toDouble(opMap['total_amount']),
      'unite': opMap['unite']?.toString() ?? 'KG',
      'categorie': opMap['categorie']?.toString() ?? '',
      'source_ref': opMap['source_ref']?.toString() ?? '',
      'created_at': opMap['created_at']?.toString() ?? '',
      'created_by': opMap['created_by']?.toString() ?? '',
    };
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

  /// Get inventory SMP item by ref_code (same format as get_all)
  static Future<Map<String, dynamic>> getInventorySmpByRef(
    String refCode,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/inventory_smp/get_by_ref.php?ref_code=$refCode',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final itemData = data['data'];

        // معالجة البيانات - نفس التنسيق كـ get_all
        final processed = _processInventoryItemWithOperations(itemData);

        return {'success': data['success'] ?? false, 'data': processed};
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

  /// Create new inventory SMP item
  static Future<Map<String, dynamic>> createInventorySmp(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/inventory_smp/create.php'),
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

  /// Update inventory SMP item (only material_name and material_type)
  static Future<Map<String, dynamic>> updateInventorySmp(
    Map<String, dynamic> data,
  ) async {
    try {
      final request = http.Request(
        'PUT',
        Uri.parse('$baseUrl/api/inventory_smp/update.php'),
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

  /// Delete inventory SMP item by ref_code (deletes from both tables)
  static Future<Map<String, dynamic>> deleteInventorySmp(String refCode) async {
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/api/inventory_smp/delete.php'),
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
          'details': responseData['details'],
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
