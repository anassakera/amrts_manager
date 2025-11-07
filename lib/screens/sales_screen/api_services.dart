import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amrts_manager/model/api_services.dart';

/// Dedicated API helper for the sales module.
class SalesApiService {
  SalesApiService._();

  static const Duration _requestTimeout = Duration(seconds: 30);

  static Future<String> _ensureBaseUrl() async {
    if (ApiServices.baseUrl == null) {
      await ApiServices.initBaseUrl();
    }
    return ApiServices.baseUrl!;
  }

  static Map<String, String> get _headers => const {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  /// Fetch paginated sales orders.
  static Future<Map<String, dynamic>> fetchOrders({
    int page = 1,
    int pageSize = 20,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse(
      '$baseUrl/api/sales_orders/sales_orders_read_all.php',
    ).replace(queryParameters: {'page': '$page', 'page_size': '$pageSize'});

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    return {
      'orders': _normalizeOrders(parsed['data']),
      'pagination': parsed['pagination'],
      'meta': parsed,
    };
  }

  /// Fetch a single order by its document reference.
  static Future<Map<String, dynamic>> fetchOrderByRef(
    String documentRef,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse(
      '$baseUrl/api/sales_orders/sales_orders_read_by_id.php',
    );

    final response = await http
        .post(
          uri,
          headers: _headers,
          body: json.encode({'document_ref': documentRef}),
        )
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    return _normalizeOrder(parsed['data'] ?? <String, dynamic>{});
  }

  /// Create a new sales order.
  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> order,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse('$baseUrl/api/sales_orders/sales_orders_create.php');

    final response = await http
        .post(
          uri,
          headers: _headers,
          body: json.encode(_denormalizeOrder(order)),
        )
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    return _normalizeOrder(parsed['data'] ?? <String, dynamic>{});
  }

  /// Update an existing sales order.
  static Future<Map<String, dynamic>> updateOrder(
    Map<String, dynamic> order,
  ) async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse('$baseUrl/api/sales_orders/sales_orders_update.php');

    final response = await http
        .post(
          uri,
          headers: _headers,
          body: json.encode(_denormalizeOrder(order)),
        )
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    return _normalizeOrder(parsed['data'] ?? <String, dynamic>{});
  }

  /// Delete (soft by default) a sales order.
  static Future<void> deleteOrder(
    String documentRef, {
    bool hardDelete = false,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse('$baseUrl/api/sales_orders/sales_orders_delete.php');

    final response = await http
        .post(
          uri,
          headers: _headers,
          body: json.encode({
            'document_ref': documentRef,
            'delete_mode': hardDelete ? 'hard' : 'soft',
          }),
        )
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    _decodeResponse(response);
  }

  /// Retrieve aggregated statistics for dashboards.
  static Future<Map<String, dynamic>> fetchStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse('$baseUrl/api/sales_orders/sales_orders_stats.php');

    final body = {
      if (dateFrom != null) 'date_from': _formatDate(dateFrom),
      if (dateTo != null) 'date_to': _formatDate(dateTo),
    };

    final response = await http
        .post(uri, headers: _headers, body: json.encode(body))
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    return _normalizeStats(parsed['data'] ?? <String, dynamic>{});
  }

  /// Retrieve active articles for dropdowns.
  static Future<List<Map<String, dynamic>>> fetchArticles() async {
    final baseUrl = await _ensureBaseUrl();
    final uri = Uri.parse('$baseUrl/api/articles/articles_read_all.php');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_requestTimeout, onTimeout: _onTimeout);

    final parsed = _decodeResponse(response);
    final data = parsed['data'];

    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_normalizeArticle)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Future<http.Response> _onTimeout() {
    throw TimeoutException('La requÃªte a dÃ©passÃ© le dÃ©lai autorisÃ©.');
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    // debugPrint(
    //   '[SalesApiService] ${response.request?.url} '
    //   '→ ${response.statusCode}',
    // );

    if (response.body.isEmpty) {
      throw Exception('Réponse vide reçue du serveur.');
    }

    // طباعة الـ response للتشخيص
    // debugPrint('[SalesApiService] Response body: ${response.body}');

    // التحقق من أن الـ response هو JSON وليس HTML
    if (response.body.trim().startsWith('<')) {
      throw Exception(
        'Le serveur a retourné du HTML au lieu de JSON. '
        'Vérifiez l\'URL de l\'API ou les erreurs PHP sur le serveur.',
      );
    }

    try {
      final dynamic decodedBody = json.decode(response.body);
      if (decodedBody is! Map<String, dynamic>) {
        throw Exception('Format de réponse inattendu.');
      }

      final success = decodedBody['success'] == true;
      if (response.statusCode >= 200 && response.statusCode < 300 && success) {
        return decodedBody;
      }

      final message =
          decodedBody['message'] ??
          decodedBody['error'] ??
          response.reasonPhrase ??
          'Une erreur est survenue.';
      throw Exception(message.toString());
    } on FormatException catch (e) {
      throw Exception(
        'Erreur de format JSON: ${e.message}. '
        'Le serveur a peut-être retourné une erreur PHP.',
      );
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _normalizeOrders(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(_normalizeOrder).toList();
  }

  static Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    final items = order['items'];
    return {...order, 'items': _normalizeItems(items)};
  }

  static List<Map<String, dynamic>> _normalizeItems(dynamic items) {
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().map(_normalizeItem).toList();
  }

  static Map<String, dynamic> _normalizeItem(Map<String, dynamic> item) {
    final reference = item['Référence'] ?? item['product_reference'];
    final designation = item['Désignation'] ?? item['product_designation'];
    final quantity = _toInt(item['Quantité'] ?? item['quantity']);
    final weightConsumed = _toDouble(
      item['Poids consommé'] ?? item['weight_consumed'],
    );

    return {
      ...item,
      'item_id': item['item_id'],
      'Référence': reference,
      'Désignation': designation,
      'Quantité': quantity,
      'Poids consommé': weightConsumed,
      'Poids': _toDouble(item['Poids'] ?? item['weight_per_unit']),
      'Peinture': _toDouble(item['Peinture'] ?? item['peinture']),
      'Gaz': _toDouble(item['Gaz'] ?? item['gaz']),
      'bellet': _toDouble(item['bellet']),
      'dechet': _toDouble(item['dechet']),
      'dechet initial': _toDouble(
        item['dechet initial'] ?? item['dechet_initial'],
      ),
      'Price': _toDouble(item['Price'] ?? item['unit_price']),
      'Couleur': item['Couleur'] ?? item['product_color'],
      'date': item['date'] ?? item['item_date'],
    };
  }

  static Map<String, dynamic> _normalizeArticle(Map<String, dynamic> article) {
    final reference = article['Référence'] ?? article['Référence'];
    final designation = article['Désignation'] ?? article['Désignation'];

    return {
      ...article,
      'Référence': reference,
      'Désignation': designation,
      'Poids': _toDouble(article['Poids']),
      'Price': _toDouble(article['Price']),
    };
  }

  static Map<String, dynamic> _normalizeStats(Map<String, dynamic> stats) {
    return {
      ...stats,
      'totalPoidsConsomme': _toDouble(stats['totalPoidsConsomme']),
      'totalPeinture': _toDouble(stats['totalPeinture']),
      'totalGaz': _toDouble(stats['totalGaz']),
      'totalBellet': _toDouble(stats['totalBellet']),
      'totalDechet': _toDouble(stats['totalDechet']),
      'totalDechetInitial': _toDouble(stats['totalDechetInitial']),
      'total_revenue': _toDouble(stats['total_revenue']),
      'avg_order_value': _toDouble(stats['avg_order_value']),
    };
  }

  static Map<String, dynamic> _denormalizeOrder(Map<String, dynamic> order) {
    final items = order['items'];
    return {
      'Document_Ref': order['Document_Ref'],
      'Client': order['Client'],
      'date': order['date'],
      if (order['status'] != null) 'status': order['status'],
      'items': _denormalizeItems(items),
    };
  }

  static List<Map<String, dynamic>> _denormalizeItems(dynamic items) {
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_denormalizeItem)
        .toList();
  }

  static Map<String, dynamic> _denormalizeItem(Map<String, dynamic> item) {
    return {
      'product_reference': item['Référence'] ?? item['Référence'],
      'product_designation': item['Désignation'] ?? item['Désignation'],
      'weight_per_unit': _toDouble(item['Poids']),
      'quantity': _toInt(item['Quantité'] ?? item['Quantité']),
      'product_color': item['Couleur'],
      'weight_consumed': _toDouble(
        item['Poids consommé'] ?? item['Poids consommé'],
      ),
      'peinture': _toDouble(item['Peinture']),
      'gaz': _toDouble(item['Gaz']),
      'bellet': _toDouble(item['bellet']),
      'dechet': _toDouble(item['dechet']),
      'dechet_initial': _toDouble(item['dechet initial']),
      'unit_price': _toDouble(item['Price']),
      'item_date': item['date'],
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
