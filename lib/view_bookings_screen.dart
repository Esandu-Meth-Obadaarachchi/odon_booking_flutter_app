import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'edit_booking_screen.dart';
import 'future_bookings_screen.dart'; // Import the correct file

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
          final bookingDate = DateTime.parse(booking['date']);
          return isSameDay(bookingDate, day);
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
            ElevatedButton( // Button to navigate to future bookings screen
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
            Expanded(
              child: _bookingsForSelectedDay.isEmpty
                  ? Center(child: Text('No bookings for selected day'))
                  : ListView.builder(
                itemCount: _bookingsForSelectedDay.length,
                itemBuilder: (context, index) {
                  final booking = _bookingsForSelectedDay[index];
                  return ListTile(
                    title: Text(
                      booking['roomNumber'] as String? ?? '',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Type: ${booking['roomType']}, Package: ${booking['package']}\nDetails: ${booking['extraDetails']}',
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
