import 'package:http/http.dart' as http;
import 'dart:convert';

class FinancialTransactionsService {
  // قم بتعيين عنوان URL الخاص بخدمة Financial Transactions API
  final String baseUrl = 'http://localhost/amrts_manager/financial_transactions';

  // الحصول على جميع المعاملات المالية
  Future<List<dynamic>> getAllTransactions() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  // إضافة معاملة مالية جديدة
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transactionData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add transaction');
    }
  }

  // حذف معاملة مالية
  Future<void> deleteTransaction(int transactionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$transactionId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction');
    }
  }

  // تحديث معاملة مالية
  Future<void> updateTransaction(int transactionId, Map<String, dynamic> transactionData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$transactionId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transactionData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction');
    }
  }
}
