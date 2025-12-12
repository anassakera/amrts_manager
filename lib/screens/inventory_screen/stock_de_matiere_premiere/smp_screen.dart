import 'dart:math';
import '../../../core/imports.dart';
import 'smp_card_widget.dart';
import 'smp_edit_screen.dart';
import 'api_services.dart';

class SmpScreen extends StatefulWidget {
  final String searchQuery;

  const SmpScreen({super.key, this.searchQuery = ''});

  @override
  State<SmpScreen> createState() => _SmpScreenState();
}

class _SmpScreenState extends State<SmpScreen> {
  List<Map<String, dynamic>> smpData = [];
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> get filteredSmpData {
    if (widget.searchQuery.isEmpty) {
      return smpData;
    }

    final query = widget.searchQuery.toLowerCase();
    return smpData.where((smp) {
      return (smp['ref_code']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['material_name']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['material_type']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['status']?.toString().toLowerCase().contains(query) ?? false) ||
          (smp['total_quantity']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['total_amount']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['operations_count']?.toString().toLowerCase().contains(query) ??
              false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSmpData();
  }

  Future<void> _loadSmpData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await InventorySmpApiService.getAllInventorySmp();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          smpData = (result['data'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String? _getLastRefCode() {
    if (smpData.isEmpty) return null;
    final reg = RegExp(r'^REF(\d{3})$');
    String? bestRef;
    int bestSeq = -1;
    for (final s in smpData) {
      final ref = s['ref_code']?.toString() ?? '';
      final m = reg.firstMatch(ref);
      if (m != null) {
        final seq = int.tryParse(m.group(1)!) ?? 0;
        if (seq > bestSeq) {
          bestSeq = seq;
          bestRef = ref;
        }
      }
    }
    return bestRef;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSmpData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedSmpData = filteredSmpData;

    return Scaffold(
      body: displayedSmpData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 1),
              itemCount: displayedSmpData.length,
              itemBuilder: (context, index) {
                final smp = displayedSmpData[index];
                return SmpCard(
                  smp: smp,
                  onEdit: () => _handleEditSmp(context, smp),
                  onDelete: () => _handleDeleteSmp(context, smp),
                );
              },
            ),
    );
  }

  Future<bool?> _showMathConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> smp,
  ) async {
    final random = Random();
    final operationType = random.nextInt(3); // 0: جمع, 1: طرح, 2: ضرب

    int num1, num2, correctAnswer;
    String operator;

    switch (operationType) {
      case 0: // جمع
        num1 = random.nextInt(20) + 1; // 1-20
        num2 = random.nextInt(20) + 1; // 1-20
        correctAnswer = num1 + num2;
        operator = '+';
        break;
      case 1: // طرح
        num1 = random.nextInt(30) + 10; // 10-39
        num2 = random.nextInt(num1) + 1; // 1-num1
        correctAnswer = num1 - num2;
        operator = '-';
        break;
      case 2: // ضرب
        num1 = random.nextInt(10) + 1; // 1-10
        num2 = random.nextInt(10) + 1; // 1-10
        correctAnswer = num1 * num2;
        operator = '×';
        break;
      default:
        num1 = 5;
        num2 = 3;
        correctAnswer = 8;
        operator = '+';
    }

    final answerController = TextEditingController();
    bool isAnswerCorrect = false;
    String userInput = '';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text(
                'تأكيد الحذف',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من حذف ${smp['ref_code']}؟',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'أجب على السؤال التالي للتأكيد:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Text(
                            '$num1 $operator $num2 = ?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answerController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'الإجابة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isAnswerCorrect
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isAnswerCorrect
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isAnswerCorrect
                                ? Colors.green
                                : Colors.blue.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isAnswerCorrect
                            ? Colors.green.shade50
                            : Colors.white,
                      ),
                      onChanged: (value) {
                        final userAnswer = int.tryParse(value);
                        setState(() {
                          userInput = value;
                          isAnswerCorrect = userAnswer == correctAnswer;
                        });
                      },
                    ),
                    if (userInput.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isAnswerCorrect)
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الإجابة صحيحة!',
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الإجابة غير صحيحة',
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isAnswerCorrect
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEditSmp(
    BuildContext context,
    Map<String, dynamic> smp,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SmpEditScreen(lastRefCode: _getLastRefCode(), stock: smp),
      ),
    );

    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      await _saveSmp(result, isNew: false);
    }
  }

  Future<void> _handleDeleteSmp(
    BuildContext context,
    Map<String, dynamic> smp,
  ) async {
    final confirm = await _showMathConfirmationDialog(context, smp);

    if (confirm != true || !mounted) return;

    try {
      final result = await InventorySmpApiService.deleteInventorySmp(
        smp['ref_code'],
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock supprimé avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadSmpData();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveSmp(
    Map<String, dynamic> result, {
    required bool isNew,
  }) async {
    try {
      final apiResult = isNew
          ? await InventorySmpApiService.createInventorySmp(result)
          : await InventorySmpApiService.updateInventorySmp(result);

      if (!mounted) return;

      if (apiResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew ? 'Stock créé avec succès' : 'Stock mis à jour avec succès',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadSmpData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiResult['message'] ?? 'Erreur lors de la sauvegarde',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
