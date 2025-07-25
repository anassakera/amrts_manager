// providers/document_provider.dart
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../services/calculation_service.dart';

class DocumentProvider with ChangeNotifier {
  final CalculationService _calculationService = CalculationService();

  // البيانات الأساسية
  List<DocumentItem> _items = [];
  DocumentSummary _summary = DocumentSummary(
    factureNumber: 'CI-SSA240103002,1',
    transit: 0,
    droitDouane: 0,
    chequeChange: 0,
    freiht: 0,
    autres: 0,
    total: 0,
    txChange: 0,
    poidsTotal: 0.0,
  );

  // حالة التحكم
  int? _editingIndex;
  List<int> _selectedIndices = [];
  bool _isMultiSelectMode = false;

  // Getters
  List<DocumentItem> get items => _items;
  DocumentSummary get summary => _summary;
  int? get editingIndex => _editingIndex;
  List<int> get selectedIndices => _selectedIndices;
  bool get isMultiSelectMode => _isMultiSelectMode;
  bool get hasSelection => _selectedIndices.isNotEmpty;

  // تحميل البيانات التجريبية
  void loadSampleData() {
    _items = [];

    // تحديث الملخص بناء على البيانات الجديدة
    _recalculateSummary();
    notifyListeners();
  }

  // إضافة عنصر جديد
  void addItem() {
    _editingIndex = _items.length;
    notifyListeners();
  }

  // بدء التحرير
  void startEditing(int index) {
    _stopAllEditing();
    _editingIndex = index;
    _items[index] = _items[index].copyWith(isEditing: true);
    notifyListeners();
  }

  // حفظ التحرير
  void saveItem(int index, Map<String, dynamic> data) {
    // تأكد أن data لا تحتوي إلا على الحقول المدخلة يدوياً
    final filteredData = {
      'refFournisseur': data['refFournisseur'],
      'articles': data['articles'],
      'qte': data['qte'],
      'poids': data['poids'],
      'puPieces': data['puPieces'],
      'exchangeRate': data['exchangeRate'],
      // لا تمرر autresCharges أبداً
    };
    final totals = _calculationService.calculateTotals(_items, _summary);
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final grandTotal = totals['total'] ?? 0.0;
    if (index == _items.length) {
      // إضافة عنصر جديد
      final calculatedData = _calculationService.calculateItemValues(
        filteredData,
        totalMt: totalMt,
        poidsTotal: poidsTotal,
        grandTotal: grandTotal,
      );
      _items.add(
        DocumentItem.fromJson(calculatedData).copyWith(isEditing: false),
      );
      _editingIndex = null;
      _recalculateSummary();
      notifyListeners();
    } else if (index < _items.length) {
      final calculatedData = _calculationService.calculateItemValues(
        filteredData,
        totalMt: totalMt,
        poidsTotal: poidsTotal,
        grandTotal: grandTotal,
      );
      _items[index] = DocumentItem.fromJson(
        calculatedData,
      ).copyWith(isEditing: false);
      _editingIndex = null;
      _recalculateSummary();
      notifyListeners();
    }
  }

  // إلغاء التحرير
  void cancelEditing(int index) {
    if (index == _items.length) {
      // إلغاء إضافة جديد فقط
      _editingIndex = null;
      notifyListeners();
    } else if (index < _items.length) {
      if (_items[index].refFournisseur.isEmpty) {
        // إذا كان عنصر جديد، احذفه
        _items.removeAt(index);
      } else {
        // إعادة إلى الحالة الأصلية
        _items[index] = _items[index].copyWith(isEditing: false);
      }
      _editingIndex = null;
      notifyListeners();
    }
  }

  // حذف عنصر واحد
  void deleteItem(int index) {
    if (index < _items.length) {
      _items.removeAt(index);
      _recalculateSummary();
      notifyListeners();
    }
  }

  // تحديد/إلغاء تحديد عنصر
  void toggleSelection(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }

    _isMultiSelectMode = _selectedIndices.isNotEmpty;
    notifyListeners();
  }

  // تحديد الكل
  void selectAll() {
    _selectedIndices = List.generate(_items.length, (index) => index);
    _isMultiSelectMode = true;
    notifyListeners();
  }

  // إلغاء تحديد الكل
  void clearSelection() {
    _selectedIndices.clear();
    _isMultiSelectMode = false;
    notifyListeners();
  }

  // حذف المحدد
  void deleteSelected() {
    _selectedIndices.sort((a, b) => b.compareTo(a)); // ترتيب عكسي للحذف الآمن
    for (int index in _selectedIndices) {
      if (index < _items.length) {
        _items.removeAt(index);
      }
    }
    _selectedIndices.clear();
    _isMultiSelectMode = false;
    _recalculateSummary();
    notifyListeners();
  }

  // تحديث الملخص
  void updateSummary(DocumentSummary newSummary) {
    _summary = newSummary;
    _recalculateSummary();
    notifyListeners();
  }

  // تحديث حقل فردي في الملخص بناءً على الاسم العربي
  void updateSummaryField(String field, double value) {
    switch (field) {
      case 'النقل':
        _summary = _summary.copyWith(transit: value);
        break;
      case 'حق الجمرك':
        _summary = _summary.copyWith(droitDouane: value);
        break;
      case 'شيك الصرف':
        _summary = _summary.copyWith(chequeChange: value);
        break;
      case 'الشحن':
        _summary = _summary.copyWith(freiht: value);
        break;
      case 'أخرى':
        _summary = _summary.copyWith(autres: value);
        break;
      case 'سعر الصرف':
        _summary = _summary.copyWith(txChange: value);
        // إعادة حساب جميع العناصر بقيمة exchangeRate الجديدة
        _recalculateAllItemsWithExchangeRate(value);
        break;
      // أضف المزيد إذا لزم الأمر
    }
    _recalculateSummary();
    notifyListeners();
  }

  // دالة لإعادة حساب جميع العناصر عند تغيير سعر الصرف الرئيسي
  void _recalculateAllItemsWithExchangeRate(double newExchangeRate) {
    final totals = _calculationService.calculateTotals(_items, _summary);
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final grandTotal = totals['total'] ?? 0.0;
    _items = _items.map((item) {
      final recalculated = _calculationService.calculateItemValues(
        {
          'refFournisseur': item.refFournisseur,
          'articles': item.articles,
          'qte': item.qte,
          'poids': item.poids,
          'puPieces': item.puPieces,
          'exchangeRate': newExchangeRate,
        },
        totalMt: totalMt,
        poidsTotal: poidsTotal,
        grandTotal: grandTotal,
      );
      return DocumentItem.fromJson(recalculated);
    }).toList();
  }

  // إعادة جميع عمليات التحرير
  void _stopAllEditing() {
    _editingIndex = null;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isEditing) {
        _items[i] = _items[i].copyWith(isEditing: false);
      }
    }
  }

  // إعادة حساب الملخص
  void _recalculateSummary() {
    final totals = _calculationService.calculateTotals(_items, _summary);
    _summary = _summary.copyWith(
      total: totals['total'],
      poidsTotal: totals['poidsTotal'],
    );
  }

  // إعادة تعيين البيانات
  void reset() {
    _items.clear();
    _selectedIndices.clear();
    _editingIndex = null;
    _isMultiSelectMode = false;
    loadSampleData();
  }
}
