import '../../../core/imports.dart';

class SsfCard extends StatelessWidget {
  final Map<String, dynamic> ssf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SsfCard({
    super.key,
    required this.ssf,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Support both 'items' and 'inventory_ssf_operations' keys for operations
    final items =
        (ssf['items'] as List?)?.cast<Map<String, dynamic>>() ??
        (ssf['inventory_ssf_operations'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Support both ref_code and product_ref for reference code
    final refCode = (ssf['ref_code'] ?? ssf['product_ref'] ?? 'N/A').toString();

    final totalQuantity = ssf['total_quantity'] ?? ssf['quantity'] ?? 0;
    final totalWeight =
        (ssf['total_weight'] as num?)?.toStringAsFixed(2) ??
        ssf['total_weight']?.toString() ??
        '0.00';
    final totalAmount =
        (ssf['total_amount'] as num?)?.toStringAsFixed(2) ??
        (ssf['total_cost'] as num?)?.toStringAsFixed(2) ??
        ssf['total_amount']?.toString() ??
        ssf['total_cost']?.toString() ??
        '0.00';
    final operationsCount = ssf['operations_count'] ?? items.length;
    final cmup =
        (ssf['CMUP'] as num?)?.toStringAsFixed(2) ??
        ssf['CMUP']?.toString() ??
        '0.00';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200.withValues(alpha: 0.45),
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
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 5,
              children: [
                _buildStatCard(
                  icon: Icons.qr_code_2,
                  color: const Color(0xFF4338CA),
                  label: 'Réf. Code',
                  value: refCode,
                ),
                _buildStatCard(
                  icon: Icons.monetization_on,
                  color: const Color(0xFF7C3AED),
                  label: 'CMUP (DH)',
                  value: cmup,
                ),
                _buildStatCard(
                  icon: Icons.production_quantity_limits,
                  color: const Color(0xFF2563EB),
                  label: 'Quantité totale',
                  value: '$totalQuantity',
                ),
                _buildStatCard(
                  icon: Icons.scale,
                  color: const Color(0xFFF59E0B),
                  label: 'Poids total (KG)',
                  value: totalWeight,
                ),
                _buildStatCard(
                  icon: Icons.attach_money,
                  color: const Color(0xFF16A34A),
                  label: 'Montant total (DH)',
                  value: totalAmount,
                ),
                _buildStatCard(
                  icon: Icons.list_alt,
                  color: const Color(0xFF9333EA),
                  label: 'Opérations',
                  value: '$operationsCount',
                ),
                _buildGridAction(Icons.delete, Colors.red.shade600, onDelete),
                _buildGridAction(Icons.edit, Colors.orange.shade600, onEdit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
