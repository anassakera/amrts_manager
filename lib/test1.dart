// widgets/invoice_header_widget.dart
import 'package:flutter/material.dart';

class InvoiceHeaderWidget extends StatelessWidget {
  final VoidCallback? onClearControllers;

  const InvoiceHeaderWidget({super.key, this.onClearControllers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: _buildContainerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: _buildInnerGradient(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeaderRow(context),
                const SizedBox(height: 16),
                _buildInfoGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 التصميم الخارجي للحاوية
  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E3A8A).withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF3B82F6).withOpacity(0.08),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // 🌈 التدرج الداخلي
  BoxDecoration _buildInnerGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  // 📋 الصف العلوي للعنوان والأيقونة
  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        _buildInvoiceIcon(),
        const SizedBox(width: 20),
        Expanded(child: _buildTitleSection()),
        _buildActionPanel(context),
      ],
    );
  }

  // 🏷️ أيقونة الفاتورة المطورة
  Widget _buildInvoiceIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  // 📝 قسم العنوان الرئيسي
  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'فاتورة إلكترونية',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A8A),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'نظام إدارة الفواتير المتقدم',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // 🎛️ لوحة الأفعال المطورة
  Widget _buildActionPanel(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionButton(
              icon: Icons.select_all_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () {},
              tooltip: 'تحديد الكل',
            ),
            _buildActionButton(
              icon: Icons.add_circle_outline_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                onClearControllers?.call();
              },
              tooltip: 'إضافة جديد',
            ),
            _buildActionButton(
              icon: Icons.delete_sweep_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => _showDeleteConfirmation(context),
              tooltip: 'حذف المحدد',
              visible: false,
            ),
            _buildActionButton(
              icon: Icons.clear_all_rounded,
              color: const Color(0xFF6B7280),
              onTap: () {},
              tooltip: 'إلغاء التحديد',
              visible: false,
            ),
          ],
        ),
      ),
    );
  }

  // 🔘 أزرار الأفعال المحسنة
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    bool visible = true,
  }) {
    if (!visible) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  // 📊 شبكة المعلومات التفصيلية
  Widget _buildInfoGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.receipt_long,
                  label: 'رقم الفاتورة',
                  value: 'فاتورة رقم: 0001',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.person_pin_rounded,
                  label: 'المورد',
                  value: 'غير محدد',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.calendar_month_rounded,
            label: 'تاريخ الإصدار',
            value: _getFormattedDate(),
            color: const Color(0xFFF59E0B),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  // 🏷️ بطاقة المعلومات المفردة
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📅 تنسيق التاريخ
  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ⚠️ حوار تأكيد الحذف
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('تأكيد الحذف'),
            ],
          ),
          content: const Text('هل أنت متأكد من رغبتك في حذف العناصر المحددة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}
