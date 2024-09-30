import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'edit_booking_screen.dart';
import 'future_bookings_screen.dart'; // Import the correct file

class PastBookingsScreen extends StatefulWidget {

  @override
  _PastBookingsScreenState createState() => _PastBookingsScreenState();
}

class _PastBookingsScreenState extends State<PastBookingsScreen> {
  DateTime _selectedMonth = DateTime.now(); // Default to current month
  List<Map<String, dynamic>> _bookingsForSelectedMonth = [];

  final ApiService _apiService = ApiService();

  Future<void> _fetchBookingsForMonth(DateTime month) async {
    try {
      final bookings = await _apiService.fetchBookingsForMonth(month);
      setState(() {
        // Filter bookings to only those that match the selected month using checkIn date
        _bookingsForSelectedMonth = bookings.where((booking) {
          final checkInDate = DateTime.parse(booking['checkIn']);
          return checkInDate.year == month.year && checkInDate.month == month.month;
        }).toList();
      });
    } catch (e) {
      print('Failed to fetch bookings: $e');
    }
  }

  void _selectMonth(BuildContext context) {
    showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
    ).then((selectedMonth) {
      if (selectedMonth != null) {
        setState(() {
          _selectedMonth = selectedMonth;
        });
        _fetchBookingsForMonth(selectedMonth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Past Bookings',
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
            ElevatedButton(
              onPressed: () => _selectMonth(context),
              child: Text(
                'Select Month',
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _bookingsForSelectedMonth.isEmpty
                  ? Center(child: Text('No bookings for selected month'))
                  : ListView.builder(
                itemCount: _bookingsForSelectedMonth.length,
                itemBuilder: (context, index) {
                  final booking = _bookingsForSelectedMonth[index];

                  // Parse check-in, check-out, and number of nights fields
                  DateTime checkInDate = DateTime.parse(booking['checkIn']);
                  DateTime? checkOutDate = booking['checkOut'] != null
                      ? DateTime.parse(booking['checkOut'])
                      : null;
                  final numOfNights = booking['num_of_nights'] ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3.0,
                    child: ListTile(
                      title: Text(
                        'Room ${booking['roomNumber'] ?? 'N/A'}',
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

  // Utility to format DateTime as 'DD/MM/YYYY'
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

