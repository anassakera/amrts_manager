import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:flutter/services.dart' show rootBundle;
import 'number_formatting_service.dart';

class PrintInvoiceServiceBuy {
  static Future<Uint8List> generateInvoicesPdf(
    List<Map<String, dynamic>> invoices,
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

    for (final invoice in invoices) {
      final items = invoice['items'] as List?;
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
                    // Titre FACTURE avec informations
                    pdf.Row(
                      children: [
                        // Titre FACTURE
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
                                'FACTURE',
                                style: pdf.TextStyle(
                                  font: poppinsBoldFont,
                                  fontSize: 32,
                                  color: PdfColors.white,
                                  letterSpacing: 3,
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
                                  'Nom du fournisseur:',
                                  invoice['clientName'] ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                                pdf.SizedBox(height: 4),
                                _buildInfoRow(
                                  'Numéro de facture:',
                                  invoice['invoiceNumber']?.toString() ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                                pdf.SizedBox(height: 4),
                                _buildInfoRow(
                                  'Statut:',
                                  invoice['status'] ?? '',
                                  poppinsFont,
                                  poppinsBoldFont,
                                ),
                                pdf.SizedBox(height: 4),
                                _buildInfoRow(
                                  'Date et heure:',
                                  invoice['date'] ?? '',
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
                    _buildSummaryBox(
                      invoice['summary'] as Map<String, dynamic>?,
                      poppinsFont,
                      poppinsBoldFont,
                      invoice['totalAmount'],
                    ),
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
                        // Titre FACTURE avec informations (فقط في الصفحة الأولى)
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
                                    'FACTURE',
                                    style: pdf.TextStyle(
                                      font: poppinsBoldFont,
                                      fontSize: 32,
                                      color: PdfColors.white,
                                      letterSpacing: 3,
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
                                      'Nom du fournisseur:',
                                      invoice['clientName'] ?? '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                    pdf.SizedBox(height: 4),
                                    _buildInfoRow(
                                      'Numéro de la facture:',
                                      invoice['invoiceNumber']?.toString() ??
                                          '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                    pdf.SizedBox(height: 4),
                                    _buildInfoRow(
                                      'Statut:',
                                      invoice['status'] ?? '',
                                      poppinsFont,
                                      poppinsBoldFont,
                                    ),
                                    pdf.SizedBox(height: 4),
                                    _buildInfoRow(
                                      'Date et heure:',
                                      invoice['date'] ?? '',
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
                          invoice['summary'] as Map<String, dynamic>?,
                          poppinsFont,
                          poppinsBoldFont,
                          invoice['totalAmount'],
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
    // En-têtes du tableau optimisés pour tenir sur une ligne
    final headers = [
      'Réf',
      'Article',
      'Qté',
      'Poids',
      'P.U',
      'M.Total',
      // 'P.Achat',
      // 'A.Frais',
      // 'C.U',
    ];

    // Largeurs personnalisées pour chaque colonne
    final columnWidths = [
      1.0, // Réf.
      1.8, // Article
      0.8, // Qté
      1.0, // Poids
      1.0, // P.U.
      1.2, // Total
      // 1.0, // Achat
      // 1.0, // Frais
      // 1.0, // Coût
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
                'Aucun article disponible pour cette facture.',
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
                    // Réf. fournisseur
                    pdf.Expanded(
                      flex: (columnWidths[0] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['refFournisseur'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 8),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Article
                    pdf.Expanded(
                      flex: (columnWidths[1] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['articles'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 8),
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
                            item['qte'],
                          ),
                          style: pdf.TextStyle(font: font, fontSize: 8),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Poids
                    pdf.Expanded(
                      flex: (columnWidths[3] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatWeightSafe(
                            item['poids'],
                          ),
                          style: pdf.TextStyle(font: font, fontSize: 8),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Prix unitaire
                    pdf.Expanded(
                      flex: (columnWidths[4] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatCurrencySafe(
                            item['puPieces'],
                            symbol: '',
                          ),
                          style: pdf.TextStyle(font: font, fontSize: 8),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ),
                    // Montant total
                    pdf.Expanded(
                      flex: (columnWidths[5] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatCurrencySafe(
                            item['mt'],
                          ),
                          style: pdf.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: PdfColor.fromHex('#1E3A8A'),
                          ),
                          textAlign: pdf.TextAlign.right,
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
    Map<String, dynamic>? summary,
    pdf.Font font,
    pdf.Font boldFont,
    dynamic totalAmount,
  ) {
    if (summary == null) return pdf.SizedBox();

    final summaryFields = [
      // ['Facture douanière:', summary['factureNumber'] ?? ''],
      // ['Transport:', NumberFormattingService.formatCurrencySafe(summary['transit'])],
      // ['Droit de douane:', NumberFormattingService.formatCurrencySafe(summary['droitDouane'])],
      // ['Fret:', NumberFormattingService.formatCurrencySafe(summary['freiht'])],
      // ['Autre:', NumberFormattingService.formatCurrencySafe(summary['autres'])],
      [
        'Poids total:',
        NumberFormattingService.formatWeightSafe(summary['poidsTotal']),
      ],
      // ['Total des dépenses:', NumberFormattingService.formatCurrencySafe(summary['total'])],
      [
        'Total marchandises:',
        NumberFormattingService.formatCurrencySafe(totalAmount),
      ],
      // ['Taux de change:', summary['txChange']?.toString() ?? ''],
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
                for (var row in summaryFields.take(4))
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
                for (var row in summaryFields.skip(4).take(3))
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
