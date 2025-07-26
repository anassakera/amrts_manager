// models/invoice_manage_model.dart

// كلاس عنصر الفاتورة
class InvoiceItem {
  final String refFournisseur;
  final String articles;
  final int qte;
  final double poids;
  final double puPieces;
  final double mt;
  final double prixAchat;
  final double autresCharges;
  final double cuHt;
  final double exchangeRate;
  bool isEditing;
  bool isSelected;

  InvoiceItem({
    required this.refFournisseur,
    required this.articles,
    required this.qte,
    required this.poids,
    required this.puPieces,
    required this.mt,
    required this.prixAchat,
    required this.autresCharges,
    required this.cuHt,
    this.exchangeRate = 1.0,
    this.isEditing = false,
    this.isSelected = false,
  });

  // نسخة محدثة من العنصر
  InvoiceItem copyWith({
    String? refFournisseur,
    String? articles,
    int? qte,
    double? poids,
    double? puPieces,
    double? mt,
    double? prixAchat,
    double? autresCharges,
    double? cuHt,
    double? exchangeRate,
    bool? isEditing,
    bool? isSelected,
  }) {
    return InvoiceItem(
      refFournisseur: refFournisseur ?? this.refFournisseur,
      articles: articles ?? this.articles,
      qte: qte ?? this.qte,
      poids: poids ?? this.poids,
      puPieces: puPieces ?? this.puPieces,
      mt: mt ?? this.mt,
      prixAchat: prixAchat ?? this.prixAchat,
      autresCharges: autresCharges ?? this.autresCharges,
      cuHt: cuHt ?? this.cuHt,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isEditing: isEditing ?? this.isEditing,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // تحويل إلى Map للحفظ
  Map<String, dynamic> toJson() {
    return {
      'refFournisseur': refFournisseur,
      'articles': articles,
      'qte': qte,
      'poids': poids,
      'puPieces': puPieces,
      'mt': mt,
      'prixAchat': prixAchat,
      'autresCharges': autresCharges,
      'cuHt': cuHt,
      'exchangeRate': exchangeRate,
    };
  }

  // إنشاء من Map للقراءة
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      refFournisseur: json['refFournisseur'] ?? '',
      articles: json['articles'] ?? '',
      qte: json['qte'] ?? 0,
      poids: json['poids']?.toDouble() ?? 0.0,
      puPieces: json['puPieces']?.toDouble() ?? 0.0,
      mt: json['mt']?.toDouble() ?? 0.0,
      prixAchat: json['prixAchat']?.toDouble() ?? 0.0,
      autresCharges: json['autresCharges']?.toDouble() ?? 0.0,
      cuHt: json['cuHt']?.toDouble() ?? 0.0,
      exchangeRate: json['exchangeRate']?.toDouble() ?? 1.0,
    );
  }
}

// كلاس ملخص الفاتورة
class InvoiceSummary {
  final String factureNumber;
  final double transit;
  final double droitDouane;
  final double chequeChange;
  final double freiht;
  final double autres;
  final double total;
  final double txChange;
  final double poidsTotal;

  InvoiceSummary({
    required this.factureNumber,
    required this.transit,
    required this.droitDouane,
    required this.chequeChange,
    required this.freiht,
    required this.autres,
    required this.total,
    required this.txChange,
    required this.poidsTotal,
  });

  InvoiceSummary copyWith({
    String? factureNumber,
    double? transit,
    double? droitDouane,
    double? chequeChange,
    double? freiht,
    double? autres,
    double? total,
    double? txChange,
    double? poidsTotal,
  }) {
    return InvoiceSummary(
      factureNumber: factureNumber ?? this.factureNumber,
      transit: transit ?? this.transit,
      droitDouane: droitDouane ?? this.droitDouane,
      chequeChange: chequeChange ?? this.chequeChange,
      freiht: freiht ?? this.freiht,
      autres: autres ?? this.autres,
      total: total ?? this.total,
      txChange: txChange ?? this.txChange,
      poidsTotal: poidsTotal ?? this.poidsTotal,
    );
  }
}

// كلاس الفاتورة الرئيسي
class InvoiceModel {
  final String id;
  final String clientName;
  final String invoiceNumber;
  final DateTime date;
  final bool isLocal; // true للمحلي، false للخارجي
  final double totalAmount;
  final String status;
  final List<InvoiceItem> items;
  final InvoiceSummary summary;

  InvoiceModel({
    required this.id,
    required this.clientName,
    required this.invoiceNumber,
    required this.date,
    required this.isLocal,
    this.totalAmount = 0.0,
    this.status = 'مسودة',
    this.items = const [],
    required this.summary,
  });

  InvoiceModel copyWith({
    String? id,
    String? clientName,
    String? invoiceNumber,
    DateTime? date,
    bool? isLocal,
    double? totalAmount,
    String? status,
    List<InvoiceItem>? items,
    InvoiceSummary? summary,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      isLocal: isLocal ?? this.isLocal,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
    );
  }
}
