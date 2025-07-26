import 'package:amrts_manager/core/imports.dart';
import '../screens/edit_invoice_screen.dart';

class AddInvoiceDialog extends StatefulWidget {
  final bool isLocal;

  const AddInvoiceDialog({super.key, required this.isLocal});

  @override
  State<AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends State<AddInvoiceDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _numberController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    // إنشاء رقم فاتورة تلقائي
    _generateInvoiceNumber();
  }

  void _generateInvoiceNumber() {
    final year = DateTime.now().year;
    final prefix = widget.isLocal ? 'LOC' : 'INT';
    final number = DateTime.now().millisecondsSinceEpoch % 1000;
    _numberController.text =
        '$prefix-$year-${number.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _clientController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان مع التدرج
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isLocal
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isLocal
                            ? Icons.home_outlined
                            : Icons.language_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة فاتورة جديدة',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.isLocal ? 'استيراد محلي' : 'استيراد خارجي',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // النموذج
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // حقل اسم العميل
                      _buildTextField(
                        controller: _clientController,
                        label: 'اسم العميل',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم العميل';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // حقل رقم الفاتورة
                      _buildTextField(
                        controller: _numberController,
                        label: 'رقم الفاتورة',
                        icon: Icons.numbers_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رقم الفاتورة';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // حقل التاريخ
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تاريخ الفاتورة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // أزرار الإجراءات
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _createInvoice,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.isLocal
                                    ? Colors.green.shade600
                                    : Colors.blue.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'إنشاء الفاتورة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.isLocal
                ? Colors.green.shade600
                : Colors.blue.shade600,
            width: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.isLocal
                  ? Colors.green.shade600
                  : Colors.blue.shade600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create the invoice
    final invoice = InvoiceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientName: _clientController.text,
      invoiceNumber: _numberController.text,
      date: _selectedDate,
      isLocal: widget.isLocal,
      summary: InvoiceSummary(
        factureNumber: _numberController.text,
        transit: 0.0,
        droitDouane: 0.0,
        chequeChange: 0.0,
        freiht: 0.0,
        autres: 0.0,
        total: 0.0,
        txChange: 1.0,
        poidsTotal: 0.0,
      ),
    );

    // Close the dialog first
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    
    // Wait for the next frame to ensure the dialog is closed
    await Future.delayed(Duration.zero);
    
    // Get the current scaffold messenger before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Navigate to the edit screen
    final result = await navigator.push(
      MaterialPageRoute(
        builder: (context) => SmartDocumentScreen(invoice: invoice),
      ),
    );
    
    if (result is! InvoiceModel) return;
    
    // Add the invoice to the provider
    final provider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    
    provider.addInvoice(result);
    
    // Show success message
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('تم إنشاء الفاتورة بنجاح'),
        backgroundColor: widget.isLocal ? Colors.green : Colors.blue,
      ),
    );
  }
}
