import 'package:flutter/material.dart';

class FinancialTransactionsScreen extends StatefulWidget {
  const FinancialTransactionsScreen({super.key});

  @override
  State<FinancialTransactionsScreen> createState() =>
      _FinancialTransactionsScreenState();
}

class _FinancialTransactionsScreenState
    extends State<FinancialTransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Welcome to the Financial Transactions Screen!'),
      ),
    );
  }
}
