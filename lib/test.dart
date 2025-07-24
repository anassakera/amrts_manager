// test.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/document_model.dart';
import 'services/calculation_service.dart';
import 'provider/document_provider.dart';
import 'package:flutter/services.dart';

class SmartDocumentScreen extends StatefulWidget {
  const SmartDocumentScreen({super.key});

  @override
  SmartDocumentScreenState createState() => SmartDocumentScreenState();
}

class SmartDocumentScreenState extends State<SmartDocumentScreen> {
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
      'exchangeRate',
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
    _controllers['exchangeRate']?.text = item.exchangeRate.toString();
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
      'exchangeRate':
          double.tryParse(_controllers['exchangeRate']?.text ?? '1') ?? 1.0,
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

  // دالة لبناء زر أيقونة مربع مع Tooltip ودعم خاصية الإظهار/الإخفاء
  Widget _buildSquareAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    bool visible = true,
  }) {
    if (!visible) return SizedBox.shrink();

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 20,
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Icon(icon, key: ValueKey(icon), color: color, size: 24),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartHeader(
    DocumentProvider provider,
    Map<String, double> totals,
  ) {
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF60A5FA).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],

        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
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
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
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
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Facture N° : ${provider.summary.factureNumber}',
                      style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14),
                    ),
                  ],
                ),
              ),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  // تطبيق radius على 3 زوايا فقط (تاركين الزاوية اليمنى السفلى مربعة)
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4), // زاوية مربعة
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF60A5FA).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Color(0xFF60A5FA).withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(color: Color(0xFFF1F5F9), width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildSquareAction(
                        icon: Icons.checklist_rtl_rounded,
                        color: Color(0xFF8B5CF6),
                        onTap: () => provider.selectAll(),
                        tooltip: 'تحديد الكل',
                      ),
                      _buildSquareAction(
                        icon: Icons.add_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        onTap: () {
                          provider.addItem();
                          _clearControllers();
                        },
                        tooltip: 'إضافة جديد',
                      ),
                      _buildSquareAction(
                        icon: Icons.delete_sweep_rounded,
                        color: Color(0xFFEF4444),
                        onTap: () => _showDeleteConfirmation(context, provider),
                        tooltip: 'حذف المحدد',
                        visible: provider.hasSelection,
                      ),
                      _buildSquareAction(
                        icon: Icons.clear_all_rounded,
                        color: Color(0xFF6B7280),
                        onTap: () => provider.clearSelection(),
                        tooltip: 'إلغاء التحديد',
                        visible: provider.hasSelection,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // شريط الأدوات الذكي الجديد (أيقونة + نص داخل Container)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
                'مجموع المصاريف',
                '${totals['total']?.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
              SizedBox(width: 5),
              _buildQuickStat(
                'إجمالي البضائع',
                _calculationService.formatCurrency(totals['totalMt'] ?? 0),
                Icons.inventory,
              ),
              Spacer(),
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
            color: Color(0xFF60A5FA).withValues(alpha: 0.10),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الأيقونة في اليسار
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
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
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
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
                    color: Colors.black.withValues(alpha: 0.18),
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

  Widget _buildSmartTable(DocumentProvider provider) {
    final isAddingNew = provider.editingIndex == provider.items.length;
    final itemCount = provider.items.length + (isAddingNew ? 1 : 0);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // رأس الجدول
          _buildTableHeader(),

          // محتوى الجدول
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (isAddingNew) {
                  if (index == 0) {
                    // صف التحرير في الأعلى عند الإضافة
                    return _buildEditRow(provider, provider.items.length);
                  } else {
                    // بقية العناصر
                    return _buildTableRow(
                      provider,
                      provider.items[index - 1],
                      index - 1,
                    );
                  }
                } else {
                  if (index < provider.items.length) {
                    return _buildTableRow(
                      provider,
                      provider.items[index],
                      index,
                    );
                  } else {
                    // احتياطي، لا يجب أن يصل هنا
                    return SizedBox.shrink();
                  }
                }
              },
            ),
          ), // ← هنا الفاصلة المطلوبة
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
          // SizedBox(width: 16), // مساحة للأزرار
          // زر الإضافة في رأس الجدول
          InkWell(
            onTap: () {
              final provider = Provider.of<DocumentProvider>(
                context,
                listen: false,
              );
              provider.addItem();
              _clearControllers();
            },
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF3B82F6), width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF1E3A8A),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'إضافة',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            ? Color(0xFF60A5FA).withValues(alpha: 0.13)
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
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.bold,
        ), //anass
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEditRow(DocumentProvider provider, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF60A5FA).withValues(alpha: 0.10),
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
            _buildEditField(
              'qte',
              'الكمية',
              flex: 1,
              isNumber: true,
              isDecimal: false,
            ),
            _buildEditField(
              'poids',
              'الوزن',
              flex: 2,
              isNumber: true,
              isDecimal: true,
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
              readOnly: true,
            ),
            _buildEditField(
              'autresCharges',
              'مصاريف أخرى',
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            _buildEditField(
              'cuHt',
              'تكلفة القطعة',
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            _buildEditField(
              'exchangeRate',
              'سعر الصرف',
              flex: 2,
              isNumber: true,
              isDecimal: true,
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
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: _controllers[key],
            readOnly: readOnly,
            keyboardType: isNumber
                ? (isDecimal
                      ? TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number)
                : TextInputType.text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: isNumber
                ? [
                    isDecimal
                        ? FilteringTextInputFormatter.allow(
                            RegExp(r'^[0-9]*\.?[0-9]*'),
                          )
                        : FilteringTextInputFormatter.digitsOnly,
                  ]
                : [],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              filled: true,
              fillColor: Colors.white,
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
              if (key == 'qte' ||
                  key == 'puPieces' ||
                  key == 'autresCharges' ||
                  key == 'exchangeRate') {
                _updateCalculatedFieldsWithService();
              }
            },
          ),
        ),
      ),
    );
  }

  // أضف دالة جديدة تستخدم CalculationService
  void _updateCalculatedFieldsWithService() {
    final data = _getFormData();
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final totals = _calculationService.calculateTotals(
      provider.items,
      provider.summary,
    );
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final calculated = _calculationService.calculateItemValues(
      data,
      totalMt: totalMt,
      poidsTotal: poidsTotal,
    );
    _controllers['mt']?.text = calculated['mt'].toString();
    _controllers['prixAchat']?.text = calculated['prixAchat'].toString();
    _controllers['autresCharges']?.text = calculated['autresCharges']
        .toString();
    _controllers['cuHt']?.text = calculated['cuHt'].toString();
  }

  Widget _buildSummaryFooter(
    DocumentProvider provider,
    Map<String, double> totals,
  ) {
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF60A5FA).withValues(alpha: 0.10),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [Expanded(child: _buildSummaryGrid(provider.summary))],
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
            color: Color(0xFF60A5FA).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: iconColor.withValues(alpha: 0.13), width: 1),
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
    super.key,
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
  });

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
              color: Color(0xFF60A5FA).withValues(alpha: 0.10),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.9),
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.isCurrency
                            ? widget.calculationService.formatCurrency(
                                widget.value,
                              )
                            : widget.unit.isNotEmpty
                            ? '${widget.calculationService.formatWeight(widget.value)} ${widget.unit}'
                            : widget.value.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
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
