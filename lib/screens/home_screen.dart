import '../../../core/imports.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/language_provider.dart';
import '../../core/language.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  // late GlobalKey<State<SalesInterfaceScreen>> _salesInterfaceKey;
  // late GlobalKey<State<ProductManagementScreen>> _productManagementKey;
  // late List<Widget> _screens;

  // قائمة بأسماء الشاشات
  List<String> _screenTitles(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return [
      AppTranslations.get('purchases', lang),
      AppTranslations.get('sales', lang),
      AppTranslations.get('inventory', lang),
      AppTranslations.get('production', lang),
      AppTranslations.get('financial_transactions', lang),
    ];
  }

  @override
  void initState() {
    super.initState();
    // _salesInterfaceKey = GlobalKey<State<SalesInterfaceScreen>>();
    // _productManagementKey = GlobalKey<State<ProductManagementScreen>>();
    // _screens = [
    //   SalesInterfaceScreen(key: _salesInterfaceKey),
    //   ProductManagementScreen(key: _productManagementKey),
    //   const SalesInvoicesScreen(),
    //   const PurchaseInvoicesScreen(),
    //   const ReportsScreen(),
    // ];
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // دالة للحصول على عنوان الشاشة الحالية
  String _getCurrentScreenTitle(BuildContext context) {
    return _screenTitles(context)[_selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: DrawerScreen(
      //   onNavigationItemSelected: (index) {
      //     setState(() {
      //       _selectedIndex = index;
      //       _tabController.animateTo(index);
      //     });
      //   },
      // ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E3A8A), // أزرق داكن عميق
                Color(0xFF3B82F6), // أزرق متوسط
                Color(0xFF60A5FA), // أزرق فاتح
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6),
                blurRadius: 15,
                offset: Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (context) => Text(
                _getCurrentScreenTitle(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Help button
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            tooltip: AppTranslations.get(
              'help',
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).currentLanguage,
            ),
            onPressed: () {
              // if (_selectedIndex == 0 &&
              //     _salesInterfaceKey.currentState != null) {
              //   final dynamic state = _salesInterfaceKey.currentState;
              //   state.showTutorialIfNeeded();
              // } else if (_selectedIndex == 1 &&
              //     _productManagementKey.currentState != null) {
              //   final dynamic state = _productManagementKey.currentState;
              //   state.showTutorialIfNeeded();
              // } else {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(
              //       content: Text(
              //         'المساعدة متوفرة فقط في شاشة نقطة البيع أو إدارة المنتجات',
              //       ),
              //       backgroundColor: Color(0xFF3B82F6),
              //     ),
              //   );
              // }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            tooltip: AppTranslations.get(
              'settings',
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).currentLanguage,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 24,
            ),
            tooltip: AppTranslations.get(
              'customers',
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).currentLanguage,
            ),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const CustomerManagementScreen(),
              //   ),
              // );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const NotificationsScreen(),
                      //   ),
                      // );
                    },
                  ),
                ),
                // نقطة الإشعار
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const ProfileScreen(),
                    //   ),
                    // );
                  },
                  // child: ClipRRect(
                  //   borderRadius: BorderRadius.circular(18),
                  //   child: Image.asset(
                  //     'assets/images/photo.jpg',
                  //     fit: BoxFit.cover,
                  //     errorBuilder: (context, error, stackTrace) {
                  //       return const Icon(
                  //         Icons.person_rounded,
                  //         color: Colors.white,
                  //         size: 24,
                  //       );
                  //     },
                  //   ),
                  // ),
                ),
              ),
            ),
          ),
        ],
        bottom: MediaQuery.of(context).size.width > 768
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Column(
                  children: [
                    // TabBar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: _buildTabBar(),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              )
            : null,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      body: Column(
        children: [
          // Expanded(child: _screens[_selectedIndex])
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).currentLanguage;
    return HomeScreenWidgets.buildCustomTabBar(_tabController, [
      HomeScreenWidgets.buildCustomTab(
        Icons.shopping_cart,
        AppTranslations.get('purchases', lang),
      ),
      HomeScreenWidgets.buildCustomTab(
        Icons.point_of_sale,
        AppTranslations.get('sales', lang),
      ),
      HomeScreenWidgets.buildCustomTab(
        Icons.inventory,
        AppTranslations.get('inventory', lang),
      ),
      HomeScreenWidgets.buildCustomTab(
        Icons.factory,
        AppTranslations.get('production', lang),
      ),
      HomeScreenWidgets.buildCustomTab(
        Icons.account_balance_wallet,
        AppTranslations.get('financial_transactions', lang),
      ),
    ]);
  }
}
