import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'ai_insights_page.dart'; // Import the new AI insights page

class CalculateProfitPage extends StatefulWidget {
  @override
  _CalculateProfitPageState createState() => _CalculateProfitPageState();
}

class _CalculateProfitPageState extends State<CalculateProfitPage> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _bookingsForSelectedMonth = [];
  List<Map<String, dynamic>> _expensesForSelectedMonth = [];
  List<Map<String, dynamic>> _salariesForSelectedMonth = [];
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
    _fetchAllDataForMonth(_selectedMonth);
  }

  Future<void> _fetchAllDataForMonth(DateTime month) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all data in parallel
      final futures = await Future.wait([
        _apiService.fetchBookingsForMonth(month),
        _apiService.fetchExpensesForMonth(month),
        _apiService.fetchSalariesForMonth(month),
      ]);

      print(futures[1]);
      print(futures[2]);

      final bookings = futures[0] as List<Map<String, dynamic>>;
      final expenses = futures[1] as List<Map<String, dynamic>>;
      final salaries = futures[2] as List<Map<String, dynamic>>;

      setState(() {
        _bookingsForSelectedMonth = bookings.where((booking) {
          final checkInDate = DateTime.parse(booking['checkIn']);
          return checkInDate.year == month.year && checkInDate.month == month.month;
        }).toList();

        _expensesForSelectedMonth = expenses;
        _salariesForSelectedMonth = salaries;

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
    for (var booking in _bookingsForSelectedMonth) {
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
    for (var expense in _expensesForSelectedMonth) {
      double amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
      totalExpenses += amount;
    }

    // Calculate salary totals
    for (var salary in _salariesForSelectedMonth) {
      double amount = double.tryParse(salary['amount'].toString()) ?? 0.0;
      totalSalaries += amount;
    }

    // Calculate profit
    totalProfit = totalRevenue - totalExpenses - totalSalaries;
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
        _fetchAllDataForMonth(selectedMonth);
      }
    });
  }

  void _navigateToAIInsights() {
    // Ensure we pass valid data to AI insights
    final safeBookings = _bookingsForSelectedMonth.isNotEmpty ? _bookingsForSelectedMonth : <Map<String, dynamic>>[];
    final safeExpenses = _expensesForSelectedMonth.isNotEmpty ? _expensesForSelectedMonth : <Map<String, dynamic>>[];
    final safeSalaries = _salariesForSelectedMonth.isNotEmpty ? _salariesForSelectedMonth : <Map<String, dynamic>>[];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiInsightsPage(
          selectedMonth: _selectedMonth,
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
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectMonth(context),
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

            // AI Insights Button - NEW ADDITION
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
                      Tab(text: "Bookings (${_bookingsForSelectedMonth.length})"),
                      Tab(text: "Expenses (${_expensesForSelectedMonth.length})"),
                      Tab(text: "Salaries (${_salariesForSelectedMonth.length})"),
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
    if (_bookingsForSelectedMonth.isEmpty) {
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
      itemCount: _bookingsForSelectedMonth.length,
      itemBuilder: (context, index) {
        final booking = _bookingsForSelectedMonth[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildExpensesList() {
    if (_expensesForSelectedMonth.isEmpty) {
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
      itemCount: _expensesForSelectedMonth.length,
      itemBuilder: (context, index) {
        final expense = _expensesForSelectedMonth[index];
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
    if (_salariesForSelectedMonth.isEmpty) {
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
      itemCount: _salariesForSelectedMonth.length,
      itemBuilder: (context, index) {
        final salary = _salariesForSelectedMonth[index];
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