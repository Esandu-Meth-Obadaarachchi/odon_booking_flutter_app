import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Import your API service file
import 'api_service.dart';

class ViewEditSalariesExpensesScreen extends StatefulWidget {
  @override
  _ViewEditSalariesExpensesScreenState createState() => _ViewEditSalariesExpensesScreenState();
}

class _ViewEditSalariesExpensesScreenState extends State<ViewEditSalariesExpensesScreen> {
  String _selectedType = 'Salaries'; // Salaries or Expenses
  String _selectedMonth = DateTime.now().month.toString();
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = '';
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService(); // Uncomment when you import the API service
  double total = 0.0;
  String totalInString = '';
  final List<String> _months = [
    '1', '2', '3', '4', '5', '6',
    '7', '8', '9', '10', '11', '12'
  ];

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _years = [
    '2023', '2024', '2025', '2026', '2027'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();


  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> allRecords = [];

      // TODO: Uncomment these lines when you import the API service
      if (_selectedType == 'Salaries') {
        allRecords = await _apiService.fetchSalaries();
      } else {
        allRecords = await _apiService.fetchExpenses();
      }

      // Filter by month and year
      final filteredRecords = allRecords.where((record) {
        final recordDate = DateTime.parse(record['date'] ?? record['createdAt']);
        return recordDate.month.toString() == _selectedMonth &&
            recordDate.year.toString() == _selectedYear;
      }).toList();

      setState(() {
        _records = filteredRecords;
        _applySearchFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading records: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredRecords = List.from(_records);
    } else {
      _filteredRecords = _records.where((record) {
        if (_selectedType == 'Salaries') {
          final employeeName = (record['employeeName'] ?? '').toLowerCase();
          return employeeName.contains(_searchQuery.toLowerCase());
        } else {
          final expenseName = (record['expenseName'] ?? '').toLowerCase();
          return expenseName.contains(_searchQuery.toLowerCase());
        }
      }).toList();
    }
  }

  double _calculateTotal() {
    return _filteredRecords.fold(0.0, (sum, record) {
      final amount = record['amount'];
      if (amount is int) {
        return sum + amount.toDouble();
      } else if (amount is double) {
        return sum + amount;
      } else if (amount is String) {
        return sum + (double.tryParse(amount) ?? 0.0);
      }
      return sum;
    });
  }

  String _formatTotal() {
    final total = _calculateTotal();
    return '\LKR${total.toStringAsFixed(2)}';
  }

  Future<void> _deleteRecord(String id) async {
    try {
      // TODO: Uncomment these lines when you import the API service
      if (_selectedType == 'Salaries') {
        await _apiService.deleteSalary(id);
      } else {
        await _apiService.deleteExpense(id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
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
    final _nameController = TextEditingController(text: salary['employeeName']);
    final _amountController = TextEditingController(text: salary['amount'].toString());
    String _selectedSalaryType = salary['salaryType'];

    final List<String> _salaryTypes = ['OT', 'Monthly', 'Weekly', 'Commission'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Salary Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Employee Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSalaryType,
                      decoration: InputDecoration(
                        labelText: 'Salary Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _salaryTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSalaryType = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      final updatedData = {
                        'employeeName': _nameController.text,
                        'salaryType': _selectedSalaryType,
                        'amount': double.parse(_amountController.text),
                        'date': salary['date'],
                      };

                      // TODO: Uncomment this line when you import the API service
                      await _apiService.updateSalary(salary['_id'], updatedData);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Salary updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadRecords();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating salary: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditExpenseDialog(Map<String, dynamic> expense) {
    final _nameController = TextEditingController(text: expense['expenseName']);
    final _amountController = TextEditingController(text: expense['amount'].toString());
    final _reasonController = TextEditingController(text: expense['reason'] ?? '');
    String _selectedCategory = expense['category'];
    DateTime _selectedDate = DateTime.parse(expense['date']);

    final List<String> _expenseCategories = [
      'Food', 'Utilities', 'Maintenance', 'Supplies', 'Transportation', 'Marketing', 'Equipment', 'Other'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Expense Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Expense Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _expenseCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFFEF4444)),
                            SizedBox(width: 12),
                            Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Reason/Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      final updatedData = {
                        'expenseName': _nameController.text,
                        'category': _selectedCategory,
                        'amount': double.parse(_amountController.text),
                        'date': _selectedDate.toIso8601String(),
                        'reason': _reasonController.text,
                      };

                      // TODO: Uncomment this line when you import the API service
                      await _apiService.updateExpense(expense['_id'], updatedData);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Expense updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadRecords();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating expense: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSalaryCard(Map<String, dynamic> salary) {
    final date = DateTime.parse(salary['date'] ?? salary['createdAt']);
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    salary['employeeName'] ?? 'Unknown Employee',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFFEF4444)),
                      onPressed: () => _showEditDialog(salary),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[700]),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Salary Record'),
                              content: Text('Are you sure you want to delete this salary record?'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                ElevatedButton(
                                  child: Text('Delete'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteRecord(salary['_id']);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Type: ${salary['salaryType']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Amount: \$${salary['amount'].toString()}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Date: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final date = DateTime.parse(expense['date']);
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense['expenseName'] ?? 'Unknown Expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFFEF4444)),
                      onPressed: () => _showEditDialog(expense),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[700]),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Expense Record'),
                              content: Text('Are you sure you want to delete this expense record?'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                ElevatedButton(
                                  child: Text('Delete'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteRecord(expense['_id']);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Category: ${expense['category']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Amount: \$${expense['amount'].toString()}',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Date: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (expense['reason'] != null && expense['reason'].toString().isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${expense['reason']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'View/Edit Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFEF4444),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Type Selector
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            items: ['Salaries', 'Expenses'].map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedType = newValue!;
                              });
                              _loadRecords();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Month and Year Selector
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            isExpanded: true,
                            items: _months.map((String month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(_monthNames[int.parse(month) - 1]),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedMonth = newValue!;
                              });
                              _loadRecords();
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedYear,
                            isExpanded: true,
                            items: _years.map((String year) {
                              return DropdownMenuItem<String>(
                                value: year,
                                child: Text(year),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedYear = newValue!;
                              });
                              _loadRecords();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: _selectedType == 'Salaries'
                        ? 'Search by employee name...'
                        : 'Search by expense name...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFFEF4444)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applySearchFilter();
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applySearchFilter();
                  },
                ),
              ],
            ),
          ),
          // Total Summary Section
          if (!_isLoading && _filteredRecords.isNotEmpty)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFEF4444).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Total for "$_searchQuery"'
                                : 'Total ${_selectedType}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_monthNames[int.parse(_selectedMonth) - 1]} $_selectedYear',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTotal(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_filteredRecords.length} record${_filteredRecords.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Records List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
                : _filteredRecords.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedType == 'Salaries' ? Icons.people : Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery"'
                        : 'No ${_selectedType.toLowerCase()} found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'for ${_monthNames[int.parse(_selectedMonth) - 1]} $_selectedYear',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applySearchFilter();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Clear Search'),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) {
                final record = _filteredRecords[index];
                return _selectedType == 'Salaries'
                    ? _buildSalaryCard(record)
                    : _buildExpenseCard(record);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRecords,
        backgroundColor: Color(0xFFEF4444),
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh',
      ),
    );
  }
}