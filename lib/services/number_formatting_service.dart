class NumberFormattingService {
  // تنسيق الأرقام مع فواصل للقراءة
  static String formatWithSpaces(double number, {int decimalPlaces = 2}) {
    // تحويل الرقم إلى نص مع العدد المطلوب من الخانات العشرية
    String numberStr = number.toStringAsFixed(decimalPlaces);
    
    // فصل الجزء الصحيح عن الجزء العشري
    List<String> parts = numberStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    // إضافة فواصل للجزء الصحيح كل 3 أرقام من اليمين
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ' ';
      }
      formattedInteger += integerPart[i];
    }
    
    // إعادة تجميع الرقم مع الجزء العشري
    if (decimalPlaces > 0 && decimalPart.isNotEmpty) {
      return '$formattedInteger.$decimalPart';
    } else {
      return formattedInteger;
    }
  }

  // تنسيق الأرقام الكبيرة بشكل مختصر (مثل 1.2M, 3.4K)
  static String formatCompact(double number, {int decimalPlaces = 1}) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(decimalPlaces)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(decimalPlaces)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(decimalPlaces)}K';
    } else {
      return formatWithSpaces(number, decimalPlaces: 2);
    }
  }

  // تنسيق العملة مع الرمز
  static String formatCurrency(double amount, {String symbol = 'DH', int decimalPlaces = 2}) {
    String formattedAmount = formatWithSpaces(amount, decimalPlaces: decimalPlaces);
    return '$formattedAmount $symbol';
  }

  // تنسيق العملة مع معالجة آمنة للأنواع المختلفة
  static String formatCurrencySafe(dynamic amount, {String symbol = 'DH', int decimalPlaces = 2}) {
    double safeAmount = 0.0;
    
    if (amount == null) {
      safeAmount = 0.0;
    } else if (amount is int) {
      safeAmount = amount.toDouble();
    } else if (amount is double) {
      safeAmount = amount;
    } else if (amount is String) {
      safeAmount = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      safeAmount = amount.toDouble();
    } else {
      safeAmount = 0.0;
    }
    
    return formatCurrency(safeAmount, symbol: symbol, decimalPlaces: decimalPlaces);
  }

  // تنسيق الوزن
  static String formatWeight(double weight, {String unit = 'Kg', int decimalPlaces = 2}) {
    String formattedWeight = formatWithSpaces(weight, decimalPlaces: decimalPlaces);
    return '$formattedWeight $unit';
  }

  // تنسيق الوزن مع معالجة آمنة للأنواع المختلفة
  static String formatWeightSafe(dynamic weight, {String unit = 'Kg', int decimalPlaces = 2}) {
    double safeWeight = 0.0;
    
    if (weight == null) {
      safeWeight = 0.0;
    } else if (weight is int) {
      safeWeight = weight.toDouble();
    } else if (weight is double) {
      safeWeight = weight;
    } else if (weight is String) {
      safeWeight = double.tryParse(weight) ?? 0.0;
    } else if (weight is num) {
      safeWeight = weight.toDouble();
    } else {
      safeWeight = 0.0;
    }
    
    return formatWeight(safeWeight, unit: unit, decimalPlaces: decimalPlaces);
  }

  // تنسيق الكمية (أرقام صحيحة)
  static String formatQuantity(int quantity) {
    return formatWithSpaces(quantity.toDouble(), decimalPlaces: 0);
  }

  // تنسيق الكمية مع معالجة آمنة للأنواع المختلفة
  static String formatQuantitySafe(dynamic quantity) {
    int safeQuantity = 0;
    
    if (quantity == null) {
      safeQuantity = 0;
    } else if (quantity is int) {
      safeQuantity = quantity;
    } else if (quantity is double) {
      safeQuantity = quantity.toInt();
    } else if (quantity is String) {
      safeQuantity = int.tryParse(quantity) ?? 0;
    } else if (quantity is num) {
      safeQuantity = quantity.toInt();
    } else {
      safeQuantity = 0;
    }
    
    return formatQuantity(safeQuantity);
  }

  // تنسيق النسبة المئوية
  static String formatPercentage(double percentage, {int decimalPlaces = 1}) {
    String formattedPercentage = formatWithSpaces(percentage, decimalPlaces: decimalPlaces);
    return '$formattedPercentage%';
  }

  // تنسيق الأرقام مع دعم الاتجاه (RTL/LTR)
  static String formatWithDirection(double number, {int decimalPlaces = 2, bool isRTL = true}) {
    String formatted = formatWithSpaces(number, decimalPlaces: decimalPlaces);
    
    if (isRTL) {
      // إضافة علامة اتجاه للنص العربي
      return '\u202B$formatted';
    } else {
      // إضافة علامة اتجاه للنص الإنجليزي
      return '\u202A$formatted';
    }
  }

  // تنسيق الأرقام مع دعم العملات المختلفة
  static String formatCurrencyWithLocale(double amount, {
    String locale = 'ar_MA',
    String currencyCode = 'MAD',
    int decimalPlaces = 2,
  }) {
    String formattedAmount = formatWithSpaces(amount, decimalPlaces: decimalPlaces);
    
    switch (locale) {
      case 'ar_MA':
        return '$formattedAmount درهم';
      case 'en_US':
        return '\$$formattedAmount';
      case 'en_GB':
        return '£$formattedAmount';
      case 'fr_FR':
        return '$formattedAmount €';
      default:
        return '$formattedAmount $currencyCode';
    }
  }

  // تنسيق الأرقام مع دعم النطاقات
  static String formatRange(double min, double max, {int decimalPlaces = 2}) {
    String formattedMin = formatWithSpaces(min, decimalPlaces: decimalPlaces);
    String formattedMax = formatWithSpaces(max, decimalPlaces: decimalPlaces);
    return '$formattedMin - $formattedMax';
  }

  // تنسيق الأرقام مع دعم المقارنة
  static String formatComparison(double current, double previous, {int decimalPlaces = 2}) {
    String formattedCurrent = formatWithSpaces(current, decimalPlaces: decimalPlaces);
    
    double change = current - previous;
    double changePercent = previous != 0 ? (change / previous) * 100 : 0;
    
    String changeSymbol = change >= 0 ? '+' : '';
    String changeText = '$changeSymbol${formatWithSpaces(change, decimalPlaces: decimalPlaces)}';
    String percentText = '$changeSymbol${changePercent.toStringAsFixed(1)}%';
    
    return '$formattedCurrent ($changeText, $percentText)';
  }

  // تنسيق الأرقام مع دعم التدرج اللوني
  static String formatWithColor(double number, {
    int decimalPlaces = 2,
    double? minValue,
    double? maxValue,
  }) {
    String formatted = formatWithSpaces(number, decimalPlaces: decimalPlaces);
    
    if (minValue != null && maxValue != null) {
      double percentage = (number - minValue) / (maxValue - minValue);
      if (percentage < 0.3) {
        return '🔴 $formatted'; // أحمر للقيم المنخفضة
      } else if (percentage < 0.7) {
        return '🟡 $formatted'; // أصفر للقيم المتوسطة
      } else {
        return '🟢 $formatted'; // أخضر للقيم العالية
      }
    }
    
    return formatted;
  }

  // تنسيق الأرقام مع دعم الوحدات الذكية
  static String formatSmartUnit(double value, String unit, {int decimalPlaces = 2}) {
    if (unit.toLowerCase() == 'weight' || unit.toLowerCase() == 'kg') {
      return formatWeight(value, unit: 'Kg', decimalPlaces: decimalPlaces);
    } else if (unit.toLowerCase() == 'currency' || unit.toLowerCase() == 'money') {
      return formatCurrency(value, decimalPlaces: decimalPlaces);
    } else if (unit.toLowerCase() == 'percentage' || unit.toLowerCase() == '%') {
      return formatPercentage(value, decimalPlaces: decimalPlaces);
    } else if (unit.toLowerCase() == 'quantity' || unit.toLowerCase() == 'count') {
      return formatQuantity(value.toInt());
    } else {
      return '${formatWithSpaces(value, decimalPlaces: decimalPlaces)} $unit';
    }
  }
} 