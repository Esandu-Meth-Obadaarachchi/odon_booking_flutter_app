import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:google_fonts/google_fonts.dart'; // For elegant fonts
import 'api_service.dart'; // Ensure you import your API service

class CalculateProfitPage extends StatefulWidget {
  @override
  _CalculateProfitPageState createState() => _CalculateProfitPageState();
}

class _CalculateProfitPageState extends State<CalculateProfitPage> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _bookingsForSelectedMonth = [];
  final ApiService _apiService = ApiService();

  double totalRevenue = 0.0;
  double totalAdvance = 0.0;
  double totalBalance = 0.0;

  Future<void> _fetchBookingsForMonth(DateTime month) async {
    try {
      final bookings = await _apiService.fetchBookingsForMonth(month);
      setState(() {
        _bookingsForSelectedMonth = bookings.where((booking) {
          final checkInDate = DateTime.parse(booking['checkIn']);
          return checkInDate.year == month.year && checkInDate.month == month.month;
        }).toList();

        // Calculate totals
        totalRevenue = _bookingsForSelectedMonth.fold(0.0, (sum, booking) =>
        sum + (double.tryParse(booking['total'].toString()) ?? 0.0));

        totalAdvance = _bookingsForSelectedMonth.fold(0.0, (sum, booking) =>
        sum + (double.tryParse(booking['advance'].toString()) ?? 0.0));

        totalBalance = totalRevenue - totalAdvance;
      });
    } catch (e) {
      print('Failed to fetch bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch bookings. Please try again.')),
      );
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
      backgroundColor: Colors.grey[200], // Subtle background
      appBar: AppBar(
        title: Text("Calculate Profit",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectMonth(context),
          ),

        ],
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Month Display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "📅 ${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}",
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectMonth(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Change", style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Revenue", totalRevenue, Colors.green),
                _buildSummaryCard("Advance", totalAdvance, Colors.blue),
                _buildSummaryCard("Balance", totalBalance, Colors.orange),
              ],
            ),
            const SizedBox(height: 20),

            // Bookings List
            Expanded(
              child: _bookingsForSelectedMonth.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 10),
                    Text("No bookings found for this month.",
                        style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _bookingsForSelectedMonth.length,
                itemBuilder: (context, index) {
                  final booking = _bookingsForSelectedMonth[index];
                  return _buildBookingCard(booking);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to create gradient summary cards
  Widget _buildSummaryCard(String title, double value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.6)]),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Text(title,
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 5),
            Text("LKR ${value.toStringAsFixed(2)}",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // Function to create an enhanced booking list item
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.hotel, color: Colors.white, size: 30),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Room: ${booking['roomNumber']} - ${booking['roomType']}",
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Total: LKR ${booking['total']} | Advance: LKR ${booking['advance']}",
                      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text("Check-in: ${booking['checkIn']}",
                      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}