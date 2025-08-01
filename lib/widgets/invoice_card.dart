import '../core/imports.dart';

class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onDelete;
  final Function(String)? onStatusUpdate; // إضافة callback لتحديث الحالة
  final Function(bool)? onTypeUpdate; // إضافة callback لتغيير النوع

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onView,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    this.onStatusUpdate, // إضافة parameter جديد
    this.onTypeUpdate, // إضافة parameter جديد
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط الحالة الجانبي
            Container(
              width: 8,
              height: isWide ? 90 : 120,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            // المحتوى الرئيسي
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // معلومات العميل ونوع الفاتورة
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice['clientName'] ?? 'غير محدد',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1a202c),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildTypeChip(),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 15, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    invoice['date'] ?? 'غير محدد',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // رقم الفاتورة والحالة
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                invoice['invoiceNumber'] ?? 'غير محدد',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildStatusChip(),
                              const SizedBox(height: 18),
                              Text(
                                '${(invoice['totalAmount'] ?? 0.0).toStringAsFixed(2)} DH',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2d3748),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Divider عمودي جميل
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 0),
                          width: 3,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // الإجراءات
                        Expanded(
                          flex: 0,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildGridAction(Icons.visibility, Colors.blue.shade600, onView),
                                    _buildGridAction(Icons.edit, Colors.orange.shade600, onEdit),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildGridAction(Icons.print, Colors.green.shade600, onPrint),
                                    _buildGridAction(Icons.delete, Colors.red.shade600, onDelete),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // اسم العميل ونوع الفاتورة
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice['clientName'] ?? 'غير محدد',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1a202c),
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  _buildTypeChip(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // رقم الفاتورة والحالة
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    invoice['invoiceNumber'] ?? 'غير محدد',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildStatusChip(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              invoice['date'] ?? 'غير محدد',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const Spacer(),
                            Text(
                              '${(invoice['totalAmount'] ?? 0.0).toStringAsFixed(2)} DH',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2d3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // الإجراءات في صف واحد على الهاتف
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildGridAction(Icons.visibility, Colors.blue.shade600, onView),
                            _buildGridAction(Icons.edit, Colors.orange.shade600, onEdit),
                            _buildGridAction(Icons.print, Colors.green.shade600, onPrint),
                            _buildGridAction(Icons.delete, Colors.red.shade600, onDelete),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    final bool isLocal = invoice['isLocal'] ?? true;
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showTypePopup(context, isLocal),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isLocal
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isLocal ? 'محلي' : 'خارجي',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isLocal ? Colors.green.shade700 : Colors.blue.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showStatusPopup(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                invoice['status'] ?? 'غير محدد',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 12, color: _getStatusColor()),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPopup(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        _buildStatusMenuItem('Terminée', Colors.green),
        _buildStatusMenuItem('En attente', Colors.orange),
        _buildStatusMenuItem('Brouillon', Colors.grey),
      ],
    ).then((selectedStatus) {
      if (selectedStatus != null && onStatusUpdate != null) {
        onStatusUpdate!(selectedStatus);
      }
    });
  }

  PopupMenuItem<String> _buildStatusMenuItem(String status, Color color) {
    final bool isCurrentStatus = invoice['status'] == status;
    return PopupMenuItem<String>(
      value: status,
      child: Row(
        children: [
          Icon(
            isCurrentStatus ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isCurrentStatus ? color : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: isCurrentStatus ? color : Colors.black87,
              fontWeight: isCurrentStatus ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showTypePopup(BuildContext context, bool isLocal) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<bool>(
      context: context,
      position: position,
      items: [
        _buildTypeMenuItem(true, 'محلي', Colors.green),
        _buildTypeMenuItem(false, 'خارجي', Colors.blue),
      ],
    ).then((selectedType) {
      if (selectedType != null && onTypeUpdate != null) {
        onTypeUpdate!(selectedType);
      }
    });
  }

  PopupMenuItem<bool> _buildTypeMenuItem(
    bool value,
    String label,
    Color color,
  ) {
    final bool isCurrent = (invoice['isLocal'] ?? true) == value;
    return PopupMenuItem<bool>(
      value: value,
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isCurrent ? color : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isCurrent ? color : Colors.black87,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Color _getStatusColor() {
    final String status = invoice['status'] ?? '';
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

  // String _formatDate(DateTime? date) {
  //   if (date == null) return 'غير محدد';
  //   return '${date.day}/${date.month}/${date.year} | ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  // }
}
