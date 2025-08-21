import '../core/imports.dart';

class InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventoryCard({
    super.key,
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage;
    
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
            color: Colors.black.withValues(alpha: 0.04),
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
                        // معلومات العنصر والفئة
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['articleName'] ?? 'غير محدد',
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
                              _buildCategoryChip(currentLang),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.inventory, size: 15, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    'المرجع: ${item['supplierRef'] ?? 'غير محدد'}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // الكمية والحالة
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item['quantity']} ${item['unit']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildStatusChip(currentLang),
                              const SizedBox(height: 18),
                              Text(
                                '${item['totalValue']?.toStringAsFixed(0)} د.ك',
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
                            // اسم العنصر والفئة
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['articleName'] ?? 'غير محدد',
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
                                  _buildCategoryChip(currentLang),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // الكمية والحالة
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['quantity']} ${item['unit']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildStatusChip(currentLang),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.inventory, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              'المرجع: ${item['supplierRef'] ?? 'غير محدد'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const Spacer(),
                            Text(
                              '${item['totalValue']?.toStringAsFixed(0)} د.ك',
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

  Widget _buildCategoryChip(String currentLang) {
    final String category = item['category'] ?? 'غير محدد';
    Color categoryColor;
    
    switch (category) {
      case 'أقمشة':
        categoryColor = Colors.purple;
        break;
      case 'خيوط':
        categoryColor = Colors.blue;
        break;
      case 'إكسسوارات':
        categoryColor = Colors.orange;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
             child: Text(
         category,
         style: TextStyle(
           fontSize: 10,
           fontWeight: FontWeight.w500,
           color: categoryColor,
         ),
       ),
    );
  }

  Widget _buildStatusChip(String currentLang) {
    final String status = item['status'] ?? 'غير محدد';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 12,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
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
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon, 
          size: 20, 
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    final String status = item['status'] ?? '';
    switch (status) {
      case 'متوفر':
        return Colors.green.shade600;
      case 'منخفض':
        return Colors.orange.shade600;
      case 'نفذ':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon() {
    final String status = item['status'] ?? '';
    switch (status) {
      case 'متوفر':
        return Icons.check_circle;
      case 'منخفض':
        return Icons.warning;
      case 'نفذ':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
