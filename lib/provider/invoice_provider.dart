// ignore_for_file: avoid_print

import 'package:amrts_manager/models/invoice_manage_model.dart';
import 'package:flutter/material.dart';

class InvoiceProvider extends ChangeNotifier {
  final List<InvoiceModel> _invoices = [
    InvoiceModel(
      id: '1',
      clientName: 'شركة التقنيات المتقدمة',
      invoiceNumber: 'INV-2024-001',
      date: DateTime.now().subtract(const Duration(days: 2)),
      isLocal: true,
      totalAmount: 15000.0,
      status: 'مكتملة',
      items: [], // إضافة قائمة فارغة للعناصر
      summary: InvoiceSummary(
        factureNumber: 'CI-SSA240103002,1',
        transit: 0,
        droitDouane: 0,
        chequeChange: 0,
        freiht: 0,
        autres: 0,
        total: 0,
        txChange: 0,
        poidsTotal: 0.0,
      ),
    ),
    InvoiceModel(
      id: '2',
      clientName: 'Global Tech Solutions',
      invoiceNumber: 'INV-2024-002',
      date: DateTime.now().subtract(const Duration(days: 5)),
      isLocal: false,
      totalAmount: 25000.0,
      status: 'في الانتظار',
      items: [], // إضافة قائمة فارغة للعناصر
      summary: InvoiceSummary(
        factureNumber: 'CI-SSA240103002,1',
        transit: 0,
        droitDouane: 0,
        chequeChange: 0,
        freiht: 0,
        autres: 0,
        total: 0,
        txChange: 0,
        poidsTotal: 0.0,
      ),
    ),
  ];

  List<InvoiceModel> get allInvoices => _invoices;

  List<InvoiceModel> get localInvoices =>
      _invoices.where((invoice) => invoice.isLocal).toList();

  List<InvoiceModel> get foreignInvoices =>
      _invoices.where((invoice) => !invoice.isLocal).toList();

  void addInvoice(InvoiceModel invoice) {
    print('🔥 محاولة إضافة فاتورة جديدة:');
    print('   - الرقم: ${invoice.invoiceNumber}');
    print('   - العميل: ${invoice.clientName}');
    print('   - عدد العناصر: ${invoice.items.length}');
    print('   - المبلغ الإجمالي: ${invoice.totalAmount}');
    print('   - محلي/خارجي: ${invoice.isLocal ? "محلي" : "خارجي"}');
    
    // التحقق من عدم وجود فاتورة بنفس الرقم
    if (_invoices.any((inv) => inv.invoiceNumber == invoice.invoiceNumber)) {
      print('❌ خطأ: رقم الفاتورة موجود مسبقاً');
      throw Exception('رقم الفاتورة موجود مسبقاً');
    }
    
    // إضافة الفاتورة في بداية القائمة
    _invoices.insert(0, invoice);
    print('✅ تم إضافة الفاتورة بنجاح');
    print('   - إجمالي الفواتير الآن: ${_invoices.length}');
    
    notifyListeners();
    print('🔔 تم إشعار المستمعين');
  }

  void deleteInvoice(String id) {
    print('🗑️ محاولة حذف فاتورة: $id');
    final removedCount = _invoices.length;
    _invoices.removeWhere((invoice) => invoice.id == id);
    print('   - تم حذف ${removedCount - _invoices.length} فاتورة');
    notifyListeners();
  }

  void updateInvoice(InvoiceModel updatedInvoice) {
    print('📝 محاولة تحديث فاتورة: ${updatedInvoice.id}');
    final index = _invoices.indexWhere(
      (invoice) => invoice.id == updatedInvoice.id,
    );
    if (index != -1) {
      _invoices[index] = updatedInvoice;
      print('✅ تم تحديث الفاتورة بنجاح في الموضع: $index');
      print('   - عدد العناصر المحدث: ${updatedInvoice.items.length}');
      notifyListeners();
    } else {
      print('❌ لم يتم العثور على الفاتورة للتحديث');
    }
  }
}