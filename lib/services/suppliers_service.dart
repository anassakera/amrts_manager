import 'package:http/http.dart' as http;
import 'dart:convert';

class SuppliersService {
  // قم بتعيين عنوان URL الخاص بخدمة Suppliers API
  final String baseUrl = 'http://localhost/amrts_manager/suppliers';

  // الحصول على جميع الموردين
  Future<List<dynamic>> getAllSuppliers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load suppliers');
    }
  }

  // إضافة مورد جديد
  Future<void> addSupplier(Map<String, dynamic> supplierData) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(supplierData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add supplier');
    }
  }

  // حذف مورد
  Future<void> deleteSupplier(int supplierId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$supplierId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete supplier');
    }
  }

  // تحديث مورد
  Future<void> updateSupplier(int supplierId, Map<String, dynamic> supplierData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$supplierId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(supplierData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update supplier');
    }
  }

  // الحصول على تفاصيل مورد محدد
  Future<Map<String, dynamic>> getSupplierDetails(int supplierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$supplierId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load supplier details');
    }
  }
}
