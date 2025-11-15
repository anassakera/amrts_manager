import '../../core/imports.dart';

class FonderieCard extends StatelessWidget {
  final Map<String, dynamic> fondry;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FonderieCard({
    super.key,
    required this.fondry,

    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final items =
        (fondry['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalQuantity = fondry['total_quantity'] ?? 0;
    final totalCout =
        (fondry['total_cout'] as num?)?.toStringAsFixed(2) ??
        fondry['total_cout']?.toString() ??
        '0.00';
    final operationsCount = fondry['operations_count'] ?? items.length;

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
                  label: 'Réf. Fonderie',
                  value: fondry['ref_fondrie'] ?? 'N/A',
                ),
                _buildStatCard(
                  icon: Icons.production_quantity_limits,
                  color: const Color(0xFF2563EB),
                  label: 'Quantité totale',
                  value: '$totalQuantity',
                ),
                _buildStatCard(
                  icon: Icons.attach_money,
                  color: const Color(0xFF16A34A),
                  label: 'Coût total (DH)',
                  value: totalCout,
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
