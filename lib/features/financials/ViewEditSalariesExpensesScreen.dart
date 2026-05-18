import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odon_booking/core/api/api_service.dart';

class ViewEditSalariesExpensesScreen extends StatefulWidget {
  @override
  _ViewEditSalariesExpensesScreenState createState() =>
      _ViewEditSalariesExpensesScreenState();
}

class _ViewEditSalariesExpensesScreenState
    extends State<ViewEditSalariesExpensesScreen> {
  String _selectedType     = 'Salaries';
  String _selectedMonth    = DateTime.now().month.toString();
  String _selectedYear     = DateTime.now().year.toString();
  String _selectedCategory = 'All';
  String _searchQuery      = '';

  List<Map<String, dynamic>> _records         = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  final List<String> _months = [
    '1','2','3','4','5','6','7','8','9','10','11','12'
  ];
  final List<String> _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  final List<String> _years = ['2023','2024','2025','2026','2027'];
  final List<String> _salaryTypes     = ['OT','Monthly','Weekly','Commission'];
  final List<String> _expenseCategories = [
    'Food','Utilities','Maintenance','Supplies',
    'Transportation','Marketing','Equipment','Other',
  ];

  List<String> get _currentCategoryOptions {
    return ['All', ...(_selectedType == 'Salaries' ? _salaryTypes : _expenseCategories)];
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final selectedDate =
          DateTime(int.parse(_selectedYear), int.parse(_selectedMonth));
      final fetched = _selectedType == 'Salaries'
          ? await _apiService.fetchSalariesForMonth(selectedDate)
          : await _apiService.fetchExpensesForMonth(selectedDate);
      setState(() {
        _records = fetched;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_records);
    if (_selectedCategory != 'All') {
      filtered = filtered.where((r) {
        return _selectedType == 'Salaries'
            ? r['salaryType'] == _selectedCategory
            : r['category'] == _selectedCategory;
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final name = _selectedType == 'Salaries'
            ? (r['employeeName'] ?? '').toLowerCase()
            : (r['expenseName']  ?? '').toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    setState(() => _filteredRecords = filtered);
  }

  double _calculateTotal() => _filteredRecords.fold(0.0, (sum, r) {
        final a = r['amount'];
        if (a is int)    return sum + a.toDouble();
        if (a is double) return sum + a;
        if (a is String) return sum + (double.tryParse(a) ?? 0.0);
        return sum;
      });

  Future<void> _deleteRecord(String id) async {
    try {
      if (_selectedType == 'Salaries') {
        await _apiService.deleteSalary(id);
      } else {
        await _apiService.deleteExpense(id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Record deleted'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> record) {
    if (_selectedType == 'Salaries') {
      _showEditSalaryDialog(record);
    } else {
      _showEditExpenseDialog(record);
    }
  }

  void _showEditSalaryDialog(Map<String, dynamic> salary) {
    final nameCtrl   = TextEditingController(text: salary['employeeName']);
    final amountCtrl = TextEditingController(text: salary['amount'].toString());
    String type      = salary['salaryType'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Salary', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Employee Name', Icons.person_outline),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: _dialogDeco('Salary Type', Icons.category_outlined),
                  items: _salaryTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setS(() => type = v!),
                ),
                const SizedBox(height: 14),
                _dialogField(amountCtrl, 'Amount (LKR)', Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                try {
                  await _apiService.updateSalary(salary['_id'], {
                    'employeeName': nameCtrl.text,
                    'salaryType': type,
                    'amount': double.parse(amountCtrl.text),
                    'date': salary['date'],
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Updated'), backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating),
                  );
                  _loadRecords();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditExpenseDialog(Map<String, dynamic> expense) {
    final nameCtrl   = TextEditingController(text: expense['expenseName']);
    final amountCtrl = TextEditingController(text: expense['amount'].toString());
    final reasonCtrl = TextEditingController(text: expense['reason'] ?? '');
    String category  = expense['category'];
    DateTime date    = DateTime.parse(expense['date']);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Expense', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Expense Name', Icons.receipt_outlined),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _dialogDeco('Category', Icons.label_outline),
                  items: _expenseCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setS(() => category = v!),
                ),
                const SizedBox(height: 14),
                _dialogField(amountCtrl, 'Amount (LKR)', Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(primary: Colors.indigo),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setS(() => date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: Colors.indigo.shade400, size: 18),
                        const SizedBox(width: 10),
                        Text('${date.day}/${date.month}/${date.year}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _dialogField(reasonCtrl, 'Reason / Description', Icons.notes_rounded, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                try {
                  await _apiService.updateExpense(expense['_id'], {
                    'expenseName': nameCtrl.text,
                    'category': category,
                    'amount': double.parse(amountCtrl.text),
                    'date': date.toIso8601String(),
                    'reason': reasonCtrl.text,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Updated'), backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating),
                  );
                  _loadRecords();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
            ),
          ),
        ),
        title: const Text(
          'Records',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Filter Panel ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                // Type + category row
                Row(
                  children: [
                    Expanded(child: _compactDropdown<String>(
                      value: _selectedType,
                      items: ['Salaries', 'Expenses'],
                      itemLabel: (v) => v,
                      icon: Icons.swap_horiz_rounded,
                      onChanged: (v) {
                        setState(() {
                          _selectedType = v!;
                          _selectedCategory = 'All';
                        });
                        _loadRecords();
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _compactDropdown<String>(
                      value: _selectedCategory,
                      items: _currentCategoryOptions,
                      itemLabel: (v) => v == 'All' ? 'All types' : v,
                      icon: Icons.filter_list_rounded,
                      onChanged: (v) {
                        setState(() => _selectedCategory = v!);
                        _applyFilters();
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 10),
                // Month + Year row
                Row(
                  children: [
                    Expanded(flex: 3, child: _compactDropdown<String>(
                      value: _selectedMonth,
                      items: _months,
                      itemLabel: (v) => _monthNames[int.parse(v) - 1],
                      icon: Icons.calendar_month_outlined,
                      onChanged: (v) {
                        setState(() => _selectedMonth = v!);
                        _loadRecords();
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _compactDropdown<String>(
                      value: _selectedYear,
                      items: _years,
                      itemLabel: (v) => v,
                      icon: Icons.event_note_outlined,
                      onChanged: (v) {
                        setState(() => _selectedYear = v!);
                        _loadRecords();
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 10),
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _selectedType == 'Salaries'
                        ? 'Search by employee name…'
                        : 'Search by expense name…',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.indigo, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          // ── Total Banner ──────────────────────────────────────────────────
          if (!_isLoading && _filteredRecords.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildFilterDescription(),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_monthNames[int.parse(_selectedMonth) - 1]} $_selectedYear',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        child: Text(
                          'LKR ${_calculateTotal().toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${_filteredRecords.length} record${_filteredRecords.length != 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (_, i) {
                          final r = _filteredRecords[i];
                          return _selectedType == 'Salaries'
                              ? _SalaryCard(salary: r, onEdit: () => _showEditDialog(r), onDelete: () => _confirmDelete(r['_id']))
                              : _ExpenseCard(expense: r, onEdit: () => _showEditDialog(r), onDelete: () => _confirmDelete(r['_id']));
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRecords,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              _deleteRecord(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedType == 'Salaries' ? Icons.people_outline : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _buildEmptyStateMessage(),
            style: TextStyle(fontSize: 17, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            '${_monthNames[int.parse(_selectedMonth) - 1]} $_selectedYear',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          if (_searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() { _searchQuery = ''; _selectedCategory = 'All'; });
                _applyFilters();
              },
              child: const Text('Clear Filters', style: TextStyle(color: Colors.indigo)),
            ),
          ],
        ],
      ),
    );
  }

  String _buildFilterDescription() {
    if (_searchQuery.isNotEmpty && _selectedCategory != 'All') return 'Filtered Total';
    if (_searchQuery.isNotEmpty) return 'Search Results';
    if (_selectedCategory != 'All') return '$_selectedCategory Total';
    return 'Total ${_selectedType}';
  }

  String _buildEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) return 'No search results';
    if (_selectedCategory != 'All') return 'No $_selectedCategory found';
    return 'No ${_selectedType.toLowerCase()} found';
  }

  Widget _compactDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: Colors.indigo.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORD CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _SalaryCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  final VoidCallback onEdit, onDelete;
  const _SalaryCard({required this.salary, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(salary['date'] ?? salary['createdAt']);
    final amount = double.tryParse(salary['amount'].toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Left accent
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salary['employeeName'] ?? 'Unknown Employee',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _pill(salary['salaryType'] ?? '', Colors.indigo.shade50, Colors.indigo.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Amount + actions
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.indigo,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.indigo),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onEdit, onDelete;
  const _ExpenseCard({required this.expense, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date   = DateTime.parse(expense['date']);
    final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
    final reason = expense['reason']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent (rose for expenses — semantic)
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: Colors.pink.shade400,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense['expenseName'] ?? 'Unknown Expense',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _pill(expense['category'] ?? '', Colors.pink.shade50, Colors.pink.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.pink.shade700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.indigo),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
}

Widget _pill(String label, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );

TextField _dialogField(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) =>
    TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _dialogDeco(label, icon),
    );

InputDecoration _dialogDeco(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo.shade400, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
