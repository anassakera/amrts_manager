// models/document_model.dart
class DocumentItem {
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

  DocumentItem({
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
  DocumentItem copyWith({
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
    return DocumentItem(
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
  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      refFournisseur: json['refFournisseur'] ?? '',
      articles: json['articles'] ?? '',
      qte: json['qte'] ?? 0,
      poids: json['poids']?.toDouble() ?? 0.0,
      puPieces: json['puPieces']?.toDouble() ?? 0.0,
      mt: json['mt']?.toDouble() ?? 0.0,
      prixAchat: json['prixAchat']?.toDouble() ?? 0.0,
      autresCharges: json['autresCharges']?.toDouble() ?? 0.0, // فقط من الحساب
      cuHt: json['cuHt']?.toDouble() ?? 0.0,
      exchangeRate: json['exchangeRate']?.toDouble() ?? 1.0,
    );
  }
}

class DocumentSummary {
  final String factureNumber;
  final double transit;
  final double droitDouane;
  final double chequeChange;
  final double freiht;
  final double autres;
  final double total;
  final double txChange;
  final double poidsTotal;

  DocumentSummary({
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

  DocumentSummary copyWith({
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
    return DocumentSummary(
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
