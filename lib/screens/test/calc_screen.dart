import 'imports.dart';

// =================== Main Screen =================== //
class CalcScreen extends StatefulWidget {
  const CalcScreen({super.key});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  late CalcData _data;
  late CalcLogic _logic;
  late CalcWidgets _widgets;

  @override
  void initState() {
    super.initState();
    _data = CalcData();
    _logic = CalcLogic(_data);
    _widgets = CalcWidgets(_data, _logic, _refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    _widgets.setContext(context);
    final totals = _logic.calculateTotals();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة الحسابات'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _widgets.showAddDialog(context),
            tooltip: 'إضافة عنصر جديد',
          ),
        ],
      ),
      body: Column(
        children: [
          _widgets.buildVariablesSection(),
          Expanded(
            child: isSmallScreen
                ? _widgets.buildCardView()
                : _widgets.buildTableView(isMediumScreen),
          ),
          _widgets.buildTotalsSection(totals, isSmallScreen),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _widgets.showAddDialog(context),
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
      ),
    );
  }
}
