import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'api_service.dart';

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
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            OutlinedButton.icon(
              onPressed: () => _selectMonth(context),
              icon: Icon(Icons.calendar_today, color: Colors.indigo),
              label: Text(
                'Select Month',
                style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.indigo),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: _bookingsForSelectedMonth.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, color: Colors.grey, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings for selected month',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room ${booking['roomNumber'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const Divider(),
                          Text(
                            'Check-in: ${_formatDate(checkInDate)}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Check-out: ${checkOutDate != null ? _formatDate(checkOutDate) : 'N/A'}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Nights: $numOfNights',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type: ${booking['roomType'] ?? 'N/A'}, Package: ${booking['package'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            'Details: ${booking['extraDetails'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
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