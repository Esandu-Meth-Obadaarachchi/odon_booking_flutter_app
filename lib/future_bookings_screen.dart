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
      final bookings = await _apiService.fetchFutureBookings(DateTime.now());
      setState(() {
        _futureBookings = bookings;
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
                        selectedDay: DateTime.parse(booking['date']),
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
}
