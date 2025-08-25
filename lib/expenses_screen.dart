import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Import your API service file
import 'api_service.dart';
import 'ViewEditSalariesExpensesScreen.dart';
import 'image_processor_service.dart';
import 'data_confirmation_dialog.dart';

class ExpensesAndSalaryScreen extends StatefulWidget {
  @override
  _ExpensesAndSalaryScreenState createState() => _ExpensesAndSalaryScreenState();
}

class _ExpensesAndSalaryScreenState extends State<ExpensesAndSalaryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Expenses & Salaries',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFEF4444),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.visibility, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewEditSalariesExpensesScreen(),
                ),
              );
            },
            tooltip: 'View Records',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: [
            Tab(
              icon: Icon(Icons.people),
              text: 'Salaries',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'Expenses',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SalaryTab(),
          ExpensesTab(),
        ],
      ),
    );
  }
}

class SalaryTab extends StatefulWidget {
  @override
  _SalaryTabState createState() => _SalaryTabState();
}

class _SalaryTabState extends State<SalaryTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'OT';
  final List<String> _salaryTypes = ['OT', 'Monthly', 'Weekly', 'Commission'];
  final ApiService _apiService = ApiService();
  final ImageProcessorService _imageProcessor = ImageProcessorService();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitSalary() async {
    if (_formKey.currentState!.validate()) {
      try {
        final salaryData = {
          'employeeName': _nameController.text,
          'salaryType': _selectedType,
          'amount': double.parse(_amountController.text),
          'date': DateTime.now().toIso8601String(),
        };

        await _apiService.addSalary(salaryData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salary record added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method to BOTH SalaryTab and ExpensesTab classes if not already present:
  Future<void> _saveBatchSalaries(List<Map<String, dynamic>> salaries) async {
    try {
      for (var salary in salaries) {
        await _apiService.addSalary(salary);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving salaries: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Re-throw to handle in calling method
    }
  }

// Add this method to BOTH SalaryTab and ExpensesTab classes if not already present:
  Future<void> _saveBatchExpenses(List<Map<String, dynamic>> expenses) async {
    try {
      for (var expense in expenses) {
        await _apiService.addExpense(expense);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving expenses: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Re-throw to handle in calling method
    }
  }


  void _processImageWithAI() async {
    try {
      // Extract data using the image processor
      final extractedData = await _imageProcessor.processImage(context);

      if (extractedData.isNotEmpty) {
        // Show confirmation dialog
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => DataConfirmationDialog(
            data: extractedData,
          ),
        );

        if (result != null) {
          // Get separated data from the result
          final salaryData = result['salaryData'] as List<Map<String, dynamic>>? ?? [];
          final expenseData = result['expenseData'] as List<Map<String, dynamic>>? ?? [];

          // Save BOTH types regardless of which tab we're on
          int savedSalaries = 0;
          int savedExpenses = 0;

          // Save salary data if exists
          if (salaryData.isNotEmpty) {
            await _saveBatchSalaries(salaryData);
            savedSalaries = salaryData.length;
          }

          // Save expense data if exists
          if (expenseData.isNotEmpty) {
            await _saveBatchExpenses(expenseData);
            savedExpenses = expenseData.length;
          }

          // Show success message with counts for both types
          if (savedSalaries > 0 || savedExpenses > 0) {
            String message = 'Successfully added ';
            if (savedSalaries > 0 && savedExpenses > 0) {
              message += '$savedSalaries salary entries and $savedExpenses expense entries';
            } else if (savedSalaries > 0) {
              message += '$savedSalaries salary entries';
            } else {
              message += '$savedExpenses expense entries';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        // Show message when no data is extracted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No financial data found in the image. Please try with a clearer image containing expense or salary information.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _processImageWithAI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }





  void _clearForm() {
    _nameController.clear();
    _amountController.clear();
    setState(() {
      _selectedType = 'OT';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Camera Button Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: Color(0xFFEF4444), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan salary table from image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _processImageWithAI,
                    icon: Icon(Icons.camera_alt, size: 20),
                    label: Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Manual Entry Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Salary Record Manually',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Employee Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Employee Name',
                        hintText: 'Enter employee name',
                        prefixIcon: Icon(Icons.person, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter employee name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Salary Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Salary Type',
                        prefixIcon: Icon(Icons.category, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
                      ),
                      items: _salaryTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount',
                        prefixIcon: Icon(Icons.attach_money, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitSalary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Add Salary Record',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}

class ExpensesTab extends StatefulWidget {
  @override
  _ExpensesTabState createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  final ApiService _apiService = ApiService();
  final ImageProcessorService _imageProcessor = ImageProcessorService();

  final List<String> _expenseCategories = [
    'Food',
    'Utilities',
    'Maintenance',
    'Supplies',
    'Transportation',
    'Marketing',
    'Equipment',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        final expenseData = {
          'expenseName': _nameController.text,
          'category': _selectedCategory,
          'amount': double.parse(_amountController.text),
          'date': _selectedDate.toIso8601String(),
          'reason': _reasonController.text,
        };

        await _apiService.addExpense(expenseData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense record added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processImageWithAI() async {
    try {
      // Extract data using the image processor
      final extractedData = await _imageProcessor.processImage(context);

      if (extractedData.isNotEmpty) {
        // Show confirmation dialog
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => DataConfirmationDialog(
            data: extractedData,
          ),
        );

        if (result != null) {
          // Get separated data from the result
          final salaryData = result['salaryData'] as List<Map<String, dynamic>>? ?? [];
          final expenseData = result['expenseData'] as List<Map<String, dynamic>>? ?? [];

          // Save BOTH types regardless of which tab we're on
          int savedSalaries = 0;
          int savedExpenses = 0;

          // Save salary data if exists
          if (salaryData.isNotEmpty) {
            await _saveBatchSalaries(salaryData);
            savedSalaries = salaryData.length;
          }

          // Save expense data if exists
          if (expenseData.isNotEmpty) {
            await _saveBatchExpenses(expenseData);
            savedExpenses = expenseData.length;
          }

          // Show success message with counts for both types
          if (savedSalaries > 0 || savedExpenses > 0) {
            String message = 'Successfully added ';
            if (savedSalaries > 0 && savedExpenses > 0) {
              message += '$savedSalaries salary entries and $savedExpenses expense entries';
            } else if (savedSalaries > 0) {
              message += '$savedSalaries salary entries';
            } else {
              message += '$savedExpenses expense entries';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        // Show message when no data is extracted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No financial data found in the image. Please try with a clearer image containing expense or salary information.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _processImageWithAI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
  // Add this method to BOTH SalaryTab and ExpensesTab classes if not already present:
  Future<void> _saveBatchSalaries(List<Map<String, dynamic>> salaries) async {
    try {
      for (var salary in salaries) {
        await _apiService.addSalary(salary);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving salaries: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Re-throw to handle in calling method
    }
  }

// Add this method to BOTH SalaryTab and ExpensesTab classes if not already present:
  Future<void> _saveBatchExpenses(List<Map<String, dynamic>> expenses) async {
    try {
      for (var expense in expenses) {
        await _apiService.addExpense(expense);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving expenses: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Re-throw to handle in calling method
    }
  }



  void _clearForm() {
    _nameController.clear();
    _amountController.clear();
    _reasonController.clear();
    setState(() {
      _selectedCategory = 'Food';
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFEF4444),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Camera Button Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: Color(0xFFEF4444), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan expense table from image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _processImageWithAI,
                    icon: Icon(Icons.camera_alt, size: 20),
                    label: Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Manual Entry Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Expense Record Manually',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Expense Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Expense Name',
                        hintText: 'Enter expense name',
                        prefixIcon: Icon(Icons.receipt, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expense name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
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

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount',
                        prefixIcon: Icon(Icons.attach_money, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Date Selector
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFFEF4444)),
                            SizedBox(width: 12),
                            Text(
                              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Reason Field
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Reason/Description',
                        hintText: 'Enter reason or description (optional)',
                        prefixIcon: Icon(Icons.notes, color: Color(0xFFEF4444)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Add Expense Record',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}