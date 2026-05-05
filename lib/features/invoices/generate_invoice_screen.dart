import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice.dart' as invoice;
import 'invoice.dart';
import 'package:odon_booking/core/api/api_service.dart';
import 'package:odon_booking/features/financials/price_settings_screen.dart';
class Room {
  String type;
  int quantity;

  Room(this.type, this.quantity);
}

class ExtraCharge {
  String reason;
  double amount;

  ExtraCharge({required this.reason, required this.amount});
}

class GenerateInvoiceScreen extends StatefulWidget {
  @override
  _GenerateInvoiceScreenState createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();
  final TextEditingController _additionalDiscountController = TextEditingController();
  final TextEditingController _specialNotesController = TextEditingController();
  final TextEditingController _extraChargesController = TextEditingController();
  final TextEditingController _extraChargesReasonController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _extraChargesController.dispose();
    _extraChargesReasonController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  String _packageType = 'Full Board';
  String _startMeal = 'Lunch'; // To track starting meal for FB/HB
  bool _customizePackages = false;
  List<String> _dayPackages = [];
  double _totalAmount = 0.0;
  double _discount = 0.0;
  double _additionalDiscount = 0.0;
  double _discountPerRoom = 1000.0; // Preset discount amount per room per night
  bool _includeDriverRoom = false;
  double _driverRoomPrice = 2500.0;

  // Extra charges
  List<ExtraCharge> _extraCharges = [];

  // Multiple rooms selection
  List<Room> _selectedRooms = [];

  // Prices loaded from DB; these defaults are used until the API responds
  Map<String, Map<String, double>> _roomPrices = {
    'Full Board':        {'Single': 15250, 'Double': 22500, 'Triple': 28750, 'Family': 35000, 'Family Plus': 42250},
    'Half Board':        {'Single': 13250, 'Double': 18500, 'Triple': 22750, 'Family': 27000, 'Family Plus': 32250},
    'Bed and Breakfast': {'Single': 11250, 'Double': 14500, 'Triple': 16750, 'Family': 19000, 'Family Plus': 22250},
    'Room Only':         {'Single': 10000, 'Double': 12000, 'Triple': 13000, 'Family': 14000, 'Family Plus': 16000},
    'Room + Dinner':     {'Single': 14000, 'Double': 15000, 'Triple': 18000, 'Family': 21000, 'Family Plus': 24000},
  };

  // Room capacity
  Map<String, int> _roomCapacity = {
    'Single': 1,
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

  // Driver room total calculation
  double get _driverRoomTotal {
    if (!_includeDriverRoom || _checkInDate == null || _checkOutDate == null)
      return 0.0;
    int nights = _checkOutDate!.difference(_checkInDate!).inDays;
    return _driverRoomPrice * nights;
  }

  // Sum of all extra charges
  double get _totalExtraCharges {
    return _extraCharges.fold(0.0, (sum, charge) => sum + charge.amount);
  }

  final TextEditingController _advanceAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRooms.add(Room('Double', 1));
    _extraCharges.add(ExtraCharge(reason: '', amount: 0.0));
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final data = await ApiService().fetchPrices();
      final packages = data['packages'] as Map<String, dynamic>;
      setState(() {
        _roomPrices = packages.map(
          (pkg, rooms) => MapEntry(
            pkg,
            (rooms as Map<String, dynamic>).map(
              (room, price) => MapEntry(room, (price as num).toDouble()),
            ),
          ),
        );
        _driverRoomPrice = (data['driverRoomPrice'] as num).toDouble();
      });
      _calculateTotal();
    } catch (_) {
      // Keep using the default prices already set
    }
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
            roomTotal +=
                (_roomPrices[package]?[room.type] ?? 0.0) * room.quantity;
          } else {
            roomTotal +=
                (_roomPrices[_packageType]?[room.type] ?? 0.0) * room.quantity;
          }
        }
      } else {
        roomTotal += days * (_roomPrices[_packageType]?[room.type] ?? 0.0) *
            room.quantity;
      }
    }

    // Add driver room cost if selected
    double driverRoomCost = _driverRoomTotal;

    // Calculate main subtotal (rooms + driver room)
    subtotal = roomTotal + driverRoomCost;

    // Calculate preset discount (Rs 1000 per room per night)
    _discount = _discountPerRoom * _totalRoomNights;

    // Add additional discount if any
    _additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0.0;

    // Add extra charges
    double extraChargesTotal = _totalExtraCharges;

    setState(() {
      _totalAmount =
          subtotal - _discount - _additionalDiscount + extraChargesTotal;
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

  void _addExtraCharge() {
    setState(() {
      _extraCharges.add(ExtraCharge(reason: '', amount: 0.0));
    });
  }

  void _removeExtraCharge(int index) {
    if (_extraCharges.length > 1) {
      setState(() {
        _extraCharges.removeAt(index);
        _calculateTotal();
      });
    } else {
      // Just clear the values if it's the last one
      setState(() {
        _extraCharges[0] = ExtraCharge(reason: '', amount: 0.0);
        _calculateTotal();
      });
    }
  }

  void _updateExtraChargeReason(int index, String reason) {
    setState(() {
      _extraCharges[index].reason = reason;
    });
  }

  void _updateExtraChargeAmount(int index, String amountStr) {
    setState(() {
      _extraCharges[index].amount = double.tryParse(amountStr) ?? 0.0;
      _calculateTotal();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? (DateTime.now()) : (_checkInDate ??
          DateTime.now().add(Duration(days: 1))),
      firstDate: DateTime(2000), // Allows selection from the year 2000 onwards
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          _checkInController.text = DateFormat('yyyy-MM-dd').format(picked);

          // Automatically set check-out date to the next day
          _checkOutDate = _checkInDate!.add(Duration(days: 1));
          _checkOutController.text =
              DateFormat('yyyy-MM-dd').format(_checkOutDate!);
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
        actions: [
          IconButton(
            icon: Icon(Icons.price_change),
            tooltip: 'Edit Room Prices',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PriceSettingsScreen()),
              );
              _fetchPrices(); // reload prices when returning
            },
          ),
        ],
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

                // Guest Phone Number (optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Guest Phone Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
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

                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _selectedRooms.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with room number and delete button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Room ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                            SizedBox(height: 12),

                            // Room Type Dropdown - Full Width
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Room Type',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              value: _selectedRooms[index].type,
                              items: [
                                'Single',
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

                            SizedBox(height: 12),

                            // Quantity Controls - Centered
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Quantity: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove),
                                        onPressed: _selectedRooms[index]
                                            .quantity > 1
                                            ? () =>
                                            _updateRoomQuantity(index,
                                            _selectedRooms[index].quantity - 1)
                                            : null,
                                        constraints: BoxConstraints(
                                            minWidth: 40, minHeight: 40),
                                      ),
                                      Container(
                                        constraints: BoxConstraints(
                                            minWidth: 40),
                                        child: Text(
                                          '${_selectedRooms[index].quantity}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add),
                                        onPressed: () =>
                                            _updateRoomQuantity(
                                            index,
                                            _selectedRooms[index].quantity + 1),
                                        constraints: BoxConstraints(
                                            minWidth: 40, minHeight: 40),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

                // Driver Room Option
                CheckboxListTile(
                  title: Text('Include Driver Room (LKR ${_driverRoomPrice
                      .toStringAsFixed(2)}/night)'),
                  value: _includeDriverRoom,
                  onChanged: (bool? value) {
                    setState(() {
                      _includeDriverRoom = value ?? false;
                      _calculateTotal();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.indigo,
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

                // START: New Starting Meal Selection
                if (_packageType == 'Full Board' ||
                    _packageType == 'Half Board')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starting Meal:', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Lunch'),
                                value: 'Lunch',
                                groupValue: _startMeal,
                                onChanged: (String? value) {
                                  setState(() {
                                    _startMeal = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Dinner'),
                                value: 'Dinner',
                                groupValue: _startMeal,
                                onChanged: (String? value) {
                                  setState(() {
                                    _startMeal = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // END: New Starting Meal Selection

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
                  activeColor: Colors.indigo,
                ),

                // Day-by-day package selection (only shown if customize is checked)
                if (_customizePackages && _checkInDate != null &&
                    _checkOutDate != null)
                  _buildDayPackageOptions(),

                SizedBox(height: 16),

                // Extra Charges Section
                Text(
                  'Extra Charges:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Multiple Extra Charges
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _extraCharges.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: _extraCharges[index].reason,
                                decoration: InputDecoration(
                                  labelText: 'Reason',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., Airport Transfer',
                                ),
                                onChanged: (value) =>
                                    _updateExtraChargeReason(index, value),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: _extraCharges[index].amount > 0
                                    ? _extraCharges[index].amount.toString()
                                    : '',
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount (LKR)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    _updateExtraChargeAmount(index, value),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeExtraCharge(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Add Extra Charge Button
                Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Extra Charge'),
                    onPressed: _addExtraCharge,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Additional Discount
                TextFormField(
                  controller: _additionalDiscountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Additional Discount (LKR)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _calculateTotal(),
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
                  onChanged: (_) =>
                      setState(() {}), // Just to refresh UI when value changes
                ),

                SizedBox(height: 16),

                // Special Notes
                TextFormField(
                  controller: _specialNotesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Special Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Any special requests or notes',
                  ),
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
                      Text('Summary:', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (_checkInDate != null && _checkOutDate != null) ...[
                        Text('Duration: ${_checkOutDate!.difference(
                            _checkInDate!).inDays} nights'),
                        SizedBox(height: 8),

                        // Room details
                        Text('Rooms:', style: TextStyle(
                            fontWeight: FontWeight.w500)),
                        ..._selectedRooms.map((room) =>
                            Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text(
                                  '${room.quantity}x ${room.type} Room'),
                            )).toList(),

                        if (_includeDriverRoom)
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text('1x Driver Room'),
                          ),

                        SizedBox(height: 8),
                        Text('Total Guests: $_totalGuests'),
                        Text('Package: ${_customizePackages
                            ? "Custom Package"
                            : _packageType}'),
                        if (!_customizePackages &&
                            (_packageType == 'Full Board' ||
                                _packageType == 'Half Board'))
                          Text('Starting Meal: $_startMeal'),

                        // Extra charges
                        if (_extraCharges.any((charge) =>
                        charge.reason.isNotEmpty && charge.amount > 0)) ...[
                          SizedBox(height: 8),
                          Text('Extra Charges:',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          ..._extraCharges
                              .where((charge) =>
                          charge.reason.isNotEmpty && charge.amount > 0)
                              .map((charge) =>
                              Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                    '${charge.reason}: LKR ${NumberFormat(
                                        '#,##0.00').format(charge.amount)}'),
                              )).toList(),
                        ],

                        SizedBox(height: 8),

                        // Financial breakdown
                        Text('Subtotal: LKR ${NumberFormat('#,##0.00').format(
                            _totalAmount + _discount + _additionalDiscount -
                                _totalExtraCharges)}',
                            style: TextStyle(fontWeight: FontWeight.w500)),

                        if (_discount > 0)
                          Text('Standard Discount: LKR ${NumberFormat(
                              '#,##0.00').format(_discount)}',
                              style: TextStyle(color: Colors.red)),

                        if (_additionalDiscount > 0)
                          Text('Additional Discount: LKR ${NumberFormat(
                              '#,##0.00').format(_additionalDiscount)}',
                              style: TextStyle(color: Colors.red)),

                        if (_totalExtraCharges > 0)
                          Text('Extra Charges: LKR ${NumberFormat('#,##0.00')
                              .format(_totalExtraCharges)}',
                              style: TextStyle(color: Colors.blue)),

                        Divider(),
                        Text('Total Amount: LKR ${NumberFormat('#,##0.00')
                            .format(_totalAmount)}',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo)),

                        if (_advanceAmount > 0) ...[
                          Text('Advance Paid: LKR ${NumberFormat('#,##0.00')
                              .format(_advanceAmount)}',
                              style: TextStyle(color: Colors.green)),
                          Text('Balance: LKR ${NumberFormat('#,##0.00').format(
                              _remainingBalance)}',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                        ],

                        if (_specialNotesController.text.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text('Special Notes:',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(_specialNotesController.text),
                          ),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                        'Generate Invoice', style: TextStyle(fontSize: 16)),
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
                child: Text('Day ${i + 1} - $dayString:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
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

    if (_includeDriverRoom) {
      roomDetails += ", 1x Driver Room";
    }

    // Determine if start meal should be passed
    String? startMealForInvoice;
    if (!_customizePackages &&
        (_packageType == 'Full Board' || _packageType == 'Half Board')) {
      startMealForInvoice = _startMeal;
    }

    // Calculate price breakdown by room type and package
    Map<String, Map<String, dynamic>> priceBreakdown = {};

    if (_checkInDate != null && _checkOutDate != null) {
      int nights = _checkOutDate!.difference(_checkInDate!).inDays;

      for (var room in _selectedRooms) {
        String key = "${room.type} - ${_customizePackages
            ? "Custom"
            : _packageType}";
        double roomPrice = 0;

        if (_customizePackages) {
          // This is a simplified calculation for custom packages
          roomPrice = 0;
          for (int i = 0; i < nights && i < _dayPackages.length; i++) {
            roomPrice +=
                _roomPrices[_dayPackages[i]]![room.type]! * room.quantity;
          }
        } else {
          roomPrice =
              _roomPrices[_packageType]![room.type]! * room.quantity * nights;
        }

        priceBreakdown[key] = {
          'quantity': room.quantity,
          'nights': nights,
          'unitPrice': _roomPrices[_packageType]![room.type],
          'totalPrice': roomPrice
        };
      }

      // Add driver room if selected
      if (_includeDriverRoom) {
        priceBreakdown["Driver Room"] = {
          'quantity': 1,
          'nights': nights,
          'unitPrice': _driverRoomPrice,
          'totalPrice': _driverRoomPrice * nights
        };
      }
    }


    // Prepare standard fixed notes and combine with user's special notes
    String fixedNotes = """- Once you arrive to check in, please produce the NIC of the person under whose name the booking was made.
- If you need a driver's room, please inform on the same day you make the reservation
- If you need any extra meal please inform the previous day
- Meals brought from outside will not be allowed to have inside the rooms or restaurant
- Swimming Pool will be unavailable after 8.00pm""";

    String combinedNotes = _specialNotesController.text;
    if (combinedNotes.isNotEmpty) {
      combinedNotes += "\n\n";
    }
    combinedNotes += "PLEASE NOTE THAT:\n" + fixedNotes;

    await invoice.generateInvoice(
      guestName: _nameController.text,
      guestPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      checkIn: _checkInController.text,
      checkOut: _checkOutController.text,
      numGuests: _totalGuests,
      room: roomDetails,
      packageDetails: packageDetails,
      startMeal: startMealForInvoice,
      // Pass the selected start meal
      totalAmount: NumberFormat('#,##0.00').format(
          _totalAmount + _discount + _additionalDiscount - _totalExtraCharges),
      standardDiscount: NumberFormat('#,##0.00').format(_discount),
      additionalDiscount: NumberFormat('#,##0.00').format(_additionalDiscount),
      extraCharges: _extraCharges
          .where((charge) => charge.reason.isNotEmpty && charge.amount > 0)
          .map((charge) =>
          invoice.ExtraCharge(reason: charge.reason, amount: charge.amount))
          .toList(),
      finalAmount: NumberFormat('#,##0.00').format(_totalAmount),
      advanceAmount: NumberFormat('#,##0.00').format(_advanceAmount),
      balanceAmount: NumberFormat('#,##0.00').format(_remainingBalance),
      priceBreakdown: priceBreakdown,
      specialNotes: combinedNotes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice generated and saved to Downloads folder'),
        backgroundColor: Colors.green,
      ),
    );
  }


}

