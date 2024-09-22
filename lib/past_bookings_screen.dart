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
        // Filter bookings to only those that match the selected month
        _bookingsForSelectedMonth = bookings.where((booking) {
          final bookingDate = DateTime.parse(booking['date']);
          return bookingDate.year == month.year && bookingDate.month == month.month;
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
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3.0,
                    // Inside your ListTile
                    child: ListTile(
                      title: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(booking['date']))}\nRoom ${booking['roomNumber']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Type: ${booking['roomType']}, Package: ${booking['package']}\nDetails: ${booking['extraDetails']}',
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
