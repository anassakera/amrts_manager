import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_services.dart';

class CompanyInfoService {
  static Future<Map<String, dynamic>> getCompanyInfo(int companyId) async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiServices.baseUrl}/api/company_info/company_info_crud.php?action=read_single&CompanyID=$companyId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          final error = data['error'];
          throw Exception(error['message'] ?? 'فشل في تحميل معلومات الشركة');
        }
      } else {
        throw Exception('فشل في تحميل معلومات الشركة (${response.statusCode})');
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

  static Future<List<Map<String, dynamic>>> getAllCompanies() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiServices.baseUrl}/api/company_info/company_info_crud.php?action=read'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final companies = data['data'];
          if (companies == null) {
            return [];
          }
          return List<Map<String, dynamic>>.from(companies);
        } else {
          final error = data['error'];
          throw Exception(error['message'] ?? 'فشل في تحميل قائمة الشركات');
        }
      } else {
        throw Exception('فشل في تحميل قائمة الشركات (${response.statusCode})');
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

  static Future<Map<String, dynamic>> createCompany({
    required String legalName,
    required String ice,
    String? tradeName,
    String? rc,
    String? ifNumber,
    String? cnss,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? website,
    Uint8List? logoBytes,
  }) async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }

    try {
      final Map<String, dynamic> requestBody = {
        'legalName': legalName,
        'ice': ice,
        'tradeName': tradeName,
        'rc': rc,
        'ifNumber': ifNumber,
        'cnss': cnss,
        'address': address,
        'city': city,
        'country': country ?? 'Morocco',
        'phone': phone,
        'email': email,
        'website': website,
      };

      if (logoBytes != null) {
        requestBody['logo_base64'] = base64Encode(logoBytes);
      }

      final response = await http.post(
        Uri.parse('${ApiServices.baseUrl}/api/company_info/company_info_crud.php?action=create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          final error = data['error'];
          throw Exception(error['message'] ?? 'فشل في إنشاء الشركة');
        }
      } else {
        throw Exception('فشل في إنشاء الشركة (${response.statusCode})');
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

  static Future<Map<String, dynamic>> updateCompany({
    required int companyId,
    String? legalName,
    String? tradeName,
    String? ice,
    String? rc,
    String? ifNumber,
    String? cnss,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? website,
    Uint8List? logoBytes,
    bool removeLogo = false,
  }) async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }

    try {
      final Map<String, dynamic> requestBody = {
        'CompanyID': companyId,
      };

      // Only include non-empty fields to avoid constraint violations
      if (legalName != null && legalName.isNotEmpty) requestBody['legalName'] = legalName;
      if (tradeName != null && tradeName.isNotEmpty) requestBody['tradeName'] = tradeName;
      if (ice != null && ice.isNotEmpty) requestBody['ice'] = ice;
      if (rc != null && rc.isNotEmpty) requestBody['rc'] = rc;
      if (ifNumber != null && ifNumber.isNotEmpty) requestBody['ifNumber'] = ifNumber;
      if (cnss != null && cnss.isNotEmpty) requestBody['cnss'] = cnss;
      if (address != null && address.isNotEmpty) requestBody['address'] = address;
      if (city != null && city.isNotEmpty) requestBody['city'] = city;
      if (country != null && country.isNotEmpty) requestBody['country'] = country;
      if (phone != null && phone.isNotEmpty) requestBody['phone'] = phone;
      if (email != null && email.isNotEmpty) requestBody['email'] = email;
      if (website != null && website.isNotEmpty) requestBody['website'] = website;

      // Handle logo - only send if we have new logo or want to remove
      if (removeLogo) {
        requestBody['remove_logo'] = true;
      } else if (logoBytes != null) {
        requestBody['logo_base64'] = base64Encode(logoBytes);
      }

      final response = await http.post(
        Uri.parse('${ApiServices.baseUrl}/api/company_info/company_info_crud.php?action=update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          final error = data['error'];
          throw Exception(error['message'] ?? 'فشل في تحديث معلومات الشركة');
        }
      } else {
        throw Exception('فشل في تحديث معلومات الشركة (${response.statusCode})');
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

  static Future<Map<String, dynamic>> deleteCompany(int companyId) async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiServices.baseUrl}/api/company_info/company_info_crud.php?action=delete'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'CompanyID': companyId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          final error = data['error'];
          throw Exception(error['message'] ?? 'فشل في حذف الشركة');
        }
      } else {
        throw Exception('فشل في حذف الشركة (${response.statusCode})');
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

  static Uint8List? decodeBase64Logo(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }
}