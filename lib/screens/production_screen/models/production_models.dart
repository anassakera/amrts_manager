// ═══════════════════════════════════════════════════════════════════════════════
// Production Models - نماذج البيانات
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// نموذج المنتج
/// Product Model - represents a manufactured aluminum profile
class ProductModel {
  final String id;
  final String name;
  final String reference;
  final String category;
  final double standardWeight; // الوزن القياسي بالكيلوغرام
  final double standardLength; // الطول القياسي بالمتر
  final String description;
  final DateTime createdAt;
  bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.reference,
    required this.category,
    required this.standardWeight,
    required this.standardLength,
    required this.description,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'reference': reference,
    'category': category,
    'standardWeight': standardWeight,
    'standardLength': standardLength,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'],
    name: json['name'],
    reference: json['reference'],
    category: json['category'],
    standardWeight: json['standardWeight'],
    standardLength: json['standardLength'],
    description: json['description'],
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'] ?? true,
  );
}

/// نموذج المواد الخام
/// Raw Material Model - represents materials used in production
class MaterialModel {
  final String id;
  final String name;
  final String type; // waste_aluminum, billet, paint, gas, scrap
  double stock; // الكمية المتوفرة
  final String unit; // kg, liter, m³
  final double costPerUnit; // التكلفة لكل وحدة
  final double reorderLevel; // مستوى إعادة الطلب
  final DateTime lastUpdated;

  MaterialModel({
    required this.id,
    required this.name,
    required this.type,
    required this.stock,
    required this.unit,
    required this.costPerUnit,
    required this.reorderLevel,
    required this.lastUpdated,
  });

  bool get needsReorder => stock <= reorderLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'stock': stock,
    'unit': unit,
    'costPerUnit': costPerUnit,
    'reorderLevel': reorderLevel,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

/// نموذج سجل الإنتاج
/// Production Record Model - comprehensive production data
class ProductionRecordModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double totalWeight;
  final ProductionStage stage;
  final double materialConsumed;
  final double wasteGenerated;
  final ProductionCostBreakdown costs;
  final DateTime productionDate;
  final String operatorName;
  final String shiftTeam;
  final String machineId;
  final ProductionQualityMetrics quality;
  final String notes;
  final DateTime createdAt;
  final List<ProductionParameter> parameters;

  ProductionRecordModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalWeight,
    required this.stage,
    required this.materialConsumed,
    required this.wasteGenerated,
    required this.costs,
    required this.productionDate,
    required this.operatorName,
    required this.shiftTeam,
    required this.machineId,
    required this.quality,
    required this.notes,
    required this.createdAt,
    required this.parameters,
  });

  double get efficiency => stage == ProductionStage.extrusion
      ? ((totalWeight / materialConsumed) * 100)
      : (((materialConsumed - wasteGenerated) / materialConsumed) * 100);

  double get wastePercentage => (wasteGenerated / materialConsumed) * 100;

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'totalWeight': totalWeight,
    'stage': stage.name,
    'materialConsumed': materialConsumed,
    'wasteGenerated': wasteGenerated,
    'costs': costs.toMap(),
    'productionDate': productionDate.toIso8601String(),
    'operatorName': operatorName,
    'shiftTeam': shiftTeam,
    'machineId': machineId,
    'quality': quality.toMap(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'parameters': parameters.map((p) => p.toMap()).toList(),
    'efficiency': efficiency,
    'wastePercentage': wastePercentage,
  };
}

/// مراحل الإنتاج
/// Production Stages
enum ProductionStage {
  smelting, // المسبكة
  extrusion, // البثق
  painting, // الطلاء
}

extension ProductionStageExtension on ProductionStage {
  String get arabicName {
    switch (this) {
      case ProductionStage.smelting:
        return 'المسبكة';
      case ProductionStage.extrusion:
        return 'البثق';
      case ProductionStage.painting:
        return 'الطلاء';
    }
  }

  String get frenchName {
    switch (this) {
      case ProductionStage.smelting:
        return 'Fonderie';
      case ProductionStage.extrusion:
        return 'Extrusion';
      case ProductionStage.painting:
        return 'Peinture';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductionStage.smelting:
        return Icons.local_fire_department;
      case ProductionStage.extrusion:
        return Icons.precision_manufacturing;
      case ProductionStage.painting:
        return Icons.palette;
    }
  }

  Color get color {
    switch (this) {
      case ProductionStage.smelting:
        return Colors.deepOrange;
      case ProductionStage.extrusion:
        return Colors.blue;
      case ProductionStage.painting:
        return Colors.purple;
    }
  }
}

/// تفصيل التكاليف
/// Cost Breakdown Structure
class ProductionCostBreakdown {
  final double materialCost; // تكلفة المواد الخام
  final double laborCost; // تكلفة العمالة
  final double energyCost; // تكلفة الطاقة (كهرباء + غاز)
  final double maintenanceCost; // تكلفة الصيانة
  final double depreciationCost; // الإهلاك
  final double overheadCost; // التكاليف العامة
  final double qualityControlCost; // تكلفة مراقبة الجودة

  ProductionCostBreakdown({
    required this.materialCost,
    required this.laborCost,
    required this.energyCost,
    required this.maintenanceCost,
    required this.depreciationCost,
    required this.overheadCost,
    required this.qualityControlCost,
  });

  double get totalCost =>
      materialCost +
      laborCost +
      energyCost +
      maintenanceCost +
      depreciationCost +
      overheadCost +
      qualityControlCost;

  double get directCost => materialCost + laborCost + energyCost;

  double get indirectCost =>
      maintenanceCost + depreciationCost + overheadCost + qualityControlCost;

  Map<String, dynamic> toMap() => {
    'materialCost': materialCost,
    'laborCost': laborCost,
    'energyCost': energyCost,
    'maintenanceCost': maintenanceCost,
    'depreciationCost': depreciationCost,
    'overheadCost': overheadCost,
    'qualityControlCost': qualityControlCost,
    'totalCost': totalCost,
    'directCost': directCost,
    'indirectCost': indirectCost,
  };
}

/// مقاييس الجودة
/// Quality Metrics
class ProductionQualityMetrics {
  final double defectRate; // معدل العيوب (%)
  final double surfaceQuality; // جودة السطح (1-10)
  final double dimensionalAccuracy; // الدقة البعدية (%)
  final String inspectorName;
  final DateTime inspectionDate;
  final List<String> defectTypes;

  ProductionQualityMetrics({
    required this.defectRate,
    required this.surfaceQuality,
    required this.dimensionalAccuracy,
    required this.inspectorName,
    required this.inspectionDate,
    required this.defectTypes,
  });

  bool get passedQualityControl =>
      defectRate < 5.0 && surfaceQuality >= 7.0 && dimensionalAccuracy >= 95.0;

  Map<String, dynamic> toMap() => {
    'defectRate': defectRate,
    'surfaceQuality': surfaceQuality,
    'dimensionalAccuracy': dimensionalAccuracy,
    'inspectorName': inspectorName,
    'inspectionDate': inspectionDate.toIso8601String(),
    'defectTypes': defectTypes,
    'passedQualityControl': passedQualityControl,
  };
}

/// معاملات الإنتاج
/// Production Parameters
class ProductionParameter {
  final String name;
  final dynamic value;
  final String unit;

  ProductionParameter({
    required this.name,
    required this.value,
    required this.unit,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'value': value,
    'unit': unit,
  };
}

/// إحصائيات الإنتاج
class ProductionStatistics {
  final int totalRecords;
  final double totalWeight;
  final double totalCost;
  final double totalWaste;
  final double averageEfficiency;

  ProductionStatistics({
    required this.totalRecords,
    required this.totalWeight,
    required this.totalCost,
    required this.totalWaste,
    required this.averageEfficiency,
  });
}
