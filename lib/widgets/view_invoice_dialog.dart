import 'package:flutter/material.dart';

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
                      'فاتورة رقم: ${widget.invoice['invoiceNumber'] ?? 'غير محدد'}',
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
                      tooltip: 'إغلاق',
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
                              widget.invoice['clientName'] ?? 'غير محدد',
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
                            widget.invoice['date'] ?? 'غير محدد',
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
                              isLocal ? 'محلي' : 'خارجي',
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
                            '${(widget.invoice['totalAmount'] ?? 0.0).toStringAsFixed(2)} DH',
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
                          child: const Text(
                            'العناصر',
                            style: TextStyle(
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
                              tooltip: 'تمرير لليسار',
                            ),
                            Text(
                              'استخدم الأزرار للتنقل بين الأعمدة',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            IconButton(
                              onPressed: _scrollRight,
                              icon: Icon(Icons.arrow_right, color: Colors.blue.shade600),
                              tooltip: 'تمرير لليمين',
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
                              columns: const [
                                DataColumn(label: Text('المرجع', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('الصنف', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('الكمية', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('الوزن', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('سعر القطعة', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('سعر الشراء', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('مصروفات أخرى', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('الإجمالي', style: TextStyle(fontSize: 12))),
                              ],
                              rows: items
                                  .map<DataRow>(
                                    (item) => DataRow(
                                      cells: [
                                        DataCell(Text(item['refFournisseur']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['articles']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['qte']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['poids']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['puPieces']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['prixAchat']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['autresCharges']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(item['cuHt']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
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
                      if (summary.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: const Text(
                            'ملخص الفاتورة',
                            style: TextStyle(
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
                              _summaryItem('رقم الفاتورة الجمركية', summary['factureNumber']),
                              _summaryItem('الترانزيت', summary['transit']),
                              _summaryItem('الجمركة', summary['droitDouane']),
                              _summaryItem('شيك الصرف', summary['chequeChange']),
                              _summaryItem('الشحن', summary['freiht']),
                              _summaryItem('مصروفات أخرى', summary['autres']),
                              _summaryItem('إجمالي الوزن', summary['poidsTotal']),
                              _summaryItem('إجمالي الفاتورة', summary['total']),
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
                  label: const Text(
                    'إغلاق',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          value?.toString() ?? '-',
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