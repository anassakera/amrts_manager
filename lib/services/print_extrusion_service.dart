import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:flutter/services.dart' show rootBundle;
import 'number_formatting_service.dart';

class PrintExtrusionService {
  static Future<Uint8List> generateExtrusionPdf(
    Map<String, dynamic> fiche,
  ) async {
    final pdfDoc = pdf.Document();

    // Load Poppins fonts
    final poppinsFont = pdf.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    );
    final poppinsBoldFont = pdf.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
    );

    final production =
        (fiche['production'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final arrets =
        (fiche['arrets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final culot =
        (fiche['culot'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    // Calculate statistics
    final totalBrut = production.fold<double>(
      0,
      (prev, item) => prev + _parseDouble(item['prut_kg']),
    );
    final totalNet = production.fold<double>(
      0,
      (prev, item) => prev + _parseDouble(item['net_kg']),
    );
    final avgChutes = production.isEmpty
        ? 0.0
        : production.fold<double>(
                0,
                (prev, item) => prev + _parseDouble(item['taux_de_chutes']),
              ) /
              production.length;
    final totalArretsValue = fiche['total_arrets'];
    final totalArrets = totalArretsValue?.toString() ?? '0';

    pdfDoc.addPage(
      pdf.Page(
        margin: const pdf.EdgeInsets.all(15),
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.stretch,
            children: [
              // Header Section
              _buildHeader(fiche, poppinsFont, poppinsBoldFont),
              pdf.SizedBox(height: 8),
              // Statistics Cards
              _buildStatsRow(
                production.length,
                totalBrut,
                totalNet,
                avgChutes,
                totalArrets,
                arrets.length,
                poppinsFont,
                poppinsBoldFont,
              ),
              pdf.SizedBox(height: 8),
              // Production Table
              _buildProductionTable(production, poppinsFont, poppinsBoldFont),
              pdf.Spacer(),
              // Bottom sections row
              // Bottom sections
              if (_hasCulotData(culot))
                _buildCulotSection(culot, poppinsFont, poppinsBoldFont),
              if (_hasCulotData(culot) && arrets.isNotEmpty)
                pdf.SizedBox(height: 8),
              if (arrets.isNotEmpty)
                _buildArretsTable(arrets, poppinsFont, poppinsBoldFont),
            ],
          );
        },
      ),
    );

    return pdfDoc.save();
  }

  static pdf.Widget _buildHeader(
    Map<String, dynamic> fiche,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    return pdf.Row(
      children: [
        // Title
        pdf.Expanded(
          flex: 2,
          child: pdf.Container(
            padding: const pdf.EdgeInsets.symmetric(vertical: 12),
            decoration: pdf.BoxDecoration(
              borderRadius: pdf.BorderRadius.circular(10),
              color: PdfColor.fromHex('#1E3A8A'),
            ),
            child: pdf.Center(
              child: pdf.Text(
                'FICHE D\'EXTRUSION',
                style: pdf.TextStyle(
                  font: boldFont,
                  fontSize: 22,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        pdf.SizedBox(width: 8),
        // Info Panel
        pdf.Expanded(
          flex: 3,
          child: pdf.Container(
            padding: const pdf.EdgeInsets.all(10),
            decoration: pdf.BoxDecoration(
              borderRadius: pdf.BorderRadius.circular(8),
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#F8FAFC'),
                  PdfColor.fromHex('#E2E8F0'),
                ],
              ),
              border: pdf.Border.all(
                color: PdfColor.fromHex('#CBD5E1'),
                width: 1,
              ),
            ),
            child: pdf.Row(
              mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  'N°',
                  fiche['numero']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#3B82F6'),
                ),
                _buildInfoChip(
                  'Date',
                  fiche['date']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#F59E0B'),
                ),
                _buildInfoChip(
                  'Horaire',
                  fiche['horaire']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#10B981'),
                ),
                _buildInfoChip(
                  'Équipe',
                  fiche['equipe']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#8B5CF6'),
                ),
                _buildInfoChip(
                  'Conducteur',
                  fiche['conducteur']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#EC4899'),
                ),
                _buildInfoChip(
                  'Dressage',
                  fiche['dressage']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#F59E0B'),
                ),
                _buildInfoChip(
                  'Presse',
                  fiche['presse']?.toString() ?? '',
                  font,
                  boldFont,
                  PdfColor.fromHex('#0EA5E9'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pdf.Widget _buildInfoChip(
    String label,
    String value,
    pdf.Font font,
    pdf.Font boldFont,
    PdfColor color,
  ) {
    return pdf.Column(
      crossAxisAlignment: pdf.CrossAxisAlignment.start,
      children: [
        pdf.Text(
          label,
          style: pdf.TextStyle(
            font: font,
            fontSize: 7,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
        pdf.Text(
          value.isNotEmpty ? value : '-',
          style: pdf.TextStyle(font: boldFont, fontSize: 9, color: color),
        ),
      ],
    );
  }

  static pdf.Widget _buildStatsRow(
    int lotsCount,
    double totalBrut,
    double totalNet,
    double avgChutes,
    String totalArrets,
    int arretsCount,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    return pdf.Row(
      children: [
        _buildStatCard(
          'Lots traités',
          '$lotsCount',
          font,
          boldFont,
          PdfColor.fromHex('#3B82F6'),
        ),
        pdf.SizedBox(width: 6),
        _buildStatCard(
          'Total brut (Kg)',
          NumberFormattingService.formatWeightSafe(totalBrut),
          font,
          boldFont,
          PdfColor.fromHex('#6366F1'),
        ),
        pdf.SizedBox(width: 6),
        _buildStatCard(
          'Total net (Kg)',
          NumberFormattingService.formatWeightSafe(totalNet),
          font,
          boldFont,
          PdfColor.fromHex('#10B981'),
        ),
        pdf.SizedBox(width: 6),
        _buildStatCard(
          'Chutes (%)',
          avgChutes.toStringAsFixed(2),
          font,
          boldFont,
          PdfColor.fromHex('#F59E0B'),
        ),
        pdf.SizedBox(width: 6),
        _buildStatCard(
          'Total arrêts',
          '$totalArrets min',
          font,
          boldFont,
          PdfColor.fromHex('#EF4444'),
        ),
        pdf.SizedBox(width: 6),
        _buildStatCard(
          'Arrêts',
          '$arretsCount',
          font,
          boldFont,
          PdfColor.fromHex('#9C27B0'),
        ),
      ],
    );
  }

  static pdf.Widget _buildStatCard(
    String label,
    String value,
    pdf.Font font,
    pdf.Font boldFont,
    PdfColor color,
  ) {
    // Map labels to simple iconic representations using shapes/text
    pdf.Widget iconWidget;
    if (label.contains('Lots')) {
      iconWidget = _buildIconShape(color, (context) {
        context.canvas.drawRect(0, 0, 8, 8);
        context.canvas.fillPath();
      });
    } else if (label.contains('brut') || label.contains('net')) {
      iconWidget = _buildIconShape(color, (context) {
        context.canvas.drawEllipse(4, 4, 4, 4);
        context.canvas.fillPath();
      });
    } else if (label.contains('Chutes')) {
      iconWidget = _buildIconShape(color, (context) {
        context.canvas.moveTo(4, 0);
        context.canvas.lineTo(8, 8);
        context.canvas.lineTo(0, 8);
        context.canvas.fillPath();
      });
    } else {
      iconWidget = _buildIconShape(color, (context) {
        context.canvas.drawRect(2, 0, 4, 8);
        context.canvas.fillPath();
      });
    }

    return pdf.Expanded(
      child: pdf.Container(
        padding: const pdf.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: pdf.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: pdf.BorderRadius.circular(6),
          border: pdf.Border.all(color: color, width: 1),
        ),
        child: pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.center,
          children: [
            pdf.Row(
              mainAxisAlignment: pdf.MainAxisAlignment.center,
              children: [
                iconWidget,
                pdf.SizedBox(width: 4),
                pdf.Text(
                  label,
                  style: pdf.TextStyle(
                    font: font,
                    fontSize: 7,
                    color: PdfColor.fromHex('#475569'),
                  ),
                ),
              ],
            ),
            pdf.SizedBox(height: 2),
            pdf.Text(
              value,
              style: pdf.TextStyle(font: boldFont, fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  static pdf.Widget _buildIconShape(
    PdfColor color,
    void Function(pdf.Context context) paint,
  ) {
    return pdf.Container(
      width: 8,
      height: 8,
      child: pdf.CustomPaint(
        painter: (canvas, size) {
          canvas.setFillColor(color);
          // Create context without document if possible, or pass a dummy one if required by the API version
          // Based on typical pdf package usage, Context often needs a document for page referencing
          // Trying simplified approach if CustomPaint painter signature allows
          paint(pdf.Context(canvas: canvas, document: pdf.Document().document));
        },
      ),
    );
  }

  static pdf.Widget _buildProductionTable(
    List<Map<String, dynamic>> production,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final headers = [
      'N°Éclt',
      'Réf',
      'Produit',
      'Ind',
      'Blocs',
      'Lg',
      'Lot',
      'Vit',
      'Pres',
      'Barres',
      'Long',
      'P.Bar',
      'Brut',
      'Net',
      'Taux',
      'H.Déb',
      'H.Fin',
      'Status',
    ];

    return pdf.Container(
      decoration: pdf.BoxDecoration(
        borderRadius: pdf.BorderRadius.circular(8),
        border: pdf.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      ),
      child: pdf.Column(
        children: [
          // Header
          pdf.Container(
            decoration: pdf.BoxDecoration(
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#1E3A8A'),
                  PdfColor.fromHex('#3B82F6'),
                ],
              ),
              borderRadius: const pdf.BorderRadius.only(
                topLeft: pdf.Radius.circular(8),
                topRight: pdf.Radius.circular(8),
              ),
            ),
            padding: const pdf.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: pdf.Row(
              children: headers.map((h) {
                return pdf.Expanded(
                  child: pdf.Center(
                    child: pdf.Text(
                      h,
                      style: pdf.TextStyle(
                        font: boldFont,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pdf.TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Rows
          if (production.isEmpty)
            pdf.Container(
              height: 30,
              alignment: pdf.Alignment.center,
              child: pdf.Text(
                'Aucune donnée de production',
                style: pdf.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.grey600,
                  fontStyle: pdf.FontStyle.italic,
                ),
              ),
            )
          else
            ...production.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isEven = i % 2 == 0;
              final isCompleted = item['status']?.toString() == 'completed';

              return pdf.Container(
                decoration: pdf.BoxDecoration(
                  color: isEven ? PdfColor.fromHex('#F9FAFB') : PdfColors.white,
                  border: i < production.length - 1
                      ? pdf.Border(
                          bottom: pdf.BorderSide(
                            color: PdfColor.fromHex('#E5E7EB'),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                padding: const pdf.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 4,
                ),
                child: pdf.Row(
                  children: [
                    _buildCell(item['nbr_eclt']?.toString() ?? '', font),
                    _buildCell(item['ref']?.toString() ?? '', font),
                    _buildCell(item['product_name']?.toString() ?? '', font),
                    _buildCell(item['ind']?.toString() ?? '', font),
                    _buildCell(item['nbr_blocs']?.toString() ?? '', font),
                    _buildCell(item['Lg_blocs']?.toString() ?? '', font),
                    _buildCell(
                      item['num_lot_billette']?.toString() ?? '',
                      font,
                    ),
                    _buildCell(item['vitesse']?.toString() ?? '', font),
                    _buildCell(item['pres_extru']?.toString() ?? '', font),
                    _buildCell(item['nbr_barres']?.toString() ?? '', font),
                    _buildCell(item['long']?.toString() ?? '', font),
                    _buildCell(item['p_barre_reel']?.toString() ?? '', font),
                    _buildCell(
                      NumberFormattingService.formatWeightSafe(item['prut_kg']),
                      font,
                    ),
                    _buildCell(
                      NumberFormattingService.formatWeightSafe(item['net_kg']),
                      font,
                    ),
                    _buildCell(
                      '${_parseDouble(item['taux_de_chutes']).toStringAsFixed(1)}%',
                      font,
                    ),
                    _buildCell(item['heur_debut']?.toString() ?? '', font),
                    _buildCell(item['heur_fin']?.toString() ?? '', font),
                    // Status dot
                    pdf.Expanded(
                      child: pdf.Center(
                        child: pdf.Container(
                          width: 8,
                          height: 8,
                          decoration: pdf.BoxDecoration(
                            shape: pdf.BoxShape.circle,
                            color: isCompleted
                                ? PdfColor.fromHex('#10B981')
                                : PdfColors.grey300,
                          ),
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

  static pdf.Widget _buildCell(String value, pdf.Font font) {
    return pdf.Expanded(
      child: pdf.Center(
        child: pdf.Text(
          value,
          style: pdf.TextStyle(font: font, fontSize: 6),
          textAlign: pdf.TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }

  static pdf.Widget _buildArretsTable(
    List<Map<String, dynamic>> arrets,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final headers = ['Début', 'Fin', 'Durée', 'Cause', 'Action'];

    return pdf.Container(
      decoration: pdf.BoxDecoration(
        borderRadius: pdf.BorderRadius.circular(8),
        border: pdf.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      ),
      child: pdf.Column(
        children: [
          // Main Title
          pdf.Container(
            width: double.infinity,
            decoration: pdf.BoxDecoration(
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#DC2626'),
                  PdfColor.fromHex('#EF4444'),
                ],
              ),
              borderRadius: const pdf.BorderRadius.only(
                topLeft: pdf.Radius.circular(8),
                topRight: pdf.Radius.circular(8),
              ),
            ),
            padding: const pdf.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pdf.Text(
              'Arrêts',
              style: pdf.TextStyle(
                font: boldFont,
                fontSize: 9,
                color: PdfColors.white,
              ),
            ),
          ),
          // Column Headers
          pdf.Container(
            padding: const pdf.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: pdf.BoxDecoration(
              color: PdfColor.fromHex('#FEF2F2'),
              border: pdf.Border(
                bottom: pdf.BorderSide(
                  color: PdfColor.fromHex('#E5E7EB'),
                  width: 0.5,
                ),
              ),
            ),
            child: pdf.Row(
              children: headers.map((h) {
                return pdf.Expanded(
                  child: pdf.Center(
                    child: pdf.Text(
                      h,
                      style: pdf.TextStyle(
                        font: boldFont,
                        fontSize: 7,
                        color: PdfColor.fromHex('#7F1D1D'),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Rows
          ...arrets.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;

            return pdf.Container(
              decoration: pdf.BoxDecoration(
                color: PdfColors.white,
                border: i < arrets.length - 1
                    ? pdf.Border(
                        bottom: pdf.BorderSide(
                          color: PdfColor.fromHex('#E5E7EB'),
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              padding: const pdf.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 4,
              ),
              child: pdf.Row(
                children: [
                  _buildCell(item['debut']?.toString() ?? '', font),
                  _buildCell(item['fin']?.toString() ?? '', font),
                  _buildCell(item['duree']?.toString() ?? '', font),
                  _buildCell(item['cause']?.toString() ?? '', font),
                  _buildCell(item['action']?.toString() ?? '', font),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static bool _hasCulotData(Map<String, dynamic> culot) {
    return culot.values.any((v) => v != null && v.toString().isNotEmpty);
  }

  static pdf.Widget _buildCulotSection(
    Map<String, dynamic> culot,
    pdf.Font font,
    pdf.Font boldFont,
  ) {
    final fields = [
      ['Par NC', culot['par_NC']],
      ['Culot', culot['culot']],
      ['Bag', culot['Bag']],
      ['FO', culot['FO']],
      ['Retour F', culot['retour_F']],
      ['Poids Déchet', culot['POID_DECHET']],
      ['Total', culot['total']],
    ];

    return pdf.Container(
      decoration: pdf.BoxDecoration(
        borderRadius: pdf.BorderRadius.circular(8),
        border: pdf.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
      ),
      child: pdf.Column(
        children: [
          // Header
          pdf.Container(
            decoration: pdf.BoxDecoration(
              gradient: pdf.LinearGradient(
                colors: [
                  PdfColor.fromHex('#00695C'),
                  PdfColor.fromHex('#00897B'),
                ],
              ),
              borderRadius: const pdf.BorderRadius.only(
                topLeft: pdf.Radius.circular(8),
                topRight: pdf.Radius.circular(8),
              ),
            ),
            padding: const pdf.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pdf.Row(
              children: [
                pdf.Text(
                  'Section Culot',
                  style: pdf.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          // Fields
          pdf.Padding(
            padding: const pdf.EdgeInsets.all(8),
            child: pdf.Wrap(
              spacing: 8,
              runSpacing: 6,
              children: fields.map((field) {
                return pdf.Container(
                  width: 80,
                  padding: const pdf.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: pdf.BoxDecoration(
                    color: PdfColor.fromHex('#F0FDF4'),
                    borderRadius: pdf.BorderRadius.circular(4),
                    border: pdf.Border.all(
                      color: PdfColor.fromHex('#86EFAC'),
                      width: 0.5,
                    ),
                  ),
                  child: pdf.Column(
                    crossAxisAlignment: pdf.CrossAxisAlignment.start,
                    children: [
                      pdf.Text(
                        field[0] as String,
                        style: pdf.TextStyle(
                          font: font,
                          fontSize: 6,
                          color: PdfColor.fromHex('#475569'),
                        ),
                      ),
                      pdf.Text(
                        field[1]?.toString() ?? '-',
                        style: pdf.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: PdfColor.fromHex('#166534'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static double _parseDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final sanitized = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(sanitized) ?? 0;
  }
}
