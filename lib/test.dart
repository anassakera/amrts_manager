// test.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/document_model.dart';
import 'services/calculation_service.dart';
import 'provider/document_provider.dart';

class SmartDocumentScreen extends StatefulWidget {
  @override
  _SmartDocumentScreenState createState() => _SmartDocumentScreenState();
}

class _SmartDocumentScreenState extends State<SmartDocumentScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CalculationService _calculationService = CalculationService();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final fields = [
      'refFournisseur',
      'articles',
      'qte',
      'poids',
      'puPieces',
      'mt',
      'prixAchat',
      'autresCharges',
      'cuHt',
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  void _populateControllers(DocumentItem item) {
    _controllers['refFournisseur']?.text = item.refFournisseur;
    _controllers['articles']?.text = item.articles;
    _controllers['qte']?.text = item.qte.toString();
    _controllers['poids']?.text = item.poids.toString();
    _controllers['puPieces']?.text = item.puPieces.toString();
    _controllers['mt']?.text = item.mt.toString();
    _controllers['prixAchat']?.text = item.prixAchat.toString();
    _controllers['autresCharges']?.text = item.autresCharges.toString();
    _controllers['cuHt']?.text = item.cuHt.toString();
  }

  void _clearControllers() {
    _controllers.forEach((key, controller) {
      controller.clear();
    });
  }

  Map<String, dynamic> _getFormData() {
    return {
      'refFournisseur': _controllers['refFournisseur']?.text ?? '',
      'articles': _controllers['articles']?.text ?? '',
      'qte': int.tryParse(_controllers['qte']?.text ?? '0') ?? 0,
      'poids': double.tryParse(_controllers['poids']?.text ?? '0') ?? 0.0,
      'puPieces': double.tryParse(_controllers['puPieces']?.text ?? '0') ?? 0.0,
      'mt': double.tryParse(_controllers['mt']?.text ?? '0') ?? 0.0,
      'prixAchat':
          double.tryParse(_controllers['prixAchat']?.text ?? '0') ?? 0.0,
      'autresCharges':
          double.tryParse(_controllers['autresCharges']?.text ?? '0') ?? 0.0,
      'cuHt': double.tryParse(_controllers['cuHt']?.text ?? '0') ?? 0.0,
    };
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF1F5F9), // خلفية رئيسية فاتحة جدًا
        ),
        child: Consumer<DocumentProvider>(
          builder: (context, provider, child) {
            final totals = _calculationService.calculateTotals(
              provider.items,
              provider.summary,
            );

            return Column(
              children: [
                // رأس الصفحة الذكي
                _buildSmartHeader(provider, totals),

                // الجدول الذكي
                Expanded(child: _buildSmartTable(provider)),

                // ملخص البيانات
                _buildSummaryFooter(provider, totals),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmartHeader(
    DocumentProvider provider,
    Map<String, double> totals,
  ) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF60A5FA).withOpacity(0.10), // ظل أزرق فاتح
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // العنوان الرئيسي
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                    ], // تدرج أزرق داكن إلى متوسط
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Facture',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A), // أزرق داكن عميق
                      ),
                    ),
                    Text(
                      'Facture N° : ${provider.summary.factureNumber}',
                      style: TextStyle(
                        color: Color(0xFF3B82F6), // أزرق متوسط
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // شريط الأدوات الذكي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // معلومات سريعة
              // Row(
              //   children: [

              //   ],
              // ),

              // أزرار التحكم
              Row(
                children: [
                  _buildQuickStat(
                    'العناصر',
                    provider.items.length.toString(),
                    Icons.inventory,
                  ),
                  SizedBox(width: 5),
                  _buildQuickStat(
                    'الوزن الكلي',
                    '${totals['poidsTotal']?.toStringAsFixed(0)} كغ',
                    Icons.scale,
                  ),
                  SizedBox(width: 5),
                  _buildQuickStat(
                    'القيمة',
                    '${totals['total']?.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                  SizedBox(width: 5),

                  if (provider.hasSelection) ...[
                    _buildActionButton(
                      'حذف المحدد (${provider.selectedIndices.length})',
                      Icons.delete_sweep_rounded, // أيقونة أفضل للحذف
                      Color(0xFFEF4444), // أحمر حديث
                      () => _showDeleteConfirmation(context, provider),
                    ),
                    SizedBox(width: 8),
                    _buildActionButton(
                      'إلغاء التحديد',
                      Icons.clear_all_rounded, // أيقونة أوضح
                      Color(0xFF6B7280), // رمادي متوسط أنيق
                      () => provider.clearSelection(),
                    ),
                    SizedBox(width: 8),
                  ],
                  _buildActionButton(
                    'تحديد الكل',
                    Icons.checklist_rtl_rounded, // أيقونة أنسب للتحديد
                    Color(0xFF8B5CF6), // بنفسجي جميل
                    () => provider.selectAll(),
                  ),
                  SizedBox(width: 8),
                  _buildActionButton(
                    'إضافة جديد',
                    Icons.add_circle_outline_rounded, // أيقونة إضافة أنيقة
                    Color(0xFF10B981), // أخضر زمردي حديث
                    () {
                      provider.addItem();
                      _clearControllers();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 5),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF60A5FA).withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الأيقونة في اليسار
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),

          SizedBox(width: 5),
          // العنوان في الوسط
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(width: 5),
          // القيمة في اليمين
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.18),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18), // زيادة حجم الأيقونة قليلاً
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600, // خط أقوى قليلاً
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), // حشو أكبر
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // زوايا أكثر انحناءً
          side: BorderSide(color: color.withOpacity(0.25), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildSmartTable(DocumentProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // رأس الجدول
          _buildTableHeader(),

          // محتوى الجدول
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount:
                  provider.items.length +
                  (provider.editingIndex == provider.items.length ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < provider.items.length) {
                  return _buildTableRow(provider, provider.items[index], index);
                } else {
                  // صف جديد للتحرير
                  return _buildEditRow(provider, index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 40), // مساحة للتحديد
          _buildHeaderCell('مرجع المورد', flex: 2),
          _buildHeaderCell('المادة', flex: 3),
          _buildHeaderCell('الكمية', flex: 1),
          _buildHeaderCell('الوزن', flex: 2),
          _buildHeaderCell('سعر القطعة', flex: 2),
          _buildHeaderCell('المبلغ الإجمالي', flex: 2),
          _buildHeaderCell('سعر الشراء', flex: 2),
          _buildHeaderCell('مصاريف أخرى', flex: 2),
          _buildHeaderCell('تكلفة القطعة', flex: 2),
          SizedBox(width: 60), // مساحة للأزرار
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(
    DocumentProvider provider,
    DocumentItem item,
    int index,
  ) {
    final isSelected = provider.selectedIndices.contains(index);
    final isEditing = provider.editingIndex == index;

    if (isEditing) {
      return _buildEditRow(provider, index);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF60A5FA).withOpacity(0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Color(0xFF3B82F6), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => provider.toggleSelection(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // زر التحديد
              InkWell(
                onTap: () => provider.toggleSelection(index),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF1E3A8A) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Color(0xFF1E3A8A) : Color(0xFF60A5FA),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              SizedBox(width: 20),

              // بيانات الصف
              _buildDataCell(item.refFournisseur, flex: 2),
              _buildDataCell(item.articles, flex: 3),
              _buildDataCell(item.qte.toString(), flex: 1),
              _buildDataCell(
                _calculationService.formatWeight(item.poids),
                flex: 2,
              ),
              _buildDataCell(
                _calculationService.formatCurrency(item.puPieces),
                flex: 2,
              ),
              _buildDataCell(
                _calculationService.formatCurrency(item.mt),
                flex: 2,
              ),
              _buildDataCell(
                _calculationService.formatCurrency(item.prixAchat),
                flex: 2,
              ),
              _buildDataCell(
                _calculationService.formatCurrency(item.autresCharges),
                flex: 2,
              ),
              _buildDataCell(
                _calculationService.formatCurrency(item.cuHt),
                flex: 2,
              ),

              // أزرار التحكم
              SizedBox(
                width: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      onPressed: () {
                        provider.startEditing(index);
                        _populateControllers(item);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => _showDeleteSingleConfirmation(
                        context,
                        provider,
                        index,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEditRow(DocumentProvider provider, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF60A5FA).withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF3B82F6), width: 2),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            SizedBox(width: 40),
            _buildEditField('refFournisseur', 'مرجع المورد', flex: 2),
            _buildEditField('articles', 'المادة', flex: 3),
            _buildEditField('qte', 'الكمية', flex: 1, isNumber: true),
            _buildEditField(
              'poids',
              'الوزن',
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: false,
            ),
            _buildEditField(
              'puPieces',
              'سعر القطعة',
              flex: 2,
              isNumber: true,
              isDecimal: true,
            ),
            _buildEditField(
              'mt',
              'المبلغ الإجمالي',
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            _buildEditField(
              'prixAchat',
              'سعر الشراء',
              flex: 2,
              isNumber: true,
              isDecimal: true,
            ),
            _buildEditField(
              'autresCharges',
              'مصاريف أخرى',
              flex: 2,
              isNumber: true,
              isDecimal: true,
            ),
            _buildEditField(
              'cuHt',
              'تكلفة القطعة',
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),

            // أزرار الحفظ والإلغاء
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.save, size: 16, color: Color(0xFF1E3A8A)),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        provider.saveItem(index, _getFormData());
                        _clearControllers();
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () {
                      provider.cancelEditing(index);
                      _clearControllers();
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    String key,
    String hint, {
    int flex = 1,
    bool isNumber = false,
    bool isDecimal = false,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: TextFormField(
          controller: _controllers[key],
          readOnly: readOnly,
          keyboardType: isNumber
              ? (isDecimal
                    ? TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number)
              : TextInputType.text,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 9, color: Color(0xFF60A5FA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Color(0xFF60A5FA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            filled: readOnly,
            fillColor: readOnly ? Color(0xFFF1F5F9) : null,
          ),
          validator: (value) {
            if (!readOnly && (value == null || value.isEmpty)) {
              return 'مطلوب';
            }
            if (isNumber && value != null && value.isNotEmpty) {
              if (isDecimal) {
                if (double.tryParse(value) == null) return 'رقم غير صحيح';
              } else {
                if (int.tryParse(value) == null) return 'رقم صحيح فقط';
              }
            }
            return null;
          },
          onChanged: (value) {
            if (key == 'qte' || key == 'puPieces') {
              _updateCalculatedFields();
            }
          },
        ),
      ),
    );
  }

  void _updateCalculatedFields() {
    final qte = int.tryParse(_controllers['qte']?.text ?? '0') ?? 0;
    final puPieces =
        double.tryParse(_controllers['puPieces']?.text ?? '0') ?? 0.0;
    final prixAchat =
        double.tryParse(_controllers['prixAchat']?.text ?? '0') ?? 0.0;
    final autresCharges =
        double.tryParse(_controllers['autresCharges']?.text ?? '0') ?? 0.0;

    // تحديث الحقول المحسوبة
    _controllers['poids']?.text = (qte * 13.0).toString();
    _controllers['mt']?.text = (qte * puPieces).toString();
    _controllers['cuHt']?.text = (prixAchat + autresCharges).toString();
  }

  Widget _buildSummaryFooter(
    DocumentProvider provider,
    Map<String, double> totals,
  ) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF60A5FA).withOpacity(0.10),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ملخص المصاريف
          Row(children: [Expanded(child: _buildSummaryGrid(provider.summary))]),

          SizedBox(height: 16),

          // صف جديد: إجمالي البضائع، الوزن الكلي، إجمالي الفاتورة
          Row(
            children: [
              Expanded(
                child: buildSummaryCard(
                  icon: Icons.inventory,
                  iconColor: Color(0xFF3B82F6),
                  label: 'إجمالي البضائع',
                  value: _calculationService.formatCurrency(
                    totals['totalMt'] ?? 0,
                  ),
                ),
              ),
              Expanded(
                child: buildSummaryCard(
                  icon: Icons.scale,
                  iconColor: Color(0xFF60A5FA),
                  label: 'الوزن الكلي',
                  value:
                      '${_calculationService.formatWeight(totals['poidsTotal'] ?? 0)} كغ',
                ),
              ),
              Expanded(
                child: buildSummaryCard(
                  icon: Icons.attach_money,
                  iconColor: Color(0xFF22C55E),
                  label: 'إجمالي الفاتورة',
                  value:
                      '${_calculationService.formatCurrency(totals['total'] ?? 0)} درهم',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(DocumentSummary summary) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        // متغير مركزي لتتبع أي حقل في وضع التحرير
        final editingField = ValueNotifier<String?>(null);
        return StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل المصاريف المرجو إدخال المبالغ بدون رسوم الضريبة على القيمة المضافة(',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: EditableSummaryItem(
                      label: 'النقل',
                      value: summary.transit,
                      icon: Icons.local_shipping,
                      calculationService: _calculationService,
                      isEditing: editingField.value == 'النقل',
                      onEdit: () {
                        setState(() => editingField.value = 'النقل');
                      },
                      onValueChanged: (v) {
                        provider.updateSummaryField('النقل', v);
                        setState(() => editingField.value = null);
                      },
                      onCancel: () => setState(() => editingField.value = null),
                    ),
                  ),
                  Expanded(
                    child: EditableSummaryItem(
                      label: 'حق الجمرك',
                      value: summary.droitDouane,
                      icon: Icons.account_balance,
                      calculationService: _calculationService,
                      isEditing: editingField.value == 'حق الجمرك',
                      onEdit: () {
                        setState(() => editingField.value = 'حق الجمرك');
                      },
                      onValueChanged: (v) {
                        provider.updateSummaryField('حق الجمرك', v);
                        setState(() => editingField.value = null);
                      },
                      onCancel: () => setState(() => editingField.value = null),
                    ),
                  ),
                  Expanded(
                    child: EditableSummaryItem(
                      label: 'شيك الصرف',
                      value: summary.chequeChange,
                      icon: Icons.money,
                      calculationService: _calculationService,
                      isEditing: editingField.value == 'شيك الصرف',
                      onEdit: () {
                        setState(() => editingField.value = 'شيك الصرف');
                      },
                      onValueChanged: (v) {
                        provider.updateSummaryField('شيك الصرف', v);
                        setState(() => editingField.value = null);
                      },
                      onCancel: () => setState(() => editingField.value = null),
                    ),
                  ),
                  Expanded(
                    child: EditableSummaryItem(
                      label: 'الشحن',
                      value: summary.freiht,
                      icon: Icons.flight_takeoff,
                      calculationService: _calculationService,
                      isEditing: editingField.value == 'الشحن',
                      onEdit: () {
                        setState(() => editingField.value = 'الشحن');
                      },
                      onValueChanged: (v) {
                        provider.updateSummaryField('الشحن', v);
                        setState(() => editingField.value = null);
                      },
                      onCancel: () => setState(() => editingField.value = null),
                    ),
                  ),
                  Expanded(
                    child: EditableSummaryItem(
                      label: 'أخرى',
                      value: summary.autres,
                      icon: Icons.more_horiz,
                      calculationService: _calculationService,
                      isEditing: editingField.value == 'أخرى',
                      onEdit: () {
                        setState(() => editingField.value = 'أخرى');
                      },
                      onValueChanged: (v) {
                        provider.updateSummaryField('أخرى', v);
                        setState(() => editingField.value = null);
                      },
                      onCancel: () => setState(() => editingField.value = null),
                    ),
                  ),
                  Expanded(
                    child: EditableSummaryItem(
                      label: 'سعر الصرف',
                      value: summary.txChange,
                      isCurrency: false,
                      icon: Icons.currency_exchange,
                      calculationService: _calculationService,
                      isEditing: editingField.value == 'سعر الصرف',
                      onEdit: () {
                        setState(() => editingField.value = 'سعر الصرف');
                      },
                      onValueChanged: (v) {
                        provider.updateSummaryField('سعر الصرف', v);
                        setState(() => editingField.value = null);
                      },
                      onCancel: () => setState(() => editingField.value = null),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalsGrid(Map<String, double> totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجماليات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSummaryItem('إجمالي البضائع', totals['totalMt'] ?? 0),
            _buildSummaryItem(
              'الوزن الكلي',
              totals['poidsTotal'] ?? 0,
              unit: 'كغ',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value, {
    bool isCurrency = true,
    String unit = '',
    IconData? icon,
  }) {
    return EditableSummaryItem(
      label: label,
      value: value,
      isCurrency: isCurrency,
      unit: unit,
      icon: icon,
      calculationService: _calculationService,
      onValueChanged: (newValue) {
        // يمكنك هنا تحديث القيمة في provider أو summary
      },
    );
  }

  Widget buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF60A5FA).withOpacity(0.10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: iconColor.withOpacity(0.13), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DocumentProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text(
            'هل تريد حذف العناصر المحددة (${provider.selectedIndices.length} عنصر)؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteSelected();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSingleConfirmation(
    BuildContext context,
    DocumentProvider provider,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text('هل تريد حذف هذا العنصر؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteItem(index);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// تمرير CalculationService للعنصر القابل للتعديل
class EditableSummaryItem extends StatefulWidget {
  final String label;
  final double value;
  final bool isCurrency;
  final String unit;
  final IconData? icon;
  final void Function(double newValue)? onValueChanged;
  final CalculationService calculationService;
  final bool isEditing;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const EditableSummaryItem({
    Key? key,
    required this.label,
    required this.value,
    required this.calculationService,
    this.isCurrency = true,
    this.unit = '',
    this.icon,
    this.onValueChanged,
    this.isEditing = false,
    this.onEdit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<EditableSummaryItem> createState() => _EditableSummaryItemState();
}

class _EditableSummaryItemState extends State<EditableSummaryItem> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onEdit != null) {
          widget.onEdit!();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(5),
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF60A5FA).withOpacity(0.10),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                ],
                // نص التسمية
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: widget.isEditing
                  ? Row(
                      key: ValueKey('edit'),
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E3A8A),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'أدخل القيمة',
                              hintStyle: TextStyle(color: Color(0xFF60A5FA)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onSubmitted: (val) {
                              double? newValue = double.tryParse(val);
                              if (newValue != null &&
                                  widget.onValueChanged != null) {
                                widget.onValueChanged!(newValue);
                              }
                              if (widget.onCancel != null) {
                                widget.onCancel!();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Color(0xFF22C55E)),
                          onPressed: () {
                            double? newValue = double.tryParse(controller.text);
                            if (newValue != null &&
                                widget.onValueChanged != null) {
                              widget.onValueChanged!(newValue);
                            }
                            if (widget.onCancel != null) {
                              widget.onCancel!();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () {
                            if (widget.onCancel != null) {
                              widget.onCancel!();
                            }
                          },
                        ),
                      ],
                    )
                  : Container(
                      key: ValueKey('value'),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.isCurrency
                            ? widget.calculationService.formatCurrency(
                                widget.value,
                              )
                            : widget.unit.isNotEmpty
                            ? widget.calculationService.formatWeight(
                                    widget.value,
                                  ) +
                                  ' ${widget.unit}'
                            : widget.value.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
