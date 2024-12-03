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

      // Filter and sort bookings
      final filteredBookings = bookings.where((booking) {
        DateTime checkInDate = DateTime.parse(booking['checkIn']);
        return checkInDate.isAfter(currentDate);
      }).toList()
        ..sort((a, b) => DateTime.parse(a['checkIn']).compareTo(DateTime.parse(b['checkIn'])));

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
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _futureBookings.isEmpty
            ? Center(
          child: Text(
            'No future bookings found',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
        )
            : ListView.builder(
          itemCount: _futureBookings.length,
          itemBuilder: (context, index) {
            final booking = _futureBookings[index];

            // Parse dates and data
            DateTime checkInDate = DateTime.parse(booking['checkIn']);
            DateTime? checkOutDate = booking['checkOut'] != null
                ? DateTime.parse(booking['checkOut'])
                : null;
            final numOfNights = booking['num_of_nights'] ?? 'N/A';

            return Card(
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room Number: ${booking['roomNumber'] +" => "+_formatDate(checkInDate).toString() as String? ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBookingDetail(
                          'Check-in',
                          _formatDate(checkInDate).toString(),
                        ),
                        _buildBookingDetail(
                          'Check-out',
                          checkOutDate != null
                              ? _formatDate(checkOutDate).toString()
                              : 'N/A',
                        ),
                        _buildBookingDetail('Nights', numOfNights.toString()),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Type: ${booking['roomType'] ?? 'N/A'}, Package: ${booking['package'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Details: ${booking['extraDetails'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
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
                            _fetchFutureBookings();
                          }
                        },
                        icon: Icon(Icons.edit, size: 18,color: Colors.white,),
                        label: Text(
                          'Edit Booking',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper to build individual booking details
  Widget _buildBookingDetail(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}