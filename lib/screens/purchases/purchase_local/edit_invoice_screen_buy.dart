// ignore_for_file: avoid_print
import '../../../core/imports.dart';
import 'api_services.dart';

class SmartDocumentScreenBuy extends StatefulWidget {
  final Map<String, dynamic>? invoice;
  final bool isLocal;
  final String? clientName;
  final String? invoiceNumber;
  final DateTime? date;

  const SmartDocumentScreenBuy({
    super.key,
    this.invoice,
    this.isLocal = true,
    this.clientName,
    this.invoiceNumber,
    this.date,
  });

  @override
  SmartDocumentScreenBuyState createState() => SmartDocumentScreenBuyState();
}

class SmartDocumentScreenBuyState extends State<SmartDocumentScreenBuy> {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CalculationService _calculationService = CalculationService();
  final PurchaseApiService _purchaseApiService = PurchaseApiService();

  // State moved from DocumentProvider
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _articles = [];
  Map<String, dynamic>? _selectedArticle;
  Map<String, dynamic> _summary = {
    'factureNumber':
        'CI-SSA${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().millisecond}',
    'transit': 0.0,
    'droitDouane': 0.0,
    'chequeChange': 0.0,
    'freiht': 0.0,
    'autres': 0.0,
    'txChange': 0.0,
    'poidsTotal': 0.0,
  };
  int? _editingIndex;
  List<int> _selectedIndices = [];
  bool get _hasSelection => _selectedIndices.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchArticles();
    if (widget.invoice != null) {
      _setFromInvoiceModel(widget.invoice!);
    } else {
      setState(() {
        if (widget.invoiceNumber != null) {
          _summary['factureNumber'] = widget.invoiceNumber!;
        }
      });
    }
  }

  Future<void> _fetchArticles() async {
    try {
      final fetchedArticles = await _purchaseApiService.getAllArticlesStock();
      if (!mounted) return;
      setState(() {
        _articles = fetchedArticles;
      });
    } catch (e) {
      if (!mounted) return;
      print('Error fetching articles: $e');
    }
  }

  bool _isAddingItem = false;
  // Methods moved from DocumentProvider
  void _addItem() {
    if (_isAddingItem) return;
    _isAddingItem = true;
    setState(() {
      _editingIndex = _items.length;
    });
    _isAddingItem = false;
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
    });
  }

  void _saveItem(int index, Map<String, dynamic> data) {
    setState(() {
      final filteredData = {
        'refFournisseur': data['refFournisseur'],
        'articles': data['articles'],
        'qte': data['qte'],
        'material_type': data['material_type'],
        'puPieces': data['puPieces'],
      };

      // التحقق من أن العنصر لا يحتوي على بيانات فارغة
      if (filteredData['refFournisseur'].toString().trim().isEmpty ||
          filteredData['articles'].toString().trim().isEmpty) {
        return;
      }

      // تحديث أو إضافة العنصر
      if (index < _items.length) {
        // تحديث عنصر موجود
        _items[index] = {...filteredData, 'isEditing': false};
      } else {
        // إضافة عنصر جديد فقط إذا لم يكن موجوداً بالفعل
        bool itemExists = _items.any(
          (item) =>
              item['refFournisseur'] == filteredData['refFournisseur'] &&
              item['articles'] == filteredData['articles'],
        );

        if (!itemExists) {
          _items.add({...filteredData, 'isEditing': false});
        }
      }

      _editingIndex = null;

      // إعادة حساب جميع العناصر في القائمة مع القيم الجديدة
      _recalculateAllItemsWithNewSummary(_summary);
      _recalculateSummary();
    });
  }

  void _cancelEditing(int index) {
    setState(() {
      if (index == _items.length) {
        _editingIndex = null;
      } else if (index < _items.length) {
        if ((_items[index]['refFournisseur'] as String).isEmpty) {
          _items.removeAt(index);
        }
        _editingIndex = null;
      }
      // إعادة تعيين المادة المحددة
      _selectedArticle = null;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      if (index < _items.length) {
        _items.removeAt(index);
        _recalculateSummary();
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIndices = List.generate(_items.length, (index) => index);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _deleteSelected() {
    setState(() {
      _selectedIndices.sort((a, b) => b.compareTo(a));
      for (int index in _selectedIndices) {
        if (index < _items.length) {
          _items.removeAt(index);
        }
      }
      _selectedIndices.clear();
      _recalculateSummary();
    });
  }

  void _recalculateAllItemsWithNewSummary(Map<String, dynamic> newSummary) {
    final totals = _calculationService.calculateTotals(_items, newSummary);
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;

    _items = _items.map((item) {
      final itemData = {
        'refFournisseur': item['refFournisseur'],
        'articles': item['articles'],
        'qte': item['qte'],
        'puPieces': item['puPieces'],
      };
      final calculated = _calculationService.calculateItemValues(
        itemData,
        totalMt: totalMt,
        poidsTotal: poidsTotal,
        grandTotal: 0.0,
      );
      // Preserve material_type as it's not used in calculations
      calculated['material_type'] = item['material_type'];
      return calculated;
    }).toList();
  }

  void _recalculateSummary() {
    final totals = _calculationService.calculateTotals(_items, _summary);
    final newSummary = Map<String, dynamic>.from(_summary);
    newSummary['poidsTotal'] = totals['poidsTotal'];
    _summary = newSummary;
  }

  void _reset() {
    setState(() {
      _items.clear();
      _selectedIndices.clear();
      _editingIndex = null;
      _summary = {
        'factureNumber':
            'CI-SSA${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().millisecond}',
        'transit': 0.0,
        'droitDouane': 0.0,
        'chequeChange': 0.0,
        'freiht': 0.0,
        'autres': 0.0,
        'poidsTotal': 0.0,
      };
    });
  }

  void _setFromInvoiceModel(Map<String, dynamic> model) {
    setState(() {
      _items = (model['items'] as List? ?? [])
          .map(
            (item) => Map<String, dynamic>.from(item as Map<String, dynamic>),
          )
          .toList();
      _summary = Map<String, dynamic>.from(
        model['summary'] as Map<String, dynamic>? ?? {},
      );
      _editingIndex = null;
      _selectedIndices.clear();

      if (model['clientName'] != null && widget.clientName == null) {
        // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
      }
    });
  }

  void _initializeControllers() {
    final fields = [
      'refFournisseur',
      'articles',
      'qte',
      'material_type',
      'puPieces',
      'mt',
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController();
    }

    _controllers['qte']?.addListener(_updateCalculatedFieldsWithService);
    _controllers['puPieces']?.addListener(_updateCalculatedFieldsWithService);
  }

  void _populateControllers(Map<String, dynamic> item) {
    // defaultExchangeRate parameter is intentionally unused
    // as it's part of the method signature for future use
    _controllers['refFournisseur']?.text = item['refFournisseur'].toString();
    _controllers['articles']?.text = item['articles'].toString();
    _controllers['qte']?.text = item['qte'].toString();
    _controllers['material_type']?.text =
        item['material_type']?.toString() ?? '';
    _controllers['puPieces']?.text = item['puPieces'].toString();
    _controllers['mt']?.text = item['mt'].toString();
  }

  void _clearControllers() {
    _controllers.forEach((key, controller) {
      controller.clear();
    });
    // إعادة تعيين المادة المحددة
    setState(() {
      _selectedArticle = null;
    });
  }

  Map<String, dynamic> _getFormData() {
    return {
      'refFournisseur': _controllers['refFournisseur']?.text ?? '',
      'articles': _controllers['articles']?.text ?? '',
      'qte': int.tryParse(_controllers['qte']?.text ?? '0') ?? 0,
      'material_type': _controllers['material_type']?.text ?? '',
      'puPieces': double.tryParse(_controllers['puPieces']?.text ?? '0') ?? 0.0,
    };
  }

  bool _isSaving = false;
  bool _hasSaved = false;
  void _saveInvoice() {
    if (_isSaving || _hasSaved) return;
    _isSaving = true;
    _hasSaved = true;

    if (_editingIndex != null) {
      _isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى حفظ العنصر قيد التعديل أولاً')),
      );
      return;
    }

    if (_items.isEmpty) {
      _isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حفظ فاتورة فارغة. يرجى إضافة عناصر أولاً'),
        ),
      );
      return;
    }

    final totalAmount = _calculateTotalAmount(_items);
    final clientName = _getClientName(_items, widget.clientName);
    final now = widget.date ?? DateTime.now();
    final formattedDate =
        '${now.day}/${now.month}/${now.year} | ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    Map<String, dynamic> resultInvoice;

    if (widget.invoice != null) {
      // تحديث فاتورة موجودة
      resultInvoice = Map<String, dynamic>.from(widget.invoice!);
      resultInvoice['items'] = List<Map<String, dynamic>>.from(_items);
      resultInvoice['summary'] = Map<String, dynamic>.from(_summary);
      resultInvoice['totalAmount'] = totalAmount;
      if (widget.invoice!['clientName'] != null &&
          widget.invoice!['clientName'].toString().isNotEmpty) {
        resultInvoice['clientName'] = widget.invoice!['clientName'];
      } else {
        resultInvoice['clientName'] = clientName;
      }
    } else {
      // إنشاء فاتورة جديدة
      resultInvoice = {
        'clientName': clientName,
        'invoiceNumber': widget.invoiceNumber ?? _summary['factureNumber'],
        'date': formattedDate,
        'isLocal': widget.isLocal,
        'totalAmount': totalAmount,
        'status': 'En cours',
        'items': List<Map<String, dynamic>>.from(_items),
        'summary': Map<String, dynamic>.from(_summary),
      };
    }

    _clearControllers();
    _reset();
    print(resultInvoice);

    // إرسال البيانات إلى purchases_screen.dart
    Navigator.of(context).pop(resultInvoice);
    _isSaving = false;
  }

  String _getClientName(
    List<Map<String, dynamic>> items,
    String? fallbackClientName,
  ) {
    if (widget.invoice != null && widget.invoice!['clientName'] != null) {
      final originalClientName = widget.invoice!['clientName'];
      if (originalClientName is String && originalClientName.isNotEmpty) {
        return originalClientName;
      }
    }

    if (fallbackClientName != null && fallbackClientName.isNotEmpty) {
      return fallbackClientName;
    }

    for (var item in items) {
      final name = item['clientName'];
      if (name is String && name.isNotEmpty) {
        return name;
      }
    }

    return 'عميل غير محدد';
  }

  double _calculateTotalAmount(List<Map<String, dynamic>> items) {
    double itemsTotal = items.fold(
      0.0,
      (sum, item) => sum + _safeParseDouble(item['mt']),
    );
    return itemsTotal;
  }

  @override
  void dispose() {
    _controllers['qte']?.removeListener(_updateCalculatedFieldsWithService);
    _controllers['puPieces']?.removeListener(
      _updateCalculatedFieldsWithService,
    );
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculationService.calculateTotals(_items, _summary);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
        child: Column(
          children: [
            _buildSmartHeader(totals),
            Expanded(child: _buildSmartTable()),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // Common Widget Functions
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color hoverColor,
    required Color pressedColor,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.073,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              animationDuration: const Duration(milliseconds: 200),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.pressed)) return pressedColor;
                if (states.contains(WidgetState.hovered)) return hoverColor;
                return color;
              }),
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipButton({
    required String tooltip,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String title, {
    int flex = 1,
    bool showDivider = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _buildEditField(
    String key,
    String hint, {
    int flex = 1,
    bool isNumber = false,
    bool isDecimal = false,
    bool readOnly = false,
  }) {
    final focusNode = FocusNode();
    bool isFocused = false;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: StatefulBuilder(
          builder: (context, setState) {
            focusNode.addListener(() {
              setState(() {
                isFocused = focusNode.hasFocus;
              });
            });
            // make shure to fix this la
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isFocused
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                        : Colors.grey.withValues(alpha: 0.15),
                    spreadRadius: isFocused ? 2 : 1,
                    blurRadius: isFocused ? 8 : 4,
                    offset: Offset(0, isFocused ? 4 : 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _controllers[key],
                focusNode: focusNode,
                readOnly: readOnly,
                keyboardType: isNumber
                    ? (isDecimal
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number)
                    : TextInputType.text,
                style: TextStyle(
                  fontSize: 15,
                  color: readOnly ? Colors.grey[700] : Colors.black87,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: isNumber
                    ? [
                        isDecimal
                            ? FilteringTextInputFormatter.allow(
                                RegExp(r'^[0-9]*\.?[0-9]*'),
                              )
                            : FilteringTextInputFormatter.digitsOnly,
                      ]
                    : [],
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: readOnly
                      ? Colors.grey[100]
                      : (isFocused ? Colors.white : Colors.grey[50]),
                  errorStyle: const TextStyle(fontSize: 11, height: 0.5),
                ),
                validator: (value) {
                  if (!readOnly && (value == null || value.isEmpty)) {
                    return AppTranslations.get(
                      'required',
                      Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).currentLanguage,
                    );
                  }
                  if (isNumber && value != null && value.isNotEmpty) {
                    if (isDecimal) {
                      if (double.tryParse(value) == null) {
                        return AppTranslations.get(
                          'invalid_number',
                          Provider.of<LanguageProvider>(
                            context,
                            listen: false,
                          ).currentLanguage,
                        );
                      }
                    } else {
                      if (int.tryParse(value) == null) {
                        return AppTranslations.get(
                          'integer_only',
                          Provider.of<LanguageProvider>(
                            context,
                            listen: false,
                          ).currentLanguage,
                        );
                      }
                    }
                  }
                  return null;
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _verticalDivider({double? height}) {
    return Container(
      width: 1,
      height: height ?? double.infinity,
      color: const Color(0xFFE5E7EB),
    );
  }

  void _updateCalculatedFieldsWithService() {
    final data = _getFormData();

    // Prepare data for calculation (exclude material_type as it's text-only)
    final calculationData = {
      'refFournisseur': data['refFournisseur'],
      'articles': data['articles'],
      'qte': data['qte'],
      'puPieces': data['puPieces'],
    };

    List<Map<String, dynamic>> tempItems = _items
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (_editingIndex != null && _editingIndex! < _items.length) {
      //
    } else {
      tempItems.add(calculationData);
    }

    final totals = _calculationService.calculateTotals(tempItems, _summary);
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final calculated = _calculationService.calculateItemValues(
      calculationData,
      totalMt: totalMt,
      poidsTotal: poidsTotal,
      grandTotal: 0.0,
    );
    _controllers['mt']?.text = calculated['mt'].toString();
  }

  Widget _buildSmartHeader(Map<String, double> totals) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF1F5F9), Color(0xFFE0E7EF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.10),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.get(
                                    'smart_invoice',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E3A8A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppTranslations.get('number', Provider.of<LanguageProvider>(context, listen: true).currentLanguage)}: ${_summary['factureNumber']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getClientName(_items, widget.clientName),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getFormattedDate(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.cancel_rounded,
                      label: AppTranslations.get(
                        'cancel',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: false,
                        ).currentLanguage,
                      ),
                      color: const Color(0xFFE57373),
                      hoverColor: const Color(0xFFEF5350),
                      pressedColor: const Color(0xFFEF9A9A),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      onPressed: _saveInvoice,
                      icon: Icons.save_rounded,
                      label: AppTranslations.get(
                        'save',
                        Provider.of<LanguageProvider>(
                          context,
                          listen: false,
                        ).currentLanguage,
                      ),
                      color: const Color(0xFF66BB6A),
                      hoverColor: const Color(0xFF4CAF50),
                      pressedColor: const Color(0xFF81C784),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.inventory,
                          label: AppTranslations.get(
                            'items_count',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value: _items.length.toString(),
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.scale,
                          label: AppTranslations.get(
                            'total_weight',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value:
                              '${totals['poidsTotal']?.toStringAsFixed(0) ?? '0'} Kg',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.inventory,
                          label: AppTranslations.get(
                            'goods_total',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value: _calculationService.formatCurrency(
                            totals['totalMt'] ?? 0,
                          ),
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF64748B,
                                ).withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildTooltipButton(
                                  tooltip: AppTranslations.get(
                                    'select_all',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  onTap: _selectAll,
                                  icon: Icons.select_all_rounded,
                                  color: const Color(0xFF8B5CF6),
                                ),
                                _buildTooltipButton(
                                  tooltip: AppTranslations.get(
                                    'add_new',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  onTap: () {
                                    _addItem();
                                    _clearControllers();
                                  },
                                  icon: Icons.add_circle_outline_rounded,
                                  color: const Color(0xFF10B981),
                                ),
                                if (_hasSelection)
                                  _buildTooltipButton(
                                    tooltip: AppTranslations.get(
                                      'delete_selected',
                                      Provider.of<LanguageProvider>(
                                        context,
                                        listen: true,
                                      ).currentLanguage,
                                    ),
                                    onTap: () =>
                                        _showDeleteConfirmation(context),
                                    icon: Icons.delete_sweep_rounded,
                                    color: const Color(0xFFEF4444),
                                  ),
                                if (_hasSelection)
                                  _buildTooltipButton(
                                    tooltip: AppTranslations.get(
                                      'clear_selection',
                                      Provider.of<LanguageProvider>(
                                        context,
                                        listen: true,
                                      ).currentLanguage,
                                    ),
                                    onTap: _clearSelection,
                                    icon: Icons.clear_all_rounded,
                                    color: const Color(0xFF6B7280),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartTable() {
    final isAddingNew = _editingIndex == _items.length;
    final itemCount = _items.length + (isAddingNew ? 1 : 0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (isAddingNew) {
                  if (index == 0) {
                    return _buildEditRow(_items.length);
                  } else {
                    return _buildTableRow(_items[index - 1], index - 1);
                  }
                } else {
                  return _buildTableRow(_items[index], index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30),
          _buildHeaderCell(
            AppTranslations.get(
              'supplier_ref',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
            showDivider: true,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'article',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'quantity',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 1,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'Type',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'unit_price',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'total_amount',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 2,
          ),
          _verticalDivider(height: 28),
          _buildHeaderCell(
            AppTranslations.get(
              'actions',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            flex: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, int index) {
    final isSelected = _selectedIndices.contains(index);
    final isEditing = _editingIndex == index;

    if (isEditing) {
      return _buildEditRow(index);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF60A5FA).withValues(alpha: 0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF3B82F6), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => _toggleSelection(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              InkWell(
                onTap: () => _toggleSelection(index),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF60A5FA),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              _buildDataCell(item['refFournisseur'].toString(), flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(item['articles'].toString(), flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatQuantity(_safeParseInt(item['qte'])),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['material_type']?.toString() ?? '', flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(
                  _safeParseDouble(item['puPieces']),
                ),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(
                  _safeParseDouble(item['mt']),
                ),
                flex: 2,
              ),
              const SizedBox(width: 45),
              SizedBox(
                width: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionIconButton(
                      icon: Icons.edit,
                      onPressed: () {
                        _startEditing(index);
                        _populateControllers(item);
                      },
                      color: const Color(0xFF3B82F6),
                    ),
                    _buildActionIconButton(
                      icon: Icons.delete_outline,
                      onPressed: () =>
                          _showDeleteSingleConfirmation(context, index),
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditRow(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            const SizedBox(width: 20),
            _buildEditField(
              'refFournisseur',
              AppTranslations.get(
                'supplier_ref',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              readOnly: true,
            ),
            _verticalDivider(height: 28),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SearchableDropdownT<Map<String, dynamic>>(
                  items: _articles,
                  displayText: (article) => article['material_name'] ?? '',
                  selectedValue: _selectedArticle,
                  onChanged: (article) {
                    setState(() {
                      _selectedArticle = article;
                      if (article != null) {
                        _controllers['articles']?.text =
                            article['material_name'] ?? '';
                        // Auto-populate ref_code
                        _controllers['refFournisseur']?.text =
                            article['ref_code'] ?? '';
                        // Auto-populate unit_price
                        _controllers['puPieces']?.text =
                            article['unit_price']?.toString() ?? '';
                        // Auto-populate material_type
                        _controllers['material_type']?.text =
                            article['material_type']?.toString() ?? '';
                      } else {
                        _controllers['articles']?.clear();
                        _controllers['refFournisseur']?.clear();
                        _controllers['puPieces']?.clear();
                        _controllers['material_type']?.clear();
                      }
                    });
                  },
                  hintText: AppTranslations.get(
                    'article',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).currentLanguage,
                  ),
                  onPrefixIconTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ArticlesStockCrudScreen(),
                      ),
                    );
                  },
                  searchHint: 'بحث...',
                  noResultsText: 'لا توجد نتائج',
                  loadingText: 'جاري التحميل...',
                  isLoading: _articles.isEmpty,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  primaryColor: Colors.blue,
                  enabled: true,
                ),
              ),
            ),

            _verticalDivider(height: 28),
            _buildEditField(
              'qte',
              AppTranslations.get(
                'quantity',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 1,
              isNumber: true,
              isDecimal: false,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'material_type',
              AppTranslations.get(
                'material_type',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              readOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'puPieces',
              AppTranslations.get(
                'unit_price',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'mt',
              AppTranslations.get(
                'total_amount',
                Provider.of<LanguageProvider>(
                  context,
                  listen: true,
                ).currentLanguage,
              ),
              flex: 2,
              isNumber: true,
              isDecimal: true,
              readOnly: true,
            ),
            const SizedBox(width: 30),
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  _buildActionIconButton(
                    icon: Icons.save,
                    onPressed: () {
                      // التحقق من اختيار المادة أولاً
                      if (_selectedArticle == null ||
                          _controllers['articles']?.text.isEmpty == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء اختيار مادة'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      if (_formKey.currentState?.validate() ?? false) {
                        _saveItem(index, _getFormData());
                        _clearControllers();
                      }
                    },
                    color: const Color(0xFF1E3A8A),
                  ),
                  _buildActionIconButton(
                    icon: Icons.close,
                    onPressed: () {
                      _cancelEditing(index);
                      _clearControllers();
                    },
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppTranslations.get(
              'confirm_delete',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          content: Text(
            '${AppTranslations.get('delete_selected_items', Provider.of<LanguageProvider>(context, listen: true).currentLanguage)} (${_selectedIndices.length})؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppTranslations.get(
                  'cancel',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSelected();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                AppTranslations.get(
                  'delete',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSingleConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppTranslations.get(
              'confirm_delete',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          content: Text(
            AppTranslations.get(
              'delete_this_item',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppTranslations.get(
                  'cancel',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteItem(index);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                AppTranslations.get(
                  'delete',
                  Provider.of<LanguageProvider>(
                    context,
                    listen: true,
                  ).currentLanguage,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFormattedDate() {
    if (widget.invoice != null && widget.invoice!['date'] is String) {
      return widget.invoice!['date'];
    }
    final dateToFormat = widget.date ?? DateTime.now();
    return "${dateToFormat.day}/${dateToFormat.month.toString().padLeft(2, '0')}/${dateToFormat.year} | ${dateToFormat.hour}:${dateToFormat.minute.toString().padLeft(2, '0')}";
  }

  // دالة مساعدة لتحويل البيانات إلى double بشكل آمن
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  // دالة مساعدة لتحويل البيانات إلى int بشكل آمن
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
