import 'package:amrts_manager/core/imports.dart';
import 'edit_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'إدارة الفواتير',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'استيراد محلي'),
                Tab(text: 'استيراد خارجي'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesList(isLocal: true),
                _buildInvoicesList(isLocal: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInvoiceDialog,
        backgroundColor: const Color(0xFF667EEA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة فاتورة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInvoicesList({required bool isLocal}) {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        final invoices = isLocal
            ? provider.localInvoices
            : provider.foreignInvoices;

        if (invoices.isEmpty) {
          return _buildEmptyState(isLocal);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return InvoiceCard(
              invoice: invoice,
              onView: () => _viewInvoice(invoice),
              onEdit: () => _editInvoice(invoice),
              onPrint: () => _printInvoice(invoice),
              onDelete: () => _deleteInvoice(invoice),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isLocal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocal ? Icons.home_outlined : Icons.language_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد فواتير',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLocal
                ? 'لم يتم إنشاء أي فاتورة استيراد محلي بعد'
                : 'لم يتم إنشاء أي فاتورة استيراد خارجي بعد',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddInvoiceDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              isLocal ? 'إضافة فاتورة محلية' : 'إضافة فاتورة خارجية',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocal
                  ? Colors.green.shade600
                  : Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

void _showAddInvoiceDialog() {
  final isLocal = _tabController.index == 0;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddInvoiceDialog(isLocal: isLocal),
  ).then((result) {
    if (result == true) {
      // الانتقال إلى شاشة التحرير مع نوع الفاتورة المحدد
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmartDocumentScreen(
            isLocal: isLocal,
          ),
        ),
      );
    }
  });
}

void _editInvoice(InvoiceModel invoice) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SmartDocumentScreen(
        invoice: invoice,
        isLocal: invoice.isLocal, // تمرير نوع الفاتورة
      ),
    ),
  ).then((result) {
    // إذا عادت العملية بنجاح، يمكن إضافة أي منطق إضافي هنا
    if (result == true) {
      // تحديث الشاشة أو إظهار رسالة نجاح إضافية إذا لزم الأمر
      setState(() {
        // إعادة بناء الشاشة لإظهار التحديثات
      });
    }
  });
}

  void _viewInvoice(InvoiceModel invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('عرض تفاصيل الفاتورة: ${invoice.invoiceNumber}'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    // هنا يمكن الانتقال إلى شاشة عرض التفاصيل
  }

  void _printInvoice(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.print, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('طباعة الفاتورة'),
          ],
        ),
        content: Text('هل تريد طباعة الفاتورة رقم ${invoice.invoiceNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إرسال الفاتورة للطباعة'),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('طباعة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteInvoice(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف هذه الفاتورة؟'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رقم الفاتورة: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('العميل: ${invoice.clientName}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحذير: لا يمكن التراجع عن هذا الإجراء',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<InvoiceProvider>(
                context,
                listen: false,
              ).deleteInvoice(invoice.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الفاتورة بنجاح'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
