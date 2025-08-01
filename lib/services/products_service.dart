import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductsService {
  // قم بتعيين عنوان URL الخاص بخدمة Products API
  final String baseUrl = 'http://localhost/amrts_manager/products';

  // الحصول على جميع المنتجات
  Future<List<dynamic>> getAllProducts() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  // إضافة منتج جديد
  Future<void> addProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add product');
    }
  }

  // حذف منتج
  Future<void> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$productId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  // تحديث منتج
  Future<void> updateProduct(int productId, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$productId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update product');
    }
  }

  // الحصول على تفاصيل منتج محدد
  Future<Map<String, dynamic>> getProductDetails(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$productId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product details');
    }
  }
}
