// ═══════════════════════════════════════════════════════════════════════════════
// Production Comprehensive Management System - نظام إدارة الإنتاج الشامل
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/production_models.dart';
import 'services/calculation_engine.dart';
import 'services/production_data_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN - الشاشة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════════

class ProductionComprehensiveScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataSaved;

  const ProductionComprehensiveScreen({
    super.key,
    this.onDataSaved,
  });

  @override
  State<ProductionComprehensiveScreen> createState() =>
      _ProductionComprehensiveScreenState();
}

class _ProductionComprehensiveScreenState
    extends State<ProductionComprehensiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final _dataService = ProductionDataService();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _dataService.initialize();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'إدارة الإنتاج الشاملة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: ProductionStage.values.map((stage) {
            return Tab(
              icon: Icon(stage.icon),
              text: stage.arabicName,
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          SmeltingStageView(
            stage: ProductionStage.smelting,
            onDataSaved: widget.onDataSaved,
          ),
          ExtrusionStageView(stage: ProductionStage.extrusion),
          PaintingStageView(stage: ProductionStage.painting),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAGE VIEWS - عرض المراحل
// ═══════════════════════════════════════════════════════════════════════════════

/// عرض مرحلة المسبكة
class SmeltingStageView extends StatefulWidget {
  final ProductionStage stage;
  final Function(Map<String, dynamic>)? onDataSaved;

  const SmeltingStageView({
    super.key,
    required this.stage,
    this.onDataSaved,
  });

  @override
  State<SmeltingStageView> createState() => _SmeltingStageViewState();
}

class _SmeltingStageViewState extends State<SmeltingStageView>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            indicatorColor: ProductionStage.smelting.color,
            labelColor: ProductionStage.smelting.color,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'تسجيل جديد'),
              Tab(icon: Icon(Icons.list_alt), text: 'السجلات'),
              Tab(icon: Icon(Icons.analytics), text: 'التحليلات'),
              Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              SmeltingInputForm(onDataSaved: widget.onDataSaved),
              SmeltingRecordsList(),
              SmeltingAnalytics(),
              SmeltingSettings(),
            ],
          ),
        ),
      ],
    );
  }
}

/// نموذج إدخال المسبكة
class SmeltingInputForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataSaved;

  const SmeltingInputForm({
    super.key,
    this.onDataSaved,
  });

  @override
  State<SmeltingInputForm> createState() => _SmeltingInputFormState();
}

class _SmeltingInputFormState extends State<SmeltingInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _wasteWeightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _operatorNameController = TextEditingController();
  final _shiftTeamController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedAlloy = 'AL-6063';
  final List<String> _alloyTypes = ['AL-6063', 'AL-6060', 'AL-6082', 'AL-5754'];

  SmeltingCalculationResult? _calculationResult;

  @override
  void dispose() {
    _wasteWeightController.dispose();
    _temperatureController.dispose();
    _operatingHoursController.dispose();
    _operatorNameController.dispose();
    _shiftTeamController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _calculationResult = ProductionCalculationEngine.calculateSmelting(
        wasteWeight: double.parse(_wasteWeightController.text),
        temperature: double.parse(_temperatureController.text),
        alloyType: _selectedAlloy,
        operatingHours: double.parse(_operatingHoursController.text),
      );
    });
  }

  void _submitRecord() {
    if (_calculationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء حساب النتائج أولاً')),
      );
      return;
    }

    final record = ProductionRecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: 'smelting_billet',
      productName: 'بليت من المسبكة',
      quantity: 1,
      totalWeight: _calculationResult!.billetOutput,
      stage: ProductionStage.smelting,
      materialConsumed: _calculationResult!.wasteInput,
      wasteGenerated: _calculationResult!.waste,
      costs: _calculationResult!.costBreakdown,
      productionDate: DateTime.now(),
      operatorName: _operatorNameController.text,
      shiftTeam: _shiftTeamController.text,
      machineId: 'FURNACE-01',
      quality: ProductionQualityMetrics(
        defectRate: 0,
        surfaceQuality: 9.0,
        dimensionalAccuracy: 100,
        inspectorName: 'نظام آلي',
        inspectionDate: DateTime.now(),
        defectTypes: [],
      ),
      notes: _notesController.text,
      createdAt: DateTime.now(),
      parameters: [
        ProductionParameter(
          name: 'درجة الحرارة',
          value: double.parse(_temperatureController.text),
          unit: '°C',
        ),
        ProductionParameter(
          name: 'نوع السبيكة',
          value: _selectedAlloy,
          unit: '',
        ),
      ],
    );

    final dataService = ProductionDataService();
    dataService.consumeMaterial('waste_aluminum', _calculationResult!.wasteInput);
    dataService.addMaterial('billet', _calculationResult!.billetOutput);
    dataService.addMaterial('scrap', _calculationResult!.waste);
    dataService.addRecord(record);

    // Call the callback if provided
    if (widget.onDataSaved != null) {
      widget.onDataSaved!({
        'record': record.toMap(),
        'calculation_result': {
          'billet_output': _calculationResult!.billetOutput,
          'waste': _calculationResult!.waste,
          'efficiency': _calculationResult!.efficiency,
          'total_cost': _calculationResult!.totalCost,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('تم حفظ سجل الإنتاج بنجاح'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    setState(() {
      _wasteWeightController.clear();
      _temperatureController.clear();
      _operatingHoursController.clear();
      _operatorNameController.clear();
      _shiftTeamController.clear();
      _notesController.clear();
      _calculationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(5),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('معلومات الإدخال', Icons.input),
            const SizedBox(height: 5),
            _buildInputCard(),
            const SizedBox(height: 5),
            if (_calculationResult != null) ...[
              _buildSectionTitle('نتائج الحسابات', Icons.calculate),
              const SizedBox(height: 5),
              _buildResultsCard(),
              const SizedBox(height: 5),
            ],
            if (_calculationResult != null)
              _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: ProductionStage.smelting.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ProductionStage.smelting.color, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _wasteWeightController,
                    decoration: const InputDecoration(
                      labelText: 'وزن النفايات (كغ)',
                      prefixIcon: Icon(Icons.scale),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(5),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) {
                        return 'قيمة غير صحيحة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextFormField(
                    controller: _temperatureController,
                    decoration: const InputDecoration(
                      labelText: 'درجة الحرارة (°C)',
                      prefixIcon: Icon(Icons.thermostat),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(5),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final temp = double.tryParse(v);
                      if (temp == null || temp < 600 || temp > 800) {
                        return '600-800°C';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              initialValue: _selectedAlloy,
              decoration: const InputDecoration(
                labelText: 'نوع السبيكة',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(5),
              ),
              items: _alloyTypes.map((alloy) {
                return DropdownMenuItem(value: alloy, child: Text(alloy));
              }).toList(),
              onChanged: (value) => setState(() => _selectedAlloy = value!),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _operatingHoursController,
              decoration: const InputDecoration(
                labelText: 'ساعات التشغيل',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(5),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'قيمة غير صحيحة';
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _operatorNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المشغل',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(5),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextFormField(
                    controller: _shiftTeamController,
                    decoration: const InputDecoration(
                      labelText: 'الفريق',
                      prefixIcon: Icon(Icons.groups),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(5),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(5),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'احسب النتائج',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProductionStage.smelting.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final result = _calculationResult!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            _buildResultRow(
              'وزن البليت الناتج',
              '${result.billetOutput.toStringAsFixed(2)} كغ',
              Icons.inventory,
              Colors.green,
            ),
            const Divider(height: 5),
            _buildResultRow(
              'الفاقد',
              '${result.waste.toStringAsFixed(2)} كغ (${result.lossRate.toStringAsFixed(1)}%)',
              Icons.delete,
              Colors.orange,
            ),
            const Divider(height: 5),
            _buildResultRow(
              'الكفاءة',
              '${result.efficiency.toStringAsFixed(1)}%',
              Icons.speed,
              Colors.blue,
            ),
            const Divider(height: 5),
            _buildResultRow(
              'استهلاك الغاز',
              '${result.gasConsumption.toStringAsFixed(2)} م³',
              Icons.gas_meter,
              Colors.purple,
            ),
            const Divider(height: 5),
            _buildResultRow(
              'استهلاك الكهرباء',
              '${result.electricityConsumption.toStringAsFixed(2)} كيلوواط/ساعة',
              Icons.electric_bolt,
              Colors.amber,
            ),
            const Divider(height: 5),
            _buildResultRow(
              'التكلفة الإجمالية',
              '${result.totalCost.toStringAsFixed(2)} درهم',
              Icons.attach_money,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _submitRecord,
        icon: const Icon(Icons.save),
        label: const Text(
          'حفظ السجل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// قائمة سجلات المسبكة
class SmeltingRecordsList extends StatelessWidget {
  const SmeltingRecordsList({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = ProductionDataService();
    final records = dataService.getRecordsByStage(ProductionStage.smelting);

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد سجلات إنتاج',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة أول سجل إنتاج',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordCard(record, context);
      },
    );
  }

  Widget _buildRecordCard(ProductionRecordModel record, BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'ar');

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(context, record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: ProductionStage.smelting.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      ProductionStage.smelting.icon,
                      color: ProductionStage.smelting.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(record.productionDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${record.efficiency.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(BuildContext context, ProductionRecordModel record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(5),
            child: Center(
              child: Text('تفاصيل السجل: ${record.productName}'),
            ),
          );
        },
      ),
    );
  }
}

/// تحليلات المسبكة
class SmeltingAnalytics extends StatelessWidget {
  const SmeltingAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('قريباً: تحليلات متقدمة ورسوم بيانية'),
    );
  }
}

/// إعدادات المسبكة
class SmeltingSettings extends StatelessWidget {
  const SmeltingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('قريباً: إعدادات المسبكة'),
    );
  }
}

/// عرض مرحلة البثق
class ExtrusionStageView extends StatelessWidget {
  final ProductionStage stage;

  const ExtrusionStageView({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('قريباً: مرحلة البثق'),
    );
  }
}

/// عرض مرحلة الطلاء
class PaintingStageView extends StatelessWidget {
  final ProductionStage stage;

  const PaintingStageView({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('قريباً: مرحلة الطلاء'),
    );
  }
}
