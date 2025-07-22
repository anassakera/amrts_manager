import 'package:amrts_manager/provider/document_provider.dart';
import 'package:amrts_manager/test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/language_provider.dart';
// import 'screens/home_screen.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => DocumentProvider()..loadSampleData(),
//       child: MaterialApp(
//         title: 'إدارة الوثائق الذكية',
//         theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
//         home: SmartDocumentScreen(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider()..loadSampleData(),
        ),
      ],
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
      home: SmartDocumentScreen(),
    );
  }
}
