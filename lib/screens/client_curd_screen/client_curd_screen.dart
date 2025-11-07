import 'dart:async';

import 'package:flutter/material.dart';

import 'api_services.dart';

class ClientCurdScreen extends StatefulWidget {
  const ClientCurdScreen({super.key});

  @override
  State<ClientCurdScreen> createState() => _ClientCurdScreenState();
}

class _ClientCurdScreenState extends State<ClientCurdScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchClients();
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
      _fetchClients(query: query, showLoader: false);
    });
  }

  Future<void> _fetchClients({String? query, bool showLoader = true}) async {
    final trimmedQuery = query?.trim();
    final shouldSearch = trimmedQuery != null && trimmedQuery.isNotEmpty;
    final shouldShowLoader = showLoader || _clients.isEmpty;

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
      final clients = shouldSearch
          ? await _apiService.searchClients(searchQuery: trimmedQuery)
          : await _apiService.loadAllClients();

      if (!mounted) return;

      setState(() {
        _clients = clients;
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

  Future<void> _showClientDialog({Map<String, dynamic>? initial}) async {
    final isEdit = initial != null;
    final initialData = initial ?? <String, dynamic>{};
    final nameController = TextEditingController(
      text: initialData['ClientName']?.toString() ?? '',
    );
    final iceController = TextEditingController(
      text: initialData['ice']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: initialData['Phone']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: initialData['Address']?.toString() ?? '',
    );

    bool isActive = isEdit ? initialData['IsActive'] == true : true;
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
              final name = nameController.text.trim();
              final ice = iceController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();

              if (name.isEmpty) {
                setDialogState(() {
                  dialogError = 'يرجى إدخال اسم العميل';
                });
                return;
              }

              final clientId = initialData['client_id'] as int?;

              if (isEdit && clientId == null) {
                setDialogState(() {
                  dialogError = 'تعذر تحديد العميل المراد تعديله';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                dialogError = null;
              });

              try {
                final result = isEdit
                    ? await _apiService.modifyClient(
                        clientId: clientId!,
                        clientName: name,
                        ice: ice.isEmpty ? null : ice,
                        phone: phone.isEmpty ? null : phone,
                        address: address.isEmpty ? null : address,
                        isActive: isActive,
                      )
                    : await _apiService.addClient(
                        clientName: name,
                        ice: ice.isEmpty ? null : ice,
                        phone: phone.isEmpty ? null : phone,
                        address: address.isEmpty ? null : address,
                        isActive: isActive,
                      );

                if (!mounted) return;

                setState(() {
                  final updated = List<Map<String, dynamic>>.from(_clients);
                  final index = updated.indexWhere(
                    (client) => client['client_id'] == result['client_id'],
                  );

                  if (index >= 0) {
                    updated[index] = result;
                  } else {
                    updated.insert(0, result);
                  }

                  _clients = updated;
                });

                if (navigator.mounted && navigator.canPop()) {
                  navigator.pop();
                }

                _showSnackBar(
                  isEdit
                      ? 'تم تحديث بيانات العميل بنجاح'
                      : 'تم إضافة العميل بنجاح',
                );

                unawaited(
                  _fetchClients(
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
                    isEdit ? 'تحديث بيانات العميل' : 'إضافة عميل جديد',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Icon(
                    isEdit ? Icons.edit : Icons.person_add_alt_1,
                    color: Colors.blue,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'اسم العميل',
                      icon: Icons.person_outline,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: iceController,
                      label: 'ICE',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_iphone,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField(
                      controller: addressController,
                      label: 'العنوان',
                      icon: Icons.location_on_outlined,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('نشط'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isActive,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isActive = value;
                                  });
                                },
                        ),
                      ],
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

  Future<void> _confirmDelete(Map<String, dynamic> client) async {
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
              final clientId = client['client_id'] as int?;
              if (clientId == null) {
                setDialogState(() {
                  dialogError = 'معرف العميل غير متوفر';
                });
                return;
              }

              setDialogState(() {
                isDeleting = true;
                dialogError = null;
              });

              try {
                final removed = await _apiService.removeClient(clientId);
                if (!mounted) return;

                if (removed) {
                  setState(() {
                    _clients.removeWhere(
                      (item) => item['client_id'] == clientId,
                    );
                  });

                  if (navigator.mounted && navigator.canPop()) {
                    navigator.pop();
                  }

                  _showSnackBar('تم حذف العميل بنجاح');

                  unawaited(
                    _fetchClients(
                      query: _searchController.text.trim(),
                      showLoader: false,
                    ),
                  );
                } else {
                  throw Exception('تعذر حذف العميل');
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
                    'تأكيد حذف العميل',
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
                    'هل تريد حذف العميل "${client['ClientName'] ?? ''}"؟',
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
  }) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
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
          hintText: 'ابحث عن عميل بالاسم أو الهاتف...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _fetchClients();
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

  Widget _buildClientsList() {
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
                    _fetchClients(query: _searchController.text.trim()),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_clients.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
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
        itemCount: _clients.length,
        itemBuilder: (context, index) => _buildClientCard(index),
      ),
    );
  }

  Widget _buildClientCard(int index) {
    final client = _clients[index];
    final name = client['ClientName']?.toString() ?? '';
    final ice = client['ice']?.toString() ?? '';
    final phone = client['Phone']?.toString() ?? '';
    final address = client['Address']?.toString() ?? '';
    final isActive = client['IsActive'] == true;

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
              onPressed: () => _showClientDialog(initial: client),
              tooltip: 'تعديل',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              color: Colors.red,
              onPressed: () => _confirmDelete(client),
              tooltip: 'حذف',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        title: Text(
          name,
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
                    color: (isActive ? Colors.green : Colors.grey).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'غير نشط',
                    style: TextStyle(
                      color: isActive ? Colors.green[700] : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    ice,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              phone,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              textAlign: TextAlign.right,
            ),
            Text(
              address,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.right,
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
                '${_clients.length} عميل',
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
          'إدارة العملاء',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [_buildSearchBar(), _buildClientsList(), _buildBottomBar()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('إضافة عميل', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4F8BFF),
      ),
    );
  }
}
