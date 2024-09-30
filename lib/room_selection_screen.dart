import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
//now WHAT I HAVE TO DO IS PUT A SCREEN TO ASSIGN ROOM TYPE TO ROOMS , AND ALSO BLOCKING BOOKED ONES DOESNT WORK
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
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _roomType;
  String? _packageType;
  final TextEditingController _extraDetailsController = TextEditingController();
  Set<int> _selectedRooms = {};
  Set<int> _bookedRooms = {};
  final ApiService _apiService = ApiService();

  int _numOfNights = 0;

  // Method to select check-in date
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
      });

      if (_checkOutDate != null) {
        _calculateNumOfNights();
        _fetchBookingsForDateRange(); // Fetch bookings for the selected range
      }
    }
  }

  // Method to select check-out date
  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: _checkInDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });

      if (_checkInDate != null) {
        _calculateNumOfNights();
        _fetchBookingsForDateRange(); // Fetch bookings for the selected range
      }
    }
  }

  // Calculate number of nights based on check-in and check-out
  void _calculateNumOfNights() {
    if (_checkInDate != null && _checkOutDate != null) {
      setState(() {
        _numOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
      });
    }
  }

  Future<void> _fetchBookingsForDateRange() async {
    if (_checkInDate == null || _checkOutDate == null) {
      print('No check-in or check-out date selected');
      return;
    }

    try {
      // Fetch all bookings for the selected date range
      List<Map<String, dynamic>> bookings = await _apiService.fetchBookingsForDateRange(_checkInDate!, _checkOutDate!);

      setState(() {
        _bookedRooms = bookings
            .where((booking) {
          DateTime bookingCheckIn = DateTime.parse(booking['checkIn']);
          DateTime bookingCheckOut = DateTime.parse(booking['checkOut']);

          // Normalize both booking and user-selected dates to ignore the time part
          DateTime normalizedBookingCheckIn = DateTime(bookingCheckIn.year, bookingCheckIn.month, bookingCheckIn.day);
          DateTime normalizedBookingCheckOut = DateTime(bookingCheckOut.year, bookingCheckOut.month, bookingCheckOut.day);
          DateTime normalizedCheckIn = DateTime(_checkInDate!.year, _checkInDate!.month, _checkInDate!.day);
          DateTime normalizedCheckOut = DateTime(_checkOutDate!.year, _checkOutDate!.month, _checkOutDate!.day);

          // Print fetched room details for debugging
          print('Fetched booking - Room: ${booking['roomNumber']}, Check-in: $bookingCheckIn, Check-out: $bookingCheckOut');

          // Check if there's an overlap in booking (ignoring time, comparing only dates)
          bool isBooked = normalizedCheckIn.isBefore(normalizedBookingCheckOut) &&
              normalizedCheckOut.isAfter(normalizedBookingCheckIn);

          // Debugging: Print the overlap check
          print('Normalized Check-In: $normalizedCheckIn, Check-Out: $normalizedCheckOut');
          print('Comparing with Booking - Room: ${booking['roomNumber']}, Normalized Booking Check-In: $normalizedBookingCheckIn, Normalized Booking Check-Out: $normalizedBookingCheckOut');
          print('Is Booked (before checkout logic): $isBooked');

          // Logic to handle the case where the check-in date is on the day of the checkout
          if (normalizedCheckIn.isAtSameMomentAs(normalizedBookingCheckOut)) {
            isBooked = false; // Room should be available for booking on the checkout day
            print('Check-in is on checkout day, so not booked: Room ${booking['roomNumber']}');
          }

          // Final debug statement to confirm the booking status
          print('Final isBooked for Room ${booking['roomNumber']}: $isBooked');

          return isBooked;
        })
            .map((booking) => int.parse(booking['roomNumber']))
            .toSet();

        // Debugging: Print the final booked rooms
        print('Booked rooms for the selected range: $_bookedRooms');
      });
    } catch (e) {
      print('Failed to fetch bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch bookings')),
      );
    }
  }





  Future<void> _saveBooking() async {
    if (_checkInDate == null || _checkOutDate == null || _roomType == null || _packageType == null || _selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields and select rooms')),
      );
      return;
    }

    // Normalize check-in and check-out dates to avoid timezone issues
    DateTime normalizedCheckInDate = DateTime(_checkInDate!.year, _checkInDate!.month, _checkInDate!.day);
    DateTime normalizedCheckOutDate = DateTime(_checkOutDate!.year, _checkOutDate!.month, _checkOutDate!.day);

    for (int roomNumber in _selectedRooms) {
      // Assuming normalizedCheckInDate and normalizedCheckOutDate are DateTime objects
      final newCheckInDate = normalizedCheckInDate.add(Duration(days: 1));
      final newCheckOutDate = normalizedCheckOutDate.add(Duration(days: 1));
      //
      final newBooking = {
        'roomNumber': roomNumber.toString(),
        'roomType': _roomType!,
        'package': _packageType!,
        'extraDetails': _extraDetailsController.text,
        'checkIn': newCheckInDate.toIso8601String(),
        'checkOut': newCheckOutDate.toIso8601String(),
        'num_of_nights': _numOfNights,
      };


    try {
        await _apiService.addBooking(newBooking);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save booking')),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking(s) saved successfully')),
    );

    _resetBooking();
  }


  void _resetBooking() {
    setState(() {
      _roomType = null;
      _packageType = null;
      _extraDetailsController.clear();
      _selectedRooms.clear();
      _bookedRooms.clear();
      _checkInDate = null;
      _checkOutDate = null;
      _numOfNights = 0;
    });
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
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () => _selectCheckInDate(context),
              child: Text(
                _checkInDate == null
                    ? 'Select Check-In Date'
                    : DateFormat('yyyy-MM-dd').format(_checkInDate!),
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => _selectCheckOutDate(context),
              child: Text(
                _checkOutDate == null
                    ? 'Select Check-Out Date'
                    : DateFormat('yyyy-MM-dd').format(_checkOutDate!),
                style: TextStyle(fontSize: 16),
              ),
            ),
            Text(
              'Number of Nights: $_numOfNights',
              style: TextStyle(fontSize: 16),
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

                    // Check if the room is already booked for the selected date range
                    bool isBooked = _bookedRooms.contains(roomNumber);

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
