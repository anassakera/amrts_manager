import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiServices {
  static String? baseUrl;

  static Future<String> _getLocalIp() async {
    // تجنّب البلجن على الويب وويندوز/لينكس، واستخدم البلجن فقط على الموبايل
    if (kIsWeb) {
      return 'localhost';
    }

    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        final info = NetworkInfo();
        final ip = await info.getWifiIP();
        if (ip != null && ip.isNotEmpty) return ip;
      }
    } catch (_) {
      // تجاهل أي استثناء من البلجن، سنعتمد على البديل أدناه
    }

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return '127.0.0.1';
  }

  static Future<void> initBaseUrl() async {
    final ip = await _getLocalIp();
    baseUrl = 'http://$ip/amrts_manager';
    // ignore: avoid_print
    print(baseUrl);
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
}
