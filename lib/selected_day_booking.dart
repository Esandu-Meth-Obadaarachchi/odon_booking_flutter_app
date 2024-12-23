import 'package:flutter/material.dart';

class SelectedDayBookingsScreen extends StatelessWidget {
  final DateTime selectedDay;
  final List<Map<String, dynamic>> bookings;

  SelectedDayBookingsScreen({
    required this.selectedDay,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bookings for ${selectedDay.toLocal().toString().split(' ')[0]}",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bookings.isEmpty
            ? Center(
          child: Text(
            'No bookings for selected day',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
        )
            : ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];

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