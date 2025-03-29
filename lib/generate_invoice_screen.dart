import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice.dart';

class Room {
  String type;
  int quantity;

  Room(this.type, this.quantity);
}

class GenerateInvoiceScreen extends StatefulWidget {
  @override
  _GenerateInvoiceScreenState createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();
  final TextEditingController _extraChargesController = TextEditingController();
  final TextEditingController _extraChargesReasonController = TextEditingController();
  final TextEditingController _advanceAmountController = TextEditingController();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  String _packageType = 'Full Board';
  bool _customizePackages = false;
  List<String> _dayPackages = [];
  double _totalAmount = 0.0;
  double _discount = 0.0;
  double _discountPerRoom = 1000.0; // Preset discount amount per room per night

  // Multiple rooms selection
  List<Room> _selectedRooms = [];

  // 2025 Room prices
  Map<String, Map<String, double>> _roomPrices = {
    'Full Board': {
      'Double': 20500.0,
      'Triple': 26250.0,
      'Family': 32000.0,
      'Family Plus': 37750.0,
    },
    'Half Board': {
      'Double': 17000.0,
      'Triple': 21000.0,
      'Family': 25000.0,
      'Family Plus': 29000.0,
    },
    'Bed and Breakfast': {
      'Double': 13500.0,
      'Triple': 15750.0,
      'Family': 18000.0,
      'Family Plus': 20250.0,
    },
    'Room Only': {
      'Double': 11000.0,
      'Triple': 12000.0,
      'Family': 13000.0,
      'Family Plus': 14000.0,
    },
    'Room + Dinner': {
      'Double': 11000.0 + (1750.0 * 2),
      'Triple': 12000.0 + (1750.0 * 3),
      'Family': 13000.0 + (1750.0 * 4),
      'Family Plus': 14000.0 + (1750.0 * 5),
    },
  };

  // Room capacity
  Map<String, int> _roomCapacity = {
    'Double': 2,
    'Triple': 3,
    'Family': 4,
    'Family Plus': 5,
  };

  int get _totalGuests {
    int total = 0;
    for (var room in _selectedRooms) {
      total += _roomCapacity[room.type]! * room.quantity;
    }
    return total;
  }

  // Total room nights for discount calculation
  int get _totalRoomNights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    int nights = _checkOutDate!.difference(_checkInDate!).inDays;
    int total = 0;
    for (var room in _selectedRooms) {
      total += room.quantity * nights;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    // Initialize with one empty room
    _selectedRooms.add(Room('Double', 1));
  }

  void _updateDayPackages() {
    if (_checkInDate != null && _checkOutDate != null) {
      int days = _checkOutDate!.difference(_checkInDate!).inDays;
      _dayPackages = List.filled(days, _packageType);
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    if (_checkInDate == null || _checkOutDate == null) return;

    int days = _checkOutDate!.difference(_checkInDate!).inDays;
    double subtotal = 0.0;
    double roomTotal = 0.0;

    // Calculate for each room
    for (var room in _selectedRooms) {
      if (_customizePackages) {
        for (int i = 0; i < days; i++) {
          if (i < _dayPackages.length) {
            String package = _dayPackages[i];
            roomTotal += (_roomPrices[package]?[room.type] ?? 0.0) * room.quantity;
          } else {
            roomTotal += (_roomPrices[_packageType]?[room.type] ?? 0.0) * room.quantity;
          }
        }
      } else {
        roomTotal += days * (_roomPrices[_packageType]?[room.type] ?? 0.0) * room.quantity;
      }
    }

    subtotal = roomTotal;

    // Calculate discount (Rs 1000 per room per night)
    _discount = _discountPerRoom * _totalRoomNights;

    // Add extra charges if any
    double extraCharges = 0.0;
    if (_extraChargesController.text.isNotEmpty) {
      extraCharges = double.tryParse(_extraChargesController.text) ?? 0.0;
      subtotal += extraCharges;
    }

    setState(() {
      _totalAmount = subtotal - _discount;
    });
  }

  double get _advanceAmount {
    return double.tryParse(_advanceAmountController.text) ?? 0.0;
  }

  double get _remainingBalance {
    return _totalAmount - _advanceAmount;
  }

  void _addRoom() {
    setState(() {
      _selectedRooms.add(Room('Double', 1));
      _calculateTotal();
    });
  }

  void _removeRoom(int index) {
    if (_selectedRooms.length > 1) {
      setState(() {
        _selectedRooms.removeAt(index);
        _calculateTotal();
      });
    }
  }

  void _updateRoomType(int index, String type) {
    setState(() {
      _selectedRooms[index].type = type;
      _calculateTotal();
    });
  }

  void _updateRoomQuantity(int index, int quantity) {
    setState(() {
      _selectedRooms[index].quantity = quantity;
      _calculateTotal();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? (DateTime.now()) : (_checkInDate ?? DateTime.now().add(Duration(days: 1))),
      firstDate: isCheckIn ? DateTime.now() : (_checkInDate ?? DateTime.now()),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          _checkInController.text = DateFormat('yyyy-MM-dd').format(picked);

          // If check-out date is before new check-in date, update it
          if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
            _checkOutDate = _checkInDate!.add(Duration(days: 1));
            _checkOutController.text = DateFormat('yyyy-MM-dd').format(_checkOutDate!);
          }
        } else {
          _checkOutDate = picked;
          _checkOutController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
        _updateDayPackages();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Invoice'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Guest Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Guest Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter guest name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Check-in and Check-out dates
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _checkInController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Check In',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _selectDate(context, true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select check-in date';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _checkOutController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Check Out',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _selectDate(context, false),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select check-out date';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Room Type Selection
                Text(
                  'Select Rooms:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Multiple Room Selection
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _selectedRooms.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Room Type',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedRooms[index].type,
                                items: [
                                  'Double',
                                  'Triple',
                                  'Family',
                                  'Family Plus',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _updateRoomType(index, newValue);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Text('Quantity: '),
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: _selectedRooms[index].quantity > 1
                                        ? () => _updateRoomQuantity(index, _selectedRooms[index].quantity - 1)
                                        : null,
                                  ),
                                  Text('${_selectedRooms[index].quantity}'),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () => _updateRoomQuantity(index, _selectedRooms[index].quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: _selectedRooms.length > 1
                                  ? () => _removeRoom(index)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Add Room Button
                Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Another Room'),
                    onPressed: _addRoom,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Package Selection
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Package',
                    border: OutlineInputBorder(),
                  ),
                  value: _packageType,
                  items: [
                    'Room Only',
                    'Bed and Breakfast',
                    'Half Board',
                    'Full Board',
                    'Room + Dinner',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _packageType = newValue!;
                      _updateDayPackages();
                    });
                  },
                ),
                SizedBox(height: 16),

                // Custom Package Option
                CheckboxListTile(
                  title: Text('Break the days into different packages'),
                  value: _customizePackages,
                  onChanged: (bool? value) {
                    setState(() {
                      _customizePackages = value ?? false;
                      _updateDayPackages();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                // Day-by-day package selection (only shown if customize is checked)
                if (_customizePackages && _checkInDate != null && _checkOutDate != null)
                  _buildDayPackageOptions(),

                SizedBox(height: 16),

                // Extra Charges with Reason
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _extraChargesReasonController,
                        decoration: InputDecoration(
                          labelText: 'Extra Charges Reason',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Airport Transfer, Late Checkout',
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _extraChargesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (LKR)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotal(),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Advance Payment
                TextFormField(
                  controller: _advanceAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Advance Payment (LKR)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}), // Just to refresh UI when value changes
                ),

                SizedBox(height: 24),

                // Summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (_checkInDate != null && _checkOutDate != null) ...[
                        Text('Duration: ${_checkOutDate!.difference(_checkInDate!).inDays} nights'),
                        SizedBox(height: 8),

                        // Room details
                        Text('Rooms:', style: TextStyle(fontWeight: FontWeight.w500)),
                        ..._selectedRooms.map((room) => Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('${room.quantity}x ${room.type} Room'),
                        )).toList(),

                        SizedBox(height: 8),
                        Text('Total Guests: $_totalGuests'),
                        Text('Package: ${_customizePackages ? "Custom Package" : _packageType}'),
                        if (_extraChargesReasonController.text.isNotEmpty && double.tryParse(_extraChargesController.text) != null && double.tryParse(_extraChargesController.text)! > 0)
                          Text('Extra: ${_extraChargesReasonController.text} - LKR ${NumberFormat('#,##0.00').format(double.parse(_extraChargesController.text))}'),
                        SizedBox(height: 8),

                        // Financial breakdown
                        Text('Subtotal: LKR ${NumberFormat('#,##0.00').format(_totalAmount + _discount)}',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('Discount: LKR ${NumberFormat('#,##0.00').format(_discount)}',
                            style: TextStyle(color: Colors.red)),
                        Divider(),
                        Text('Total Amount: LKR ${NumberFormat('#,##0.00').format(_totalAmount)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),

                        if (_advanceAmount > 0) ...[
                          Text('Advance Paid: LKR ${NumberFormat('#,##0.00').format(_advanceAmount)}',
                              style: TextStyle(color: Colors.green)),
                          Text('Balance: LKR ${NumberFormat('#,##0.00').format(_remainingBalance)}',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                        ]
                      ]
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Generate Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _generateInvoice();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text('Generate Invoice', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayPackageOptions() {
    if (_checkInDate == null || _checkOutDate == null) return SizedBox();

    int days = _checkOutDate!.difference(_checkInDate!).inDays;
    List<Widget> dayWidgets = [];

    for (int i = 0; i < days; i++) {
      // Make sure _dayPackages has enough elements
      if (_dayPackages.length <= i) {
        _dayPackages.add(_packageType);
      }

      DateTime day = _checkInDate!.add(Duration(days: i));
      String dayString = DateFormat('MMM d').format(day);

      dayWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Text('Day ${i+1} - $dayString:', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 7,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _dayPackages[i],
                  items: [
                    'Room Only',
                    'Bed and Breakfast',
                    'Half Board',
                    'Full Board',
                    'Room + Dinner',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _dayPackages[i] = newValue!;
                      _calculateTotal();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        ...dayWidgets,
      ],
    );
  }

  void _generateInvoice() async {
    if (_checkInDate == null || _checkOutDate == null) return;

    String packageDetails = _customizePackages
        ? "Custom package with varying meal plans"
        : _packageType;

    // Create room details string
    String roomDetails = _selectedRooms.map((room) =>
    "${room.quantity}x ${room.type}").join(", ");

    // Calculate price breakdown by room type and package
    Map<String, Map<String, dynamic>> priceBreakdown = {};

    if (_checkInDate != null && _checkOutDate != null) {
      int nights = _checkOutDate!.difference(_checkInDate!).inDays;

      for (var room in _selectedRooms) {
        String key = "${room.type} - ${_customizePackages ? "Custom" : _packageType}";
        double roomPrice = 0;

        if (_customizePackages) {
          // This is a simplified calculation for custom packages
          roomPrice = 0;
          for (int i = 0; i < nights && i < _dayPackages.length; i++) {
            roomPrice += _roomPrices[_dayPackages[i]]![room.type]! * room.quantity;
          }
        } else {
          roomPrice = _roomPrices[_packageType]![room.type]! * room.quantity * nights;
        }

        priceBreakdown[key] = {
          'quantity': room.quantity,
          'nights': nights,
          'unitPrice': _roomPrices[_packageType]![room.type],
          'totalPrice': roomPrice
        };
      }
    }

    // Add extra charges if applicable
    if (_extraChargesController.text.isNotEmpty && _extraChargesReasonController.text.isNotEmpty) {
      double extraAmount = double.tryParse(_extraChargesController.text) ?? 0.0;
      if (extraAmount > 0) {
        priceBreakdown[_extraChargesReasonController.text] = {
          'quantity': 1,
          'nights': 1,
          'unitPrice': extraAmount,
          'totalPrice': extraAmount
        };
      }
    }

    await generateInvoice(
      guestName: _nameController.text,
      checkIn: _checkInController.text,
      checkOut: _checkOutController.text,
      numGuests: _totalGuests,
      room: roomDetails,
      packageDetails: packageDetails,
      totalAmount: NumberFormat('#,##0.00').format(_totalAmount + _discount),
      discount: NumberFormat('#,##0.00').format(_discount),
      finalAmount: NumberFormat('#,##0.00').format(_totalAmount),
      advanceAmount: NumberFormat('#,##0.00').format(_advanceAmount),
      balanceAmount: NumberFormat('#,##0.00').format(_remainingBalance),
      priceBreakdown: priceBreakdown,
      extraChargesReason: _extraChargesReasonController.text,
      extraChargesAmount: _extraChargesController.text.isEmpty ? 0 : double.parse(_extraChargesController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice generated and saved to Downloads folder'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _extraChargesController.dispose();
    _extraChargesReasonController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }
}