// ═══════════════════════════════════════════════════════════════════════════════
// DATA SERVICE - خدمة البيانات
// ═══════════════════════════════════════════════════════════════════════════════

import '../models/production_models.dart';

/// خدمة إدارة بيانات الإنتاج
/// Production Data Management Service
class ProductionDataService {
  static final ProductionDataService _instance = ProductionDataService._internal();
  factory ProductionDataService() => _instance;
  ProductionDataService._internal();

  // البيانات الأساسية
  final List<ProductModel> _products = [];
  final List<MaterialModel> _materials = [];
  final List<ProductionRecordModel> _records = [];

  // Getters
  List<ProductModel> get products => List.unmodifiable(_products);
  List<MaterialModel> get materials => List.unmodifiable(_materials);
  List<ProductionRecordModel> get records => List.unmodifiable(_records);

  /// تهيئة البيانات الأولية
  void initialize() {
    if (_products.isEmpty) _seedProducts();
    if (_materials.isEmpty) _seedMaterials();
    if (_records.isEmpty) _seedRecords();
  }

  /// بذر المنتجات الأولية
  void _seedProducts() {
    _products.addAll([
      ProductModel(
        id: 'prod_001',
        name: 'بروفيل نافذة A-500',
        reference: 'A-500',
        category: 'نوافذ',
        standardWeight: 1.5,
        standardLength: 6.0,
        description: 'بروفيل ألمنيوم للنوافذ - سبيكة 6063',
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_002',
        name: 'بروفيل باب B-300',
        reference: 'B-300',
        category: 'أبواب',
        standardWeight: 2.0,
        standardLength: 6.0,
        description: 'بروفيل ألمنيوم للأبواب - سبيكة 6063',
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_003',
        name: 'بروفيل واجهة C-200',
        reference: 'C-200',
        category: 'واجهات',
        standardWeight: 2.5,
        standardLength: 6.0,
        description: 'بروفيل ألمنيوم للواجهات - سبيكة 6082',
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_004',
        name: 'بروفيل صناعي D-100',
        reference: 'D-100',
        category: 'صناعي',
        standardWeight: 1.8,
        standardLength: 6.0,
        description: 'بروفيل ألمنيوم صناعي - سبيكة 6060',
        createdAt: DateTime.now(),
      ),
    ]);
  }

  /// بذر المواد الأولية
  void _seedMaterials() {
    _materials.addAll([
      MaterialModel(
        id: 'mat_001',
        name: 'نفايات ألمنيوم',
        type: 'waste_aluminum',
        stock: 5000.0,
        unit: 'kg',
        costPerUnit: 0.0,
        reorderLevel: 1000.0,
        lastUpdated: DateTime.now(),
      ),
      MaterialModel(
        id: 'mat_002',
        name: 'بليت ألمنيوم',
        type: 'billet',
        stock: 3000.0,
        unit: 'kg',
        costPerUnit: 15.0,
        reorderLevel: 500.0,
        lastUpdated: DateTime.now(),
      ),
      MaterialModel(
        id: 'mat_003',
        name: 'طلاء بودرة',
        type: 'paint',
        stock: 800.0,
        unit: 'kg',
        costPerUnit: 35.0,
        reorderLevel: 100.0,
        lastUpdated: DateTime.now(),
      ),
      MaterialModel(
        id: 'mat_004',
        name: 'غاز طبيعي',
        type: 'gas',
        stock: 1500.0,
        unit: 'm³',
        costPerUnit: 7.0,
        reorderLevel: 200.0,
        lastUpdated: DateTime.now(),
      ),
      MaterialModel(
        id: 'mat_005',
        name: 'خردة',
        type: 'scrap',
        stock: 500.0,
        unit: 'kg',
        costPerUnit: 5.0,
        reorderLevel: 0.0,
        lastUpdated: DateTime.now(),
      ),
    ]);
  }

  /// بذر سجلات أولية للعرض
  void _seedRecords() {
    // سيتم إضافة السجلات من خلال التطبيق
  }

  /// إضافة سجل إنتاج جديد
  void addRecord(ProductionRecordModel record) {
    _records.insert(0, record); // إضافة في البداية
  }

  /// استهلاك مادة خام
  void consumeMaterial(String materialType, double quantity) {
    final material = _materials.firstWhere(
      (m) => m.type == materialType,
      orElse: () => throw Exception('Material not found: $materialType'),
    );
    material.stock -= quantity;
  }

  /// إضافة مادة خام
  void addMaterial(String materialType, double quantity) {
    final material = _materials.firstWhere(
      (m) => m.type == materialType,
      orElse: () => throw Exception('Material not found: $materialType'),
    );
    material.stock += quantity;
  }

  /// الحصول على سجلات حسب المرحلة
  List<ProductionRecordModel> getRecordsByStage(ProductionStage stage) {
    return _records.where((r) => r.stage == stage).toList();
  }

  /// إحصائيات الإنتاج
  ProductionStatistics getStatistics() {
    final totalRecords = _records.length;
    final totalWeight = _records.fold<double>(0, (sum, r) => sum + r.totalWeight);
    final totalCost = _records.fold<double>(0, (sum, r) => sum + r.costs.totalCost);
    final totalWaste = _records.fold<double>(0, (sum, r) => sum + r.wasteGenerated);
    final avgEfficiency = _records.isEmpty
        ? 0.0
        : _records.fold<double>(0, (sum, r) => sum + r.efficiency) / totalRecords;

    return ProductionStatistics(
      totalRecords: totalRecords,
      totalWeight: totalWeight,
      totalCost: totalCost,
      totalWaste: totalWaste,
      averageEfficiency: avgEfficiency,
    );
  }
}
