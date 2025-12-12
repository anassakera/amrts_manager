// ============================================
// Article Stock Model
// ============================================

class ArticleStock {
  final int? id;
  final String refCode;
  final String materialName;
  final String materialType;
  final double unitPrice;
  final String status;
  final int? minStockLevel;
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy;

  ArticleStock({
    this.id,
    required this.refCode,
    required this.materialName,
    required this.materialType,
    required this.unitPrice,
    this.status = 'Disponible',
    this.minStockLevel,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  // Convert from JSON (API response)
  factory ArticleStock.fromJson(Map<String, dynamic> json) {
    return ArticleStock(
      id: json['id'] as int?,
      refCode: json['ref_code']?.toString() ?? '',
      materialName: json['material_name']?.toString() ?? '',
      materialType: json['material_type']?.toString() ?? '',
      unitPrice: _parseDouble(json['unit_price']),
      status: json['status']?.toString() ?? 'Disponible',
      minStockLevel: json['min_stock_level'] as int?,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      createdBy: json['created_by']?.toString(),
    );
  }

  // Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ref_code': refCode,
      'material_name': materialName,
      'material_type': materialType,
      'unit_price': unitPrice,
      'status': status,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  // Copy with modifications
  ArticleStock copyWith({
    int? id,
    String? refCode,
    String? materialName,
    String? materialType,
    double? unitPrice,
    String? status,
    int? minStockLevel,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
  }) {
    return ArticleStock(
      id: id ?? this.id,
      refCode: refCode ?? this.refCode,
      materialName: materialName ?? this.materialName,
      materialType: materialType ?? this.materialType,
      unitPrice: unitPrice ?? this.unitPrice,
      status: status ?? this.status,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Helper method to parse double from dynamic value
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() {
    return 'ArticleStock(id: $id, refCode: $refCode, materialName: $materialName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticleStock && other.id == id && other.refCode == refCode;
  }

  @override
  int get hashCode => Object.hash(id, refCode);
}
