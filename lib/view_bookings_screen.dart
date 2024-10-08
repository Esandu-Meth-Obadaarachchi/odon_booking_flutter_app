import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'edit_booking_screen.dart';
import 'future_bookings_screen.dart'; // Import the correct file
import 'past_bookings_screen.dart';

class ViewBookingsScreen extends StatefulWidget {
  @override
  _ViewBookingsScreenState createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends State<ViewBookingsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _bookingsForSelectedDay = [];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchBookingsForDay(_focusedDay); // Fetch bookings for initial focused day
  }

  Future<void> _fetchBookingsForDay(DateTime day) async {
    try {
      final bookings = await _apiService.fetchBookings(day);
      setState(() {
        _bookingsForSelectedDay = bookings.where((booking) {
          final checkInDate = DateTime.parse(booking['checkIn']);
          return isSameDay(checkInDate, day);
        }).toList();
      });
    } catch (e) {
      print('Failed to fetch bookings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Bookings',
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
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _fetchBookingsForDay(selectedDay); // Update bookings for selected day
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _fetchBookingsForDay(focusedDay); // Fetch bookings when calendar page changes
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FutureBookingsScreen(),
                  ),
                );
              },
              child: Text('List All Future Bookings'),
            ),
            const SizedBox(height: 8.0), // Add space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PastBookingsScreen(),
                  ),
                );
              },
              child: Text('Past Bookings'),
            ),
            Expanded(
              child: _bookingsForSelectedDay.isEmpty
                  ? Center(child: Text('No bookings for selected day'))
                  : ListView.builder(
                itemCount: _bookingsForSelectedDay.length,
                itemBuilder: (context, index) {
                  final booking = _bookingsForSelectedDay[index];

                  // Adding null checks with defaults where necessary
                  final roomNumber = booking['roomNumber'] as String? ?? 'N/A';
                  final roomType = booking['roomType'] as String? ?? 'N/A';
                  final package = booking['package'] as String? ?? 'N/A';
                  final extraDetails = booking['extraDetails'] as String? ?? 'N/A';

                  // Parsing new fields: checkIn, checkOut, num_of_nights
                  final checkIn = booking['checkIn'] != null
                      ? DateTime.parse(booking['checkIn']).subtract(Duration(days: 1))
                      : null;
                  final checkOut = booking['checkOut'] != null
                      ? DateTime.parse(booking['checkOut']).subtract(Duration(days: 1))
                      : null;
                  final num_of_nights = booking['num_of_nights'] != null
                      ? booking['num_of_nights'].toString()
                      : 'N/A';
                  return ListTile(
                    title: Text(
                      'Room number: $roomNumber'
                      ,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Type: $roomType, Package: $package\n'
                          'Details: $extraDetails\n'
                          'Check-in: ${checkIn != null ? checkIn.toLocal().toString().split(' ')[0] : 'N/A'}\n'
                          'Check-out: ${checkOut != null ? checkOut.toLocal().toString().split(' ')[0] : 'N/A'}\n'
                          'Nights: $num_of_nights',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBookingScreen(
                              booking: booking,
                              selectedDay: _selectedDay ?? _focusedDay,
                            ),
                          ),
                        );
                        if (result == true) {
                          _fetchBookingsForDay(_selectedDay ?? _focusedDay);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

