import 'dart:convert';
import 'package:http/http.dart' as http;

class InvoicesApiService {
  // قم بتعيين عنوان URL الخاص بخدمة Invoices API
  final String baseUrl = 'http://localhost/amrts_manager/invoices';

  // الحصول على جميع الفواتير
  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  // إضافة فاتورة جديدة
  Future<Map<String, dynamic>> addInvoice(Map<String, dynamic> invoiceData) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoiceData),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add invoice');
    }
  }

  // حذف فاتورة
  Future<void> deleteInvoice(String invoiceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$invoiceId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete invoice');
    }
  }

  // تحديث فاتورة
  Future<Map<String, dynamic>> updateInvoice(String invoiceId, Map<String, dynamic> invoiceData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$invoiceId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoiceData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update invoice');
    }
  }

  // تحديث حالة الفاتورة
  Future<Map<String, dynamic>> updateInvoiceStatus(String invoiceId, String newStatus) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$invoiceId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': newStatus}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update invoice status');
    }
  }

  // تحديث نوع الفاتورة (محلي/خارجي)
  Future<Map<String, dynamic>> updateInvoiceType(String invoiceId, bool isLocal) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$invoiceId/type'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'isLocal': isLocal}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update invoice type');
    }
  }

  // الحصول على تفاصيل فاتورة محددة
  Future<Map<String, dynamic>> getInvoiceById(String invoiceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$invoiceId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load invoice details');
    }
  }
}
