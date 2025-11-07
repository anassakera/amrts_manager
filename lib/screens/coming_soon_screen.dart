import '../core/imports.dart';

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  final List<Map<String, dynamic>> features = [
    {
      'icon': Icons.point_of_sale_outlined, // أو Icons.sell_outlined
      'title': 'المبيعات',
      'description': 'إدارة عمليات البيع بكفاءة وسهولة',
      'color': Colors.green,
      'comingSoon': false, // ✅ متوفر الآن
    },
    {
      'icon': Icons.shopping_cart_outlined, // أو Icons.shopping_bag_outlined
      'title': 'المشتريات',
      'description': 'تتبع وإدارة جميع مشترياتك بسلاسة',
      'color': Colors.purple,
      'comingSoon': false, // ✅ متوفر الآن
    },
    {
      'icon': Icons.dark_mode_outlined,
      'title': 'الوضع الليلي',
      'description': 'تجربة مريحة للعين في الإضاءة المنخفضة',
      'color': Colors.deepPurple,
      'comingSoon': true,
    },
    {
      'icon': Icons.notification_important_outlined,
      'title': 'الإشعارات الذكية',
      'description': 'ابقَ على اطلاع بكل جديد',
      'color': Colors.cyan,
      'comingSoon': true,
    },
    {
      'icon': Icons.cloud_sync_outlined,
      'title': 'المزامنة السحابية',
      'description': 'بياناتك آمنة ومتزامنة دائماً',
      'color': Colors.green,
      'comingSoon': true,
    },
    {
      'icon': Icons.phone_android_outlined,
      'title': 'تطبيق للهاتف',
      'description': 'استمتع بتجربة تطبيق الهاتف المحمول المثالية',
      'color': Colors.blue,
      'comingSoon': true,
    },
    {
      'icon': Icons.support_agent_outlined,
      'title': 'الاتصال السريع بالدعم',
      'description': 'تواصل مع الدعم الفني بسرعة وفعالية',
      'color': Colors.orange,
      'comingSoon': true,
    },
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
            onError: (exception, stackTrace) {
              // معالجة الخطأ
              // ignore: avoid_print
              print('فشل تحميل الصورة: $exception');
            },
          ),
        ),
        child: Stack(
          children: [
            // خلفية متحركة
            _buildAnimatedBackground(),

            // المحتوى الرئيسي
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // أيقونة الصاروخ المتحركة
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildRocketIcon(),
                          ),
                          const SizedBox(height: 32),

                          // العنوان الرئيسي
                          _buildMainTitle(),
                          const SizedBox(height: 16),

                          // النص التوضيحي
                          _buildSubtitle(),
                          const SizedBox(height: 48),

                          // قائمة المميزات
                          _buildFeaturesList(),
                          const SizedBox(height: 48),

                          // زر الإشعار
                          _buildNotifyButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: 100 + (50 * _rotateAnimation.value),
              right: 50,
              child: _buildFloatingCircle(
                100,
                Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              bottom: 150 + (30 * (1 - _rotateAnimation.value)),
              left: 30,
              child: _buildFloatingCircle(
                150,
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: 300 + (40 * _rotateAnimation.value),
              left: 100,
              child: _buildFloatingCircle(
                80,
                Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildRocketIcon() {
    return GlassContainer.clearGlass(
      height: 120,
      width: 120,
      borderRadius: BorderRadius.circular(30),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: const Icon(
          Icons.rocket_launch_rounded,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainTitle() {
    return GlassContainer(
      height: 80,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.2),
        ],
      ),
      blur: 20,
      borderWidth: 1.5,
      isFrostedGlass: true,
      child: const Center(
        child: Text(
          'مميزات قادمة قريباً',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'نعمل بجد لتقديم تجربة استثنائية لك',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.5,
      ),
    );
  }

  Widget _buildFeaturesList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> feature = features[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: _buildFeatureCard(feature),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.2),
        ],
      ),
      blur: 20,
      borderWidth: 1.5,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة الميزة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: feature['color'].withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(feature['icon'], size: 30, color: Colors.white),
            ),
            const SizedBox(height: 12),
            // عنوان الميزة
            Text(
              feature['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // وصف الميزة
            Text(
              feature['description'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feature['comingSoon'] == false ? '🎉' : 'قريباً',
                style: TextStyle(
                  fontSize: feature['comingSoon'] == false ? 45.0 : 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifyButton() {
    return GlassContainer(
      height: 60,
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.3),
        ],
      ),
      blur: 15,
      borderWidth: 2,
      elevation: 8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '🎉 سنخبرك عند إطلاق المميزات الجديدة 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                backgroundColor: Colors.green.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'أخبرني عند التوفر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
