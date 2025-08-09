import '../core/imports.dart';

class DrawerScreen extends StatelessWidget {
  final Function(int)? onNavigationItemSelected;

  const DrawerScreen({super.key, this.onNavigationItemSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            _buildHeader(),

            // Navigation Items
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Main Navigation
                      _buildNavigationSection(),

                      const Divider(height: 40, thickness: 1),

                      // Settings Section
                      _buildSettingsSection(),

                      const SizedBox(height: 20),

                      // Footer
                      _buildFooter(context),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLang = languageProvider.currentLanguage;
        
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
          child: Column(
            children: [
              // Profile Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/photo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Color(0xFF1E40AF),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User Info
              Text(
                'Admin',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.get('system_manager', currentLang),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.get('online', currentLang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationSection() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLang = languageProvider.currentLanguage;
        
        final navigationItems = [
          {
            'icon': Icons.shopping_cart_rounded,
            'title': AppTranslations.get('purchases', currentLang),
            'subtitle': AppTranslations.get('purchases_subtitle', currentLang),
            'color': const Color(0xFF3B82F6),
            'key': 'purchases',
          },
          {
            'icon': Icons.point_of_sale_rounded,
            'title': AppTranslations.get('sales', currentLang),
            'subtitle': AppTranslations.get('sales_subtitle', currentLang),
            'color': const Color(0xFF10B981),
            'key': 'sales',
          },
          {
            'icon': Icons.inventory_2_rounded,
            'title': AppTranslations.get('inventory', currentLang),
            'subtitle': AppTranslations.get('inventory_subtitle', currentLang),
            'color': const Color(0xFFF59E0B),
            'key': 'inventory',
          },
          {
            'icon': Icons.factory_rounded,
            'title': AppTranslations.get('production', currentLang),
            'subtitle': AppTranslations.get('production_subtitle', currentLang),
            'color': const Color(0xFFDC2626),
            'key': 'production',
          },
          {
            'icon': Icons.account_balance_wallet_rounded,
            'title': AppTranslations.get('financial_transactions', currentLang),
            'subtitle': AppTranslations.get('financial_transactions_subtitle', currentLang),
            'color': const Color(0xFF8B5CF6),
            'key': 'financial_transactions',
          },
        ];

        return Column(
          children: navigationItems
              .map((item) => _buildNavigationItem(item))
              .toList(),
        );
      },
    );
  }

  Widget _buildNavigationItem(Map<String, dynamic> item) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Handle navigation based on key
              String key = item['key'];
              int selectedIndex = 0;

              switch (key) {
                case 'purchases':
                  selectedIndex = 0;
                  break;
                case 'sales':
                  selectedIndex = 1;
                  break;
                case 'inventory':
                  selectedIndex = 2;
                  break;
                case 'production':
                  selectedIndex = 3;
                  break;
                case 'financial_transactions':
                  selectedIndex = 4;
                  break;
              }

              // Close drawer first
              Navigator.pop(context);

              // Then navigate to the selected screen
              if (onNavigationItemSelected != null) {
                onNavigationItemSelected!(selectedIndex);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item['icon'], color: item['color'], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLang = languageProvider.currentLanguage;
        
        final settingsItems = [
          {
            'icon': Icons.people_rounded,
            'title': 'إدارة المستخدمين',
            'subtitle': 'إضافة وتعديل وحذف المستخدمين',
            'color': const Color(0xFF1E3A8A),
          },
          {
            'icon': Icons.settings_rounded,
            'title': AppTranslations.get('settings', currentLang),
            'subtitle': 'إعدادات النظام',
            'color': const Color(0xFF64748B),
          },
          {
            'icon': Icons.notifications_rounded,
            'title': AppTranslations.get('notifications', currentLang),
            'subtitle': 'إدارة الإشعارات',
            'color': const Color(0xFFEF4444),
            'badge': '3',
          },
          {
            'icon': Icons.help_rounded,
            'title': AppTranslations.get('help', currentLang),
            'subtitle': 'الدعم والمساعدة',
            'color': const Color(0xFF7C3AED),
          },
        ];

        return Column(
          children: settingsItems
              .map((item) => _buildSettingsItem(context, item))
              .toList(),
        );
      },
    );
  }

  Widget _buildSettingsItem(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle settings navigation based on title
            String title = item['title'];
            if (title == 'إدارة المستخدمين') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsersManagementScreen(),
                ),
              );
            } else if (title == AppTranslations.get('settings', Provider.of<LanguageProvider>(context, listen: false).currentLanguage)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            } else if (title == AppTranslations.get('notifications', Provider.of<LanguageProvider>(context, listen: false).currentLanguage)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            } else if (title == AppTranslations.get('help', Provider.of<LanguageProvider>(context, listen: false).currentLanguage)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'], color: item['color'], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item['badge'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item['color'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item['badge'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLang = languageProvider.currentLanguage;
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Version Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.get('version', currentLang),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle logout
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppTranslations.get('logout', currentLang)),
                        content: Text(AppTranslations.get('logout_confirmation', currentLang)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppTranslations.get('cancel', currentLang)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Handle logout logic
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(AppTranslations.get('logout', currentLang)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(AppTranslations.get('logout', currentLang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
