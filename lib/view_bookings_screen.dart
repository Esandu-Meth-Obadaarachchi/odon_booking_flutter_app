// lib/view_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'edit_booking_screen.dart';

class ViewBookingsScreen extends StatefulWidget {
  @override
  _ViewBookingsScreenState createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends State<ViewBookingsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dummy bookings data
  final Map<DateTime, List<Map<String, String>>> _bookings = {
    DateTime.utc(2024, 7, 7): [
      {
        'roomNumber': 'Room 101',
        'roomType': 'Family',
        'packageType': 'Full Board',
        'extraDetails': 'Near pool',
      },
      {
        'roomNumber': 'Room 102',
        'roomType': 'Double',
        'packageType': 'BnB',
        'extraDetails': 'Sea view',
      },
    ],
    DateTime.utc(2024, 7, 10): [
      {
        'roomNumber': 'Room 103',
        'roomType': 'Triple',
        'packageType': 'Half Board',
        'extraDetails': 'High floor',
      },
    ],
    DateTime.utc(2024, 7, 15): [
      {
        'roomNumber': 'Room 201',
        'roomType': 'Family Plus',
        'packageType': 'Room Only',
        'extraDetails': 'Corner room',
      },
      {
        'roomNumber': 'Room 202',
        'roomType': 'Double',
        'packageType': 'Full Board',
        'extraDetails': 'Garden view',
      },
      {
        'roomNumber': 'Room 203',
        'roomType': 'Family',
        'packageType': 'Half Board',
        'extraDetails': 'Near elevator',
      },
    ],
  };

  List<Map<String, String>> _getBookingsForDay(DateTime day) {
    return _bookings[day] ?? [];
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
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getBookingsForDay,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _getBookingsForDay(_selectedDay ?? _focusedDay).length,
                itemBuilder: (context, index) {
                  final booking = _getBookingsForDay(_selectedDay ?? _focusedDay)[index];
                  return ListTile(
                    title: Text(
                      booking['roomNumber']!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Type: ${booking['roomType']}, Package: ${booking['packageType']}\nDetails: ${booking['extraDetails']}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBookingScreen(
                              booking: booking,
                              selectedDay: _selectedDay ?? _focusedDay,
                            ),
                          ),
                        );
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
