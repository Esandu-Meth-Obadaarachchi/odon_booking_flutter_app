import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
class AddInventoryItemScreen extends StatefulWidget {
  @override
  _AddInventoryItemScreenState createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _purchasedDate;

  // Function to submit the form
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final itemName = _itemNameController.text.trim();
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
      final purchasedDate = _purchasedDate;

      if (purchasedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a purchase date')),
        );
        return;
      }

      final newItem = {
        'item_name': itemName,
        'quantity': quantity,
        'purchasedDate': purchasedDate.toIso8601String(),
      };

      // Send data to the backend
      try {
        ApiService service = ApiService();
        service.addInventory(newItem);
        print('Sending data to the database: $newItem');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.pop(context); // Return to the previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Inventory Item'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
                    initialDate: DateTime.now(),
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
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}