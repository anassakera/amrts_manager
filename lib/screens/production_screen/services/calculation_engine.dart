// ═══════════════════════════════════════════════════════════════════════════════
// CALCULATION ENGINE - محرك الحسابات الذكي
// ═══════════════════════════════════════════════════════════════════════════════

import '../models/production_models.dart';

/// محرك الحسابات لجميع مراحل الإنتاج
/// Smart Calculation Engine for all production stages
class ProductionCalculationEngine {
  // ────────────────────────────────────────────────────────────────────────────
  // SMELTING CALCULATIONS - حسابات المسبكة
  // ────────────────────────────────────────────────────────────────────────────

  /// حساب إنتاج البيليت من النفايات
  /// Calculate billet output from waste aluminum
  /// معدل الفقد: 6% (Loss rate)
  static SmeltingCalculationResult calculateSmelting({
    required double wasteWeight,
    required double temperature,
    required String alloyType,
    required double operatingHours,
  }) {
    // معدل الفقد حسب نوع السبيكة
    final lossRate = _getSmeltingLossRate(alloyType);
    final billetOutput = wasteWeight * (1 - lossRate);
    final waste = wasteWeight * lossRate;

    // حساب استهلاك الطاقة
    final gasConsumption = wasteWeight * 0.15; // 0.15 m³ gas per kg
    final electricityConsumption = wasteWeight * 0.8; // 0.8 kWh per kg

    // حساب التكاليف
    final gasCost = gasConsumption * 7.0; // 7 DH per m³
    final electricityCost = electricityConsumption * 1.2; // 1.2 DH per kWh
    final laborCost = operatingHours * 50.0; // 50 DH per hour
    final maintenanceCost = wasteWeight * 0.5; // 0.5 DH per kg
    final depreciationCost = operatingHours * 25.0; // 25 DH per hour

    final totalEnergyCost = gasCost + electricityCost;
    final totalCost = totalEnergyCost + laborCost + maintenanceCost + depreciationCost;

    // تحذيرات وتوصيات
    final warnings = <String>[];
    if (lossRate > 0.07) {
      warnings.add('معدل الفقد مرتفع - يُنصح بمراجعة درجة الحرارة');
    }
    if (temperature < 650 || temperature > 750) {
      warnings.add('درجة الحرارة خارج النطاق المثالي (650-750°C)');
    }

    return SmeltingCalculationResult(
      wasteInput: wasteWeight,
      billetOutput: billetOutput,
      waste: waste,
      lossRate: lossRate * 100,
      gasConsumption: gasConsumption,
      electricityConsumption: electricityConsumption,
      totalEnergyCost: totalEnergyCost,
      totalCost: totalCost,
      efficiency: (1 - lossRate) * 100,
      warnings: warnings,
      costBreakdown: ProductionCostBreakdown(
        materialCost: 0, // النفايات مجانية
        laborCost: laborCost,
        energyCost: totalEnergyCost,
        maintenanceCost: maintenanceCost,
        depreciationCost: depreciationCost,
        overheadCost: wasteWeight * 0.3,
        qualityControlCost: 50.0,
      ),
    );
  }

  static double _getSmeltingLossRate(String alloyType) {
    switch (alloyType) {
      case 'AL-6063':
        return 0.06;
      case 'AL-6060':
        return 0.055;
      case 'AL-6082':
        return 0.065;
      case 'AL-5754':
        return 0.07;
      default:
        return 0.06;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // EXTRUSION CALCULATIONS - حسابات البثق
  // ────────────────────────────────────────────────────────────────────────────

  /// حساب عملية البثق
  /// Calculate extrusion process
  /// كفاءة البثق: 82% (Extrusion efficiency)
  /// معدل الخردة: 18% (Scrap rate)
  static ExtrusionCalculationResult calculateExtrusion({
    required double quantity,
    required double productWeight,
    required double billetWeight,
    required double speed,
    required double pressure,
    required double operatingHours,
  }) {
    final totalProductWeight = quantity * productWeight;
    final billetConsumed = totalProductWeight / 0.82; // كفاءة 82%
    final scrapGenerated = billetConsumed * 0.18; // خردة 18%
    final efficiency = (totalProductWeight / billetConsumed) * 100;

    // حساب استهلاك الطاقة
    final electricityConsumption = billetConsumed * 1.5; // 1.5 kWh per kg

    // حساب التكاليف
    final materialCost = billetConsumed * 15.0; // 15 DH per kg billet
    final energyCost = electricityConsumption * 1.2; // 1.2 DH per kWh
    final laborCost = operatingHours * 60.0; // 60 DH per hour
    final dieCost = quantity * 0.5; // تكلفة القالب لكل قطعة
    final maintenanceCost = operatingHours * 30.0;
    final depreciationCost = operatingHours * 40.0;

    final totalCost = materialCost + energyCost + laborCost + dieCost +
        maintenanceCost + depreciationCost;

    // تحذيرات وتوصيات
    final warnings = <String>[];
    if (efficiency < 80) {
      warnings.add('الكفاءة منخفضة - يُنصح بمراجعة إعدادات المكبس');
    }
    if (speed > 15) {
      warnings.add('السرعة مرتفعة - قد تؤثر على جودة المنتج');
    }
    if (pressure > 350) {
      warnings.add('الضغط مرتفع - يُنصح بفحص القالب');
    }

    return ExtrusionCalculationResult(
      quantity: quantity,
      totalProductWeight: totalProductWeight,
      billetConsumed: billetConsumed,
      scrapGenerated: scrapGenerated,
      efficiency: efficiency,
      scrapRate: 18.0,
      electricityConsumption: electricityConsumption,
      totalCost: totalCost,
      warnings: warnings,
      costBreakdown: ProductionCostBreakdown(
        materialCost: materialCost,
        laborCost: laborCost,
        energyCost: energyCost,
        maintenanceCost: maintenanceCost,
        depreciationCost: depreciationCost,
        overheadCost: billetConsumed * 0.8,
        qualityControlCost: 75.0,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PAINTING CALCULATIONS - حسابات الطلاء
  // ────────────────────────────────────────────────────────────────────────────

  /// حساب عملية الطلاء
  /// Calculate painting process
  /// استهلاك الطلاء: 10% من وزن المنتج
  /// استهلاك الغاز: 5% من وزن المنتج
  static PaintingCalculationResult calculatePainting({
    required double quantity,
    required double productWeight,
    required String paintType,
    required String paintingMethod,
    required double operatingHours,
    required int coatLayers,
  }) {
    final totalProductWeight = quantity * productWeight;

    // حساب استهلاك المواد حسب طريقة الطلاء
    final paintConsumptionRate = _getPaintConsumptionRate(paintingMethod);
    final paintConsumed = totalProductWeight * paintConsumptionRate;
    final gasConsumed = totalProductWeight * 0.05; // 5% للتجفيف

    // حساب سمك الطبقة
    final layerThickness = _calculateLayerThickness(paintType, coatLayers);

    // حساب استهلاك الطاقة
    final gasConsumptionM3 = gasConsumed * 1.2; // m³
    final electricityConsumption = totalProductWeight * 0.5; // kWh

    // حساب التكاليف
    final paintCost = paintConsumed * _getPaintCostPerKg(paintType);
    final gasCost = gasConsumptionM3 * 7.0;
    final electricityCost = electricityConsumption * 1.2;
    final laborCost = operatingHours * 55.0;
    final cleaningMaterialsCost = quantity * 0.3;
    final maintenanceCost = operatingHours * 20.0;

    final totalEnergyCost = gasCost + electricityCost;
    final totalCost = paintCost + totalEnergyCost + laborCost +
        cleaningMaterialsCost + maintenanceCost;

    // حساب معدل إعادة العمل
    final reworkRate = _calculateReworkRate(paintingMethod, coatLayers);

    // تحذيرات وتوصيات
    final warnings = <String>[];
    if (layerThickness < 40 || layerThickness > 120) {
      warnings.add('سمك الطبقة خارج النطاق المثالي (40-120 ميكرون)');
    }
    if (reworkRate > 5) {
      warnings.add('معدل إعادة العمل مرتفع - يُنصح بمراجعة عملية الطلاء');
    }

    return PaintingCalculationResult(
      quantity: quantity,
      totalProductWeight: totalProductWeight,
      paintConsumed: paintConsumed,
      gasConsumed: gasConsumed,
      layerThickness: layerThickness,
      coverage: 100 - reworkRate,
      reworkRate: reworkRate,
      totalCost: totalCost,
      warnings: warnings,
      costBreakdown: ProductionCostBreakdown(
        materialCost: paintCost,
        laborCost: laborCost,
        energyCost: totalEnergyCost,
        maintenanceCost: maintenanceCost,
        depreciationCost: operatingHours * 15.0,
        overheadCost: totalProductWeight * 0.5,
        qualityControlCost: 60.0,
      ),
    );
  }

  static double _getPaintConsumptionRate(String method) {
    switch (method) {
      case 'electrostatic':
        return 0.08; // 8%
      case 'powder':
        return 0.10; // 10%
      case 'liquid':
        return 0.12; // 12%
      default:
        return 0.10;
    }
  }

  static double _calculateLayerThickness(String paintType, int layers) {
    final baseThickness = paintType == 'powder' ? 80.0 : 60.0;
    return baseThickness * layers;
  }

  static double _getPaintCostPerKg(String paintType) {
    switch (paintType) {
      case 'powder':
        return 35.0;
      case 'liquid':
        return 45.0;
      case 'epoxy':
        return 55.0;
      default:
        return 40.0;
    }
  }

  static double _calculateReworkRate(String method, int layers) {
    double baseRate = method == 'electrostatic' ? 2.0 : 4.0;
    if (layers > 2) baseRate += 1.0;
    return baseRate;
  }
}

/// نتيجة حسابات المسبكة
class SmeltingCalculationResult {
  final double wasteInput;
  final double billetOutput;
  final double waste;
  final double lossRate;
  final double gasConsumption;
  final double electricityConsumption;
  final double totalEnergyCost;
  final double totalCost;
  final double efficiency;
  final List<String> warnings;
  final ProductionCostBreakdown costBreakdown;

  SmeltingCalculationResult({
    required this.wasteInput,
    required this.billetOutput,
    required this.waste,
    required this.lossRate,
    required this.gasConsumption,
    required this.electricityConsumption,
    required this.totalEnergyCost,
    required this.totalCost,
    required this.efficiency,
    required this.warnings,
    required this.costBreakdown,
  });
}

/// نتيجة حسابات البثق
class ExtrusionCalculationResult {
  final double quantity;
  final double totalProductWeight;
  final double billetConsumed;
  final double scrapGenerated;
  final double efficiency;
  final double scrapRate;
  final double electricityConsumption;
  final double totalCost;
  final List<String> warnings;
  final ProductionCostBreakdown costBreakdown;

  ExtrusionCalculationResult({
    required this.quantity,
    required this.totalProductWeight,
    required this.billetConsumed,
    required this.scrapGenerated,
    required this.efficiency,
    required this.scrapRate,
    required this.electricityConsumption,
    required this.totalCost,
    required this.warnings,
    required this.costBreakdown,
  });
}

/// نتيجة حسابات الطلاء
class PaintingCalculationResult {
  final double quantity;
  final double totalProductWeight;
  final double paintConsumed;
  final double gasConsumed;
  final double layerThickness;
  final double coverage;
  final double reworkRate;
  final double totalCost;
  final List<String> warnings;
  final ProductionCostBreakdown costBreakdown;

  PaintingCalculationResult({
    required this.quantity,
    required this.totalProductWeight,
    required this.paintConsumed,
    required this.gasConsumed,
    required this.layerThickness,
    required this.coverage,
    required this.reworkRate,
    required this.totalCost,
    required this.warnings,
    required this.costBreakdown,
  });
}
