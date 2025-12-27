import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class ApiServices {
  static String? baseUrl;

  /// قراءة عنوان IP السيرفر من ملف الإعدادات
  static Future<String> _getServerIp() async {
    try {
      // قراءة ملف الإعدادات من assets
      final configString = await rootBundle.loadString(
        'lib/api_amrts_manager/config/connectivity.config',
      );
      final config = json.decode(configString);
      final serverIP = config['serverIP'] as String?;
      if (serverIP != null && serverIP.isNotEmpty) {
        return serverIP;
      }
    } catch (e) {
      // ignore: avoid_print
      print('خطأ في قراءة ملف الإعدادات: $e');
    }
    // قيمة افتراضية في حالة فشل القراءة
    return '192.168.1.254';
  }

  static Future<void> initBaseUrl() async {
    final ip = await _getServerIp();
    baseUrl = 'http://$ip/amrts_manager';
    // ignore: avoid_print
    print('Base URL initialized: $baseUrl');
  }

  static Future<Map<String, dynamic>> signIn(
    String email,
    String password,
  ) async {
    if (baseUrl == null) {
      await initBaseUrl();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signin.php'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'email': email, 'password': password}),
    );

    return json.decode(response.body);
  }

  // خدمات المستخدمين
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/crud_user_api.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'فشل في تحميل المستخدمين');
        }
      } else {
        throw Exception('فشل في تحميل المستخدمين (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/crud_user_api.php?id=$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في تحميل المستخدم');
        }
      } else if (response.statusCode == 404) {
        throw Exception('المستخدم غير موجود');
      } else {
        throw Exception('فشل في تحميل المستخدم (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> user,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/crud_user_api.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(user),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في إنشاء المستخدم');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else {
        throw Exception('فشل في إنشاء المستخدم (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> user,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/crud_user_api.php?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(user),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في تحديث المستخدم');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else if (response.statusCode == 404) {
        throw Exception('المستخدم غير موجود');
      } else {
        throw Exception('فشل في تحديث المستخدم (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/crud_user_api.php?id=$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'فشل في حذف المستخدم');
        }
      } else if (response.statusCode == 404) {
        throw Exception('المستخدم غير موجود');
      } else {
        throw Exception('فشل في حذف المستخدم (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  // خدمات الفواتير
  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/invoices/get_all.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'فشل في تحميل الفواتير');
        }
      } else {
        throw Exception('فشل في تحميل الفواتير (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> getInvoiceById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/invoices/get_by_id.php?id=$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في تحميل الفاتورة');
        }
      } else if (response.statusCode == 404) {
        throw Exception('الفاتورة غير موجودة');
      } else {
        throw Exception('فشل في تحميل الفاتورة (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> createInvoice(
    Map<String, dynamic> invoice,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/invoices/create.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(invoice),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في إنشاء الفاتورة');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else {
        throw Exception('فشل في إنشاء الفاتورة (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> updateInvoice(
    String id,
    Map<String, dynamic> invoice,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(invoice);
      payload['id'] = id;

      final response = await http.put(
        Uri.parse('$baseUrl/api/invoices/update.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في تحديث الفاتورة');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else if (response.statusCode == 404) {
        throw Exception('الفاتورة غير موجودة');
      } else {
        throw Exception('فشل في تحديث الفاتورة (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<void> deleteInvoice(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/invoices/delete.php?id=$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'فشل في حذف الفاتورة');
        }
      } else if (response.statusCode == 404) {
        throw Exception('الفاتورة غير موجودة');
      } else {
        throw Exception('فشل في حذف الفاتورة (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> updateInvoiceStatus(
    String id,
    String status,
  ) async {
    http.Response? response;
    try {
      response = await http.put(
        Uri.parse('$baseUrl/api/invoices/update_status.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'id': id, 'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في تحديث حالة الفاتورة');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else if (response.statusCode == 404) {
        throw Exception('الفاتورة غير موجودة');
      } else {
        String errorMessage =
            'فشل في تحديث حالة الفاتورة (${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage += ': ${errorData['message']}';
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> updateInvoiceType(
    String id,
    bool isLocal,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/invoices/update_type.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'id': id, 'isLocal': isLocal}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في تحديث نوع الفاتورة');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else if (response.statusCode == 404) {
        throw Exception('الفاتورة غير موجودة');
      } else {
        throw Exception('فشل في تحديث نوع الفاتورة (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  // دالة مساعدة لاختبار الاتصال
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/API/test_connection.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // خدمات المخزون (Inventory)
  static Future<List<Map<String, dynamic>>> getAllInventory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory/inventory_read_all.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'فشل في تحميل المخزون');
        }
      } else {
        throw Exception('فشل في تحميل المخزون (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> sendInvoiceToInventory(
    String invoiceId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/inventory/inventory_create_from_invoice.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'invoice_id': invoiceId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'فشل في إرسال الفاتورة للمخزون');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'بيانات غير صحيحة');
      } else if (response.statusCode == 404) {
        throw Exception('الفاتورة غير موجودة');
      } else {
        throw Exception(
          'فشل في إرسال الفاتورة للمخزون (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  // ==========================================
  // خدمات الموردين (Suppliers)
  // ==========================================

  /// جلب جميع الموردين النشطين مع الترقيم
  static Future<List<Map<String, dynamic>>> getAllSuppliers({
    int page = 1,
    int pageSize = 50,
  }) async {
    if (baseUrl == null) {
      await initBaseUrl();
    }
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/suppliers/suppliers_read_all.php?page=$page&page_size=$pageSize',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['error'] ?? 'فشل في تحميل الموردين');
        }
      } else {
        throw Exception('فشل في تحميل الموردين (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  /// جلب مورد محدد بواسطة المعرف
  static Future<Map<String, dynamic>> getSupplierById(String id) async {
    if (baseUrl == null) {
      await initBaseUrl();
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/suppliers/suppliers_read_filtered.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'supplier_id': int.parse(id)}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List suppliers = data['data'];
          if (suppliers.isNotEmpty) {
            return Map<String, dynamic>.from(suppliers.first);
          }
          throw Exception('المورد غير موجود');
        } else {
          throw Exception(data['error'] ?? 'فشل في تحميل المورد');
        }
      } else if (response.statusCode == 404) {
        throw Exception('المورد غير موجود');
      } else {
        throw Exception('فشل في تحميل المورد (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  /// إنشاء مورد جديد
  static Future<Map<String, dynamic>> createSupplier(
    Map<String, dynamic> supplier,
  ) async {
    if (baseUrl == null) {
      await initBaseUrl();
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/suppliers/suppliers_create.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(supplier),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['error'] ?? 'فشل في إنشاء المورد');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'بيانات غير صحيحة');
      } else {
        throw Exception('فشل في إنشاء المورد (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  /// تحديث مورد موجود
  static Future<Map<String, dynamic>> updateSupplier(
    String id,
    Map<String, dynamic> supplier,
  ) async {
    if (baseUrl == null) {
      await initBaseUrl();
    }
    try {
      final payload = Map<String, dynamic>.from(supplier);
      payload['supplier_id'] = int.parse(id);

      final response = await http.post(
        Uri.parse('$baseUrl/api/suppliers/suppliers_update.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['error'] ?? 'فشل في تحديث المورد');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'بيانات غير صحيحة');
      } else if (response.statusCode == 404) {
        throw Exception('المورد غير موجود');
      } else {
        throw Exception('فشل في تحديث المورد (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  /// حذف مورد (soft أو hard)
  static Future<void> deleteSupplier(
    String id, {
    String deleteMode = 'soft',
  }) async {
    if (baseUrl == null) {
      await initBaseUrl();
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/suppliers/suppliers_delete.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'supplier_id': int.parse(id),
          'delete_mode': deleteMode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'فشل في حذف المورد');
        }
      } else if (response.statusCode == 404) {
        throw Exception('المورد غير موجود');
      } else {
        throw Exception('فشل في حذف المورد (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('خطأ في تنسيق البيانات المستلمة');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }
}
