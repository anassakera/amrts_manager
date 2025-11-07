// =================== Data Class =================== //
class CalcData {
  // =============== Constants =============== //
  static const double p2 = 2.0;
  static const double p3 = 3.0;
  static const double p5 = 5.0;

  // =============== Main Data List =============== //
  final List<Map<String, dynamic>> data = [
    {
      'document_ref': 'BC2510001',
      'client': 'anass',
      'reference': 'FT345',
      'designation': 'Tola_AL14',
      'poids': 3.0,
      'quantite': 400.0,
      'couleur': 'red',
      'bellet_constant': 1463.41,
      'date': 'AUTO',
      'gaz_price_type': 'Peinture',
      'gaz_price_value': 3.00,
    },
    {
      'document_ref': 'BC2510001',
      'client': 'anass',
      'reference': '46894',
      'designation': 'Tola_AL25',
      'poids': 2.0,
      'quantite': 500.0,
      'couleur': 'green',
      'bellet_constant': 1219.51,
      'date': 'AUTO',
      'gaz_price_type': 'bellet',
      'gaz_price_value': 0.18,
    },
    {
      'document_ref': 'BL2510002',
      'client': 'rachid',
      'reference': 'D8745',
      'designation': 'Tola_DL87',
      'poids': 10.0,
      'quantite': 500.0,
      'couleur': 'green',
      'bellet_constant': 6097.56,
      'date': 'AUTO',
      'gaz_price_type': 'dechet',
      'gaz_price_value': 0.94,
    },
    {
      'document_ref': 'BL2510002',
      'client': 'rachid',
      'reference': 'FU777',
      'designation': 'Tola_FU27',
      'poids': 15.0,
      'quantite': 500.0,
      'couleur': 'green',
      'bellet_constant': 9146.34,
      'date': 'AUTO',
      'gaz_price_type': '',
      'gaz_price_value': 7.00,
    },
    {
      'document_ref': 'BL2510002',
      'client': 'rachid',
      'reference': 'K4T88',
      'designation': 'Tola_K428',
      'poids': 14.0,
      'quantite': 500.0,
      'couleur': 'green',
      'bellet_constant': 8536.59,
      'date': 'AUTO',
      'gaz_price_type': '',
      'gaz_price_value': 0.18,
    },
  ];
}
