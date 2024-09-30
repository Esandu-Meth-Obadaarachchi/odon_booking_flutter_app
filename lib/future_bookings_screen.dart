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

      // Filter out bookings that have already checked out
      final filteredBookings = bookings.where((booking) {
        DateTime checkInDate = DateTime.parse(booking['checkIn']);
        return checkInDate.isAfter(currentDate); // Only include bookings with future check-ins
      }).toList();

      // Sort filtered bookings by check-in date in ascending order
      filteredBookings.sort((a, b) => DateTime.parse(a['checkIn']).compareTo(DateTime.parse(b['checkIn'])));

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
        iconTheme: IconThemeData(
          color: Colors.white, // Sets the back arrow color to white
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _futureBookings.isEmpty
            ? Center(child: Text('No future bookings found'))
            : ListView.builder(
          itemCount: _futureBookings.length,
          itemBuilder: (context, index) {
            final booking = _futureBookings[index];

            // Parse check-in, check-out, and number of nights fields
            DateTime checkInDate = DateTime.parse(booking['checkIn']);
            DateTime? checkOutDate = booking['checkOut'] != null
                ? DateTime.parse(booking['checkOut'])
                : null;
            final numOfNights = booking['num_of_nights'] ?? 'N/A';

            return ListTile(
              title: Text(
                'Room Number: ${booking['roomNumber'] as String? ?? 'N/A'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Check-in, Check-out, and Number of Nights
                  Text(
                    'Check-in: ${_formatDate(checkInDate)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Check-out: ${checkOutDate != null ? _formatDate(checkOutDate) : 'N/A'}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Nights: $numOfNights',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Display Room Type, Package, and Extra Details
                  Text(
                    'Type: ${booking['roomType'] ?? 'N/A'}, Package: ${booking['package'] ?? 'N/A'}',
                  ),
                  Text(
                    'Details: ${booking['extraDetails'] ?? 'N/A'}',
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
                        selectedDay: checkInDate,
                      ),
                    ),
                  );
                  if (result == true) {
                    _fetchFutureBookings(); // Reload bookings after edit
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Utility to format DateTime as 'DD/MM/YYYY'
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
