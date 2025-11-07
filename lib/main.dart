import '../core/imports.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await ApiServices.initBaseUrl();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800), // العرض × الارتفاع المطلوب
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: Size(1200, 800),
    maximumSize: Size(1920, 1080),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Tajawal'),
      // home: const AuthScreen(),
      // // home: const TestWidget(),
      // home: const UsersManagementScreen(),
      home: const HomeScreen(),
    );
  }
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  int _currentPaletteIndex = 0;
  final List<String> _texts = [
    'مرحباً بالعالم!',
    'أهلاً وسهلاً!',
    'Hello, World!',
  ];
  // 3 لوحات لونية مختلفة
  final List<List<Color>> _colorPalettes = [
    // اللوحة الأولى - الأزرق
    [
      Color(0xFF1E3A8A), // أزرق داكن عميق
      Color(0xFF3B82F6), // أزرق متوسط
      Color(0xFF60A5FA), // أزرق فاتح
    ],
    // اللوحة الثانية - البنفسجي
    [
      Color(0xFF581C87), // بنفسجي داكن
      Color(0xFF9333EA), // بنفسجي متوسط
      Color(0xFFA855F7), // بنفسجي فاتح
    ],
    // اللوحة الثالثة - الوردي والبرتقالي
    [
      Color(0xFFDB2777), // وردي داكن
      Color(0xFFF97316), // برتقالي
      Color(0xFFFBBF24), // أصفر ذهبي
    ],
  ];

  void _changeColors() {
    setState(() {
      _currentPaletteIndex = (_currentPaletteIndex + 1) % _colorPalettes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _buildContainer(),
                SizedBox(width: 5),
                _buildContainer(),
                SizedBox(width: 5),
                _buildContainer(),
              ],
            ),
            SizedBox(height: 20),
            _buildContainer(),
            SizedBox(height: 20),
            _buildContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer() {
    return GestureDetector(
      onTap: _changeColors,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        height: 200,
        width: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: _colorPalettes[_currentPaletteIndex],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            _texts[_currentPaletteIndex],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
