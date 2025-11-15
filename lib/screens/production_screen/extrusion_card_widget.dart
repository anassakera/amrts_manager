import '../../core/imports.dart';

class ExtrusionCard extends StatelessWidget {
  final Map<String, dynamic> fiche;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExtrusionCard({
    super.key,
    required this.fiche,

    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final production =
        (fiche['production_data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final arrets =
        (fiche['arrets'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalNet = production.fold<double>(
      0,
      (previousValue, element) =>
          previousValue + _parseDouble(element['net_kg']),
    );
    final totalBrut = production.fold<double>(
      0,
      (previousValue, element) =>
          previousValue + _parseDouble(element['prut_kg']),
    );
    // حساب متوسط taux_de_chutes بدلاً من الجمع
    final avgChutes = production.isEmpty
        ? 0.0
        : production.fold<double>(
                0,
                (previousValue, element) =>
                    previousValue + _parseDouble(element['taux_de_chutes']),
              ) /
              production.length;

    final totalArrets = fiche['total_arrets']?.toString() ?? '0 min';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.indigo.shade100.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _buildInfoChip(
                  icon: Icons.numbers,
                  label: '',
                  value: fiche['numero'],
                  color: const Color(0xFF2563EB),
                ),
                _buildInfoChip(
                  icon: Icons.schedule,
                  label: 'Date & Horaire',
                  value:
                      '${fiche['horaire']?.toString() ?? ''} ${fiche['date']?.toString() ?? ''}',
                  color: const Color(0xFF2563EB),
                ),
                _buildInfoChip(
                  icon: Icons.groups_2_outlined,
                  label: 'Équipe',
                  value: fiche['equipe'],
                  color: const Color(0xFF2563EB),
                ),

                _buildInfoChip(
                  icon: Icons.engineering_outlined,
                  label: 'Conducteur',
                  value: fiche['conducteur'],
                  color: const Color(0xFF7C3AED),
                ),
                _buildInfoChip(
                  icon: Icons.cut_outlined,
                  label: 'Dressage',
                  value: fiche['dressage'],
                  color: const Color(0xFF10B981),
                ),
                _buildInfoChip(
                  icon: Icons.precision_manufacturing,
                  label: 'Presse',
                  value: fiche['presse'],
                  color: const Color(0xFF0EA5E9),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _buildStatCard(
                  icon: Icons.assessment_outlined,
                  label: 'Lots traités',
                  value: '${production.length}',
                  color: const Color(0xFF2563EB),
                ),
                _buildStatCard(
                  icon: Icons.scale_outlined,
                  label: 'Total brut (Kg)',
                  value: _formatNumber(totalBrut),
                  color: const Color(0xFF7C3AED),
                ),
                _buildStatCard(
                  icon: Icons.balance_outlined,
                  label: 'Total net (Kg)',
                  value: _formatNumber(totalNet),
                  color: const Color(0xFF16A34A),
                ),
                _buildStatCard(
                  icon: Icons.percent,
                  label: 'Chutes (%)',
                  value: _formatNumber(avgChutes),
                  color: const Color(0xFFF97316),
                ),
                _buildStatCard(
                  icon: Icons.timelapse_outlined,
                  label: 'Total arrêts',
                  value: totalArrets,
                  color: const Color(0xFFEF4444),
                ),
                _buildStatCard(
                  icon: Icons.build_outlined,
                  label: 'Arrêts',
                  value: '${arrets.length}',
                  color: const Color(0xFF8B5CF6),
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Object? value,
    required Color color,
  }) {
    final display = value?.toString();
    if (display == null || display.isEmpty) {
      return const SizedBox.shrink();
    }
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            if (label.isNotEmpty)
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            Text(
              display,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          Column(
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
        ],
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

  double _parseDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final sanitized = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(sanitized) ?? 0;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
