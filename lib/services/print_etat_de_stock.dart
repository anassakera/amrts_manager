import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'number_formatting_service.dart';

/// Service for printing État de Stock (Inventory Status) reports with detailed operations
class PrintEtatDeStockService {
  /// Stock types enumeration
  static const String stockMatierePremiere = 'Stock de Matiere Premiere';
  static const String stockSemiFini = 'Stock Semi Fini';
  static const String stockProduitsFini = 'Stock Produits Fini';

  /// Generate État de Stock PDF for a specific stock type with detailed operations
  static Future<Uint8List> generateEtatDeStock({
    required String stockType,
    required List<Map<String, dynamic>> stockData,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pdfDoc = pdf.Document();

    // Load Poppins fonts
    final poppinsFont = pdf.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    );
    final poppinsBoldFont = pdf.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final fromStr = dateFormat.format(fromDate);
    final toStr = dateFormat.format(toDate);

    // Filter data by date range and get detailed operations
    final filteredData = _filterByDateRange(stockData, fromDate, toDate);

    // Calculate totals
    final totals = _calculateTotals(filteredData, stockType);

    // Build pages with articles and their operations
    final List<pdf.Widget> allArticleWidgets = [];

    for (final item in filteredData) {
      allArticleWidgets.add(
        _buildArticleWithOperations(
          item,
          stockType,
          poppinsFont,
          poppinsBoldFont,
        ),
      );
      allArticleWidgets.add(pdf.SizedBox(height: 12));
    }

    // Add pages
    pdfDoc.addPage(
      pdf.MultiPage(
        margin: const pdf.EdgeInsets.all(20),
        pageFormat: PdfPageFormat.a4,
        header: (context) => context.pageNumber == 1
            ? pdf.Column(
                children: [
                  _buildHeader(
                    stockType,
                    fromStr,
                    toStr,
                    poppinsFont,
                    poppinsBoldFont,
                  ),
                  pdf.SizedBox(height: 15),
                ],
              )
            : pdf.Container(
                margin: const pdf.EdgeInsets.only(bottom: 10),
                child: pdf.Row(
                  mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
                  children: [
                    pdf.Text(
                      'ÉTAT DE STOCK - $stockType',
                      style: pdf.TextStyle(
                        font: poppinsBoldFont,
                        fontSize: 10,
                        color: PdfColor.fromHex('#1E3A8A'),
                      ),
                    ),
                    pdf.Text(
                      'Période: $fromStr à $toStr',
                      style: pdf.TextStyle(
                        font: poppinsFont,
                        fontSize: 9,
                        color: PdfColor.fromHex('#64748B'),
                      ),
                    ),
                  ],
                ),
              ),
        footer: (context) => pdf.Container(
          alignment: pdf.Alignment.centerRight,
          margin: const pdf.EdgeInsets.only(top: 10),
          child: pdf.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pdf.TextStyle(
              font: poppinsFont,
              fontSize: 9,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ),
        build: (context) => [
          if (filteredData.isEmpty)
            pdf.Container(
              height: 100,
              alignment: pdf.Alignment.center,
              child: pdf.Text(
                'Aucune donnée disponible pour cette période.',
                style: pdf.TextStyle(
                  font: poppinsFont,
                  fontSize: 14,
                  color: PdfColors.grey600,
                  fontStyle: pdf.FontStyle.italic,
                ),
              ),
            )
          else
            ...allArticleWidgets,
          pdf.SizedBox(height: 20),
          _buildTotalsBox(totals, stockType, poppinsFont, poppinsBoldFont),
        ],
      ),
    );

    return pdfDoc.save();
  }

  /// Build article header with its operations table
  static pdf.Widget _buildArticleWithOperations(
    Map<String, dynamic> item,
    String stockType,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final operations = item['filtered_operations'] as List? ?? [];

    return pdf.Container(
      decoration: pdf.BoxDecoration(
        borderRadius: pdf.BorderRadius.circular(8),
        border: pdf.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      ),
      child: pdf.Column(
        crossAxisAlignment: pdf.CrossAxisAlignment.stretch,
        children: [
          // Article Header
          _buildArticleHeader(item, stockType, font, boldFont),
          // Operations Table
          if (operations.isNotEmpty)
            _buildOperationsTable(operations, stockType, font, boldFont)
          else
            pdf.Container(
              padding: const pdf.EdgeInsets.all(12),
              color: PdfColor.fromHex('#F9FAFB'),
              child: pdf.Text(
                'Aucune opération dans cette période',
                style: pdf.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pdf.FontStyle.italic,
                ),
                textAlign: pdf.TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Build article header row
  static pdf.Widget _buildArticleHeader(
    Map<String, dynamic> item,
    String stockType,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final refCode = item['ref_code']?.toString() ?? '-';
    final name = _getArticleName(item, stockType);
    final type = _getArticleType(item, stockType);
    final totalQty = item['filtered_quantity'] ?? item['total_quantity'] ?? 0;
    final totalAmount = item['filtered_amount'] ?? item['total_amount'] ?? 0;
    final status = item['status']?.toString() ?? 'Disponible';

    return pdf.Container(
      padding: const pdf.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pdf.BoxDecoration(
        gradient: pdf.LinearGradient(
          colors: [PdfColor.fromHex('#1E3A8A'), PdfColor.fromHex('#3B82F6')],
        ),
        borderRadius: const pdf.BorderRadius.only(
          topLeft: pdf.Radius.circular(8),
          topRight: pdf.Radius.circular(8),
        ),
      ),
      child: pdf.Row(
        children: [
          // Ref Code Badge
          pdf.Container(
            padding: const pdf.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pdf.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pdf.BorderRadius.circular(4),
            ),
            child: pdf.Text(
              refCode,
              style: pdf.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColor.fromHex('#1E3A8A'),
              ),
            ),
          ),
          pdf.SizedBox(width: 10),
          // Name and Type
          pdf.Expanded(
            flex: 3,
            child: pdf.Column(
              crossAxisAlignment: pdf.CrossAxisAlignment.start,
              children: [
                pdf.Text(
                  name,
                  style: pdf.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                  maxLines: 1,
                ),
                if (type.isNotEmpty)
                  pdf.Text(
                    type,
                    style: pdf.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: PdfColor.fromHex('#BFDBFE'),
                    ),
                  ),
              ],
            ),
          ),
          // Stats
          pdf.SizedBox(width: 10),
          _buildHeaderStat(
            'Qté',
            NumberFormattingService.formatQuantitySafe(totalQty),
            font,
            boldFont,
          ),
          pdf.SizedBox(width: 15),
          _buildHeaderStat(
            'Montant',
            NumberFormattingService.formatCurrencySafe(totalAmount, symbol: ''),
            font,
            boldFont,
          ),
          pdf.SizedBox(width: 15),
          // Status Badge
          pdf.Container(
            padding: const pdf.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pdf.BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: pdf.BorderRadius.circular(4),
            ),
            child: pdf.Text(
              status,
              style: pdf.TextStyle(
                font: font,
                fontSize: 8,
                color: _getStatusTextColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header stat widget
  static pdf.Widget _buildHeaderStat(
    String label,
    String value,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    return pdf.Column(
      crossAxisAlignment: pdf.CrossAxisAlignment.end,
      children: [
        pdf.Text(
          label,
          style: pdf.TextStyle(
            font: font,
            fontSize: 8,
            color: PdfColor.fromHex('#BFDBFE'),
          ),
        ),
        pdf.Text(
          value,
          style: pdf.TextStyle(
            font: boldFont,
            fontSize: 10,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  /// Build operations table for an article
  static pdf.Widget _buildOperationsTable(
    List operations,
    String stockType,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final headers = _getOperationHeaders(stockType);
    final columnWidths = _getOperationColumnWidths(stockType);

    return pdf.Column(
      children: [
        // Table Header
        pdf.Container(
          color: PdfColor.fromHex('#F1F5F9'),
          padding: const pdf.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pdf.Row(
            children: List.generate(headers.length, (index) {
              return pdf.Expanded(
                flex: (columnWidths[index] * 10).round(),
                child: pdf.Text(
                  headers[index],
                  style: pdf.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromHex('#475569'),
                  ),
                  textAlign: index == 1 || index == 2
                      ? pdf.TextAlign.left
                      : pdf.TextAlign.center,
                ),
              );
            }),
          ),
        ),
        // Table Rows
        ...List.generate(operations.length, (i) {
          final op = operations[i] as Map<String, dynamic>;
          final values = _getOperationValues(op, stockType);
          final isLast = i == operations.length - 1;

          return pdf.Container(
            padding: const pdf.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: pdf.BoxDecoration(
              color: i % 2 == 0 ? PdfColors.white : PdfColor.fromHex('#FAFAFA'),
              border: !isLast
                  ? pdf.Border(
                      bottom: pdf.BorderSide(
                        color: PdfColor.fromHex('#E5E7EB'),
                        width: 0.5,
                      ),
                    )
                  : null,
              borderRadius: isLast
                  ? const pdf.BorderRadius.only(
                      bottomLeft: pdf.Radius.circular(8),
                      bottomRight: pdf.Radius.circular(8),
                    )
                  : null,
            ),
            child: pdf.Row(
              children: List.generate(values.length, (colIndex) {
                final isAmount = colIndex == values.length - 1;
                final isName = colIndex == 1 || colIndex == 2;

                return pdf.Expanded(
                  flex: (columnWidths[colIndex] * 10).round(),
                  child: pdf.Text(
                    values[colIndex],
                    style: pdf.TextStyle(
                      font: isAmount ? boldFont : font,
                      fontSize: 8,
                      color: isAmount
                          ? PdfColor.fromHex('#059669')
                          : PdfColor.fromHex('#1E293B'),
                    ),
                    textAlign: isName
                        ? pdf.TextAlign.left
                        : pdf.TextAlign.center,
                    maxLines: 1,
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  /// Get operation table headers based on stock type
  static List<String> _getOperationHeaders(String stockType) {
    switch (stockType) {
      case stockMatierePremiere:
        return [
          'Date',
          'N° Facture',
          'Fournisseur',
          'Qté',
          'Prix U.',
          'Montant',
        ];
      case stockSemiFini:
        return ['Date', 'Doc Réf.', 'Source', 'Qté', 'Poids', 'Montant'];
      case stockProduitsFini:
        return ['Date', 'Doc Réf.', 'Source', 'Qté', 'Poids', 'Valeur'];
      default:
        return ['Date', 'Référence', 'Description', 'Qté', 'Montant'];
    }
  }

  /// Get operation column widths
  static List<double> _getOperationColumnWidths(String stockType) {
    // Date, Reference, Source/Supplier, Qty, Price/Weight, Amount
    return [1.0, 1.0, 1.5, 0.7, 0.8, 1.0];
  }

  /// Get operation row values
  static List<String> _getOperationValues(
    Map<String, dynamic> op,
    String stockType,
  ) {
    final date = (op['date']?.toString() ?? '-').length >= 10
        ? op['date'].toString().substring(0, 10)
        : op['date']?.toString() ?? '-';

    switch (stockType) {
      case stockMatierePremiere:
        return [
          date,
          op['n_facture']?.toString() ?? '-',
          op['fournisseur']?.toString() ?? '-',
          NumberFormattingService.formatQuantitySafe(op['quantite']),
          NumberFormattingService.formatCurrencySafe(op['prix_u'], symbol: ''),
          NumberFormattingService.formatCurrencySafe(
            op['total_amount'],
            symbol: '',
          ),
        ];
      case stockSemiFini:
        return [
          date,
          op['doc_ref']?.toString() ?? op['n_facture']?.toString() ?? '-',
          op['source']?.toString() ?? op['fournisseur']?.toString() ?? '-',
          NumberFormattingService.formatQuantitySafe(
            op['quantity'] ?? op['quantite'],
          ),
          NumberFormattingService.formatWeightSafe(op['total_weight']),
          NumberFormattingService.formatCurrencySafe(
            op['total_amount'] ?? op['total_cost'],
            symbol: '',
          ),
        ];
      case stockProduitsFini:
        return [
          date,
          op['doc_ref']?.toString() ?? '-',
          op['source']?.toString() ?? '-',
          NumberFormattingService.formatQuantitySafe(op['quantity']),
          NumberFormattingService.formatWeightSafe(op['total_weight']),
          NumberFormattingService.formatCurrencySafe(
            op['selling_price'],
            symbol: '',
          ),
        ];
      default:
        return [
          date,
          op['ref']?.toString() ?? '-',
          op['description']?.toString() ?? '-',
          NumberFormattingService.formatQuantitySafe(op['quantity']),
          NumberFormattingService.formatCurrencySafe(op['amount'], symbol: ''),
        ];
    }
  }

  /// Get article name based on stock type
  static String _getArticleName(Map<String, dynamic> item, String stockType) {
    switch (stockType) {
      case stockMatierePremiere:
        return item['material_name']?.toString() ?? '-';
      default:
        return item['product_name']?.toString() ??
            item['material_name']?.toString() ??
            '-';
    }
  }

  /// Get article type based on stock type
  static String _getArticleType(Map<String, dynamic> item, String stockType) {
    switch (stockType) {
      case stockMatierePremiere:
        return item['material_type']?.toString() ?? '';
      default:
        return item['product_type']?.toString() ?? '';
    }
  }

  /// Get status background color
  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return PdfColor.fromHex('#DCFCE7');
      case 'épuisé':
      case 'epuise':
        return PdfColor.fromHex('#FEE2E2');
      case 'faible':
        return PdfColor.fromHex('#FEF9C3');
      default:
        return PdfColor.fromHex('#F1F5F9');
    }
  }

  /// Get status text color
  static PdfColor _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return PdfColor.fromHex('#166534');
      case 'épuisé':
      case 'epuise':
        return PdfColor.fromHex('#991B1B');
      case 'faible':
        return PdfColor.fromHex('#854D0E');
      default:
        return PdfColor.fromHex('#475569');
    }
  }

  /// Filter stock data by date range
  static List<Map<String, dynamic>> _filterByDateRange(
    List<Map<String, dynamic>> data,
    DateTime fromDate,
    DateTime toDate,
  ) {
    final List<Map<String, dynamic>> result = [];

    for (final item in data) {
      // Get operations from the item
      final operations = _getOperations(item);

      // Filter operations by date range
      final filteredOps = operations.where((op) {
        final dateStr = op['date']?.toString() ?? '';
        final date = _parseDate(dateStr);
        if (date == null) return false;
        return !date.isBefore(fromDate) && !date.isAfter(toDate);
      }).toList();

      // If has operations in range, include the item with filtered operations
      if (filteredOps.isNotEmpty) {
        final itemCopy = Map<String, dynamic>.from(item);
        itemCopy['filtered_operations'] = filteredOps;
        itemCopy['filtered_quantity'] = filteredOps.fold<double>(
          0.0,
          (sum, op) => sum + _toDouble(op['quantite'] ?? op['quantity']),
        );
        itemCopy['filtered_amount'] = filteredOps.fold<double>(
          0.0,
          (sum, op) => sum + _toDouble(op['total_amount'] ?? op['total_cost']),
        );
        result.add(itemCopy);
      }
    }

    return result;
  }

  /// Get operations list from stock item based on stock type
  static List<Map<String, dynamic>> _getOperations(Map<String, dynamic> item) {
    final keys = [
      'inventory_smp_operations',
      'inventory_ssf_operations',
      'items',
      'operations',
    ];

    for (final key in keys) {
      if (item[key] != null && item[key] is List) {
        return (item[key] as List).cast<Map<String, dynamic>>();
      }
    }

    return [];
  }

  /// Parse date string to DateTime
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      if (dateStr.length >= 10) {
        final datePart = dateStr.substring(0, 10);
        return DateTime.parse(datePart);
      }
    } catch (_) {}

    return null;
  }

  /// Calculate totals for the filtered data
  static Map<String, dynamic> _calculateTotals(
    List<Map<String, dynamic>> data,
    String stockType,
  ) {
    double totalQuantity = 0;
    double totalAmount = 0;
    double totalWeight = 0;
    int itemCount = data.length;
    int operationsCount = 0;

    for (final item in data) {
      totalQuantity += _toDouble(
        item['filtered_quantity'] ?? item['total_quantity'],
      );
      totalAmount += _toDouble(item['filtered_amount'] ?? item['total_amount']);
      totalWeight += _toDouble(item['total_weight']);
      operationsCount += (item['filtered_operations'] as List?)?.length ?? 0;
    }

    return {
      'itemCount': itemCount,
      'operationsCount': operationsCount,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'totalWeight': totalWeight,
    };
  }

  /// Build PDF header
  static pdf.Widget _buildHeader(
    String stockType,
    String fromDate,
    String toDate,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    return pdf.Row(
      children: [
        // Title box
        pdf.Expanded(
          flex: 2,
          child: pdf.Container(
            padding: const pdf.EdgeInsets.symmetric(vertical: 16),
            decoration: pdf.BoxDecoration(
              borderRadius: pdf.BorderRadius.circular(12),
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#1E3A8A'),
                  PdfColor.fromHex('#3B82F6'),
                ],
              ),
            ),
            child: pdf.Column(
              children: [
                pdf.Text(
                  'ÉTAT DE STOCK',
                  style: pdf.TextStyle(
                    font: boldFont,
                    fontSize: 24,
                    color: PdfColors.white,
                    letterSpacing: 2,
                  ),
                ),
                pdf.SizedBox(height: 4),
                pdf.Text(
                  stockType.toUpperCase(),
                  style: pdf.TextStyle(
                    font: font,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        pdf.SizedBox(width: 10),
        // Info box
        pdf.Expanded(
          flex: 1,
          child: pdf.Container(
            padding: const pdf.EdgeInsets.all(12),
            decoration: pdf.BoxDecoration(
              borderRadius: pdf.BorderRadius.circular(10),
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#F8FAFC'),
                  PdfColor.fromHex('#E2E8F0'),
                ],
              ),
              border: pdf.Border.all(
                color: PdfColor.fromHex('#CBD5E1'),
                width: 1.5,
              ),
            ),
            child: pdf.Column(
              crossAxisAlignment: pdf.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Période:', '', font, boldFont),
                pdf.SizedBox(height: 4),
                _buildInfoRow('Du:', fromDate, font, boldFont),
                pdf.SizedBox(height: 4),
                _buildInfoRow('Au:', toDate, font, boldFont),
                pdf.SizedBox(height: 4),
                _buildInfoRow(
                  'Imprimé le:',
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  font,
                  boldFont,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build info row for header
  static pdf.Widget _buildInfoRow(
    String label,
    String value,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    return pdf.Row(
      crossAxisAlignment: pdf.CrossAxisAlignment.start,
      children: [
        pdf.Text(
          label,
          style: pdf.TextStyle(
            font: boldFont,
            fontSize: 9,
            color: PdfColor.fromHex('#475569'),
          ),
        ),
        pdf.SizedBox(width: 4),
        pdf.Expanded(
          child: pdf.Text(
            value.isNotEmpty ? value : '',
            style: pdf.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColor.fromHex('#1E293B'),
            ),
          ),
        ),
      ],
    );
  }

  /// Build totals summary box
  static pdf.Widget _buildTotalsBox(
    Map<String, dynamic> totals,
    String stockType,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final summaryItems = _getTotalsSummary(totals, stockType);

    return pdf.Container(
      padding: const pdf.EdgeInsets.all(16),
      decoration: pdf.BoxDecoration(
        gradient: pdf.LinearGradient(
          colors: [PdfColor.fromHex('#F8FAFC'), PdfColor.fromHex('#E2E8F0')],
          begin: pdf.Alignment.topLeft,
          end: pdf.Alignment.bottomRight,
        ),
        borderRadius: pdf.BorderRadius.circular(12),
        border: pdf.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1.5),
      ),
      child: pdf.Column(
        children: [
          // Title
          pdf.Container(
            width: double.infinity,
            padding: const pdf.EdgeInsets.only(bottom: 8),
            decoration: pdf.BoxDecoration(
              border: pdf.Border(
                bottom: pdf.BorderSide(
                  color: PdfColor.fromHex('#1E3A8A'),
                  width: 2,
                ),
              ),
            ),
            child: pdf.Text(
              'RÉCAPITULATIF',
              style: pdf.TextStyle(
                font: boldFont,
                fontSize: 14,
                color: PdfColor.fromHex('#1E3A8A'),
              ),
              textAlign: pdf.TextAlign.center,
            ),
          ),
          pdf.SizedBox(height: 12),
          // Summary cards
          pdf.Row(
            mainAxisAlignment: pdf.MainAxisAlignment.spaceEvenly,
            children: summaryItems.map((item) {
              return pdf.Container(
                width: 110,
                padding: const pdf.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: pdf.BoxDecoration(
                  color: PdfColor.fromHex('#F1F5F9'),
                  borderRadius: pdf.BorderRadius.circular(8),
                  border: pdf.Border.all(
                    color: PdfColor.fromHex('#CBD5E1'),
                    width: 1,
                  ),
                ),
                child: pdf.Column(
                  children: [
                    pdf.Text(
                      item['label']!,
                      style: pdf.TextStyle(
                        font: font,
                        fontSize: 8,
                        color: PdfColor.fromHex('#475569'),
                      ),
                      textAlign: pdf.TextAlign.center,
                    ),
                    pdf.SizedBox(height: 4),
                    pdf.Text(
                      item['value']!,
                      style: pdf.TextStyle(
                        font: boldFont,
                        fontSize: 11,
                        color: PdfColor.fromHex('#1E3A8A'),
                      ),
                      textAlign: pdf.TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Get totals summary based on stock type
  static List<Map<String, String>> _getTotalsSummary(
    Map<String, dynamic> totals,
    String stockType,
  ) {
    final List<Map<String, String>> items = [
      {'label': 'Articles', 'value': totals['itemCount']?.toString() ?? '0'},
      {
        'label': 'Opérations',
        'value': totals['operationsCount']?.toString() ?? '0',
      },
      {
        'label': 'Quantité totale',
        'value': NumberFormattingService.formatQuantitySafe(
          totals['totalQuantity'],
        ),
      },
      {
        'label': 'Montant total',
        'value': NumberFormattingService.formatCurrencySafe(
          totals['totalAmount'],
        ),
      },
    ];

    return items;
  }

  /// Convert value to double safely
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
