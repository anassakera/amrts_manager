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
    transit: 2740.00,
    droitDouane: 135350.00,
    chequeChange: 6553.92,
    freiht: 48279.84,
    autres: 10000.00,
    total: 202923.76,
    txChange: 10.0583,
    poidsTotal: 52000.00,
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
    _items = [
      DocumentItem(
        refFournisseur: '9901G',
        articles: 'TOLA BLANC',
        qte: 2001,
        poids: 26013.00,
        puPieces: 13.30,
        mt: 26613.30,
        prixAchat: 133.78,
        autresCharges: 50.73,
        cuHt: 184.51,
      ),
      DocumentItem(
        refFournisseur: '88003V',
        articles: 'TOLA BEIGE',
        qte: 498,
        poids: 6474.00,
        puPieces: 13.30,
        mt: 6623.40,
        prixAchat: 133.78,
        autresCharges: 50.73,
        cuHt: 184.51,
      ),
      DocumentItem(
        refFournisseur: '9906',
        articles: 'TOLA GRIS',
        qte: 500,
        poids: 6500.00,
        puPieces: 13.30,
        mt: 6650.00,
        prixAchat: 133.78,
        autresCharges: 50.73,
        cuHt: 184.51,
      ),
    ];

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
    if (index == _items.length) {
      // إضافة عنصر جديد
      final calculatedData = _calculationService.calculateItemValues(data);
      _items.add(
        DocumentItem.fromJson(calculatedData).copyWith(isEditing: false),
      );
      _editingIndex = null;
      _recalculateSummary();
      notifyListeners();
    } else if (index < _items.length) {
      final calculatedData = _calculationService.calculateItemValues(data);
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
        break;
      // أضف المزيد إذا لزم الأمر
    }
    _recalculateSummary();
    notifyListeners();
  }

  // إيقاف جميع عمليات التحرير
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
