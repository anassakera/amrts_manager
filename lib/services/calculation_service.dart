// services/calculation_service.dart
import '../models/invoice_manage_model.dart';

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
    final qte = (data['qte'] ?? 0).toInt();
    final poids = double.parse(
      ((data['poids'] ?? 0.0).toDouble()).toStringAsFixed(2),
    );
    final puPieces = double.parse(
      ((data['puPieces'] ?? 0.0).toDouble()).toStringAsFixed(2),
    );
    final exchangeRate = double.parse(
      ((data['exchangeRate'] ?? 1.0).toDouble()).toStringAsFixed(2),
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
    List<InvoiceItem> items,
    InvoiceSummary summary,
  ) {
    double totalMt = 0.0;
    double totalPoids = 0.0;

    // جمع المبالغ الإجمالية والأوزان من جميع العناصر
    for (var item in items) {
      totalMt += item.mt;
      totalPoids += item.poids;
    }

    // حساب المجموع الكلي للمصاريف الإضافية
    final grandTotal =
        summary.transit +
        summary.droitDouane +
        summary.chequeChange +
        summary.freiht +
        summary.autres;

    return {
      'totalMt': double.parse(totalMt.toStringAsFixed(2)),
      'poidsTotal': double.parse(totalPoids.toStringAsFixed(2)),
      'total': double.parse(grandTotal.toStringAsFixed(2)),
    };
  }

  // حساب النسب المئوية للتوزيع
  Map<String, double> calculateDistributionRatios(
    InvoiceItem item,
    double totalMt,
  ) {
    if (totalMt == 0) return {'ratio': 0.0};

    final ratio = double.parse((item.mt / totalMt).toStringAsFixed(2));
    return {'ratio': ratio};
  }

  // حساب المصاريف الموزعة على كل عنصر
  Map<String, double> calculateDistributedCosts(
    InvoiceItem item,
    InvoiceSummary summary,
    double totalMt,
  ) {
    final ratio = calculateDistributionRatios(item, totalMt)['ratio'] ?? 0.0;

    final distributedTransit = double.parse(
      (summary.transit * ratio).toStringAsFixed(2),
    );
    final distributedDroitDouane = double.parse(
      (summary.droitDouane * ratio).toStringAsFixed(2),
    );
    final distributedChequeChange = double.parse(
      (summary.chequeChange * ratio).toStringAsFixed(2),
    );
    final distributedFreiht = double.parse(
      (summary.freiht * ratio).toStringAsFixed(2),
    );
    final distributedAutres = double.parse(
      (summary.autres * ratio).toStringAsFixed(2),
    );

    final totalDistributedCost = double.parse(
      (distributedTransit +
              distributedDroitDouane +
              distributedChequeChange +
              distributedFreiht +
              distributedAutres)
          .toStringAsFixed(2),
    );

    final finalCostPerUnit = item.qte > 0
        ? double.parse(
            ((item.mt + totalDistributedCost) / item.qte).toStringAsFixed(2),
          )
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
    return amount.toStringAsFixed(2);
  }

  String formatWeight(double weight) {
    return weight.toStringAsFixed(2);
  }

  String formatQuantity(int quantity) {
    return quantity.toString();
  }

  // حساب إحصائيات سريعة
  Map<String, dynamic> getQuickStats(List<InvoiceItem> items) {
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
      totalQuantity += item.qte;
      totalWeight += item.poids;
      totalValue += item.mt;
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