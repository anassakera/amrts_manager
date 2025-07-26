import 'package:amrts_manager/models/invoice_manage_model.dart';
import 'package:flutter/material.dart';

class InvoiceProvider extends ChangeNotifier {
  final List<InvoiceModel> _invoices = [];

  List<InvoiceModel> get allInvoices => _invoices;

  List<InvoiceModel> get localInvoices =>
      _invoices.where((invoice) => invoice.isLocal).toList();

  List<InvoiceModel> get foreignInvoices =>
      _invoices.where((invoice) => !invoice.isLocal).toList();

  void addInvoice(InvoiceModel invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();
  }

  void deleteInvoice(String id) {
    _invoices.removeWhere((invoice) => invoice.id == id);
    notifyListeners();
  }

  void updateInvoice(InvoiceModel updatedInvoice) {
    final index = _invoices.indexWhere(
      (invoice) => invoice.id == updatedInvoice.id,
    );
    if (index != -1) {
      _invoices[index] = updatedInvoice;
      notifyListeners();
    }
  }
}
