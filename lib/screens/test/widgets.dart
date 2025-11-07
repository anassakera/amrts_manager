import 'imports.dart';

// =================== Widgets Class =================== //
class CalcWidgets {
  final CalcData data;
  final CalcLogic logic;
  final VoidCallback refresh;

  CalcWidgets(this.data, this.logic, this.refresh);

  // =============== Variables Display =============== //
  Widget buildVariablesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceAround,
        children: [
          _buildVariableCard('P2', CalcData.p2),
          _buildVariableCard('P3', CalcData.p3),
          _buildVariableCard('P5', CalcData.p5),
        ],
      ),
    );
  }

  Widget _buildVariableCard(String name, double value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // =============== Card View (Small Screen) =============== //
  Widget buildCardView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: data.data.length,
      itemBuilder: (context, index) {
        final item = data.data[index];
        double poidsConsomme = logic.calculatePoidsConsomme(
          item['poids'],
          item['quantite'],
        );
        double peinture = logic.calculatePeinture(poidsConsomme);
        double gaz = logic.calculateGaz(poidsConsomme);
        double bellet = item['bellet_constant'];
        double dechet = logic.calculateDechet(bellet, poidsConsomme);
        double dechetInitial = logic.calculateDechetInitial(bellet);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['document_ref'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showEditDialog(context, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => showDeleteDialog(context, index),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                _buildCardRow('Client', item['client']),
                _buildCardRow('Référence', item['reference']),
                _buildCardRow('Désignation', item['designation']),
                _buildCardRow('Poids', item['poids'].toStringAsFixed(0)),
                _buildCardRow('Quantité', item['quantite'].toStringAsFixed(0)),
                _buildCardRow(
                  'Poids consommé',
                  poidsConsomme.toStringAsFixed(0),
                ),
                _buildCardRow('Peinture', peinture.toStringAsFixed(0)),
                _buildCardRow('Gaz', gaz.toStringAsFixed(0)),
                Row(
                  children: [
                    const Text(
                      'Couleur: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item['couleur'] == 'red'
                            ? Colors.red
                            : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['couleur'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                _buildCardRow('Bellet', bellet.toStringAsFixed(2)),
                _buildCardRow('Dechet', dechet.toStringAsFixed(2)),
                _buildCardRow(
                  'Dechet initial',
                  dechetInitial.toStringAsFixed(2),
                ),
                _buildCardRow('Date', item['date']),
                if (item['gaz_price_type'].isNotEmpty)
                  _buildCardRow('Type', item['gaz_price_type']),
                _buildCardRow(
                  'Gaz price',
                  item['gaz_price_value'].toStringAsFixed(2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // =============== Table View (Medium/Large Screen) =============== //
  Widget buildTableView(bool isMediumScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue[100]),
          border: TableBorder.all(color: Colors.grey[300]!),
          columnSpacing: isMediumScreen ? 20 : 30,
          columns: const [
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Document_Ref',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Client',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Référence',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Désignation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Poids',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Quantité',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Poids consommé',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Peinture',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('Gaz', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Couleur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'bellet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'dechet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'dechet initial',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            DataColumn(
              label: Text(
                'Gaz_price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: data.data.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            double poidsConsomme = logic.calculatePoidsConsomme(
              item['poids'],
              item['quantite'],
            );
            double peinture = logic.calculatePeinture(poidsConsomme);
            double gaz = logic.calculateGaz(poidsConsomme);
            double bellet = item['bellet_constant'];
            double dechet = logic.calculateDechet(bellet, poidsConsomme);
            double dechetInitial = logic.calculateDechetInitial(bellet);

            return DataRow(
              color: WidgetStateProperty.all(Colors.red[50]),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.blue,
                        ),
                        onPressed: () => showEditDialog(null, index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => showDeleteDialog(null, index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(item['document_ref'])),
                DataCell(Text(item['client'])),
                DataCell(Text(item['reference'])),
                DataCell(Text(item['designation'])),
                DataCell(Text(item['poids'].toStringAsFixed(0))),
                DataCell(Text(item['quantite'].toStringAsFixed(0))),
                DataCell(Text(poidsConsomme.toStringAsFixed(0))),
                DataCell(Text(peinture.toStringAsFixed(0))),
                DataCell(Text(gaz.toStringAsFixed(0))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item['couleur'] == 'red'
                          ? Colors.red
                          : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['couleur'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                DataCell(Text(bellet.toStringAsFixed(2))),
                DataCell(Text(dechet.toStringAsFixed(2))),
                DataCell(Text(dechetInitial.toStringAsFixed(2))),
                DataCell(Text(item['date'])),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item['gaz_price_type'].isNotEmpty)
                        Text(
                          item['gaz_price_type'],
                          style: const TextStyle(fontSize: 10),
                        ),
                      Text(item['gaz_price_value'].toStringAsFixed(2)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // =============== Totals Section =============== //
  Widget buildTotalsSection(Map<String, double> totals, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[100],
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المجاميع:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildTotalRow('Poids consommé', totals['poids_consomme']!),
                _buildTotalRow('Peinture', totals['peinture']!),
                _buildTotalRow('Gaz', totals['gaz']!),
                _buildTotalRow('Bellet', totals['bellet']!),
                _buildTotalRow('Dechet', totals['dechet']!),
                _buildTotalRow('Dechet initial', totals['dechet_initial']!),
              ],
            )
          : Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildTotalCard('Poids consommé', totals['poids_consomme']!),
                _buildTotalCard('Peinture', totals['peinture']!),
                _buildTotalCard('Gaz', totals['gaz']!),
                _buildTotalCard('Bellet', totals['bellet']!),
                _buildTotalCard('Dechet', totals['dechet']!),
                _buildTotalCard('Dechet initial', totals['dechet_initial']!),
              ],
            ),
    );
  }

  Widget _buildTotalRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =============== Dialog Widgets =============== //
  void showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ItemDialog(
        onSave: (item) {
          logic.addItem(item, refresh);
        },
      ),
    );
  }

  void showEditDialog(BuildContext? context, int index) {
    final ctx = context ?? _currentContext!;
    showDialog(
      context: ctx,
      builder: (context) => ItemDialog(
        item: data.data[index],
        onSave: (item) {
          logic.updateItem(index, item, refresh);
        },
      ),
    );
  }

  void showDeleteDialog(BuildContext? context, int index) {
    final ctx = context ?? _currentContext!;
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنصر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              logic.deleteItem(index, refresh);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  BuildContext? _currentContext;
  void setContext(BuildContext context) {
    _currentContext = context;
  }
}

// =================== Item Dialog Widget =================== //
class ItemDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Function(Map<String, dynamic>) onSave;

  const ItemDialog({super.key, this.item, required this.onSave});

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  late TextEditingController _documentRefController;
  late TextEditingController _clientController;
  late TextEditingController _referenceController;
  late TextEditingController _designationController;
  late TextEditingController _poidsController;
  late TextEditingController _quantiteController;
  late TextEditingController _belletController;
  late TextEditingController _dateController;
  late TextEditingController _gazPriceTypeController;
  late TextEditingController _gazPriceValueController;
  String _couleur = 'red';

  @override
  void initState() {
    super.initState();
    _documentRefController = TextEditingController(
      text: widget.item?['document_ref'] ?? '',
    );
    _clientController = TextEditingController(
      text: widget.item?['client'] ?? '',
    );
    _referenceController = TextEditingController(
      text: widget.item?['reference'] ?? '',
    );
    _designationController = TextEditingController(
      text: widget.item?['designation'] ?? '',
    );
    _poidsController = TextEditingController(
      text: widget.item?['poids']?.toString() ?? '',
    );
    _quantiteController = TextEditingController(
      text: widget.item?['quantite']?.toString() ?? '',
    );
    _belletController = TextEditingController(
      text: widget.item?['bellet_constant']?.toString() ?? '',
    );
    _dateController = TextEditingController(
      text: widget.item?['date'] ?? 'AUTO',
    );
    _gazPriceTypeController = TextEditingController(
      text: widget.item?['gaz_price_type'] ?? '',
    );
    _gazPriceValueController = TextEditingController(
      text: widget.item?['gaz_price_value']?.toString() ?? '',
    );
    _couleur = widget.item?['couleur'] ?? 'red';
  }

  @override
  void dispose() {
    _documentRefController.dispose();
    _clientController.dispose();
    _referenceController.dispose();
    _designationController.dispose();
    _poidsController.dispose();
    _quantiteController.dispose();
    _belletController.dispose();
    _dateController.dispose();
    _gazPriceTypeController.dispose();
    _gazPriceValueController.dispose();
    super.dispose();
  }

  void _save() {
    if (_documentRefController.text.isEmpty ||
        _clientController.text.isEmpty ||
        _poidsController.text.isEmpty ||
        _quantiteController.text.isEmpty ||
        _belletController.text.isEmpty ||
        _gazPriceValueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    final item = {
      'document_ref': _documentRefController.text,
      'client': _clientController.text,
      'reference': _referenceController.text,
      'designation': _designationController.text,
      'poids': double.tryParse(_poidsController.text) ?? 0,
      'quantite': double.tryParse(_quantiteController.text) ?? 0,
      'couleur': _couleur,
      'bellet_constant': double.tryParse(_belletController.text) ?? 0,
      'date': _dateController.text,
      'gaz_price_type': _gazPriceTypeController.text,
      'gaz_price_value': double.tryParse(_gazPriceValueController.text) ?? 0,
    };

    widget.onSave(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return AlertDialog(
      title: Text(widget.item == null ? 'إضافة عنصر جديد' : 'تعديل العنصر'),
      content: SizedBox(
        width: isSmallScreen ? screenWidth * 0.9 : 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _documentRefController,
                decoration: const InputDecoration(
                  labelText: 'Document Ref *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Référence',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _designationController,
                decoration: const InputDecoration(
                  labelText: 'Désignation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _poidsController,
                decoration: const InputDecoration(
                  labelText: 'Poids *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _couleur,
                decoration: const InputDecoration(
                  labelText: 'Couleur',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'red', child: Text('Red')),
                  DropdownMenuItem(value: 'green', child: Text('Green')),
                ],
                onChanged: (value) {
                  setState(() {
                    _couleur = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _belletController,
                decoration: const InputDecoration(
                  labelText: 'Bellet Constant *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gazPriceTypeController,
                decoration: const InputDecoration(
                  labelText: 'Gaz Price Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gazPriceValueController,
                decoration: const InputDecoration(
                  labelText: 'Gaz Price Value *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}
