void main() {
  // === اختبار تنسيق الأرقام ===

  // اختبار تنسيق الأرقام مع فواصل
  // 1. تنسيق الأرقام مع فواصل:
  // 1234.56 -> ${NumberFormattingService.formatWithSpaces(1234.56)}
  // 1234567.89 -> ${NumberFormattingService.formatWithSpaces(1234567.89)}
  // 1000000.00 -> ${NumberFormattingService.formatWithSpaces(1000000.00)}
  // 999999999.99 -> ${NumberFormattingService.formatWithSpaces(999999999.99)}

  // اختبار تنسيق الأرقام المختصر
  // 2. تنسيق الأرقام المختصر:
  // 1234.56 -> ${NumberFormattingService.formatCompact(1234.56)}
  // 1234567.89 -> ${NumberFormattingService.formatCompact(1234567.89)}
  // 1000000.00 -> ${NumberFormattingService.formatCompact(1000000.00)}
  // 999999999.99 -> ${NumberFormattingService.formatCompact(999999999.99)}

  // اختبار تنسيق العملة
  // 3. تنسيق العملة:
  // 1234.56 -> ${NumberFormattingService.formatCurrency(1234.56)}
  // 1234567.89 -> ${NumberFormattingService.formatCurrency(1234567.89)}
  // 1000000.00 -> ${NumberFormattingService.formatCurrency(1000000.00)}

  // اختبار تنسيق الوزن
  // 4. تنسيق الوزن:
  // 1234.56 -> ${NumberFormattingService.formatWeight(1234.56)}
  // 1234567.89 -> ${NumberFormattingService.formatWeight(1234567.89)}
  // 1000000.00 -> ${NumberFormattingService.formatWeight(1000000.00)}

  // اختبار تنسيق الكمية
  // 5. تنسيق الكمية:
  // 1234 -> ${NumberFormattingService.formatQuantity(1234)}
  // 1234567 -> ${NumberFormattingService.formatQuantity(1234567)}
  // 1000000 -> ${NumberFormattingService.formatQuantity(1000000)}

  // اختبار تنسيق النسبة المئوية
  // 6. تنسيق النسبة المئوية:
  // 12.34 -> ${NumberFormattingService.formatPercentage(12.34)}
  // 123.45 -> ${NumberFormattingService.formatPercentage(123.45)}

  // اختبار تنسيق العملة مع اللغات المختلفة
  // 7. تنسيق العملة مع اللغات المختلفة:
  // 1234.56 (ar_MA) -> ${NumberFormattingService.formatCurrencyWithLocale(1234.56, locale: 'ar_MA')}
  // 1234.56 (en_US) -> ${NumberFormattingService.formatCurrencyWithLocale(1234.56, locale: 'en_US')}
  // 1234.56 (fr_FR) -> ${NumberFormattingService.formatCurrencyWithLocale(1234.56, locale: 'fr_FR')}

  // اختبار تنسيق النطاقات
  // 8. تنسيق النطاقات:
  // 1000 - 5000 -> ${NumberFormattingService.formatRange(1000, 5000)}
  // 1000000 - 5000000 -> ${NumberFormattingService.formatRange(1000000, 5000000)}

  // اختبار تنسيق المقارنة
  // 9. تنسيق المقارنة:
  // Current: 1500, Previous: 1000 -> ${NumberFormattingService.formatComparison(1500, 1000)}
  // Current: 800, Previous: 1000 -> ${NumberFormattingService.formatComparison(800, 1000)}

  // اختبار تنسيق الوحدات الذكية
  // 10. تنسيق الوحدات الذكية:
  // 1234.56 (weight) -> ${NumberFormattingService.formatSmartUnit(1234.56, 'weight')}
  // 1234.56 (currency) -> ${NumberFormattingService.formatSmartUnit(1234.56, 'currency')}
  // 12.34 (percentage) -> ${NumberFormattingService.formatSmartUnit(12.34, 'percentage')}
  // 1234 (quantity) -> ${NumberFormattingService.formatSmartUnit(1234, 'quantity')}

  // === انتهى الاختبار ===
} 