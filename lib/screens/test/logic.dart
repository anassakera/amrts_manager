import 'imports.dart';

// =================== Logic Class =================== //
class CalcLogic {
  final CalcData data;

  CalcLogic(this.data);

  // =============== CRUD Operations =============== //
  void addItem(Map<String, dynamic> item, VoidCallback refresh) {
    data.data.add(item);
    refresh();
  }

  void updateItem(int index, Map<String, dynamic> item, VoidCallback refresh) {
    data.data[index] = item;
    refresh();
  }

  void deleteItem(int index, VoidCallback refresh) {
    data.data.removeAt(index);
    refresh();
  }

  // =============== Calculations =============== //
  double calculatePoidsConsomme(double poids, double quantite) {
    return poids * quantite;
  }

  double calculatePeinture(double poidsConsomme) {
    return poidsConsomme * CalcData.p3;
  }

  double calculateGaz(double poidsConsomme) {
    return poidsConsomme * CalcData.p2;
  }

  double calculateDechet(double belletConstant, double poidsConsomme) {
    return belletConstant - poidsConsomme;
  }

  double calculateDechetInitial(double belletConstant) {
    return belletConstant / CalcData.p5;
  }

  // =============== Totals Calculation =============== //
  Map<String, double> calculateTotals() {
    double sumPoidsConsomme = 0;
    double sumPeinture = 0;
    double sumGaz = 0;
    double sumBellet = 0;
    double sumDechet = 0;
    double sumDechetInitial = 0;

    for (var item in data.data) {
      double poidsConsomme = calculatePoidsConsomme(
        item['poids'],
        item['quantite'],
      );
      double peinture = calculatePeinture(poidsConsomme);
      double gaz = calculateGaz(poidsConsomme);
      double bellet = item['bellet_constant'];
      double dechet = calculateDechet(bellet, poidsConsomme);
      double dechetInitial = calculateDechetInitial(bellet);

      sumPoidsConsomme += poidsConsomme;
      sumPeinture += peinture;
      sumGaz += gaz;
      sumBellet += bellet;
      sumDechet += dechet;
      sumDechetInitial += dechetInitial;
    }

    return {
      'poids_consomme': sumPoidsConsomme,
      'peinture': sumPeinture,
      'gaz': sumGaz,
      'bellet': sumBellet,
      'dechet': sumDechet,
      'dechet_initial': sumDechetInitial,
    };
  }

  // =============== Validation =============== //
  bool validateItem(Map<String, dynamic> item) {
    return item['document_ref'].toString().isNotEmpty &&
        item['client'].toString().isNotEmpty &&
        item['poids'] != null &&
        item['quantite'] != null &&
        item['bellet_constant'] != null &&
        item['gaz_price_value'] != null;
  }
}
