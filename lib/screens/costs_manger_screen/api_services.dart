import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:amrts_manager/model/api_services.dart';

class CostsApiService {
  static Future<String> _ensureBaseUrl() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }
    return ApiServices.baseUrl!;
  }

  Future<Map<String, dynamic>> getCosts() async {
    final baseUrl = await _ensureBaseUrl();
    final String apiUrl = "$baseUrl/api/costs/costs_api.php";

    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server Error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateCosts({
    required String fondrie,
    required String extrusion,
    required String peinture,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    final String apiUrl = "$baseUrl/api/costs/costs_api.php";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "cu_fondrie": fondrie,
          "cu_extrusion": extrusion,
          "cu_peinture": peinture,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server Error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Error: $e"};
    }
  }
}
