class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'purchases': 'المشتريات',
      'sales': 'المبيعات',
      'inventory': 'المخزون',
      'production': 'الإنتاج',
      'financial_transactions': 'المعاملات المالية',
      'help': 'مساعدة',
      'settings': 'الإعدادات',
      'customers': 'العملاء',
      'notifications': 'الإشعارات',
      'change_language': 'تغيير اللغة',
    },
    'en': {
      'purchases': 'Purchases',
      'sales': 'Sales',
      'inventory': 'Inventory',
      'production': 'Production',
      'financial_transactions': 'Financial Transactions',
      'help': 'Help',
      'settings': 'Settings',
      'customers': 'Customers',
      'notifications': 'Notifications',
      'change_language': 'Change Language',
    },
    'fr': {
      'purchases': 'Achats',
      'sales': 'Ventes',
      'inventory': 'Inventaire',
      'production': 'Production',
      'financial_transactions': 'Transactions financières',
      'help': 'Aide',
      'settings': 'Paramètres',
      'customers': 'Clients',
      'notifications': 'Notifications',
      'change_language': 'Changer de langue',
    },
  };

  static String get(String key, String lang) {
    return _localizedValues[lang]?[key] ?? _localizedValues['ar']![key] ?? key;
  }
}
