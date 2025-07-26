// test.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_manage_model.dart';
import '../services/calculation_service.dart';
import '../provider/document_provider.dart';
import '../provider/invoice_provider.dart';
import 'package:flutter/services.dart';
import '../core/language.dart';
import '../provider/language_provider.dart';

class SmartDocumentScreen extends StatefulWidget {
  final InvoiceModel? invoice;
   final bool isLocal; 
  const SmartDocumentScreen({super.key, this.invoice,
  
   this.isLocal = true,
   
   });

  @override
  SmartDocumentScreenState createState() => SmartDocumentScreenState();
}

class SmartDocumentScreenState extends State<SmartDocumentScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CalculationService _calculationService = CalculationService();
    // إضافة متغير للتحقق من حالة الصفحة
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.invoice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<DocumentProvider>(context, listen: false);
        provider.setFromInvoiceModel(widget.invoice!);
        if (widget.invoice!.items.isNotEmpty) {
          _populateControllers(widget.invoice!.items.first);
        }
      });
    }
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

  void _populateControllers(InvoiceItem item, {double? defaultExchangeRate}) {
    _controllers['refFournisseur']?.text = item.refFournisseur;
    _controllers['articles']?.text = item.articles;
    _controllers['qte']?.text = item.qte.toString();
    _controllers['poids']?.text = item.poids.toString();
    _controllers['puPieces']?.text = item.puPieces.toString();
    _controllers['mt']?.text = item.mt.toString();
    _controllers['prixAchat']?.text = item.prixAchat.toString();
    _controllers['autresCharges']?.text = item.autresCharges.toString();
    _controllers['cuHt']?.text = item.cuHt.toString();
    // إذا كان exchangeRate فارغاً أو 1، استخدم القيمة الافتراضية من ملخص الفاتورة
    if ((item.exchangeRate == 1.0 || item.exchangeRate == 0.0) &&
        defaultExchangeRate != null) {
      _controllers['exchangeRate']?.text = defaultExchangeRate.toString();
    } else {
      _controllers['exchangeRate']?.text = item.exchangeRate.toString();
    }
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
          double.tryParse(_controllers['exchangeRate']?.text.trim() ?? '') ??
          1.0,
    };
  }
// استبدل دالة _saveInvoice بالكامل بهذه النسخة المحسنة
void _saveInvoice() {
  print('🚀 بدء عملية الحفظ...');
  
  // التحقق من صحة النموذج
  if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
    print('❌ فشل التحقق من صحة النموذج');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى تصحيح الأخطاء في النموذج'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
  final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
  
  print('📋 بيانات DocumentProvider:');
  print('   - عدد العناصر: ${documentProvider.items.length}');
  print('   - رقم الفاتورة: ${documentProvider.summary.factureNumber}');
  
  // التحقق من وجود عناصر في الفاتورة
  if (documentProvider.items.isEmpty) {
    print('⚠️ لا توجد عناصر في الفاتورة');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('لا يمكن حفظ فاتورة فارغة. يرجى إضافة عناصر أولاً'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  try {
    // حساب المبلغ الإجمالي
    double totalAmount = _calculateTotalAmount(documentProvider.items, documentProvider.summary);
    print('💰 المبلغ الإجمالي المحسوب: $totalAmount');
    
    // تحديد اسم العميل
    String clientName = _getClientName(documentProvider.items, 
        widget.invoice?.clientName ?? 'عميل غير محدد');
    print('👤 اسم العميل: $clientName');

    if (widget.invoice != null) {
      print('📝 تحديث فاتورة موجودة: ${widget.invoice!.id}');
      // تحديث فاتورة موجودة
      final updatedInvoice = widget.invoice!.copyWith(
        items: List<InvoiceItem>.from(documentProvider.items),
        summary: documentProvider.summary,
        totalAmount: totalAmount,
        status: 'محدثة',
        clientName: clientName,
      );
      
      print('   - عدد العناصر في الفاتورة المحدثة: ${updatedInvoice.items.length}');
      invoiceProvider.updateInvoice(updatedInvoice);
      _showSuccessMessage('تم تحديث الفاتورة بنجاح', Icons.check_circle);
    } else {
      print('🆕 إنشاء فاتورة جديدة');
      // إنشاء فاتورة جديدة
      final newInvoice = InvoiceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientName: clientName,
        invoiceNumber: documentProvider.summary.factureNumber,
        date: DateTime.now(),
        isLocal: widget.isLocal,
        totalAmount: totalAmount,
        status: 'مسودة',
        items: List<InvoiceItem>.from(documentProvider.items),
        summary: documentProvider.summary,
      );

      print('   - رقم الفاتورة الجديدة: ${newInvoice.invoiceNumber}');
      print('   - عدد العناصر: ${newInvoice.items.length}');
      print('   - نوع الفاتورة: ${newInvoice.isLocal ? "محلي" : "خارجي"}');
      
      // طباعة تفاصيل العناصر
      for (int i = 0; i < newInvoice.items.length; i++) {
        final item = newInvoice.items[i];
        print('   - العنصر $i: ${item.articles} - الكمية: ${item.qte}');
      }

      invoiceProvider.addInvoice(newInvoice);
      _showSuccessMessage('تم إنشاء الفاتورة بنجاح', Icons.add_circle);
    }
    
    print('🧹 تنظيف البيانات والعودة...');
    // مسح النموذج والعودة
    _clearControllers();
    documentProvider.reset();
    
    // التأكد من أن Navigator متاح
    if (mounted) {
      Navigator.of(context).pop(true);
      print('✅ تم الانتهاء من عملية الحفظ بنجاح');
    }
    
  } catch (e, stackTrace) {
    print('💥 خطأ أثناء الحفظ: $e');
    print('📍 Stack Trace: $stackTrace');
    _showErrorMessage('حدث خطأ أثناء حفظ الفاتورة: ${e.toString()}');
  }
}

// دوال مساعدة
String _getClientName(List<InvoiceItem> items, String defaultName) {
  if (items.isNotEmpty && items.first.refFournisseur.isNotEmpty) {
    return items.first.refFournisseur;
  }
  return defaultName;
}

double _calculateTotalAmount(List<InvoiceItem> items, InvoiceSummary summary) {
  // حساب مجموع قيم العناصر بالعملة المحلية
  double itemsTotal = items.fold(0.0, (sum, item) => sum + (item.mt * item.exchangeRate));
  
  // إضافة المصروفات الأخرى
  double expensesTotal = summary.transit + 
                        summary.droitDouane + 
                        summary.chequeChange + 
                        summary.freiht + 
                        summary.autres;
  
  return itemsTotal + expensesTotal;
}

void _showSuccessMessage(String message, IconData icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Text(message),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

void _showErrorMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: Duration(seconds: 5),
    ),
  );
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
      // تم نقل أزرار الحفظ والإلغاء إلى _buildSmartHeader
    );
  }

  // دالة لبناء زر أيقونة مربع مع Tooltip ودعم خاصية الإظهار/الإخفاء

  Widget _buildSmartHeader(
    DocumentProvider provider,
    Map<String, double> totals,
  ) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                // Header Row (Icon + Title + Actions)
                Row(
                  children: [
                    // Title Section
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF1F5F9), Color(0xFFE0E7EF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.10),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  // فاتورة إلكترونية
                                  AppTranslations.get(
                                    'smart_invoice',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E3A8A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  // رقم: ...
                                  '${AppTranslations.get(
                                        'number',
                                        Provider.of<LanguageProvider>(
                                          context,
                                          listen: true,
                                        ).currentLanguage,
                                      )}: ${provider.summary.factureNumber}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.items.isNotEmpty
                                      ? provider.items.first.refFournisseur
                                      : AppTranslations.get(
                                          'not_specified',
                                          Provider.of<LanguageProvider>(
                                            context,
                                            listen: true,
                                          ).currentLanguage,
                                        ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getFormattedDate(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    
                    Container(
                      height: MediaQuery.of(context).size.height * 0.085,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE57373).withValues(alpha:0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel_rounded, size: 20),
                        label: Text(
                          AppTranslations.get(
                            'cancel',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: false,
                            ).currentLanguage,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          animationDuration: const Duration(milliseconds: 200),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color(0xFFEF9A9A);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return const Color(0xFFEF5350);
                              }
                              return const Color(0xFFE57373);
                            },
                          ),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white.withValues(alpha:0.1);
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Save Button
                    Container(
                      height: MediaQuery.of(context).size.height * 0.085,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF66BB6A).withValues(alpha:0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _saveInvoice,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          AppTranslations.get(
                            'save',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: false,
                            ).currentLanguage,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          animationDuration: const Duration(milliseconds: 200),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color(0xFF81C784);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return const Color(0xFF4CAF50);
                              }
                              return const Color(0xFF66BB6A);
                            },
                          ),
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white.withValues(alpha:0.1);
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
// أضف هذا الزر مؤقتاً بجانب زر الحفظ للاختبار
Container(
  height: MediaQuery.of(context).size.height * 0.085,
  child: ElevatedButton.icon(
    onPressed: () {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
      
      print('🔍 تشخيص البيانات:');
      print('DocumentProvider:');
      print('  - عدد العناصر: ${documentProvider.items.length}');
      print('  - رقم الفاتورة: ${documentProvider.summary.factureNumber}');
      
      print('InvoiceProvider:');
      print('  - عدد الفواتير الحالي: ${invoiceProvider.allInvoices.length}');
      print('  - الفواتير المحلية: ${invoiceProvider.localInvoices.length}');
      print('  - الفواتير الخارجية: ${invoiceProvider.foreignInvoices.length}');
      
      // اختبار إضافة فاتورة تجريبية
      try {
        final testInvoice = InvoiceModel(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          clientName: 'عميل تجريبي',
          invoiceNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          isLocal: true,
          totalAmount: 1000.0,
          status: 'اختبار',
          items: [],
          summary: documentProvider.summary,
        );
        
        invoiceProvider.addInvoice(testInvoice);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة فاتورة تجريبية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ خطأ في الاختبار: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    icon: Icon(Icons.bug_report, size: 20),
    label: Text('اختبار'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
    ),
  ),
),
                   
                 
                  ],
                ),

                const SizedBox(height: 5),
                // معلومات الفاتورة (شبكة)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.inventory,
                          label: AppTranslations.get(
                            'items_count',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value: provider.items.length.toString(),
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.scale,
                          label: AppTranslations.get(
                            'total_weight',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value:
                              '${totals['poidsTotal']?.toStringAsFixed(0) ?? '0'} كغ',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          label: AppTranslations.get(
                            'total_expenses',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value: totals['total']?.toStringAsFixed(2) ?? '0.00',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.inventory,
                          label: AppTranslations.get(
                            'goods_total',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value: _calculationService.formatCurrency(
                            totals['totalMt'] ?? 0,
                          ),
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Action Panel بحجم ثابت في نهاية الصف
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF64748B,
                                ).withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                // تحديد الكل
                                Tooltip(
                                  message: AppTranslations.get(
                                    'select_all',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => provider.selectAll(),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF8B5CF6,
                                            ).withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.select_all_rounded,
                                          color: Color(0xFF8B5CF6),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // إضافة جديد
                                Tooltip(
                                  message: AppTranslations.get(
                                    'add_new',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        provider.addItem();
                                        _clearControllers();
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: Color(0xFF10B981),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // حذف المحدد
                                if (provider.hasSelection)
                                  Tooltip(
                                    message: AppTranslations.get(
                                      'delete_selected',
                                      Provider.of<LanguageProvider>(
                                        context,
                                        listen: true,
                                      ).currentLanguage,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showDeleteConfirmation(
                                          context,
                                          provider,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_sweep_rounded,
                                            color: Color(0xFFEF4444),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // إلغاء التحديد
                                if (provider.hasSelection)
                                  Tooltip(
                                    message: AppTranslations.get(
                                      'clear_selection',
                                      Provider.of<LanguageProvider>(
                                        context,
                                        listen: true,
                                      ).currentLanguage,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => provider.clearSelection(),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6B7280,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF6B7280,
                                              ).withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.clear_all_rounded,
                                            color: Color(0xFF6B7280),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بطاقة معلومات مفردة
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
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
          SizedBox(width: 30), // مساحة للتحديد

          _buildHeaderCell(
            AppTranslations.get(
              'supplier_ref',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
            showDivider: true,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'article',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'quantity',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 1,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'weight',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'unit_price',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'total_amount',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'purchase_price',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'other_expenses',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'item_cost',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'actions',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 1,
          ),
          // SizedBox(width: 16), // مساحة للأزرار
          // زر الإضافة في رأس الجدول
          // InkWell(
          //   onTap: () {
          //     final provider = Provider.of<DocumentProvider>(
          //       context,
          //       listen: false,
          //     );
          //     provider.addItem();
          //     _clearControllers();
          //   },
          //   child: Container(
          //     padding: EdgeInsets.all(5),
          //     decoration: BoxDecoration(
          //       color: Color(0xFFF1F5F9),
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: Color(0xFF3B82F6), width: 1.2),
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(
          //           Icons.add_circle_outline_rounded,
          //           color: Color(0xFF1E3A8A),
          //         ),
          //         SizedBox(width: 4),
          //         Text(
          //           'إضافة',
          //           style: TextStyle(
          //             color: Color(0xFF1E3A8A),
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String title, {
    int flex = 1,
    bool showDivider = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableRow(
    DocumentProvider provider,
    InvoiceItem item,
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
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              SizedBox(width: 5),

              // بيانات الصف
              _buildDataCell(item.refFournisseur, flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(item.articles, flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(item.qte.toString(), flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatWeight(item.poids),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(item.puPieces),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(item.mt),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(item.prixAchat),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(item.autresCharges),
                flex: 2,
              ),
              _verticalDivider(height: 28),
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
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEditRow(DocumentProvider provider, int index) {
    final exchangeRateFromSummary = provider.summary.txChange;
    final isNew = index == provider.items.length;
    // عند بناء صف التحرير، إذا كان عنصر جديد أو exchangeRate فارغ، عبئ exchangeRate من ملخص الفاتورة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isNew || (_controllers['exchangeRate']?.text.isEmpty ?? true)) {
        _controllers['exchangeRate']?.text = exchangeRateFromSummary.toString();
      }
    });
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF60A5FA).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3B82F6), width: 2),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            SizedBox(width: 20),
            _buildEditField(
              'refFournisseur',
              AppTranslations.get(
                'supplier_ref',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'articles',
              AppTranslations.get(
                'article',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'qte',
              AppTranslations.get(
                'quantity',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 1,
              isNumber: true,
              isDecimal: false,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'poids',
              AppTranslations.get(
                'weight',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'puPieces',
              AppTranslations.get(
                'unit_price',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'mt',
              AppTranslations.get(
                'total_amount',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'prixAchat',
              AppTranslations.get(
                'purchase_price',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'autresCharges',
              AppTranslations.get(
                'other_expenses',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'cuHt',
              AppTranslations.get(
                'item_cost',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
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
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.2),
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
                return AppTranslations.get(
                  'required',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: false,
                  ).currentLanguage,
                );
              }
              if (isNumber && value != null && value.isNotEmpty) {
                if (isDecimal) {
                  if (double.tryParse(value) == null) {
                    return AppTranslations.get(
                      'invalid_number',
                      Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).currentLanguage,
                    );
                  }
                } else {
                  if (int.tryParse(value) == null) {
                    return AppTranslations.get(
                      'integer_only',
                      Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).currentLanguage,
                    );
                  }
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
    List<InvoiceItem> tempItems = List.from(provider.items);
    // إذا كنا في وضع إضافة عنصر جديد، أضف العنصر الجاري تحريره مؤقتًا
    if (provider.editingIndex == provider.items.length) {
      final tempCalculated = _calculationService.calculateItemValues(
        data,
        totalMt: 0.0, // سيتم تحديثها بعد حساب المجاميع
        poidsTotal: 0.0,
        grandTotal: 0.0,
      );
      tempItems.add(InvoiceItem.fromJson(tempCalculated));
    }
    final totals = _calculationService.calculateTotals(
      tempItems,
      provider.summary,
    );
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final grandTotal = totals['total'] ?? 0.0;
    final calculated = _calculationService.calculateItemValues(
      data,
      totalMt: totalMt,
      poidsTotal: poidsTotal,
      grandTotal: grandTotal,
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

  Widget _buildSummaryGrid(InvoiceSummary summary) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        // متغير مركزي لتتبع أي حقل في وضع التحرير
        final editingField = ValueNotifier<String?>(null);
        return StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.get(
                  'expense_details',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
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
                      label: AppTranslations.get(
                        'transit',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).currentLanguage,
                      ),
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
                      label: AppTranslations.get(
                        'customs',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).currentLanguage,
                      ),
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
                      label: AppTranslations.get(
                        'exchange_cheque',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).currentLanguage,
                      ),
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
                      label: AppTranslations.get(
                        'freight',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).currentLanguage,
                      ),
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
                      label: AppTranslations.get(
                        'other',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).currentLanguage,
                      ),
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
                      label: AppTranslations.get(
                        'exchange_rate',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).currentLanguage,
                      ),
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
                        // تحديث exchangeRate في الحقول المفتوحة للتحرير
                        if (_controllers['exchangeRate'] != null) {
                          _controllers['exchangeRate']?.text = v.toString();
                        }
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
          title: Text(
            AppTranslations.get(
              'confirm_delete',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          content: Text(
            '${AppTranslations.get(
                  'delete_selected_items',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                )} (${provider.selectedIndices.length})؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppTranslations.get(
                  'cancel',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteSelected();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                AppTranslations.get(
                  'delete',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
                style: TextStyle(color: Colors.white),
              ),
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
          title: Text(
            AppTranslations.get(
              'confirm_delete',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          content: Text(
            AppTranslations.get(
              'delete_this_item',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppTranslations.get(
                  'cancel',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteItem(index);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                AppTranslations.get(
                  'delete',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // أضف دالة مساعدة لتنسيق التاريخ في SmartDocumentScreenState
  String _getFormattedDate() {
    final now = DateTime.now();
    return "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
  }

  Widget _verticalDivider({double? height}) {
    return Container(
      width: 1,
      height: height ?? double.infinity,
      color: const Color(0xFFE5E7EB),
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
                    padding: EdgeInsets.all(5),
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
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
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
                                  hintText: AppTranslations.get(
                                    'enter_value',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Color(0xFF60A5FA),
                                  ),
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
                                  // إضافة أيقونة الحذف داخل الحقل
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    onPressed: () {
                                      controller.clear();
                                      setState(
                                        () {},
                                      ); // لتحديث الحقل إذا لزم الأمر
                                    },
                                    tooltip: AppTranslations.get(
                                      'clear_value',
                                      Provider.of<LanguageProvider>(
                                        context,
                                        listen: true,
                                      ).currentLanguage,
                                    ),
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
                            ],
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
