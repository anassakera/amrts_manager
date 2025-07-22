// services/calculation_service.dart
import '../models/document_model.dart';

class CalculationService {
  // حساب قيم العنصر الواحد
  Map<String, dynamic> calculateItemValues(Map<String, dynamic> data) {
    final qte = (data['qte'] ?? 0).toInt();
    final puPieces = (data['puPieces'] ?? 0.0).toDouble();
    final prixAchat = (data['prixAchat'] ?? 0.0).toDouble();
    final autresCharges = (data['autresCharges'] ?? 0.0).toDouble();

    // حساب الوزن بناء على الكمية (افتراض: كل قطعة = 13 كيلو)
    final poids = qte * 13.0;

    // حساب MT (المبلغ الإجمالي)
    final mt = qte * puPieces;

    // حساب التكلفة الإجمالية
    final cuHt = prixAchat + autresCharges;

    return {
      'refFournisseur': data['refFournisseur'] ?? '',
      'articles': data['articles'] ?? '',
      'qte': qte,
      'poids': poids,
      'puPieces': puPieces,
      'mt': mt,
      'prixAchat': prixAchat,
      'autresCharges': autresCharges,
      'cuHt': cuHt,
    };
  }

  // حساب المجاميع الكلية
  Map<String, double> calculateTotals(
    List<DocumentItem> items,
    DocumentSummary summary,
  ) {
    double totalMt = 0.0;
    double totalPoids = 0.0;

    for (var item in items) {
      totalMt += item.mt;
      totalPoids += item.poids;
    }

    // حساب المجموع الكلي (بضائع + مصاريف إضافية)
    final grandTotal =
        totalMt +
        summary.transit +
        summary.droitDouane +
        summary.chequeChange +
        summary.freiht +
        summary.autres;

    return {'totalMt': totalMt, 'poidsTotal': totalPoids, 'total': grandTotal};
  }

  // حساب النسب المئوية للتوزيع
  Map<String, double> calculateDistributionRatios(
    DocumentItem item,
    double totalMt,
  ) {
    if (totalMt == 0) return {'ratio': 0.0};

    final ratio = item.mt / totalMt;
    return {'ratio': ratio};
  }

  // حساب المصاريف الموزعة على كل عنصر
  Map<String, double> calculateDistributedCosts(
    DocumentItem item,
    DocumentSummary summary,
    double totalMt,
  ) {
    final ratio = calculateDistributionRatios(item, totalMt)['ratio'] ?? 0.0;

    final distributedTransit = summary.transit * ratio;
    final distributedDroitDouane = summary.droitDouane * ratio;
    final distributedChequeChange = summary.chequeChange * ratio;
    final distributedFreiht = summary.freiht * ratio;
    final distributedAutres = summary.autres * ratio;

    final totalDistributedCost =
        distributedTransit +
        distributedDroitDouane +
        distributedChequeChange +
        distributedFreiht +
        distributedAutres;

    return {
      'distributedTransit': distributedTransit,
      'distributedDroitDouane': distributedDroitDouane,
      'distributedChequeChange': distributedChequeChange,
      'distributedFreiht': distributedFreiht,
      'distributedAutres': distributedAutres,
      'totalDistributedCost': totalDistributedCost,
      'finalCostPerUnit': (item.mt + totalDistributedCost) / item.qte,
    };
  }

  // التحقق من صحة البيانات
  Map<String, String> validateItemData(Map<String, dynamic> data) {
    Map<String, String> errors = {};

    if (data['refFournisseur'] == null ||
        data['refFournisseur'].toString().trim().isEmpty) {
      errors['refFournisseur'] = 'مرجع المورد مطلوب';
    }

    if (data['articles'] == null ||
        data['articles'].toString().trim().isEmpty) {
      errors['articles'] = 'اسم المادة مطلوب';
    }

    final qte = data['qte'];
    if (qte == null || qte <= 0) {
      errors['qte'] = 'الكمية يجب أن تكون أكبر من صفر';
    }

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

  // حساب إحصائيات سريعة
  Map<String, dynamic> getQuickStats(List<DocumentItem> items) {
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

    final averagePrice = totalValue / totalQuantity;

    return {
      'totalItems': items.length,
      'totalQuantity': totalQuantity,
      'totalWeight': totalWeight,
      'averagePrice': averagePrice,
      'totalValue': totalValue,
    };
  }
}
