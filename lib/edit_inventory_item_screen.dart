import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class EditInventoryItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditInventoryItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditInventoryItemScreenState createState() => _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState extends State<EditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _addQuantityController = TextEditingController();
  final TextEditingController _removeQuantityController = TextEditingController();
  DateTime? _purchasedDate;
  final ApiService _apiService = ApiService();

  int currentQuantity = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing item data
    _itemNameController.text = widget.item['item_name'] ?? '';
    currentQuantity = widget.item['quantity'] ?? 0;
    _quantityController.text = currentQuantity.toString();

    // Parse the purchased date
    if (widget.item['purchasedDate'] != null) {
      try {
        _purchasedDate = DateTime.parse(widget.item['purchasedDate']);
      } catch (e) {
        _purchasedDate = DateTime.now();
      }
    }
  }

  void _addQuantity() {
    final addAmount = int.tryParse(_addQuantityController.text.trim()) ?? 0;
    if (addAmount > 0) {
      setState(() {
        currentQuantity += addAmount;
        _quantityController.text = currentQuantity.toString();
      });
      _addQuantityController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $addAmount items')),
      );
    }
  }

  void _removeQuantity() {
    final removeAmount = int.tryParse(_removeQuantityController.text.trim()) ?? 0;
    if (removeAmount > 0) {
      if (removeAmount <= currentQuantity) {
        setState(() {
          currentQuantity -= removeAmount;
          _quantityController.text = currentQuantity.toString();
        });
        _removeQuantityController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $removeAmount items')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot remove more items than available')),
        );
      }
    }
  }

  void _updateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final updatedItem = {
        'item_name': _itemNameController.text.trim(),
        'quantity': currentQuantity,
        'purchasedDate': _purchasedDate?.toIso8601String(),
      };

      try {
        await _apiService.updateInventoryItem(widget.item['_id'], updatedItem);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${_itemNameController.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.deleteInventoryItem(widget.item['_id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Inventory Item",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _isLoading ? null : _deleteItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Item Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Item Name Field
                TextFormField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Current Quantity Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    border: Border.all(color: Colors.indigo.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Current Quantity: $currentQuantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Add Section
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _addQuantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity to Add',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addQuantity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Remove Section
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remove Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _removeQuantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity to Remove',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _removeQuantity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Direct Quantity Edit
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Set Total Quantity',
                    border: OutlineInputBorder(),
                    helperText: 'Or directly set the total quantity',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newQuantity = int.tryParse(value) ?? 0;
                    setState(() {
                      currentQuantity = newQuantity;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the quantity';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Purchase Date
                ListTile(
                  title: Text(
                    _purchasedDate == null
                        ? 'Select Purchase Date'
                        : 'Purchased Date: ${DateFormat('yyyy-MM-dd').format(_purchasedDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _purchasedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _purchasedDate = selectedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Update Item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _addQuantityController.dispose();
    _removeQuantityController.dispose();
    super.dispose();
  }
}