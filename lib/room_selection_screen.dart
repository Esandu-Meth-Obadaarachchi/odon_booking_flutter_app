import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class RoomSelectionScreen extends StatefulWidget {
  final String floor;
  final int rooms;
  final int startingRoomNumber;

  RoomSelectionScreen({
    required this.floor,
    required this.rooms,
    required this.startingRoomNumber,
  });

  @override
  _RoomSelectionScreenState createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  DateTime? _selectedDate;
  String? _roomType;
  String? _packageType;
  final TextEditingController _extraDetailsController = TextEditingController();
  Set<int> _selectedRooms = {};
  Set<int> _bookedRooms = {}; // To store the rooms already booked for the selected date
  final ApiService _apiService = ApiService();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Fetch bookings for the selected date
      await _fetchBookingsForDate(picked);
    }
  }

  Future<void> _fetchBookingsForDate(DateTime date) async {
    try {
      print('Fetching bookings for date: ${date.toIso8601String()}');
      List<Map<String, dynamic>> bookings = await _apiService.fetchBookings(date);

      print('Fetched bookings: $bookings'); // Debug: print fetched bookings

      setState(() {
        // Filter bookings to include only those that match the selected date
        _bookedRooms = bookings
            .where((booking) {
          // Parse the booking date and compare it with the selected date
          DateTime bookingDate = DateTime.parse(booking['date']);
          bool isSameDay = bookingDate.year == date.year &&
              bookingDate.month == date.month &&
              bookingDate.day == date.day;

          if (isSameDay) {
            int roomNumber = int.parse(booking['roomNumber']);
            print('Booked room for selected date: $roomNumber'); // Debug: print each booked room number for selected date
            return true;
          }
          return false;
        })
            .map((booking) => int.parse(booking['roomNumber']))
            .toSet();
      });

      print('Booked rooms for selected date set: $_bookedRooms'); // Debug: print the final booked rooms set for selected date
    } catch (e) {
      print('Failed to fetch bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch bookings')),
      );
    }
  }

  void _resetBooking() {
    setState(() {
      _selectedDate = null;
      _roomType = null;
      _packageType = null;
      _extraDetailsController.clear();
      _selectedRooms.clear();
      _bookedRooms.clear();
    });
  }

  Future<void> _saveBooking() async {
    if (_selectedDate == null ||
        _roomType == null ||
        _packageType == null ||
        _selectedRooms.isEmpty) {
      // Show error message if any required field is missing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields and select rooms')),
      );
      return;
    }

    for (int roomNumber in _selectedRooms) {
      final adjustedDate = _selectedDate!.add(Duration(days: 1)); // Adjust the date
      final newBooking = {
        'roomNumber': roomNumber.toString(),
        'roomType': _roomType!,
        'package': _packageType!,
        'extraDetails': _extraDetailsController.text,
        'date': adjustedDate.toIso8601String(),
      };

      try {
        await _apiService.addBooking(newBooking);
      } catch (e) {
        print('Failed to add booking: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save booking')),
        );
        return;
      }
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking(s) saved successfully')),
    );

    // Reset booking form
    _resetBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: Text(
        widget.floor,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'outfit',
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.indigo,
      iconTheme: IconThemeData(
        color: Colors.white, // Sets the back arrow color to white
      ),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _roomType,
              decoration: InputDecoration(labelText: 'Select Room Type'),
              items: ['Family', 'Family Plus', 'Triple', 'Double']
                  .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _roomType = value;
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _packageType,
              decoration: InputDecoration(labelText: 'Select Package Type'),
              items: ['Full Board', 'Half Board', 'Room Only', 'BnB']
                  .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _packageType = value;
                });
              },
            ),
            TextField(
              controller: _extraDetailsController,
              decoration: InputDecoration(labelText: 'Extra Details'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: widget.rooms,
                  itemBuilder: (context, index) {
                    int roomNumber = widget.startingRoomNumber + index;

                    // Check if the room is already booked
                    bool isBooked = _bookedRooms.contains(roomNumber);

                    print('Processing room number: $roomNumber, isBooked: $isBooked'); // Debug: print room processing details

                    return ElevatedButton(
                      onPressed: isBooked
                          ? null // Disable button if room is booked
                          : () {
                        setState(() {
                          if (_selectedRooms.contains(roomNumber)) {
                            _selectedRooms.remove(roomNumber);
                          } else {
                            _selectedRooms.add(roomNumber);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: isBooked
                            ? Colors.red // Mark booked rooms in red
                            : (_selectedRooms.contains(roomNumber)
                            ? Colors.green
                            : Colors.white),
                        padding: EdgeInsets.all(8.0),
                      ),
                      child: Text(
                        roomNumber.toString().padLeft(3, '0'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveBooking,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Save Booking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
