// ═══════════════════════════════════════════════════════════════════════════════
// Production Record Card Widget - بطاقة سجل الإنتاج
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/production_models.dart';

class ProductionRecordCard extends StatelessWidget {
  final ProductionRecordModel record;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPrint;
  final VoidCallback? onDelete;

  const ProductionRecordCard({
    super.key,
    required this.record,
    this.onView,
    this.onEdit,
    this.onPrint,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'ar');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: record.stage.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      record.stage.icon,
                      color: record.stage.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(record.productionDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${record.efficiency.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Divider(height: 1),
              const SizedBox(height: 5),

              // Info Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'الوزن',
                      '${record.totalWeight.toStringAsFixed(2)} كغ',
                      Icons.scale,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _buildInfoChip(
                      'الفاقد',
                      '${record.wasteGenerated.toStringAsFixed(2)} كغ',
                      Icons.delete,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'التكلفة',
                      '${record.costs.totalCost.toStringAsFixed(2)} درهم',
                      Icons.attach_money,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _buildInfoChip(
                      'المشغل',
                      record.operatorName,
                      Icons.person,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    _buildActionButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onTap: onEdit!,
                      tooltip: 'تعديل',
                    ),
                  if (onPrint != null)
                    _buildActionButton(
                      icon: Icons.print,
                      color: Colors.green,
                      onTap: onPrint!,
                      tooltip: 'طباعة',
                    ),
                  if (onDelete != null)
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: onDelete!,
                      tooltip: 'حذف',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(left: 5),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
