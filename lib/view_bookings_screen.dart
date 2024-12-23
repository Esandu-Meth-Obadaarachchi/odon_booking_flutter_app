import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'edit_booking_screen.dart';
import 'future_bookings_screen.dart';
import 'past_bookings_screen.dart';
import 'selected_day_booking.dart';

class ViewBookingsScreen extends StatefulWidget {
  @override
  _ViewBookingsScreenState createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends State<ViewBookingsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _bookingsForSelectedDay = [];
  Map<DateTime, List> _events = {};
  int _totalBookingsForMonth = 0; // Total bookings for the current month
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchBookingsForDay(_focusedDay); // Fetch bookings for initial focused day
    _fetchFutureBookings(); // Fetch events for calendar indicators
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

  Future<void> _fetchFutureBookings() async {
    try {
      final bookings = await _apiService.fetchFutureBookings(DateTime.now());
      Map<DateTime, List> events = {};
      int totalRoomNights = 0;

      for (var booking in bookings) {
        DateTime checkInDate = DateTime.parse(booking['checkIn']);
        DateTime checkOutDate = DateTime.parse(booking['checkOut']);

        // Calculate the number of nights for the booking
        int nights = checkOutDate.difference(checkInDate).inDays;

        // Add to total room-nights
        totalRoomNights += nights;

        // Populate events map for the calendar
        if (checkInDate.year == _focusedDay.year && checkInDate.month == _focusedDay.month) {
          if (events[checkInDate] == null) {
            events[checkInDate] = [];
          }
          events[checkInDate]!.add(booking);
        }
      }

      setState(() {
        _events = events;
        _totalBookingsForMonth = totalRoomNights; // Update total room-nights
      });
    } catch (e) {
      print('Failed to fetch future bookings: $e');
    }
  }

  List _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
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
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display total bookings for the month
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Rooms Booked: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Text(
                    '$_totalBookingsForMonth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child:
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
                  _fetchBookingsForDay(selectedDay);
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
                  _fetchFutureBookings();
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(), // Removes the default marker dots
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day);
                    return Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: day == _selectedDay ? Colors.green : Colors.white,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}', // Show the day number
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: day == _focusedDay ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          if (events.isNotEmpty)
                            Positioned(
                              bottom: -3, // Adjusted for better placement
                              child: Text(
                                '${events.length}', // Show the number of bookings
                                style: TextStyle(
                                  fontSize: 14, // Increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FutureBookingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'List Future Bookings',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PastBookingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Past Bookings',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0), // Add spacing between rows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectedDayBookingsScreen(
                          selectedDay: _selectedDay ?? _focusedDay,
                          bookings: _bookingsForSelectedDay,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    "View Selected Day's Bookings",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            Expanded(
              child: _bookingsForSelectedDay.isEmpty
                  ? Center(
                child: Text(
                  'No bookings for selected day',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _bookingsForSelectedDay.length,
                itemBuilder: (context, index) {
                  final booking = _bookingsForSelectedDay[index];
                  final roomNumber = booking['roomNumber'] as String? ?? 'N/A';
                  final roomType = booking['roomType'] as String? ?? 'N/A';
                  final package = booking['package'] as String? ?? 'N/A';
                  final extraDetails = booking['extraDetails'] as String? ?? 'N/A';
                  final checkIn = booking['checkIn'] != null
                      ? DateTime.parse(booking['checkIn'])
                      : null;
                  final checkOut = booking['checkOut'] != null
                      ? DateTime.parse(booking['checkOut'])
                      : null;
                  final numOfNights = booking['num_of_nights']?.toString() ?? 'N/A';

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        'Room $roomNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Type: $roomType\n'
                            'Package: $package\n'
                            'Check-in: ${checkIn != null ? checkIn.toLocal().toString().split(' ')[0] : 'N/A'}\n'
                            'Check-out: ${checkOut != null ? checkOut.toLocal().toString().split(' ')[0] : 'N/A'}\n'
                            'Nights: $numOfNights\n'
                            'Details: $extraDetails',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.indigo),
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