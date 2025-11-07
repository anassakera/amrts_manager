import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:flutter/services.dart' show rootBundle;
import 'number_formatting_service.dart';

class PrintSalesDocuments {
  static String _getDocumentTitle(String documentRef) {
    if (documentRef.startsWith('BC')) {
      return 'BON DE COMMANDE';
    } else if (documentRef.startsWith('BL')) {
      return 'BON DE LIVRAISON';
    } else if (documentRef.startsWith('DE')) {
      return 'DEVIS';
    }
    return 'BON DE LIVRAISON'; // القيمة الافتراضية
  }

  static Future<Uint8List> generateInvoicesPdf(
    List<Map<String, dynamic>> commandes,
  ) async {
    final pdfDoc = pdf.Document();

    // Charger les polices Poppins
    final poppinsFont = pdf.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    );
    final poppinsBoldFont = pdf.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
    );

    const int itemsPerPage = 27; // الحد الأقصى للعناصر في الصفحة الواحدة

    for (final commande in commandes) {
      final items = commande['items'] as List?;
      final int totalItems = items?.length ?? 0;
      final int pageCount = (totalItems / itemsPerPage).ceil();

      // إذا لم يكن هناك عناصر أو عددها أقل من الحد، صفحة واحدة فقط
      if (items == null || items.isEmpty || totalItems <= itemsPerPage) {
        pdfDoc.addPage(
          pdf.Page(
            margin: const pdf.EdgeInsets.all(20),
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pdf.Container(
                color: PdfColors.white,
                child: pdf.Column(
                  crossAxisAlignment: pdf.CrossAxisAlignment.stretch,
                  children: [
                    // Titre BON DE LIVRAISON avec informations
                    pdf.Row(
                      children: [
                        // Titre BON DE LIVRAISON
                        pdf.Expanded(
                          flex: 2,
                          child: pdf.Container(
                            padding: const pdf.EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            decoration: pdf.BoxDecoration(
                              borderRadius: pdf.BorderRadius.circular(12),
                              color: PdfColor.fromHex('#1E3A8A'),
                            ),
                            child: pdf.Center(
                              child: pdf.Text(
                                _getDocumentTitle(
                                  commande['Document_Ref']?.toString() ?? '',
                                ),
                                style: pdf.TextStyle(
                                  font: poppinsBoldFont,
                                  fontSize: 26,
                                  color: PdfColors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        pdf.SizedBox(width: 5),
                        // Container des informations
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
                              boxShadow: [
                                pdf.BoxShadow(
                                  color: PdfColor.fromHex('#00000008'),
                                  offset: const PdfPoint(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: pdf.Column(
                              crossAxisAlignment: pdf.CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  'Client:',
                                  commande['Client'] ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                                pdf.SizedBox(height: 4),
                                _buildInfoRow(
                                  'Référence:',
                                  commande['Document_Ref']?.toString() ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                                pdf.SizedBox(height: 4),
                                _buildInfoRow(
                                  'Statut:',
                                  commande['status'] ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                                pdf.SizedBox(height: 4),
                                _buildInfoRow(
                                  'Date:',
                                  commande['date'] ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pdf.SizedBox(height: 5),
                    _buildItemsTable(items, poppinsFont, poppinsBoldFont),
                    pdf.SizedBox(height: 5),
                    pdf.Spacer(),
                    _buildSummaryBox(commande, poppinsFont, poppinsBoldFont),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        // تقسيم العناصر إلى صفحات
        for (int page = 0; page < pageCount; page++) {
          final start = page * itemsPerPage;
          final end = ((page + 1) * itemsPerPage < totalItems)
              ? (page + 1) * itemsPerPage
              : totalItems;
          final itemsChunk = items.sublist(start, end);

          pdfDoc.addPage(
            pdf.Page(
              margin: const pdf.EdgeInsets.all(20),
              pageFormat: PdfPageFormat.a4,
              build: (context) {
                return pdf.Container(
                  color: PdfColors.white,
                  child: pdf.Column(
                    crossAxisAlignment: pdf.CrossAxisAlignment.stretch,
                    children: [
                      if (page == 0) ...[
                        // Titre BON DE LIVRAISON avec informations (فقط في الصفحة الأولى)
                        pdf.Row(
                          children: [
                            pdf.Expanded(
                              flex: 2,
                              child: pdf.Container(
                                padding: const pdf.EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: pdf.BoxDecoration(
                                  borderRadius: pdf.BorderRadius.circular(12),
                                  color: PdfColor.fromHex('#1E3A8A'),
                                ),
                                child: pdf.Center(
                                  child: pdf.Text(
                                    _getDocumentTitle(
                                      commande['Document_Ref']?.toString() ??
                                          '',
                                    ),
                                    style: pdf.TextStyle(
                                      font: poppinsBoldFont,
                                      fontSize: 26,
                                      color: PdfColors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            pdf.SizedBox(width: 5),
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
                                  boxShadow: [
                                    pdf.BoxShadow(
                                      color: PdfColor.fromHex('#00000008'),
                                      offset: const PdfPoint(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: pdf.Column(
                                  crossAxisAlignment:
                                      pdf.CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      'Client:',
                                      commande['Client'] ?? '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                    pdf.SizedBox(height: 4),
                                    _buildInfoRow(
                                      'Référence:',
                                      commande['Document_Ref']?.toString() ??
                                          '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                    pdf.SizedBox(height: 4),
                                    _buildInfoRow(
                                      'Statut:',
                                      commande['status'] ?? '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                    pdf.SizedBox(height: 4),
                                    _buildInfoRow(
                                      'Date:',
                                      commande['date'] ?? '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        pdf.SizedBox(height: 5),
                      ],
                      // جدول العناصر لهذه الصفحة فقط
                      _buildItemsTable(
                        itemsChunk,
                        poppinsFont,
                        poppinsBoldFont,
                      ),
                      if (page == pageCount - 1) ...[
                        pdf.SizedBox(height: 5),
                        pdf.Spacer(),
                        _buildSummaryBox(
                          commande,
                          poppinsFont,
                          poppinsBoldFont,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        }
      }
    }

    return pdfDoc.save();
  }

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
            fontSize: 8,
            color: PdfColor.fromHex('#475569'),
          ),
        ),
        pdf.SizedBox(width: 4),
        pdf.Expanded(
          child: pdf.Text(
            value.isNotEmpty ? value : '-',
            style: pdf.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColor.fromHex('#1E293B'),
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  static pdf.Widget _buildItemsTable(
    List? items,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    // En-têtes du tableau
    final headers = [
      'Réf',
      'Désignation',
      'Qté',
      'Couleur',
      'Poids',
      'P.Cons',
      'Peinture',
      'Gaz',
    ];

    // Largeurs personnalisées pour chaque colonne
    final columnWidths = [
      0.8, // Réf
      1.5, // Désignation
      0.6, // Qté
      0.8, // Couleur
      0.7, // Poids
      0.8, // Poids consommé
      0.8, // Peinture
      0.8, // Gaz
    ];

    return pdf.Container(
      decoration: pdf.BoxDecoration(
        borderRadius: pdf.BorderRadius.circular(12),
        border: pdf.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1.5),
        boxShadow: [
          pdf.BoxShadow(
            color: PdfColor.fromHex('#00000008'),
            offset: const PdfPoint(0, 2),
            blurRadius: 9,
          ),
        ],
      ),
      child: pdf.Column(
        children: [
          // En-têtes du tableau
          pdf.Container(
            decoration: pdf.BoxDecoration(
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#1E3A8A'),
                  PdfColor.fromHex('#3B82F6'),
                ],
              ),
              borderRadius: const pdf.BorderRadius.only(
                topLeft: pdf.Radius.circular(12),
                topRight: pdf.Radius.circular(12),
              ),
            ),
            child: pdf.Row(
              children: List.generate(headers.length, (index) {
                return pdf.Expanded(
                  flex: (columnWidths[index] * 10).round(),
                  child: pdf.Container(
                    padding: const pdf.EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: pdf.Center(
                      child: pdf.Text(
                        headers[index],
                        style: pdf.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                        textAlign: pdf.TextAlign.center,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Contenu du tableau
          if (items == null || items.isEmpty)
            pdf.Container(
              height: 60,
              alignment: pdf.Alignment.center,
              decoration: pdf.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')),
              child: pdf.Text(
                'Aucun article disponible.',
                style: pdf.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey600,
                  fontStyle: pdf.FontStyle.italic,
                ),
              ),
            )
          else
            ...List.generate(items.length, (i) {
              final item = items[i];
              return pdf.Container(
                decoration: pdf.BoxDecoration(
                  color: i % 2 == 0
                      ? PdfColor.fromHex('#F9FAFB')
                      : PdfColors.white,
                  border: i < items.length - 1
                      ? pdf.Border(
                          bottom: pdf.BorderSide(
                            color: PdfColor.fromHex('#E5E7EB'),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: pdf.Row(
                  children: [
                    // Référence
                    pdf.Expanded(
                      flex: (columnWidths[0] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['product_reference'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Désignation
                    pdf.Expanded(
                      flex: (columnWidths[1] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['product_designation'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    // Quantité
                    pdf.Expanded(
                      flex: (columnWidths[2] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatQuantitySafe(
                            item['quantity'],
                          ),
                          style: pdf.TextStyle(font: boldFont, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Couleur
                    pdf.Expanded(
                      flex: (columnWidths[3] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['product_color'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Poids unitaire
                    pdf.Expanded(
                      flex: (columnWidths[4] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatWeightSafe(
                            item['weight_per_unit'],
                          ),
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Poids consommé
                    pdf.Expanded(
                      flex: (columnWidths[5] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatWeightSafe(
                            item['weight_consumed'],
                          ),
                          style: pdf.TextStyle(
                            font: boldFont,
                            fontSize: 7,
                            color: PdfColor.fromHex('#1E3A8A'),
                          ),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Peinture
                    pdf.Expanded(
                      flex: (columnWidths[6] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatWeightSafe(
                            item['peinture'],
                          ),
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Gaz
                    pdf.Expanded(
                      flex: (columnWidths[7] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatWeightSafe(item['gaz']),
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  static pdf.Widget _buildSummaryBox(
    Map<String, dynamic> commande,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final summaryFields = [
      ['Total articles:', '${commande['total_items'] ?? 0}'],
      [
        'Poids consommé:',
        NumberFormattingService.formatWeightSafe(
          commande['total_weight_consumed'],
        ),
      ],
      [
        'Total peinture:',
        NumberFormattingService.formatWeightSafe(commande['total_peinture']),
      ],
      [
        'Total gaz:',
        NumberFormattingService.formatWeightSafe(commande['total_gaz']),
      ],
      [
        'Total bellet:',
        NumberFormattingService.formatWeightSafe(commande['total_bellet']),
      ],
      [
        'Total déchet:',
        NumberFormattingService.formatWeightSafe(commande['total_dechet']),
      ],
    ];

    return pdf.Align(
      alignment: pdf.Alignment.centerRight,
      child: pdf.Container(
        width: double.infinity,
        padding: const pdf.EdgeInsets.all(16),
        decoration: pdf.BoxDecoration(
          gradient: pdf.LinearGradient(
            colors: [PdfColor.fromHex('#F8FAFC'), PdfColor.fromHex('#E2E8F0')],
            begin: pdf.Alignment.topLeft,
            end: pdf.Alignment.bottomRight,
          ),
          borderRadius: pdf.BorderRadius.circular(12),
          border: pdf.Border.all(
            color: PdfColor.fromHex('#CBD5E1'),
            width: 1.5,
          ),
          boxShadow: [
            pdf.BoxShadow(
              color: PdfColor.fromHex('#00000010'),
              offset: const PdfPoint(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.start,
          children: [
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
                'RÉSUMÉ',
                style: pdf.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: PdfColor.fromHex('#1E3A8A'),
                ),
                textAlign: pdf.TextAlign.center,
              ),
            ),
            pdf.SizedBox(height: 8),
            pdf.Row(
              mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
              children: [
                for (var row in summaryFields.take(3))
                  pdf.Container(
                    width: 110,
                    margin: const pdf.EdgeInsets.symmetric(horizontal: 2),
                    padding: const pdf.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
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
                      crossAxisAlignment: pdf.CrossAxisAlignment.start,
                      children: [
                        pdf.Text(
                          row[0],
                          style: pdf.TextStyle(
                            font: font,
                            fontSize: 9,
                            color: PdfColor.fromHex('#475569'),
                          ),
                        ),
                        pdf.SizedBox(height: 2),
                        pdf.Text(
                          row[1],
                          style: pdf.TextStyle(
                            font: boldFont,
                            fontSize: 10,
                            color: PdfColor.fromHex('#1E293B'),
                          ),
                          textAlign: pdf.TextAlign.right,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            pdf.SizedBox(height: 8),
            pdf.Row(
              mainAxisAlignment: pdf.MainAxisAlignment.spaceEvenly,
              children: [
                for (var row in summaryFields.skip(3))
                  pdf.Container(
                    width: 110,
                    margin: const pdf.EdgeInsets.symmetric(horizontal: 2),
                    padding: const pdf.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
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
                      crossAxisAlignment: pdf.CrossAxisAlignment.start,
                      children: [
                        pdf.Text(
                          row[0],
                          style: pdf.TextStyle(
                            font: font,
                            fontSize: 9,
                            color: PdfColor.fromHex('#475569'),
                          ),
                        ),
                        pdf.SizedBox(height: 2),
                        pdf.Text(
                          row[1],
                          style: pdf.TextStyle(
                            font: boldFont,
                            fontSize: 10,
                            color: PdfColor.fromHex('#1E293B'),
                          ),
                          textAlign: pdf.TextAlign.right,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
