// ignore_for_file: avoid_print
import '../core/imports.dart';

class SmartDocumentScreen extends StatefulWidget {
  final Map<String, dynamic>? invoice;
  final bool isLocal;
  final String? clientName;
  final String? invoiceNumber;
  final DateTime? date;

  const SmartDocumentScreen({
    super.key,
    this.invoice,
    this.isLocal = true,
    this.clientName,
    this.invoiceNumber,
    this.date,
  });

  @override
  SmartDocumentScreenState createState() => SmartDocumentScreenState();
}

class SmartDocumentScreenState extends State<SmartDocumentScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CalculationService _calculationService = CalculationService();
  late TabController _tabController;

  // State moved from DocumentProvider
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _summary = {
    'factureNumber':
        'CI-SSA${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().millisecond}',
    'transit': 0.0,
    'droitDouane': 0.0,
    'chequeChange': 0.0,
    'freiht': 0.0,
    'autres': 0.0,
    'total': 0.0,
    'txChange': 0.0,
    'poidsTotal': 0.0,
  };
  int? _editingIndex;
  List<int> _selectedIndices = [];
  bool get _hasSelection => _selectedIndices.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
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
        'poids': data['poids'],
        'puPieces': data['puPieces'],
        'exchangeRate': data['exchangeRate'],
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

  void _updateSummaryField(String field, double value) {
    setState(() {
      final newSummary = Map<String, dynamic>.from(_summary);
      switch (field) {
        case 'النقل':
          newSummary['transit'] = value;
          break;
        case 'حق الجمرك':
          newSummary['droitDouane'] = value;
          break;
        case 'شيك الصرف':
          newSummary['chequeChange'] = value;
          break;
        case 'الشحن':
          newSummary['freiht'] = value;
          break;
        case 'أخرى':
          newSummary['autres'] = value;
          break;
        case 'سعر الصرف':
          newSummary['txChange'] = value;
          break;
      }
      _summary = newSummary;

      // إعادة حساب جميع العناصر مع القيم الجديدة
      _recalculateAllItemsWithNewSummary(newSummary);
      _recalculateSummary();
    });
  }

  void _recalculateAllItemsWithNewSummary(Map<String, dynamic> newSummary) {
    final totals = _calculationService.calculateTotals(_items, newSummary);
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final grandTotal = totals['total'] ?? 0.0;

    _items = _items.map((item) {
      final itemData = {
        'refFournisseur': item['refFournisseur'],
        'articles': item['articles'],
        'qte': item['qte'],
        'poids': item['poids'],
        'puPieces': item['puPieces'],
        'exchangeRate': _safeParseDouble(newSummary['txChange']),
      };
      return _calculationService.calculateItemValues(
        itemData,
        totalMt: totalMt,
        poidsTotal: poidsTotal,
        grandTotal: grandTotal,
      );
    }).toList();
  }

  void _recalculateSummary() {
    final totals = _calculationService.calculateTotals(_items, _summary);
    final newSummary = Map<String, dynamic>.from(_summary);
    newSummary['total'] = totals['total'];
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
        'total': 0.0,
        'txChange': 0.0,
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
      'poids',
      'puPieces',
      'mt',
      'prixAchat',
      'autresCharges',
      'cuHt',
      'exchangeRate',
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController();
    }

    _controllers['qte']?.addListener(_updateCalculatedFieldsWithService);
    _controllers['poids']?.addListener(_updateCalculatedFieldsWithService);
    _controllers['puPieces']?.addListener(_updateCalculatedFieldsWithService);
    _controllers['exchangeRate']?.addListener(
      _updateCalculatedFieldsWithService,
    );
  }

  void _populateControllers(
    Map<String, dynamic> item, {
    double? defaultExchangeRate,
  }) {
    _controllers['refFournisseur']?.text = item['refFournisseur'].toString();
    _controllers['articles']?.text = item['articles'].toString();
    _controllers['qte']?.text = item['qte'].toString();
    _controllers['poids']?.text = item['poids'].toString();
    _controllers['puPieces']?.text = item['puPieces'].toString();
    _controllers['mt']?.text = item['mt'].toString();
    _controllers['prixAchat']?.text = item['prixAchat'].toString();
    _controllers['autresCharges']?.text = item['autresCharges'].toString();
    _controllers['cuHt']?.text = item['cuHt'].toString();
    final exchangeRate = _safeParseDouble(item['exchangeRate']);
    if ((exchangeRate == 1.0 || exchangeRate == 0.0) &&
        defaultExchangeRate != null) {
      _controllers['exchangeRate']?.text = defaultExchangeRate.toString();
    } else {
      _controllers['exchangeRate']?.text = exchangeRate.toString();
    }
  }

  void _clearControllers() {
    _controllers.forEach((key, controller) {
      controller.clear();
    });
  }

  Map<String, dynamic> _getFormData() {
    return {
      'refFournisseur': _controllers['refFournisseur']?.text ?? '',
      'articles': _controllers['articles']?.text ?? '',
      'qte': int.tryParse(_controllers['qte']?.text ?? '0') ?? 0,
      'poids': double.tryParse(_controllers['poids']?.text ?? '0') ?? 0.0,
      'puPieces': double.tryParse(_controllers['puPieces']?.text ?? '0') ?? 0.0,
      'exchangeRate':
          double.tryParse(_controllers['exchangeRate']?.text.trim() ?? '') ??
          1.0,
    };
  }

  bool _isSaving = false;

  void _saveInvoice() {
    print('Attempting to save invoicesss...');
    if (_isSaving) return;
    _isSaving = true;

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
    _tabController.dispose();
    _controllers['qte']?.removeListener(_updateCalculatedFieldsWithService);
    _controllers['poids']?.removeListener(_updateCalculatedFieldsWithService);
    _controllers['puPieces']?.removeListener(
      _updateCalculatedFieldsWithService,
    );
    _controllers['exchangeRate']?.removeListener(
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
    // final isDesktop = MediaQuery.of(context).size.width > 768;

    // if (isDesktop) {
    if (1 == 1) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          child: Column(
            children: [
              _buildSmartHeader(totals),
              Expanded(child: _buildSmartTable()),
              _buildSummaryFooter(totals),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: _buildPhoneAppBar(),
        body: Column(
          children: [
            _buildPhoneHeader(totals),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPhoneItemsTab(),
                  _buildPhoneSummaryTab(totals),
                  _buildPhoneActionsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildPhoneFloatingActionButton(),
      );
    }
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
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: _controllers[key],
            readOnly: readOnly,
            keyboardType: isNumber
                ? (isDecimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number)
                : TextInputType.text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
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
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              filled: true,
              fillColor: Colors.white,
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
    List<Map<String, dynamic>> tempItems = _items
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (_editingIndex != null && _editingIndex! < _items.length) {
      //
    } else {
      tempItems.add(data);
    }

    final totals = _calculationService.calculateTotals(tempItems, _summary);
    final totalMt = totals['totalMt'] ?? 0.0;
    final poidsTotal = totals['poidsTotal'] ?? 0.0;
    final grandTotal = totals['total'] ?? 0.0;
    final calculated = _calculationService.calculateItemValues(
      data,
      totalMt: totalMt,
      poidsTotal: poidsTotal,
      grandTotal: grandTotal,
    );
    _controllers['mt']?.text = calculated['mt'].toString();
    _controllers['prixAchat']?.text = calculated['prixAchat'].toString();
    _controllers['autresCharges']?.text = calculated['autresCharges']
        .toString();
    _controllers['cuHt']?.text = calculated['cuHt'].toString();
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
                      onPressed: () {
                        _saveInvoice();
                      },
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
                          icon: Icons.attach_money,
                          label: AppTranslations.get(
                            'total_expenses',
                            Provider.of<LanguageProvider>(
                              context,
                              listen: true,
                            ).currentLanguage,
                          ),
                          value: totals['total']?.toStringAsFixed(2) ?? '0.00',
                          color: const Color(0xFFF59E0B),
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
              'weight',
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
              'purchase_price',
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
              'other_expenses',
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
              'item_cost',
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
              const SizedBox(width: 5),
              _buildDataCell(item['refFournisseur'].toString(), flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(item['articles'].toString(), flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatQuantity(_safeParseInt(item['qte'])),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatWeight(
                  _safeParseDouble(item['poids']),
                ),
                flex: 2,
              ),
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
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(
                  _safeParseDouble(item['prixAchat']),
                ),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(
                  _safeParseDouble(item['autresCharges']),
                ),
                flex: 2,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _calculationService.formatCurrency(
                  _safeParseDouble(item['cuHt']),
                ),
                flex: 2,
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditRow(int index) {
    final exchangeRateFromSummary = _safeParseDouble(_summary['txChange']);
    final isNew = index == _items.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isNew || (_controllers['exchangeRate']?.text.isEmpty ?? true)) {
        _controllers['exchangeRate']?.text = exchangeRateFromSummary.toString();
      }
    });
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
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'articles',
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
              'poids',
              AppTranslations.get(
                'weight',
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
            _verticalDivider(height: 28),
            _buildEditField(
              'prixAchat',
              AppTranslations.get(
                'purchase_price',
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
            _verticalDivider(height: 28),
            _buildEditField(
              'autresCharges',
              AppTranslations.get(
                'other_expenses',
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
            _verticalDivider(height: 28),
            _buildEditField(
              'cuHt',
              AppTranslations.get(
                'item_cost',
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
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  _buildActionIconButton(
                    icon: Icons.save,
                    onPressed: () {
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryFooter(Map<String, double> totals) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [Expanded(child: _buildSummaryGrid())]),
    );
  }

  Widget _buildSummaryGrid() {
    final editingField = ValueNotifier<String?>(null);
    return StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.get(
              'expense_details',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: EditableSummaryItem(
                  label: AppTranslations.get(
                    'transit',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: true,
                    ).currentLanguage,
                  ),
                  value: _safeParseDouble(_summary['transit']),
                  icon: Icons.local_shipping,
                  calculationService: _calculationService,
                  isEditing: editingField.value == 'النقل',
                  onEdit: () => setState(() => editingField.value = 'النقل'),
                  onValueChanged: (v) {
                    _updateSummaryField('النقل', v);
                    setState(() => editingField.value = null);
                  },
                  onCancel: () => setState(() => editingField.value = null),
                ),
              ),
              Expanded(
                child: EditableSummaryItem(
                  label: AppTranslations.get(
                    'customs',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: true,
                    ).currentLanguage,
                  ),
                  value: _safeParseDouble(_summary['droitDouane']),
                  icon: Icons.account_balance,
                  calculationService: _calculationService,
                  isEditing: editingField.value == 'حق الجمرك',
                  onEdit: () =>
                      setState(() => editingField.value = 'حق الجمرك'),
                  onValueChanged: (v) {
                    _updateSummaryField('حق الجمرك', v);
                    setState(() => editingField.value = null);
                  },
                  onCancel: () => setState(() => editingField.value = null),
                ),
              ),
              Expanded(
                child: EditableSummaryItem(
                  label: AppTranslations.get(
                    'exchange_cheque',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: true,
                    ).currentLanguage,
                  ),
                  value: _safeParseDouble(_summary['chequeChange']),
                  icon: Icons.money,
                  calculationService: _calculationService,
                  isEditing: editingField.value == 'شيك الصرف',
                  onEdit: () =>
                      setState(() => editingField.value = 'شيك الصرف'),
                  onValueChanged: (v) {
                    _updateSummaryField('شيك الصرف', v);
                    setState(() => editingField.value = null);
                  },
                  onCancel: () => setState(() => editingField.value = null),
                ),
              ),
              Expanded(
                child: EditableSummaryItem(
                  label: AppTranslations.get(
                    'freight',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: true,
                    ).currentLanguage,
                  ),
                  value: _safeParseDouble(_summary['freiht']),
                  icon: Icons.flight_takeoff,
                  calculationService: _calculationService,
                  isEditing: editingField.value == 'الشحن',
                  onEdit: () => setState(() => editingField.value = 'الشحن'),
                  onValueChanged: (v) {
                    _updateSummaryField('الشحن', v);
                    setState(() => editingField.value = null);
                  },
                  onCancel: () => setState(() => editingField.value = null),
                ),
              ),
              Expanded(
                child: EditableSummaryItem(
                  label: AppTranslations.get(
                    'other',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: true,
                    ).currentLanguage,
                  ),
                  value: _safeParseDouble(_summary['autres']),
                  icon: Icons.more_horiz,
                  calculationService: _calculationService,
                  isEditing: editingField.value == 'أخرى',
                  onEdit: () => setState(() => editingField.value = 'أخرى'),
                  onValueChanged: (v) {
                    _updateSummaryField('أخرى', v);
                    setState(() => editingField.value = null);
                  },
                  onCancel: () => setState(() => editingField.value = null),
                ),
              ),
              Expanded(
                child: EditableSummaryItem(
                  label: AppTranslations.get(
                    'exchange_rate',
                    Provider.of<LanguageProvider>(
                      context,
                      listen: true,
                    ).currentLanguage,
                  ),
                  value: _safeParseDouble(_summary['txChange']),
                  isCurrency: false,
                  icon: Icons.currency_exchange,
                  calculationService: _calculationService,
                  isEditing: editingField.value == 'سعر الصرف',
                  onEdit: () =>
                      setState(() => editingField.value = 'سعر الصرف'),
                  onValueChanged: (v) {
                    _updateSummaryField('سعر الصرف', v);
                    if (_controllers['exchangeRate'] != null) {
                      _controllers['exchangeRate']?.text = v.toString();
                    }
                    setState(() => editingField.value = null);
                  },
                  onCancel: () => setState(() => editingField.value = null),
                ),
              ),
            ],
          ),
        ],
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

  // Phone Design Methods
  PreferredSizeWidget _buildPhoneAppBar() {
    return AppBar(
      title: Text(
        AppTranslations.get(
          'smart_invoice',
          Provider.of<LanguageProvider>(context, listen: true).currentLanguage,
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(
            icon: const Icon(Icons.list),
            text: AppTranslations.get(
              'items',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          Tab(
            icon: const Icon(Icons.calculate),
            text: AppTranslations.get(
              'summary',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
          Tab(
            icon: const Icon(Icons.settings),
            text: AppTranslations.get(
              'actions',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: _saveInvoice),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildPhoneHeader(Map<String, double> totals) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPhoneInfoChip(
                  Icons.confirmation_number,
                  'رقم الفاتورة',
                  _summary['factureNumber'],
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPhoneInfoChip(
                  Icons.person,
                  'العميل',
                  _getClientName(_items, widget.clientName),
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPhoneInfoChip(
                  Icons.inventory,
                  'العناصر',
                  _items.length.toString(),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPhoneInfoChip(
                  Icons.attach_money,
                  'المجموع',
                  _calculationService.formatCurrency(totals['total'] ?? 0),
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneItemsTab() {
    return Column(
      children: [
        if (_editingIndex != null) _buildPhoneEditForm(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _buildPhoneItemCard(_items[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneEditForm() {
    final exchangeRateFromSummary = _safeParseDouble(_summary['txChange']);
    final isNew = _editingIndex == _items.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isNew || (_controllers['exchangeRate']?.text.isEmpty ?? true)) {
        _controllers['exchangeRate']?.text = exchangeRateFromSummary.toString();
      }
    });

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'إضافة عنصر جديد' : 'تعديل العنصر',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPhoneEditField(
              'refFournisseur',
              'مرجع المورد',
              isNumber: false,
            ),
            const SizedBox(height: 8),
            _buildPhoneEditField('articles', 'السلعة', isNumber: false),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPhoneEditField(
                    'qte',
                    'الكمية',
                    isNumber: true,
                    isDecimal: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhoneEditField(
                    'poids',
                    'الوزن',
                    isNumber: true,
                    isDecimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPhoneEditField(
                    'puPieces',
                    'سعر الوحدة',
                    isNumber: true,
                    isDecimal: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhoneEditField(
                    'exchangeRate',
                    'سعر الصرف',
                    isNumber: true,
                    isDecimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('Item saved');
                      if (_formKey.currentState?.validate() ?? false) {
                        _saveItem(_editingIndex!, _getFormData());
                        _clearControllers();
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _cancelEditing(_editingIndex!);
                      _clearControllers();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('إلغاء'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneEditField(
    String key,
    String label, {
    bool isNumber = false,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: isNumber
          ? (isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (isNumber && isDecimal) {
          if (double.tryParse(value) == null) {
            return 'يجب إدخال رقم صحيح';
          }
        } else if (isNumber) {
          if (int.tryParse(value) == null) {
            return 'يجب إدخال رقم صحيح';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPhoneItemCard(Map<String, dynamic> item, int index) {
    final isSelected = _selectedIndices.contains(index);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () => _toggleSelection(index),
        onLongPress: () {
          _startEditing(index);
          _populateControllers(item);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleSelection(index),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['refFournisseur'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item['articles'].toString(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: const Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: const Text('حذف')),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _startEditing(index);
                        _populateControllers(item);
                      } else if (value == 'delete') {
                        _showDeleteSingleConfirmation(context, index);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPhoneItemDetail(
                      'الكمية',
                      _calculationService.formatQuantity(
                        _safeParseInt(item['qte']),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildPhoneItemDetail(
                      'الوزن',
                      _calculationService.formatWeight(
                        _safeParseDouble(item['poids']),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildPhoneItemDetail(
                      'السعر',
                      _calculationService.formatCurrency(
                        _safeParseDouble(item['puPieces']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPhoneItemDetail(
                      'المجموع',
                      _calculationService.formatCurrency(
                        _safeParseDouble(item['mt']),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildPhoneItemDetail(
                      'سعر الشراء',
                      _calculationService.formatCurrency(
                        _safeParseDouble(item['prixAchat']),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildPhoneItemDetail(
                      'المصاريف',
                      _calculationService.formatCurrency(
                        _safeParseDouble(item['autresCharges']),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneItemDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPhoneSummaryTab(Map<String, double> totals) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.get(
              'expense_details',
              Provider.of<LanguageProvider>(
                context,
                listen: true,
              ).currentLanguage,
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPhoneExpenseCard(
            'النقل',
            _safeParseDouble(_summary['transit']),
            Icons.local_shipping,
          ),
          _buildPhoneExpenseCard(
            'حق الجمرك',
            _safeParseDouble(_summary['droitDouane']),
            Icons.account_balance,
          ),
          _buildPhoneExpenseCard(
            'شيك الصرف',
            _safeParseDouble(_summary['chequeChange']),
            Icons.money,
          ),
          _buildPhoneExpenseCard(
            'الشحن',
            _safeParseDouble(_summary['freiht']),
            Icons.flight_takeoff,
          ),
          _buildPhoneExpenseCard(
            'أخرى',
            _safeParseDouble(_summary['autres']),
            Icons.more_horiz,
          ),
          _buildPhoneExpenseCard(
            'سعر الصرف',
            _safeParseDouble(_summary['txChange']),
            Icons.currency_exchange,
            isCurrency: false,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المجاميع',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhoneTotalItem(
                        'مجموع البضائع',
                        _calculationService.formatCurrency(
                          totals['totalMt'] ?? 0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildPhoneTotalItem(
                        'مجموع المصاريف',
                        _calculationService.formatCurrency(
                          totals['total'] ?? 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhoneTotalItem(
                        'الوزن الإجمالي',
                        '${totals['poidsTotal']?.toStringAsFixed(0) ?? '0'} Kg',
                      ),
                    ),
                    Expanded(
                      child: _buildPhoneTotalItem(
                        'عدد العناصر',
                        _items.length.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneExpenseCard(
    String label,
    double value,
    IconData icon, {
    bool isCurrency = true,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(
          isCurrency
              ? _calculationService.formatCurrency(value)
              : value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showPhoneExpenseEditDialog(label, value),
        ),
      ),
    );
  }

  void _showPhoneExpenseEditDialog(String label, double currentValue) {
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $label'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'القيمة الجديدة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                _updateSummaryField(label, newValue);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTotalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPhoneActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPhoneActionCard(
            'تحديد الكل',
            Icons.select_all,
            Colors.blue,
            _selectAll,
          ),
          _buildPhoneActionCard(
            'مسح التحديد',
            Icons.clear_all,
            Colors.grey,
            _clearSelection,
          ),
          if (_hasSelection)
            _buildPhoneActionCard(
              'حذف المحدد (${_selectedIndices.length})',
              Icons.delete_sweep,
              Colors.red,
              () => _showDeleteConfirmation(context),
            ),
          _buildPhoneActionCard(
            'إعادة تعيين',
            Icons.refresh,
            Colors.orange,
            _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPhoneFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _addItem();
        _clearControllers();
      },
      backgroundColor: const Color(0xFF1E3A8A),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class EditableSummaryItem extends StatefulWidget {
  final String label;
  final double value;
  final bool isCurrency;
  final String unit;
  final IconData? icon;
  final void Function(double newValue)? onValueChanged;
  final CalculationService calculationService;
  final bool isEditing;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const EditableSummaryItem({
    super.key,
    required this.label,
    required this.value,
    required this.calculationService,
    this.isCurrency = true,
    this.unit = '',
    this.icon,
    this.onValueChanged,
    this.isEditing = false,
    this.onEdit,
    this.onCancel,
  });

  @override
  State<EditableSummaryItem> createState() => _EditableSummaryItemState();
}

class _EditableSummaryItemState extends State<EditableSummaryItem> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onEdit != null) {
          widget.onEdit!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: widget.isEditing
                  ? Row(
                      key: const ValueKey('edit'),
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
                                controller: controller,
                                autofocus: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1E3A8A),
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: AppTranslations.get(
                                    'enter_value',
                                    Provider.of<LanguageProvider>(
                                      context,
                                      listen: true,
                                    ).currentLanguage,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF60A5FA),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E3A8A),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {});
                                    },
                                    tooltip: AppTranslations.get(
                                      'clear_value',
                                      Provider.of<LanguageProvider>(
                                        context,
                                        listen: true,
                                      ).currentLanguage,
                                    ),
                                  ),
                                ),
                                onSubmitted: (val) {
                                  double? newValue = double.tryParse(val);
                                  if (newValue != null &&
                                      widget.onValueChanged != null) {
                                    widget.onValueChanged!(newValue);
                                  }
                                  if (widget.onCancel != null) {
                                    widget.onCancel!();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: Color(0xFF22C55E),
                          ),
                          onPressed: () {
                            double? newValue = double.tryParse(controller.text);
                            if (newValue != null &&
                                widget.onValueChanged != null) {
                              widget.onValueChanged!(newValue);
                            }
                            if (widget.onCancel != null) {
                              widget.onCancel!();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            if (widget.onCancel != null) {
                              widget.onCancel!();
                            }
                          },
                        ),
                      ],
                    )
                  : Container(
                      key: const ValueKey('value'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.isCurrency
                            ? widget.calculationService.formatCurrency(
                                widget.value,
                              )
                            : widget.unit.isNotEmpty
                            ? '${widget.calculationService.formatWeight(widget.value)} ${widget.unit}'
                            : widget.value.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
