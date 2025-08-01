import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoicesService {
  // قم بتعيين عنوان URL الخاص بخدمة Invoices API
  final String baseUrl = 'http://localhost/amrts_manager/invoices';

  // الحصول على جميع الفواتير
  Future<List<dynamic>> getAllInvoices() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  // إضافة فاتورة جديدة
  Future<void> addInvoice(Map<String, dynamic> invoiceData) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoiceData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add invoice');
    }
  }

  // حذف فاتورة
  Future<void> deleteInvoice(int invoiceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$invoiceId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete invoice');
    }
  }

  // تحديث فاتورة
  Future<void> updateInvoice(int invoiceId, Map<String, dynamic> invoiceData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$invoiceId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoiceData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update invoice');
    }
  }

  // الحصول على تفاصيل فاتورة محددة
  Future<Map<String, dynamic>> getInvoiceDetails(int invoiceId) async {
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
