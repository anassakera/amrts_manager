import 'number_formatting_service.dart';

class CalculationService {
  // حساب قيم العنصر الواحد
  Map<String, dynamic> calculateItemValues(
    Map<String, dynamic> data, {
    required double totalMt,
    required double poidsTotal,
    required double grandTotal,
  }) {
    // البيانات المدخلة يدوياً من المستخدم
    final refFournisseur = data['refFournisseur'] ?? '';
    final articles = data['articles'] ?? '';
    final qte = _safeParseInt(data['qte']);
    final poids = double.parse(
      (_safeParseDouble(data['poids'])).toStringAsFixed(2),
    );
    final puPieces = double.parse(
      (_safeParseDouble(data['puPieces'])).toStringAsFixed(2),
    );
    final exchangeRate = double.parse(
      (_safeParseDouble(data['exchangeRate'])).toStringAsFixed(2),
    );

    // الحسابات التلقائية

    // 1. المبلغ الإجمالي = الكمية × سعر القطعة
    final mt = double.parse((qte * puPieces).toStringAsFixed(2));

    // 2. سعر الشراء = سعر القطعة × معدل الصرف
    final prixAchat = double.parse(
      (puPieces * exchangeRate).toStringAsFixed(2),
    );

    // 3. الرسوم الأخرى = (الوزن ÷ الكمية) × (المجموع الكلي ÷ الوزن الكلي)
    double autresCharges = 0.0;
    if (poids > 0 && qte > 0 && grandTotal > 0 && poidsTotal > 0) {
      autresCharges = double.parse(
        ((poids / qte) * (grandTotal / poidsTotal)).toStringAsFixed(2),
      );
    }

    // 4. التكلفة الإجمالية = سعر الشراء + الرسوم الأخرى
    final cuHt = double.parse((prixAchat + autresCharges).toStringAsFixed(2));

    return {
      // البيانات المدخلة يدوياً
      'refFournisseur': refFournisseur,
      'articles': articles,
      'qte': qte,
      'poids': poids,
      'puPieces': puPieces,
      'exchangeRate': exchangeRate,

      // البيانات المحسوبة تلقائياً
      'mt': mt, // المبلغ الإجمالي
      'prixAchat': prixAchat, // سعر الشراء
      'autresCharges': autresCharges, // الرسوم الأخرى
      'cuHt': cuHt, // التكلفة الإجمالية
    };
  }

  // حساب المجاميع الكلية
  Map<String, double> calculateTotals(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> summary,
  ) {
    double totalMt = 0.0;
    double totalPoids = 0.0;

    // جمع المبالغ الإجمالية والأوزان من جميع العناصر
    for (var item in items) {
      // تحويل البيانات من String إلى double بشكل آمن
      final mtValue = _safeParseDouble(item['mt']);
      final poidsValue = _safeParseDouble(item['qte']);

      totalMt += mtValue;
      totalPoids += poidsValue;
    }

    // حساب المجموع الكلي للمصاريف الإضافية
    final grandTotal =
        _safeParseDouble(summary['transit']) +
        _safeParseDouble(summary['droitDouane']) +
        _safeParseDouble(summary['chequeChange']) +
        _safeParseDouble(summary['freiht']) +
        _safeParseDouble(summary['autres']);

    return {
      'totalMt': double.parse(totalMt.toStringAsFixed(2)),
      'poidsTotal': double.parse(totalPoids.toStringAsFixed(2)),
      'total': double.parse(grandTotal.toStringAsFixed(2)),
    };
  }

  // حساب النسب المئوية للتوزيع
  Map<String, double> calculateDistributionRatios(
    Map<String, dynamic> item,
    double totalMt,
  ) {
    if (totalMt == 0) return {'ratio': 0.0};

    final ratio = double.parse(
      (_safeParseDouble(item['mt']) / totalMt).toStringAsFixed(2),
    );
    return {'ratio': ratio};
  }

  // حساب المصاريف الموزعة على كل عنصر
  Map<String, double> calculateDistributedCosts(
    Map<String, dynamic> item,
    Map<String, dynamic> summary,
    double totalMt,
  ) {
    final ratio = calculateDistributionRatios(item, totalMt)['ratio'] ?? 0.0;

    final distributedTransit = double.parse(
      (_safeParseDouble(summary['transit']) * ratio).toStringAsFixed(2),
    );
    final distributedDroitDouane = double.parse(
      (_safeParseDouble(summary['droitDouane']) * ratio).toStringAsFixed(2),
    );
    final distributedChequeChange = double.parse(
      (_safeParseDouble(summary['chequeChange']) * ratio).toStringAsFixed(2),
    );
    final distributedFreiht = double.parse(
      (_safeParseDouble(summary['freiht']) * ratio).toStringAsFixed(2),
    );
    final distributedAutres = double.parse(
      (_safeParseDouble(summary['autres']) * ratio).toStringAsFixed(2),
    );

    final totalDistributedCost = double.parse(
      (distributedTransit +
              distributedDroitDouane +
              distributedChequeChange +
              distributedFreiht +
              distributedAutres)
          .toStringAsFixed(2),
    );
    final qte = _safeParseInt(item['qte']);
    final mt = _safeParseDouble(item['mt']);
    final finalCostPerUnit = qte > 0
        ? double.parse(((mt + totalDistributedCost) / qte).toStringAsFixed(2))
        : 0.0;

    return {
      'distributedTransit': distributedTransit,
      'distributedDroitDouane': distributedDroitDouane,
      'distributedChequeChange': distributedChequeChange,
      'distributedFreiht': distributedFreiht,
      'distributedAutres': distributedAutres,
      'totalDistributedCost': totalDistributedCost,
      'finalCostPerUnit': finalCostPerUnit,
    };
  }

  // التحقق من صحة البيانات المدخلة يدوياً
  Map<String, String> validateItemData(Map<String, dynamic> data) {
    Map<String, String> errors = {};

    // التحقق من مرجع المورد
    if (data['refFournisseur'] == null ||
        data['refFournisseur'].toString().trim().isEmpty) {
      errors['refFournisseur'] = 'مرجع المورد مطلوب';
    }

    // التحقق من اسم المادة
    if (data['articles'] == null ||
        data['articles'].toString().trim().isEmpty) {
      errors['articles'] = 'اسم المادة مطلوب';
    }

    // التحقق من الكمية
    final qte = data['qte'];
    if (qte == null || qte <= 0) {
      errors['qte'] = 'الكمية يجب أن تكون أكبر من صفر';
    }

    // التحقق من الوزن
    final poids = data['poids'];
    if (poids == null || poids <= 0) {
      errors['poids'] = 'الوزن يجب أن يكون أكبر من صفر';
    }

    // التحقق من سعر القطعة
    final puPieces = data['puPieces'];
    if (puPieces == null || puPieces <= 0) {
      errors['puPieces'] = 'سعر القطعة يجب أن يكون أكبر من صفر';
    }

    return errors;
  }

  // تنسيق الأرقام للعرض
  String formatCurrency(double amount) {
    return NumberFormattingService.formatCurrency(amount);
  }

  // تنسيق العملة مع معالجة آمنة للأنواع المختلفة
  String formatCurrencySafe(dynamic amount) {
    return NumberFormattingService.formatCurrencySafe(amount);
  }

  String formatWeight(double weight) {
    return NumberFormattingService.formatWeight(weight);
  }

  String formatWeightSafe(dynamic weight) {
    return NumberFormattingService.formatWeightSafe(weight);
  }

  String formatQuantity(int quantity) {
    return NumberFormattingService.formatQuantity(quantity);
  }

  String formatQuantitySafe(dynamic quantity) {
    return NumberFormattingService.formatQuantitySafe(quantity);
  }

  // دالة لتنسيق الأرقام الكبيرة بشكل مختصر (مثل 1.2M, 3.4K)
  String formatCompactNumber(double number) {
    return NumberFormattingService.formatCompact(number);
  }

  // حساب إحصائيات سريعة
  Map<String, dynamic> getQuickStats(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return {
        'totalItems': 0,
        'totalQuantity': 0,
        'totalWeight': 0.0,
        'averagePrice': 0.0,
        'totalValue': 0.0,
      };
    }

    int totalQuantity = 0;
    double totalWeight = 0.0;
    double totalValue = 0.0;

    for (var item in items) {
      totalQuantity += _safeParseInt(item['qte']);
      totalWeight += _safeParseDouble(item['poids']);
      totalValue += _safeParseDouble(item['mt']);
    }

    final averagePrice = totalQuantity > 0
        ? double.parse((totalValue / totalQuantity).toStringAsFixed(2))
        : 0.0;

    return {
      'totalItems': items.length,
      'totalQuantity': totalQuantity,
      'totalWeight': double.parse(totalWeight.toStringAsFixed(2)),
      'averagePrice': averagePrice,
      'totalValue': double.parse(totalValue.toStringAsFixed(2)),
    };
  }

  // دالة مساعدة لإعادة حساب جميع العناصر عند تغيير المجاميع
  List<Map<String, dynamic>> recalculateAllItems(
    List<Map<String, dynamic>> itemsData,
    double totalMt,
    double poidsTotal,
    double grandTotal,
  ) {
    List<Map<String, dynamic>> recalculatedItems = [];

    for (var itemData in itemsData) {
      final recalculatedItem = calculateItemValues(
        itemData,
        totalMt: totalMt,
        poidsTotal: poidsTotal,
        grandTotal: grandTotal,
      );
      recalculatedItems.add(recalculatedItem);
    }

    return recalculatedItems;
  }

  // دالة مساعدة لتحويل البيانات إلى double بشكل آمن
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  // دالة مساعدة لتحويل البيانات إلى int بشكل آمن
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}



// البيانات المدخلة يدوياً:
// - refFournisseur: مرجع المورد
// - articles: اسم المادة  
// - qte: الكمية
// - poids: الوزن
// - puPieces: سعر القطعة

// البيانات المحسوبة تلقائياً:
// - mt = qte × puPieces (المبلغ الإجمالي)
// - prixAchat = puPieces × exchangeRate (سعر الشراء)
// - autresCharges = (poids ÷ qte) × (totalMt ÷ poidsTotal) (الرسوم الأخرى)
// - cuHt = prixAchat + autresCharges (التكلفة الإجمالية)
// */
