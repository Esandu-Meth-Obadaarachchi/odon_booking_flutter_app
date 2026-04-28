import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class RoomSelectionScreen extends StatefulWidget {
  @override
  _RoomSelectionScreenState createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _packageType;
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _extraDetailsController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _advanceAmountController = TextEditingController();

  // Room config fetched from DB
  List<Map<String, dynamic>> _roomConfig = [];
  bool _configLoading = true;

  String? _mealStart;  // 'Lunch' or 'Dinner' — only for Full Board / Half Board
  bool _needDriver = false;

  // Per-room selection state (room number as String, matching config)
  Set<String> _selectedRooms = {};
  Set<String> _extraBedRooms = {};  // rooms upgraded with extra bed
  Set<String> _bookedRooms = {};    // rooms already booked for selected dates

  int _numOfNights = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRoomConfig();
  }

  Future<void> _fetchRoomConfig() async {
    try {
      final config = await _apiService.fetchRoomConfig();
      setState(() {
        _roomConfig = List<Map<String, dynamic>>.from(
          (config['rooms'] as List).map((r) => Map<String, dynamic>.from(r)),
        );
        _configLoading = false;
      });
    } catch (e) {
      setState(() => _configLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load room config: $e')),
      );
    }
  }

  // Derives the effective room type for a room (base type + optional extra bed)
  String _getRoomType(Map<String, dynamic> roomCfg) {
    final baseType = roomCfg['baseType'] as String;
    final hasExtra = _extraBedRooms.contains(roomCfg['roomNumber'] as String);
    if (baseType == 'Family') return hasExtra ? 'Family Plus' : 'Family';
    return hasExtra ? 'Triple' : 'Double';
  }

  int _getPax(String roomType) {
    switch (roomType) {
      case 'Double': return 2;
      case 'Triple': return 3;
      case 'Family': return 4;
      case 'Family Plus': return 5;
      default: return 2;
    }
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        _checkOutDate = picked.add(const Duration(days: 1));
      });
      _calculateNumOfNights();
      _fetchBookingsForDateRange();
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: _checkInDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() => _checkOutDate = picked);
      if (_checkInDate != null) {
        _calculateNumOfNights();
        _fetchBookingsForDateRange();
      }
    }
  }

  void _calculateNumOfNights() {
    if (_checkInDate != null && _checkOutDate != null) {
      setState(() {
        _numOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
      });
    }
  }

  Future<void> _fetchBookingsForDateRange() async {
    if (_checkInDate == null || _checkOutDate == null) return;
    try {
      final bookings = await _apiService.fetchBookingsForDateRange(_checkInDate!, _checkOutDate!);

      final booked = <String>{};
      for (final booking in bookings) {
        final bookingCheckIn = DateTime.parse(booking['checkIn']);
        final bookingCheckOut = DateTime.parse(booking['checkOut']);
        final normBI = DateTime(bookingCheckIn.year, bookingCheckIn.month, bookingCheckIn.day);
        final normBO = DateTime(bookingCheckOut.year, bookingCheckOut.month, bookingCheckOut.day);
        final normCI = DateTime(_checkInDate!.year, _checkInDate!.month, _checkInDate!.day);
        final normCO = DateTime(_checkOutDate!.year, _checkOutDate!.month, _checkOutDate!.day);

        bool overlaps = normCI.isBefore(normBO) && normCO.isAfter(normBI);
        if (normCI.isAtSameMomentAs(normBO)) overlaps = false;

        if (overlaps) {
          // New format: rooms array
          if (booking['rooms'] != null && (booking['rooms'] as List).isNotEmpty) {
            for (final r in booking['rooms'] as List) {
              booked.add(r['roomNumber'].toString());
            }
          } else if (booking['roomNumber'] != null) {
            // Legacy format
            booked.add(booking['roomNumber'].toString());
          }
        }
      }

      setState(() => _bookedRooms = booked);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch existing bookings')),
      );
    }
  }

  Map<String, int> _getInventoryItemsForType(String roomType) {
    switch (roomType) {
      case 'Double':
        return {
          'soap': 1, 'conditioner': 1, 'body lotion': 1, 'shampoo': 1,
          'shower gel': 1, 'dental kit': 1, 'white sugar sachets': 2,
          'milk creamer sachets': 2, 'black tea sachets': 2, 'nescafe sachet': 2,
        };
      case 'Triple':
        return {
          'soap': 1, 'conditioner': 1, 'body lotion': 1, 'shampoo': 1,
          'shower gel': 1, 'dental kit': 2, 'white sugar sachets': 3,
          'milk creamer sachets': 3, 'black tea sachets': 3, 'nescafe sachet': 3,
        };
      case 'Family':
        return {
          'soap': 1, 'conditioner': 1, 'body lotion': 1, 'shampoo': 1,
          'shower gel': 1, 'dental kit': 2, 'white sugar sachets': 4,
          'milk creamer sachets': 4, 'black tea sachets': 4, 'nescafe sachet': 4,
        };
      case 'Family Plus':
        return {
          'soap': 1, 'conditioner': 1, 'body lotion': 1, 'shampoo': 1,
          'shower gel': 1, 'dental kit': 2, 'white sugar sachets': 5,
          'milk creamer sachets': 5, 'black tea sachets': 5, 'nescafe sachet': 5,
        };
      default:
        return {};
    }
  }

  Future<void> _saveBooking() async {
    if (_checkInDate == null ||
        _checkOutDate == null ||
        _packageType == null ||
        _selectedRooms.isEmpty ||
        _guestNameController.text.trim().isEmpty ||
        _guestPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields including guest name and phone')),
      );
      return;
    }

    // Build per-room data
    final roomsData = _selectedRooms.map((roomNum) {
      final cfg = _roomConfig.firstWhere((r) => r['roomNumber'] == roomNum, orElse: () => {});
      final roomType = cfg.isNotEmpty ? _getRoomType(cfg) : 'Double';
      return {
        'roomNumber': roomNum,
        'roomType': roomType,
        'pax': _getPax(roomType),
      };
    }).toList();

    // Accumulate inventory deductions across all rooms
    final Map<String, int> totalDeductions = {};
    for (final roomData in roomsData) {
      final items = _getInventoryItemsForType(roomData['roomType'] as String);
      for (final key in items.keys) {
        totalDeductions[key] = (totalDeductions[key] ?? 0) + items[key]!;
      }
    }

    // Fetch inventory and apply deductions
    List<dynamic> inventoryItems;
    try {
      inventoryItems = await _apiService.fetchInventoryItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch inventory: $e')),
      );
      return;
    }

    bool hasInventoryIssue = false;
    for (final key in totalDeductions.keys) {
      final item = inventoryItems.firstWhere(
        (i) => i['item_name'].toString().toLowerCase() == key,
        orElse: () => null,
      );
      if (item == null || (item['quantity'] ?? 0) < totalDeductions[key]!) {
        hasInventoryIssue = true;
      }
    }

    for (final key in totalDeductions.keys) {
      final item = inventoryItems.firstWhere(
        (i) => i['item_name'].toString().toLowerCase() == key,
        orElse: () => null,
      );
      if (item != null) {
        final updated = (item['quantity'] ?? 0) - totalDeductions[key]!;
        if (updated >= 0) {
          try {
            await _apiService.updateInventoryItem(item['_id'], {
              'item_name': item['item_name'],
              'quantity': updated,
            });
          } catch (_) {}
        }
      }
    }

    final normalizedCheckIn = DateTime.utc(_checkInDate!.year, _checkInDate!.month, _checkInDate!.day);
    final normalizedCheckOut = DateTime.utc(_checkOutDate!.year, _checkOutDate!.month, _checkOutDate!.day);

    final newBooking = {
      'rooms': roomsData,
      'package': _packageType!,
      if (_mealStart != null) 'mealStart': _mealStart,
      'extraDetails': _extraDetailsController.text,
      'checkIn': normalizedCheckIn.toIso8601String(),
      'checkOut': normalizedCheckOut.toIso8601String(),
      'num_of_nights': _numOfNights,
      'total': _totalCostController.text,
      'advance': _advanceAmountController.text,
      'guestName': _guestNameController.text,
      'guestPhone': _guestPhoneController.text,
      'needDriver': _needDriver,
    };

    print('[DEBUG] Saving booking, needDriver=$_needDriver');
    try {
      await _apiService.addBooking(newBooking);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save booking')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasInventoryIssue
            ? 'Booking saved! Check inventory levels.'
            : 'Booking saved and inventory updated.'),
      ),
    );
    _resetBooking();
  }

  void _resetBooking() {
    setState(() {
      _packageType = null;
      _mealStart = null;
      _extraDetailsController.clear();
      _advanceAmountController.clear();
      _totalCostController.clear();
      _guestNameController.clear();
      _guestPhoneController.clear();
      _selectedRooms.clear();
      _extraBedRooms.clear();
      _bookedRooms.clear();
      _checkInDate = null;
      _checkOutDate = null;
      _numOfNights = 0;
      _needDriver = false;
    });
  }

  // ─── Room card ───────────────────────────────────────────────────────────────

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final roomNum = room['roomNumber'] as String;
    final baseType = room['baseType'] as String;
    final isBlocked = room['isBlocked'] == true;
    final isBooked = _bookedRooms.contains(roomNum);
    final isSelected = _selectedRooms.contains(roomNum);
    final hasExtra = _extraBedRooms.contains(roomNum);

    final roomType = isSelected ? _getRoomType(room) : baseType;
    final pax = _getPax(roomType);

    Color bgColor;
    Color textColor = const Color(0xFF1E293B);

    if (isBlocked) {
      bgColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
    } else if (isBooked) {
      bgColor = Colors.red.shade400;
      textColor = Colors.white;
    } else if (isSelected && hasExtra) {
      bgColor = Colors.orange.shade400;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = Colors.green.shade500;
      textColor = Colors.white;
    } else {
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: (isBlocked || isBooked)
          ? null
          : () {
              setState(() {
                if (_selectedRooms.contains(roomNum)) {
                  _selectedRooms.remove(roomNum);
                  _extraBedRooms.remove(roomNum);
                } else {
                  _selectedRooms.add(roomNum);
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (hasExtra ? Colors.orange.shade700 : Colors.green.shade700)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      roomNum.padLeft(3, '0'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBlocked
                          ? 'Blocked'
                          : isBooked
                              ? 'Booked'
                              : (isSelected ? roomType : baseType),
                      style: TextStyle(
                        fontSize: 9,
                        color: textColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${pax}pax',
                        style: TextStyle(
                          fontSize: 9,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Extra bed toggle button — shown only when selected and not blocked/booked
            if (isSelected && !isBlocked && !isBooked)
              Positioned(
                top: 3,
                right: 3,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_extraBedRooms.contains(roomNum)) {
                        _extraBedRooms.remove(roomNum);
                      } else {
                        _extraBedRooms.add(roomNum);
                      }
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: hasExtra ? Colors.white : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasExtra ? Colors.orange.shade700 : Colors.green.shade700,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 13,
                      color: hasExtra ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorGrid(String floor) {
    final rooms = _roomConfig.where((r) => r['floor'] == floor).toList();
    if (rooms.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemCount: rooms.length,
        itemBuilder: (context, index) => _buildRoomCard(rooms[index]),
      ),
    );
  }

  Widget _buildSelectedSummary() {
    if (_selectedRooms.isEmpty) return const SizedBox.shrink();

    final items = _selectedRooms.map((roomNum) {
      final cfg = _roomConfig.firstWhere((r) => r['roomNumber'] == roomNum, orElse: () => {});
      final type = cfg.isNotEmpty ? _getRoomType(cfg) : 'Unknown';
      return '${roomNum.padLeft(3, '0')} ($type)';
    }).join('  |  ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected (${_selectedRooms.length} room${_selectedRooms.length > 1 ? 's' : ''})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(items, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Tap + on a selected room to add an extra bed (upgrades to Triple / Family Plus)',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Booking',
          style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _configLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Guest Name
                    _buildTextField(_guestNameController, 'Guest Name', maxLines: 1),
                    const SizedBox(height: 16),

                    // Guest Phone
                    _buildTextField(_guestPhoneController, 'Guest Phone Number', keyboardType: TextInputType.phone, maxLines: 1),
                    const SizedBox(height: 16),

                    // Check-In / Check-Out
                    Row(
                      children: [
                        Expanded(child: _buildDateButton(
                          label: _checkInDate == null ? 'Check-In Date' : DateFormat('dd MMM yyyy').format(_checkInDate!),
                          onPressed: () => _selectCheckInDate(context),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateButton(
                          label: _checkOutDate == null ? 'Check-Out Date' : DateFormat('dd MMM yyyy').format(_checkOutDate!),
                          onPressed: () => _selectCheckOutDate(context),
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_numOfNights > 0)
                      Center(
                        child: Text(
                          '$_numOfNights night${_numOfNights > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.indigo),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Package
                    _buildDropdown(
                      label: 'Select Package',
                      value: _packageType,
                      items: ['Full Board', 'Half Board', 'Room Only', 'BnB', 'Dinner Only'],
                      onChanged: (v) => setState(() {
                        _packageType = v;
                        // Reset meal start when package no longer needs it
                        if (v != 'Full Board' && v != 'Half Board') _mealStart = null;
                      }),
                    ),
                    if (_packageType == 'Full Board' || _packageType == 'Half Board') ...[
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'First Meal on Arrival',
                        value: _mealStart,
                        items: ['Lunch', 'Dinner'],
                        onChanged: (v) => setState(() => _mealStart = v),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Ground floor rooms
                    const Text(
                      'Ground Floor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    _buildFloorGrid('Ground'),
                    const SizedBox(height: 16),

                    // Upper floor rooms
                    const Text(
                      'Upper Floor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    _buildFloorGrid('Upper'),
                    const SizedBox(height: 14),

                    // Room legend
                    _buildLegend(),
                    const SizedBox(height: 14),

                    // Selected rooms summary
                    _buildSelectedSummary(),
                    const SizedBox(height: 16),

                    // Driver room checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _needDriver,
                            activeColor: Colors.indigo,
                            onChanged: (v) => setState(() => _needDriver = v ?? false),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.drive_eta, size: 18, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Text('Requires Driver Room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Extra Details
                    _buildTextField(_extraDetailsController, 'Extra Details', maxLines: 3),
                    const SizedBox(height: 16),

                    // Total cost
                    _buildTextField(_totalCostController, 'Total Cost', keyboardType: TextInputType.number, maxLines: 1),
                    const SizedBox(height: 16),

                    // Advance
                    _buildTextField(_advanceAmountController, 'Advance Amount', keyboardType: TextInputType.number, maxLines: 1),
                    const SizedBox(height: 24),

                    // Save
                    ElevatedButton(
                      onPressed: _saveBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                      ),
                      child: const Text('Save Booking', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendChip(Colors.white, Colors.grey.shade400, 'Available'),
        _legendChip(Colors.green.shade500, Colors.green.shade500, 'Selected'),
        _legendChip(Colors.orange.shade400, Colors.orange.shade400, 'Selected + extra bed'),
        _legendChip(Colors.red.shade400, Colors.red.shade400, 'Booked'),
        _legendChip(Colors.grey.shade300, Colors.grey.shade300, 'Blocked'),
      ],
    );
  }

  Widget _legendChip(Color fill, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
      ),
    );
  }

  Widget _buildDateButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.indigo,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.indigo, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
        items: items.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
