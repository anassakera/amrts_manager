import '../../../core/imports.dart';

class ExtrusionCard extends StatelessWidget {
  final Map<String, dynamic> fiche;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const ExtrusionCard({
    super.key,
    required this.fiche,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final production =
        (fiche['production'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
    final avgChutes = production.isEmpty
        ? 0.0
        : production.fold<double>(
                0,
                (previousValue, element) =>
                    previousValue + _parseDouble(element['taux_de_chutes']),
              ) /
              production.length;

    final totalArretsValue = fiche['total_arrets'];
    final totalArrets = totalArretsValue != null
        ? '$totalArretsValue min'
        : '0 min';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.indigo.shade100.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade100.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // COMPACT HEADER
          // ═══════════════════════════════════════════════════════════════
          _buildCompactHeader(),

          // ═══════════════════════════════════════════════════════════════
          // CONTENT SECTION
          // ═══════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                // Info + Stats Row
                _buildMainContent(
                  production: production,
                  arrets: arrets,
                  totalBrut: totalBrut,
                  totalNet: totalNet,
                  avgChutes: avgChutes,
                  totalArrets: totalArrets,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPACT HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompactHeader() {
    final numero = fiche['numero']?.toString() ?? '';
    final date = fiche['date']?.toString() ?? '';
    final horaire = fiche['horaire']?.toString() ?? '';
    final equipe = fiche['equipe']?.toString() ?? '';
    final conducteur = fiche['conducteur']?.toString() ?? '';
    final presse = fiche['presse']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep Navy Blue
            Color(0xFF3B82F6), // Bright Blue
            Color(0xFF0EA5E9), // Sky Blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fiche Number - Primary Badge
          _buildPrimaryBadge(numero),
          const SizedBox(width: 10),

          // Info Chips Container
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Date & Time
                _buildGlassChip(icon: Icons.calendar_today_rounded, text: date),
                _buildGlassChip(icon: Icons.access_time_rounded, text: horaire),
                // Team
                if (equipe.isNotEmpty)
                  _buildGlassChip(icon: Icons.groups_2_rounded, text: equipe),
                // Conducteur
                if (conducteur.isNotEmpty)
                  _buildGlassChip(
                    icon: Icons.engineering_rounded,
                    text: conducteur,
                  ),
                // Presse
                if (presse.isNotEmpty)
                  _buildGlassChip(
                    icon: Icons.precision_manufacturing_rounded,
                    text: presse,
                    highlight: true,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          // Action Buttons
          _buildCompactActions(),
        ],
      ),
    );
  }

  /// Primary badge for fiche number with premium glass effect
  Widget _buildPrimaryBadge(String numero) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.tag_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            'N° $numero',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Glass-style info chip with premium design matching _buildPrimaryBadge
  Widget _buildGlassChip({
    required IconData icon,
    required String text,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: highlight ? 0.25 : 0.2),
            Colors.white.withValues(alpha: highlight ? 0.15 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: highlight ? 0.45 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT - SINGLE ROW STATS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMainContent({
    required List<Map<String, dynamic>> production,
    required List<Map<String, dynamic>> arrets,
    required double totalBrut,
    required double totalNet,
    required double avgChutes,
    required String totalArrets,
  }) {
    final dressage = fiche['dressage']?.toString() ?? '';

    return Row(
      children: [
        // Dressage (اختياري)
        if (dressage.isNotEmpty) ...[
          Expanded(
            child: _buildCompactStat(
              icon: Icons.content_cut_rounded,
              label: 'Dressage',
              value: dressage,
              color: const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 6),
        ],
        // Lots
        Expanded(
          child: _buildCompactStat(
            icon: Icons.inventory_2_rounded,
            label: 'Lots',
            value: '${production.length}',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 6),
        // Brut
        Expanded(
          child: _buildCompactStat(
            icon: Icons.scale_rounded,
            label: 'Brut',
            value: '${_formatNumber(totalBrut)} Kg',
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 6),
        // Net
        Expanded(
          child: _buildCompactStat(
            icon: Icons.balance_rounded,
            label: 'Net',
            value: '${_formatNumber(totalNet)} Kg',
            color: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 6),
        // Chutes
        Expanded(
          child: _buildCompactStat(
            icon: Icons.trending_down_rounded,
            label: 'Chutes',
            value: '${_formatNumber(avgChutes)}%',
            color: avgChutes > 10
                ? const Color(0xFFDC2626)
                : const Color(0xFFF59E0B),
            highlight: avgChutes > 10,
          ),
        ),
        const SizedBox(width: 6),
        // Arrêts
        Expanded(
          child: _buildCompactStat(
            icon: Icons.timer_off_rounded,
            label: 'Arrêts',
            value: totalArrets,
            color: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 6),
        // Nb Arrêts
        Expanded(
          child: _buildCompactStat(
            icon: Icons.build_circle_rounded,
            label: 'Nb',
            value: '${arrets.length}',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: highlight ? 0.15 : 0.08),
            color.withValues(alpha: highlight ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: highlight ? 0.35 : 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: highlight ? 0.2 : 0.08),
            blurRadius: highlight ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة محسّنة مع خلفية دائرية
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          // النص محسّن
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPACT ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompactActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(0),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(
                  tooltip: 'Imprimer',
                  onTap: onPrint,
                  icon: Icons.print_rounded,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                _buildIconButton(
                  tooltip: 'Modifier',
                  onTap: onEdit,
                  icon: Icons.edit_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                _buildIconButton(
                  tooltip: 'Supprimer',
                  onTap: onDelete,
                  icon: Icons.delete_rounded,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required String tooltip,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

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
