import '../../core/imports.dart';
import 'dart:ui';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // // بيانات تجريبية للتطوير
    // _emailController.text = 'admin@amrts.com';
    // _passwordController.text = 'password';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiServices.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success'] == true) {
        // تخزين بيانات المستخدم
        // final userData = result['data'] as Map<String, dynamic>;
        // final user = userData['user'] as Map<String, dynamic>;
        // final token = userData['token'] as String;

        // يمكن إضافة SharedPreferences هنا لتخزين token وبيانات المستخدم
        // await SharedPreferences.getInstance().then((prefs) {
        //   prefs.setString('token', token);
        //   prefs.setString('user_data', json.encode(user));
        // });

        if (mounted) {
          // إظهار رسالة نجاح
          _showSuccessDialog('تم تسجيل الدخول بنجاح');

          // الانتقال إلى الشاشة الرئيسية
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(result['message'] ?? 'حدث خطأ في تسجيل الدخول');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'حدث خطأ في الاتصال';

        if (e.toString().contains('Invalid email or password')) {
          errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else if (e.toString().contains('Invalid email format')) {
          errorMessage = 'تنسيق البريد الإلكتروني غير صحيح';
        } else if (e.toString().contains('Email and password are required')) {
          errorMessage = 'البريد الإلكتروني وكلمة المرور مطلوبان';
        } else if (e.toString().contains('فشل في الاتصال بالخادم')) {
          errorMessage = 'فشل في الاتصال بالخادم. تأكد من اتصال الإنترنت';
        } else if (e.toString().contains('خطأ في تنسيق البيانات')) {
          errorMessage = 'خطأ في استقبال البيانات من الخادم';
        } else {
          errorMessage = 'حدث خطأ غير متوقع: $e';
        }

        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('نجح'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // أزرق داكن عميق
              Color(0xFF3B82F6), // أزرق متوسط
              Color(0xFF60A5FA), // أزرق فاتح
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? 80
                      : isTablet
                      ? 40
                      : 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        size.height - MediaQuery.of(context).padding.top - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(
                          height: isDesktop
                              ? 80
                              : isTablet
                              ? 60
                              : 40,
                        ),

                        // Logo and Title
                        _buildHeader(isDesktop, isTablet),

                        const Spacer(),

                        // Login Form Container
                        Center(
                          child: SizedBox(
                            width: isDesktop
                                ? 500
                                : isTablet
                                ? 450
                                : size.width * 0.9,
                            child: Column(
                              children: [
                                _buildLoginForm(isDesktop, isTablet),
                                const SizedBox(height: 32),
                                _buildSignInButton(isDesktop, isTablet),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Logo Container
        Container(
          width: isDesktop
              ? 140
              : isTablet
              ? 130
              : 120,
          height: isDesktop
              ? 140
              : isTablet
              ? 130
              : 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isDesktop ? 35 : 30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Icon(
            Icons.business_center,
            size: isDesktop
                ? 70
                : isTablet
                ? 65
                : 60,
            color: Colors.white,
          ),
        ),

        SizedBox(
          height: isDesktop
              ? 32
              : isTablet
              ? 28
              : 24,
        ),

        // Title
        Text(
          'AMRTS Manager',
          style: TextStyle(
            fontSize: isDesktop
                ? 40
                : isTablet
                ? 36
                : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(
          height: isDesktop
              ? 12
              : isTablet
              ? 10
              : 8,
        ),

        // Subtitle
        Text(
          'نظام إدارة المبيعات والمشتريات',
          style: TextStyle(
            fontSize: isDesktop
                ? 18
                : isTablet
                ? 17
                : 16,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDesktop, bool isTablet) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        isDesktop
            ? 28
            : isTablet
            ? 26
            : 24,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(
            isDesktop
                ? 40
                : isTablet
                ? 36
                : 32,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              isDesktop
                  ? 28
                  : isTablet
                  ? 26
                  : 24,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 28
                        : isTablet
                        ? 26
                        : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(
                  height: isDesktop
                      ? 40
                      : isTablet
                      ? 36
                      : 32,
                ),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),

                SizedBox(
                  height: isDesktop
                      ? 24
                      : isTablet
                      ? 22
                      : 20,
                ),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    required bool isDesktop,
    required bool isTablet,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: isDesktop
            ? 18
            : isTablet
            ? 17
            : 16,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: isDesktop
              ? 16
              : isTablet
              ? 15
              : 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isDesktop
                ? 22
                : isTablet
                ? 21
                : 20,
          ),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 16
                : isTablet
                ? 15
                : 12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 16
                : isTablet
                ? 15
                : 12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 16
                : isTablet
                ? 15
                : 12,
          ),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 16
                : isTablet
                ? 15
                : 12,
          ),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 16
                : isTablet
                ? 15
                : 12,
          ),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 20
              : isTablet
              ? 18
              : 16,
          vertical: isDesktop
              ? 20
              : isTablet
              ? 18
              : 16,
        ),
      ),
    );
  }

  Widget _buildSignInButton(bool isDesktop, bool isTablet) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        isDesktop
            ? 20
            : isTablet
            ? 18
            : 16,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: isDesktop
              ? 64
              : isTablet
              ? 60
              : 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : 16,
            ),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
              ),
              onTap: _isLoading ? null : _signIn,
              child: Container(
                alignment: Alignment.center,
                child: _isLoading
                    ? SizedBox(
                        width: isDesktop
                            ? 28
                            : isTablet
                            ? 26
                            : 24,
                        height: isDesktop
                            ? 28
                            : isTablet
                            ? 26
                            : 24,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login,
                            color: Colors.white,
                            size: isDesktop
                                ? 24
                                : isTablet
                                ? 22
                                : 20,
                          ),
                          SizedBox(
                            width: isDesktop
                                ? 12
                                : isTablet
                                ? 10
                                : 8,
                          ),
                          Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop
                                  ? 18
                                  : isTablet
                                  ? 17
                                  : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2024 AMRTS Manager. جميع الحقوق محفوظة',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
