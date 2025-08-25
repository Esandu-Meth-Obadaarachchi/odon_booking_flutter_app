import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataConfirmationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const DataConfirmationDialog({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _DataConfirmationDialogState createState() => _DataConfirmationDialogState();
}

class _DataConfirmationDialogState extends State<DataConfirmationDialog> {
  late List<DataItem> items;
  List<bool> selectedItems = [];

  @override
  void initState() {
    super.initState();
    items = widget.data.map((data) => DataItem.fromMap(data)).toList();
    selectedItems = List.filled(items.length, true); // All selected by default
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Confirm Extracted Data',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFEF4444),
        ),
      ),
      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              'AI extracted ${items.length} item${items.length > 1 ? 's' : ''}. Review, categorize, and edit if needed:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: selectedItems[index],
                                onChanged: (value) {
                                  setState(() {
                                    selectedItems[index] = value ?? false;
                                  });
                                },
                                activeColor: Color(0xFFEF4444),
                              ),
                              Expanded(
                                child: Text(
                                  items[index].itemName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Color(0xFFEF4444)),
                                onPressed: () => _editItem(index),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _buildItemDetails(index),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _getSelectedCount() > 0 ? _confirmData : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text('Add ${_getSelectedCount()} Item${_getSelectedCount() > 1 ? 's' : ''}'),
        ),
      ],
    );
  }

  Widget _buildItemDetails(int index) {
    final item = items[index];

    return Column(
      children: [
        _buildDetailRow('Type', item.itemType),
        _buildDetailRow('Category', item.category),
        _buildDetailRow('Amount', '\$${item.amount?.toStringAsFixed(2) ?? '0.00'}'),
        _buildDetailRow('Date', _formatDate(item.date)),
        if (item.description?.isNotEmpty == true)
          _buildDetailRow('Description', item.description!),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: value == 'Salary' ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value == 'Salary' ? Colors.green[200]! : Colors.blue[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: value == 'Salary' ? Colors.green[700] : Colors.blue[700],
                  fontWeight: label == 'Type' ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getSelectedCount() {
    return selectedItems.where((selected) => selected).length;
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: items[index],
        onSave: (editedItem) {
          setState(() {
            items[index] = editedItem;
          });
        },
      ),
    );
  }

  void _confirmData() {
    final salaryData = <Map<String, dynamic>>[];
    final expenseData = <Map<String, dynamic>>[];

    for (int i = 0; i < items.length; i++) {
      if (selectedItems[i]) {
        final itemMap = items[i].toMap();
        if (items[i].itemType.toLowerCase() == 'salary') {
          salaryData.add(itemMap);
        } else {
          expenseData.add(itemMap);
        }
      }
    }

    // Return both salary and expense data
    Navigator.pop(context, {
      'salaryData': salaryData,
      'expenseData': expenseData,
    });
  }
}

class _EditItemDialog extends StatefulWidget {
  final DataItem item;
  final Function(DataItem) onSave;

  const _EditItemDialog({
    required this.item,
    required this.onSave,
  });

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late String selectedType;
  late String selectedCategory;
  late DateTime selectedDate;

  final List<String> itemTypes = ['Salary', 'Expense'];
  final List<String> salaryCategories = ['OT', 'Monthly', 'Weekly', 'Commission'];
  final List<String> expenseCategories = [
    'Food', 'Utilities', 'Maintenance', 'Supplies',
    'Transportation', 'Marketing', 'Equipment', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.itemName);
    amountController = TextEditingController(text: widget.item.amount?.toString() ?? '');
    descriptionController = TextEditingController(text: widget.item.description ?? '');
    selectedType = widget.item.itemType;
    selectedCategory = widget.item.category;
    selectedDate = widget.item.date ?? DateTime.now();
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Item Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  selectedType == 'Salary' ? Icons.person : Icons.receipt,
                  color: selectedType == 'Salary' ? Colors.green : Colors.blue,
                ),
              ),
              items: itemTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                  // Reset category when type changes
                  if (selectedType == 'Salary') {
                    selectedCategory = salaryCategories.contains(selectedCategory)
                        ? selectedCategory
                        : salaryCategories.first;
                  } else {
                    selectedCategory = expenseCategories.contains(selectedCategory)
                        ? selectedCategory
                        : expenseCategories.first;
                  }
                });
              },
            ),
            SizedBox(height: 16),

            // Item Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: selectedType == 'Salary' ? 'Employee Name' : 'Expense Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            SizedBox(height: 16),

            // Category Dropdown (changes based on type)
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: (selectedType == 'Salary' ? salaryCategories : expenseCategories)
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
            ),
            SizedBox(height: 16),

            // Amount
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            SizedBox(height: 16),

            // Description
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description/Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final editedItem = DataItem(
      itemName: nameController.text,
      amount: double.tryParse(amountController.text) ?? 0.0,
      date: selectedDate,
      itemType: selectedType,
      category: selectedCategory,
      description: descriptionController.text,
    );

    widget.onSave(editedItem);
    Navigator.pop(context);
  }
}

class DataItem {
  final String itemName;
  final double? amount;
  final DateTime? date;
  final String itemType; // 'Salary' or 'Expense'
  final String category;
  final String? description;

  DataItem({
    required this.itemName,
    this.amount,
    this.date,
    required this.itemType,
    required this.category,
    this.description,
  });

  factory DataItem.fromMap(Map<String, dynamic> map) {
    final suggestedType = map['suggestedType']?.toString().toLowerCase() ?? 'expense';
    return DataItem(
      itemName: map['itemName']?.toString() ?? '',
      amount: map['amount'] is double
          ? map['amount']
          : double.tryParse(map['amount']?.toString() ?? '0'),
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      itemType: suggestedType == 'salary' ? 'Salary' : 'Expense',
      category: map['suggestedCategory']?.toString() ?? 'Other',
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    if (itemType == 'Salary') {
      // Convert to salary format
      return {
        'employeeName': itemName,
        'salaryType': category,
        'amount': amount,
        'date': date?.toIso8601String(),
      };
    } else {
      // Convert to expense format
      return {
        'expenseName': itemName,
        'category': category,
        'amount': amount,
        'date': date?.toIso8601String(),
        'reason': description,
      };
    }
  }
}