import 'package:flutter/material.dart';
import 'api_service.dart';
import 'edit_booking_screen.dart';

class FutureBookingsScreen extends StatefulWidget {
  @override
  _FutureBookingsScreenState createState() => _FutureBookingsScreenState();
}

class _FutureBookingsScreenState extends State<FutureBookingsScreen> {
  List<Map<String, dynamic>> _futureBookings = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchFutureBookings();
  }

  Future<void> _fetchFutureBookings() async {
    try {
      final DateTime currentDate = DateTime.now();
      final bookings = await _apiService.fetchFutureBookings(currentDate);

      // Filter out past bookings
      final filteredBookings = bookings.where((booking) {
        DateTime bookingDate = DateTime.parse(booking['date']);
        return bookingDate.isAfter(currentDate); // Only include bookings ahead of current date
      }).toList();

      // Sort filtered bookings by date in ascending order
      filteredBookings.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      setState(() {
        _futureBookings = filteredBookings;
      });
    } catch (e) {
      print('Failed to fetch future bookings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Future Bookings',
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
        child: _futureBookings.isEmpty
            ? Center(child: Text('No future bookings found'))
            : ListView.builder(
          itemCount: _futureBookings.length,
          itemBuilder: (context, index) {
            final booking = _futureBookings[index];
            DateTime bookingDate = DateTime.parse(booking['date']);
            return ListTile(
              title: Text(
                booking['roomNumber'] as String? ?? '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${_formatDate(bookingDate)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Type: ${booking['roomType']}, Package: ${booking['package']}',
                  ),
                  Text(
                    'Details: ${booking['extraDetails']}',
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBookingScreen(
                        booking: booking,
                        selectedDay: bookingDate,
                      ),
                    ),
                  );
                  if (result == true) {
                    _fetchFutureBookings();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
