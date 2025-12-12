import 'dart:async';

import 'package:flutter/material.dart';

import 'api_services.dart';

class ArticlesStockCrudScreen extends StatefulWidget {
  const ArticlesStockCrudScreen({super.key});

  @override
  State<ArticlesStockCrudScreen> createState() =>
      _ArticlesStockCrudScreenState();
}

class _ArticlesStockCrudScreenState extends State<ArticlesStockCrudScreen> {
  final _searchController = TextEditingController();
  final ArticlesStockApiService _apiService = ArticlesStockApiService();

  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchArticles();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _fetchArticles(query: query, showLoader: false);
    });
  }

  Future<void> _fetchArticles({String? query, bool showLoader = true}) async {
    final trimmedQuery = query?.trim();
    final shouldSearch = trimmedQuery != null && trimmedQuery.isNotEmpty;
    final shouldShowLoader = showLoader || _articles.isEmpty;

    if (shouldShowLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final articles = shouldSearch
          ? await _apiService.searchArticles(searchQuery: trimmedQuery)
          : await _apiService.loadAllArticles();

      if (!mounted) return;

      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showSnackBar(e.toString(), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showArticleDialog({Map<String, dynamic>? initial}) async {
    final isEdit = initial != null;
    final initialData = initial ?? <String, dynamic>{};

    final refCodeController = TextEditingController(
      text: initialData['ref_code']?.toString() ?? '',
    );
    final materialNameController = TextEditingController(
      text: initialData['material_name']?.toString() ?? '',
    );
    final materialTypeController = TextEditingController(
      text: initialData['material_type']?.toString() ?? '',
    );
    final unitPriceController = TextEditingController(
      text: initialData['unit_price']?.toString() ?? '',
    );
    final minStockLevelController = TextEditingController(
      text: initialData['min_stock_level']?.toString() ?? '',
    );

    String status = isEdit
        ? (initialData['status']?.toString() ?? 'Disponible')
        : 'Disponible';
    bool isSaving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final refCode = refCodeController.text.trim();
              final materialName = materialNameController.text.trim();
              final materialType = materialTypeController.text.trim();
              final unitPriceText = unitPriceController.text.trim();
              final minStockLevelText = minStockLevelController.text.trim();

              if (refCode.isEmpty) {
                setDialogState(() {
                  dialogError = 'يرجى إدخال رمز المرجع';
                });
                return;
              }

              if (materialName.isEmpty) {
                setDialogState(() {
                  dialogError = 'يرجى إدخال اسم المادة';
                });
                return;
              }

              if (materialType.isEmpty) {
                setDialogState(() {
                  dialogError = 'يرجى إدخال نوع المادة';
                });
                return;
              }

              if (unitPriceText.isEmpty) {
                setDialogState(() {
                  dialogError = 'يرجى إدخال سعر الوحدة';
                });
                return;
              }

              final unitPrice = double.tryParse(unitPriceText);
              if (unitPrice == null || unitPrice < 0) {
                setDialogState(() {
                  dialogError = 'سعر الوحدة يجب أن يكون رقماً موجباً';
                });
                return;
              }

              int? minStockLevel;
              if (minStockLevelText.isNotEmpty) {
                minStockLevel = int.tryParse(minStockLevelText);
                if (minStockLevel == null || minStockLevel < 0) {
                  setDialogState(() {
                    dialogError =
                        'الحد الأدنى للمخزون يجب أن يكون رقماً صحيحاً موجباً';
                  });
                  return;
                }
              }

              final articleId = initialData['id'] as int?;

              if (isEdit && articleId == null) {
                setDialogState(() {
                  dialogError = 'تعذر تحديد المادة المراد تعديلها';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                dialogError = null;
              });

              try {
                final result = isEdit
                    ? await _apiService.modifyArticle(
                        id: articleId!,
                        refCode: refCode,
                        materialName: materialName,
                        materialType: materialType,
                        unitPrice: unitPrice,
                        status: status,
                        minStockLevel: minStockLevel,
                      )
                    : await _apiService.addArticle(
                        refCode: refCode,
                        materialName: materialName,
                        materialType: materialType,
                        unitPrice: unitPrice,
                        status: status,
                        minStockLevel: minStockLevel,
                      );

                if (!mounted) return;

                setState(() {
                  final updated = List<Map<String, dynamic>>.from(_articles);
                  final index = updated.indexWhere(
                    (article) => article['id'] == result['id'],
                  );

                  if (index >= 0) {
                    updated[index] = result;
                  } else {
                    updated.insert(0, result);
                  }

                  _articles = updated;
                });

                if (navigator.mounted && navigator.canPop()) {
                  navigator.pop();
                }

                _showSnackBar(
                  isEdit
                      ? 'تم تحديث بيانات المادة بنجاح'
                      : 'تم إضافة المادة بنجاح',
                );

                unawaited(
                  _fetchArticles(
                    query: _searchController.text.trim(),
                    showLoader: false,
                  ),
                );
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                  dialogError = e.toString();
                });
                _showSnackBar(e.toString(), isError: true);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: isSaving ? null : () => navigator.pop(),
                  ),
                  Text(
                    isEdit ? 'تحديث بيانات المادة' : 'إضافة مادة جديدة',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Icon(isEdit ? Icons.edit : Icons.add_box, color: Colors.blue),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: refCodeController,
                      label: 'رمز المرجع',
                      icon: Icons.qr_code,
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: materialNameController,
                      label: 'اسم المادة',
                      icon: Icons.inventory_2_outlined,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: materialTypeController,
                      label: 'نوع المادة',
                      icon: Icons.category_outlined,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: unitPriceController,
                      label: 'سعر الوحدة',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: minStockLevelController,
                      label: 'الحد الأدنى للمخزون (اختياري)',
                      icon: Icons.low_priority,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'الحالة',
                        prefixIcon: const Icon(Icons.published_with_changes),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Disponible',
                          child: Text('متوفر'),
                        ),
                        DropdownMenuItem(value: 'Épuisé', child: Text('نفذ')),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  status = value;
                                });
                              }
                            },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          dialogError!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: isSaving ? null : () => navigator.pop(),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('إلغاء'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : submit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(isEdit ? 'تحديث' : 'حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> article) async {
    bool isDeleting = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> remove() async {
              final articleId = article['id'] as int?;
              if (articleId == null) {
                setDialogState(() {
                  dialogError = 'معرف المادة غير متوفر';
                });
                return;
              }

              setDialogState(() {
                isDeleting = true;
                dialogError = null;
              });

              try {
                final removed = await _apiService.removeArticle(articleId);
                if (!mounted) return;

                if (removed) {
                  setState(() {
                    _articles.removeWhere((item) => item['id'] == articleId);
                  });

                  if (navigator.mounted && navigator.canPop()) {
                    navigator.pop();
                  }

                  _showSnackBar('تم حذف المادة بنجاح');

                  unawaited(
                    _fetchArticles(
                      query: _searchController.text.trim(),
                      showLoader: false,
                    ),
                  );
                } else {
                  throw Exception('تعذر حذف المادة');
                }
              } catch (e) {
                setDialogState(() {
                  isDeleting = false;
                  dialogError = e.toString();
                });
                _showSnackBar(e.toString(), isError: true);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'تأكيد حذف المادة',
                    style: TextStyle(fontSize: 18),
                  ),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'هل تريد حذف المادة "${article['material_name'] ?? ''}"؟',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: isDeleting ? null : () => navigator.pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  onPressed: isDeleting ? null : remove,
                  icon: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_forever),
                  label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  TextField _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextAlign textAlign = TextAlign.left,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن مادة بالرمز أو الاسم أو النوع...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _fetchArticles();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    _fetchArticles(query: _searchController.text.trim()),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد بيانات لعرضها',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (context, index) => _buildArticleCard(index),
      ),
    );
  }

  Widget _buildArticleCard(int index) {
    final article = _articles[index];
    final refCode = article['ref_code']?.toString() ?? '';
    final materialName = article['material_name']?.toString() ?? '';
    final materialType = article['material_type']?.toString() ?? '';
    final unitPrice = article['unit_price']?.toString() ?? '0';
    final status = article['status']?.toString() ?? 'Disponible';
    final isAvailable = status == 'Disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              color: Colors.green,
              onPressed: () => _showArticleDialog(initial: article),
              tooltip: 'تعديل',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              color: Colors.red,
              onPressed: () => _confirmDelete(article),
              tooltip: 'حذف',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        title: Text(
          materialName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isAvailable ? Colors.green : Colors.red).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'متوفر' : 'نفذ',
                    style: TextStyle(
                      color: isAvailable ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    refCode,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$unitPrice DH',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 8),
                Text(
                  materialType,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.grey[400], size: 18),
              const SizedBox(width: 6),
              Text(
                '${_articles.length} مادة',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.verified, color: Colors.green[300], size: 16),
              const SizedBox(width: 6),
              const Text(
                'نظام الإدارة متصل بالخادم',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        title: const Text(
          'إدارة مخزون المواد',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [_buildSearchBar(), _buildArticlesList(), _buildBottomBar()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showArticleDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('إضافة مادة', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4F8BFF),
      ),
    );
  }
}
