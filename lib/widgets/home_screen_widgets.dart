import '../core/imports.dart';


class HomeScreenWidgets {
// لتحديد التبويبات
static Widget buildCustomTabBar(TabController controller, List<Tab> tabs) {
  return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
   child: TabBar(
  controller: controller,
  dividerColor: Colors.transparent,
  indicator: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFF1E40AF), // أزرق داكن
        Color(0xFF3B82F6), // أزرق متوسط
        Color(0xFF60A5FA), // أزرق فاتح
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF3B82F6).withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  indicatorSize: TabBarIndicatorSize.tab,
  labelColor: Colors.white,
  unselectedLabelColor: Color(0xFF64748B), // رمادي مزرق
  labelStyle: const TextStyle(
    fontSize: 12, 
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  unselectedLabelStyle: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  ),
  tabs: tabs,
),
  );
}
// لتحديد التبويبات المراد عرضها
 static Tab buildCustomTab(IconData icon, String label) {
  return Tab(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        SizedBox(height: 4),
        Text(label),
      ],
    ),
  );
}

// دالة مساعدة لإنشاء تبويب مع ترجمة
static Tab buildTranslatedTab(BuildContext context, IconData icon, String translationKey) {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  final currentLang = languageProvider.currentLanguage;
  
  return Tab(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        SizedBox(height: 4),
        Text(AppTranslations.get(translationKey, currentLang)),
      ],
    ),
  );
}

}