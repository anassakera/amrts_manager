import '../core/imports.dart';

class ViewInvoiceDialog extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const ViewInvoiceDialog({super.key, required this.invoice});

  @override
  State<ViewInvoiceDialog> createState() => _ViewInvoiceDialogState();
}

class _ViewInvoiceDialogState extends State<ViewInvoiceDialog> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Terminée':
        return Colors.green.shade600;
      case 'En attente':
        return Colors.orange.shade600;
      case 'Brouillon':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage;
    
    final items = widget.invoice['items'] as List<dynamic>? ?? [];
    final summary = widget.invoice['summary'] as Map<String, dynamic>? ?? {};
    final status = widget.invoice['status'] ?? '';
    final isLocal = widget.invoice['isLocal'] ?? true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(status).withValues(alpha:0.85),
                      Colors.blue.shade400.withValues(alpha:0.85),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                                             '${AppTranslations.get('invoice_number', currentLang)}: ${widget.invoice['invoiceNumber']?.toString() ?? AppTranslations.get('not_specified', currentLang)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: _getStatusColor(status)),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppTranslations.get('close', currentLang),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات العميل والتاريخ والنوع
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade400, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.invoice['clientName'] ?? AppTranslations.get('not_specified', currentLang),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1a202c),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.invoice['date'] ?? AppTranslations.get('not_specified', currentLang),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, color: Colors.blue.shade400, size: 18),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLocal
                                  ? Colors.green.withValues(alpha:0.1)
                                  : Colors.blue.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isLocal ? AppTranslations.get('local', currentLang) : AppTranslations.get('external', currentLang),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isLocal ? Colors.green.shade700 : Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.attach_money, color: Colors.amber.shade700, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormattingService.formatCurrencySafe(widget.invoice['totalAmount']),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // جدول العناصر
                      if (items.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            AppTranslations.get('items', currentLang),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1a202c),
                            ),
                          ),
                        ),
                        // أزرار التمرير العمودي
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _scrollLeft,
                              icon: Icon(Icons.arrow_left, color: Colors.blue.shade600),
                              tooltip: AppTranslations.get('scroll_left', currentLang),
                            ),
                            Text(
                              AppTranslations.get('use_buttons_to_navigate', currentLang),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            IconButton(
                              onPressed: _scrollRight,
                              icon: Icon(Icons.arrow_right, color: Colors.blue.shade600),
                              tooltip: AppTranslations.get('scroll_right', currentLang),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                              columns: [
                                DataColumn(label: Text(AppTranslations.get('reference', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('category', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('quantity', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('weight', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('unit_price_header', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('purchase_price_header', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('other_expenses_header', currentLang), style: const TextStyle(fontSize: 12))),
                                DataColumn(label: Text(AppTranslations.get('total_header', currentLang), style: const TextStyle(fontSize: 12))),
                              ],
                              rows: items
                                  .map<DataRow>(
                                    (item) => DataRow(
                                      cells: [
                                        DataCell(Text(item['refFournisseur']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['articles']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(NumberFormattingService.formatQuantitySafe(item['qte']), style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(NumberFormattingService.formatWeightSafe(item['poids']), style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(NumberFormattingService.formatCurrencySafe(item['puPieces']), style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(NumberFormattingService.formatCurrencySafe(item['prixAchat']), style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(NumberFormattingService.formatCurrencySafe(item['autresCharges']), style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(NumberFormattingService.formatCurrencySafe(item['cuHt']), style: const TextStyle(fontSize: 11))),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // ملخص الفاتورة
                      if (summary.isNotEmpty && isLocal == false) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            AppTranslations.get('invoice_summary', currentLang),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1a202c),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Wrap(
                            runSpacing: 8,
                            spacing: 16,
                            children: [
                              _summaryItem(AppTranslations.get('customs_invoice_number', currentLang), summary['factureNumber']),
                              _summaryItem(AppTranslations.get('transit', currentLang), summary['transit']),
                              _summaryItem(AppTranslations.get('customs', currentLang), summary['droitDouane']),
                              _summaryItem(AppTranslations.get('exchange_cheque', currentLang), summary['chequeChange']),
                              _summaryItem(AppTranslations.get('freight', currentLang), summary['freiht']),
                              _summaryItem(AppTranslations.get('other_expenses', currentLang), summary['autres']),
                              _summaryItem(AppTranslations.get('total_weight_summary', currentLang), summary['poidsTotal']),
                              _summaryItem(AppTranslations.get('total_invoice', currentLang), summary['total']),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              // زر الإغلاق
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  label: Text(
                    AppTranslations.get('close', currentLang),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, dynamic value) {
    String formattedValue = '-';
    
    if (value != null) {
      // تحديد نوع التنسيق بناءً على نوع البيانات
      if (label.contains('Poids') || label.contains('Weight') || label.contains('الوزن')) {
        formattedValue = NumberFormattingService.formatWeightSafe(value);
      } else if (label.contains('Total') || label.contains('Montant') || label.contains('الإجمالي') || 
                 label.contains('Transport') || label.contains('Droit') || label.contains('Fret') || 
                 label.contains('Autre') || label.contains('Cheque') || label.contains('النقل') || 
                 label.contains('الجمرك') || label.contains('الشحن') || label.contains('أخرى') || 
                 label.contains('الصرف')) {
        formattedValue = NumberFormattingService.formatCurrencySafe(value);
      } else {
        formattedValue = value.toString();
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF1a202c),
          ),
        ),
        Text(
          formattedValue,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            color: Color(0xFF2d3748),
          ),
        ),
      ],
    );
  }
}