import '../core/imports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  late List<Widget> _screens;

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

    _screens = [
      InvoicesScreen(),
      SalesScreen(),
      InventoryScreen(),
      ProductionScreen(),
      FinancialTransactionsScreen(),
    ];
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
      drawer: DrawerScreen(
        onNavigationItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _tabController.animateTo(index);
          });
        },
      ),
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
      
       
        bottom: MediaQuery.of(context).size.width > 768
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Column(
                  children: [
                    // TabBar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
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
          Expanded(child: _screens[_selectedIndex])
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
