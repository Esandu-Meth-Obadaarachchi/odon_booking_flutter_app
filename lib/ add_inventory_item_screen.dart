import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odon_booking/home_screen.dart';
import 'api_service.dart';
import "edit_inventory_item_screen.dart";
class AddInventoryItemScreen extends StatefulWidget {
  @override
  _AddInventoryItemScreenState createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _purchasedDate;
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _inventoryItems;

  @override
  void initState() {
    super.initState();
    _inventoryItems = _apiService.fetchInventoryItems();
  }

  // Function to submit the form
  void _submitForm() async {
    final itemName = _itemNameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final purchasedDate = _purchasedDate;

    print('Item name: $itemName');
    print('Quantity: $quantity');
    print('Purchased Date: $purchasedDate');
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
        await service.addInventory(newItem); // Ensure this is an async call
        print('Sending data to the database: $newItem');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.pop(context); // Return to the previous screen
      } catch (e) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form validation failed')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inventory Management",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Item',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'These are the item names you should use soap, conditioner, body lotion, shampoo, brush kit.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: _inventoryItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No inventory items available'));
                  }

                  final items = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two cards per row
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.9, // Smaller card height
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildInventoryCard(items[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildInventoryCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () async {
        // Navigate to edit screen when card is tapped
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditInventoryItemScreen(item: item),
          ),
        );

        // If the edit screen returned true (item was updated/deleted), refresh the list
        if (result == true) {
          setState(() {
            _inventoryItems = _apiService.fetchInventoryItems();
          });
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        shadowColor: Colors.grey.shade300,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add tap indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['item_name'] ?? 'Unnamed Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Quantity Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Quantity: ${item['quantity'] ?? '0'}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Purchase Date Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Date: ${item['purchasedDate']?.split('T')[0] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Add hint text
              const Text(
                'Tap to edit',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}