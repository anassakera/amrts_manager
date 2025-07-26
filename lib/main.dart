import 'package:amrts_manager/provider/document_provider.dart';
import 'package:amrts_manager/provider/invoice_provider.dart';
import 'package:amrts_manager/screens/invoices_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/language_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
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
      theme: ThemeData(fontFamily: 'Tajawal'),

      //home: SmartDocumentScreen(),
      home: const InvoicesScreen(),
    );
  }
}
