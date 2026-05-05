import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odon_booking/core/api/api_service.dart';
import 'package:odon_booking/features/ai_insights/ai_insights_page.dart';

class CalculateProfitPage extends StatefulWidget {
  @override
  _CalculateProfitPageState createState() => _CalculateProfitPageState();
}

class _CalculateProfitPageState extends State<CalculateProfitPage> {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _bookingsForSelectedRange = [];
  List<Map<String, dynamic>> _expensesForSelectedRange = [];
  List<Map<String, dynamic>> _salariesForSelectedRange = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Revenue totals
  double totalRevenue = 0.0;
  double totalAdvance = 0.0;
  double totalBalance = 0.0;
  double totalBankBalance = 0.0;
  double totalCashBalance = 0.0;

  // Expense and salary totals
  double totalExpenses = 0.0;
  double totalSalaries = 0.0;
  double totalProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAllDataForDateRange(_startDate, _endDate);
  }

  Future<void> _fetchAllDataForDateRange(DateTime start, DateTime end) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all unique months in the date range
      List<DateTime> monthsToFetch = _getMonthsInRange(start, end);

      List<Map<String, dynamic>> allBookings = [];
      List<Map<String, dynamic>> allExpenses = [];
      List<Map<String, dynamic>> allSalaries = [];

      // Fetch data for each month in the range
      for (DateTime month in monthsToFetch) {
        final futures = await Future.wait([
          _apiService.fetchBookingsForMonth(month),
          _apiService.fetchExpensesForMonth(month),
          _apiService.fetchSalariesForMonth(month),
        ]);

        allBookings.addAll(futures[0] as List<Map<String, dynamic>>);
        allExpenses.addAll(futures[1] as List<Map<String, dynamic>>);
        allSalaries.addAll(futures[2] as List<Map<String, dynamic>>);
      }

      setState(() {
        // Filter bookings by check-in date within range
        _bookingsForSelectedRange = allBookings.where((booking) {
          final checkInDate = DateTime.parse(booking['checkIn']);
          return checkInDate.isAfter(start.subtract(Duration(days: 1))) &&
              checkInDate.isBefore(end.add(Duration(days: 1)));
        }).toList();

        // Filter expenses by date within range
        _expensesForSelectedRange = allExpenses.where((expense) {
          if (expense['date'] != null) {
            final expenseDate = DateTime.parse(expense['date']);
            return expenseDate.isAfter(start.subtract(Duration(days: 1))) &&
                expenseDate.isBefore(end.add(Duration(days: 1)));
          }
          return false;
        }).toList();

        // Filter salaries by date within range
        _salariesForSelectedRange = allSalaries.where((salary) {
          if (salary['date'] != null) {
            final salaryDate = DateTime.parse(salary['date']);
            return salaryDate.isAfter(start.subtract(Duration(days: 1))) &&
                salaryDate.isBefore(end.add(Duration(days: 1)));
          }
          return false;
        }).toList();

        _calculateTotals();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Failed to fetch data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data. Please try again.')),
      );
    }
  }

  List<DateTime> _getMonthsInRange(DateTime start, DateTime end) {
    List<DateTime> months = [];
    DateTime current = DateTime(start.year, start.month, 1);
    DateTime endMonth = DateTime(end.year, end.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  void _calculateTotals() {
    // Reset totals
    totalRevenue = 0.0;
    totalAdvance = 0.0;
    totalBalance = 0.0;
    totalBankBalance = 0.0;
    totalCashBalance = 0.0;
    totalExpenses = 0.0;
    totalSalaries = 0.0;

    // Calculate revenue totals
    for (var booking in _bookingsForSelectedRange) {
      double total = double.tryParse(booking['total'].toString()) ?? 0.0;
      double advance = double.tryParse(booking['advance'].toString()) ?? 0.0;
      String? balanceMethod = booking['balanceMethod'];

      totalRevenue += total;
      totalAdvance += advance;
      totalBalance += (total - advance);

      if (balanceMethod == "Bank") {
        totalBankBalance += (total - advance);
      } else if (balanceMethod == "Cash") {
        totalCashBalance += (total - advance);
      }
    }

    // Calculate expense totals
    for (var expense in _expensesForSelectedRange) {
      double amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
      totalExpenses += amount;
    }

    // Calculate salary totals
    for (var salary in _salariesForSelectedRange) {
      double amount = double.tryParse(salary['amount'].toString()) ?? 0.0;
      totalSalaries += amount;
    }

    // Calculate profit
    totalProfit = totalRevenue - totalExpenses - totalSalaries;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchAllDataForDateRange(_startDate, _endDate);
    }
  }

  void _navigateToAIInsights() {
    final safeBookings = _bookingsForSelectedRange.isNotEmpty ? _bookingsForSelectedRange : <Map<String, dynamic>>[];
    final safeExpenses = _expensesForSelectedRange.isNotEmpty ? _expensesForSelectedRange : <Map<String, dynamic>>[];
    final safeSalaries = _salariesForSelectedRange.isNotEmpty ? _salariesForSelectedRange : <Map<String, dynamic>>[];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiInsightsPage(
          selectedMonth: _startDate, // You might want to adjust this in AiInsightsPage
          totalRevenue: totalRevenue,
          totalExpenses: totalExpenses,
          totalSalaries: totalSalaries,
          totalProfit: totalProfit,
          bookings: safeBookings,
          expenses: safeExpenses,
          salaries: safeSalaries,
        ),
      ),
    );
  }

  String _formatDateRange() {
    final startFormatted = "${_startDate.day}/${_startDate.month}/${_startDate.year}";
    final endFormatted = "${_endDate.day}/${_endDate.month}/${_endDate.year}";
    return "$startFormatted - $endFormatted";
  }

  int _getDaysDifference() {
    return _endDate.difference(_startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Calculate Profit",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _selectDateRange(context),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Date Range Display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📅 ${_formatDateRange()}",
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${_getDaysDifference()} day${_getDaysDifference() > 1 ? 's' : ''}",
                              style: GoogleFonts.montserrat(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectDateRange(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Change", style: TextStyle(color: Colors.indigo)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Revenue Section
            Text(
              "📊 Revenue Overview",
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryCard("Revenue", totalRevenue, Colors.green),
                _buildSummaryCard("Advance", totalAdvance, Colors.blue),
                _buildSummaryCard("Balance", totalBalance, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),

            // Bank & Cash Balance (if applicable)
            if (totalBankBalance > 0 || totalCashBalance > 0) ...[
              Row(
                children: [
                  if (totalBankBalance > 0) _buildSummaryCard("Bank Balance", totalBankBalance, Colors.purple),
                  if (totalCashBalance > 0) _buildSummaryCard("Cash Balance", totalCashBalance, Colors.teal),
                  if (totalBankBalance == 0 || totalCashBalance == 0) Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Expenses & Salaries Section
            Text(
              "💰 Expenses & Salaries",
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryCard("Total Expenses", totalExpenses, Colors.red),
                _buildSummaryCard("Total Salaries", totalSalaries, Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 20),

            // Profit Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: totalProfit >= 0
                      ? [Colors.green[600]!, Colors.green[400]!]
                      : [Colors.red[600]!, Colors.red[400]!],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4)
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    totalProfit >= 0 ? "🎉 Net Profit" : "⚠️ Net Loss",
                    style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "LKR ${totalProfit.abs().toStringAsFixed(2)}",
                    style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Revenue - Expenses - Salaries",
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white70
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Insights Button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAIInsights,
                icon: Icon(Icons.psychology, size: 24),
                label: Text(
                  "🤖 Get AI Business Insights",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Breakdown Tabs
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    tabs: [
                      Tab(text: "Bookings (${_bookingsForSelectedRange.length})"),
                      Tab(text: "Expenses (${_expensesForSelectedRange.length})"),
                      Tab(text: "Salaries (${_salariesForSelectedRange.length})"),
                    ],
                  ),
                  Container(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildBookingsList(),
                        _buildExpensesList(),
                        _buildSalariesList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(horizontal: 4),
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
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 5),
            Text("LKR ${value.toStringAsFixed(2)}",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_bookingsForSelectedRange.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            Text("No bookings found", style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _bookingsForSelectedRange.length,
      itemBuilder: (context, index) {
        final booking = _bookingsForSelectedRange[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildExpensesList() {
    if (_expensesForSelectedRange.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
            Text("No expenses found", style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _expensesForSelectedRange.length,
      itemBuilder: (context, index) {
        final expense = _expensesForSelectedRange[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[100],
              child: Icon(Icons.receipt, color: Colors.red[700]),
            ),
            title: Text(expense['expenseName'] ?? 'Unknown Expense'),
            subtitle: Text("${expense['category']} • ${expense['reason'] ?? ''}"),
            trailing: Text(
              "LKR ${double.tryParse(expense['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalariesList() {
    if (_salariesForSelectedRange.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 60, color: Colors.grey[400]),
            Text("No salaries found", style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _salariesForSelectedRange.length,
      itemBuilder: (context, index) {
        final salary = _salariesForSelectedRange[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Icon(Icons.person, color: Colors.orange[700]),
            ),
            title: Text(salary['employeeName'] ?? 'Unknown Employee'),
            subtitle: Text(salary['salaryType'] ?? 'Unknown Type'),
            trailing: Text(
              "LKR ${double.tryParse(salary['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 4),
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
              child: Icon(Icons.hotel, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Room: ${booking['roomNumber']} - ${booking['roomType']}",
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text("Total: LKR ${booking['total']} | Advance: LKR ${booking['advance']}",
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text("Check-in: ${booking['checkIn']}",
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}