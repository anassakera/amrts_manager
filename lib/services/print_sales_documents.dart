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
              return pdf.Column(
                crossAxisAlignment: pdf.CrossAxisAlignment.stretch,
                children: [
                  // Titre BON DE LIVRAISON avec informations
                  pdf.Row(
                    children: [
                      // Titre BON DE LIVRAISON
                      pdf.Expanded(
                        flex: 2,
                        child: pdf.Container(
                          padding: const pdf.EdgeInsets.symmetric(vertical: 16),
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
                  // Spacer to push total to bottom
                  pdf.Expanded(child: pdf.Container()),
                  // Total at bottom
                  _buildTotalRow(items, poppinsFont, poppinsBoldFont),
                ],
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
          final isLastPage = page == pageCount - 1;

          pdfDoc.addPage(
            pdf.Page(
              margin: const pdf.EdgeInsets.all(20),
              pageFormat: PdfPageFormat.a4,
              build: (context) {
                return pdf.Column(
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
                    ],
                    // جدول العناصر لهذه الصفحة فقط
                    _buildItemsTable(itemsChunk, poppinsFont, poppinsBoldFont),
                    // Show total only on the last page
                    if (isLastPage) ...[
                      pdf.Expanded(child: pdf.Container()),
                      _buildTotalRow(items, poppinsFont, poppinsBoldFont),
                    ],
                  ],
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

  // Total Row Widget - Separate from table, positioned at bottom
  static pdf.Widget _buildTotalRow(
    List? items,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    // Largeurs personnalisées pour chaque colonne
    final columnWidths = [
      1.0, // Réf
      2.5, // Désignation
      0.8, // Couleur
      0.6, // Qté
      0.8, // P.U
      1.0, // Montant
    ];

    // Calculate totals
    int totalQuantity = 0;
    double totalMontant = 0.0;
    if (items != null && items.isNotEmpty) {
      for (final item in items) {
        final price = (item['Price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['Quantité'] as num?)?.toInt() ?? 0;
        totalQuantity += quantity;
        totalMontant += price * quantity;
      }
    }

    return pdf.Container(
      decoration: pdf.BoxDecoration(
        gradient: pdf.LinearGradient(
          colors: [PdfColor.fromHex('#1E3A8A'), PdfColor.fromHex('#3B82F6')],
        ),
        borderRadius: pdf.BorderRadius.circular(12),
        boxShadow: [
          pdf.BoxShadow(
            color: PdfColor.fromHex('#00000015'),
            offset: const PdfPoint(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: pdf.Row(
        children: [
          // Empty space for Réf
          pdf.Expanded(
            flex: (columnWidths[0] * 10).round(),
            child: pdf.Container(
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: pdf.Text(''),
            ),
          ),
          // "TOTAL" label in Désignation column
          pdf.Expanded(
            flex: (columnWidths[1] * 10).round(),
            child: pdf.Container(
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: pdf.Text(
                'TOTAL',
                style: pdf.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: pdf.TextAlign.right,
              ),
            ),
          ),
          // Empty space for Couleur
          pdf.Expanded(
            flex: (columnWidths[2] * 10).round(),
            child: pdf.Container(
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: pdf.Text(''),
            ),
          ),
          // Total Quantity
          pdf.Expanded(
            flex: (columnWidths[3] * 10).round(),
            child: pdf.Container(
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: pdf.Text(
                NumberFormattingService.formatQuantitySafe(totalQuantity),
                style: pdf.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                textAlign: pdf.TextAlign.center,
              ),
            ),
          ),
          // Empty space for P.U
          pdf.Expanded(
            flex: (columnWidths[4] * 10).round(),
            child: pdf.Container(
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: pdf.Text(''),
            ),
          ),
          // Total Montant
          pdf.Expanded(
            flex: (columnWidths[5] * 10).round(),
            child: pdf.Container(
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: pdf.Text(
                NumberFormattingService.formatCurrencySafe(totalMontant),
                style: pdf.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                textAlign: pdf.TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pdf.Widget _buildItemsTable(
    List? items,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    // En-têtes du tableau
    final headers = ['Réf', 'Désignation', 'Couleur', 'Qté', 'P.U', 'Montant'];

    // Largeurs personnalisées pour chaque colonne
    final columnWidths = [
      1.0, // Réf
      2.5, // Désignation
      0.8, // Couleur
      0.6, // Qté
      0.8, // P.U
      1.0, // Montant
    ];

    // Alignements pour chaque colonne (left pour texte, right pour nombres)
    final alignments = [
      pdf.TextAlign.left, // Réf
      pdf.TextAlign.left, // Désignation
      pdf.TextAlign.center, // Couleur
      pdf.TextAlign.center, // Qté
      pdf.TextAlign.right, // P.U
      pdf.TextAlign.right, // Montant
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
                    child: pdf.Text(
                      headers[index],
                      style: pdf.TextStyle(
                        font: boldFont,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: alignments[index],
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
              decoration: pdf.BoxDecoration(
                color: PdfColor.fromHex('#F9FAFB'),
                borderRadius: const pdf.BorderRadius.only(
                  bottomLeft: pdf.Radius.circular(12),
                  bottomRight: pdf.Radius.circular(12),
                ),
              ),
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
              // Calculate montant (total price)
              final price = (item['Price'] as num?)?.toDouble() ?? 0.0;
              final quantity = (item['Quantité'] as num?)?.toInt() ?? 0;
              final montant = price * quantity;
              final isLastItem = i == items.length - 1;

              return pdf.Container(
                decoration: pdf.BoxDecoration(
                  color: i % 2 == 0
                      ? PdfColor.fromHex('#F9FAFB')
                      : PdfColors.white,
                  border: !isLastItem
                      ? pdf.Border(
                          bottom: pdf.BorderSide(
                            color: PdfColor.fromHex('#E5E7EB'),
                            width: 0.5,
                          ),
                        )
                      : null,
                  borderRadius: isLastItem
                      ? const pdf.BorderRadius.only(
                          bottomLeft: pdf.Radius.circular(12),
                          bottomRight: pdf.Radius.circular(12),
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
                          '${item['Référence'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: alignments[0],
                        ),
                      ),
                    ),
                    // Désignation
                    pdf.Expanded(
                      flex: (columnWidths[1] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['Désignation'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: alignments[1],
                          maxLines: 2,
                        ),
                      ),
                    ),
                    // Couleur
                    pdf.Expanded(
                      flex: (columnWidths[2] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          '${item['Couleur'] ?? ''}',
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: alignments[2],
                        ),
                      ),
                    ),
                    // Quantité
                    pdf.Expanded(
                      flex: (columnWidths[3] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatQuantitySafe(
                            item['Quantité'],
                          ),
                          style: pdf.TextStyle(font: boldFont, fontSize: 7),
                          textAlign: alignments[3],
                        ),
                      ),
                    ),
                    // Prix Unitaire
                    pdf.Expanded(
                      flex: (columnWidths[4] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatCurrencySafe(price),
                          style: pdf.TextStyle(font: font, fontSize: 7),
                          textAlign: alignments[4],
                        ),
                      ),
                    ),
                    // Montant (Total)
                    pdf.Expanded(
                      flex: (columnWidths[5] * 10).round(),
                      child: pdf.Container(
                        padding: const pdf.EdgeInsets.all(6),
                        child: pdf.Text(
                          NumberFormattingService.formatCurrencySafe(montant),
                          style: pdf.TextStyle(font: boldFont, fontSize: 7),
                          textAlign: alignments[5],
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
}
