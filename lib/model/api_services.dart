import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  static const String baseUrl = 'http://localhost/amrts_manager/api';
  
  // خدمات الفواتير
  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/invoices/get_all.php'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load invoices');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> getInvoiceById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/invoices/get_by_id.php?id=$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> invoice) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invoice),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to create invoice');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateInvoice(String id, Map<String, dynamic> invoice) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/invoices/update.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invoice),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update invoice');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> deleteInvoice(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/invoices/delete.php?id=$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to delete invoice');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> searchInvoices(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/invoices/search.php?q=$query'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to search invoices');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateInvoiceStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/invoices/update_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'status': status}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update invoice status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateInvoiceType(String id, bool isLocal) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/invoices/update_type.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'isLocal': isLocal}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update invoice type');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}