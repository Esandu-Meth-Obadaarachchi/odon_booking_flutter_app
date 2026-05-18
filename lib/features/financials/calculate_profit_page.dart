import 'package:flutter/material.dart';
import 'package:odon_booking/core/api/api_service.dart';
import 'package:odon_booking/features/ai_insights/ai_insights_page.dart';

class CalculateProfitPage extends StatefulWidget {
  @override
  _CalculateProfitPageState createState() => _CalculateProfitPageState();
}

class _CalculateProfitPageState extends State<CalculateProfitPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate   = DateTime.now();

  List<Map<String, dynamic>> _bookingsForSelectedRange = [];
  List<Map<String, dynamic>> _expensesForSelectedRange = [];
  List<Map<String, dynamic>> _salariesForSelectedRange = [];

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  double totalRevenue     = 0;
  double totalAdvance     = 0;
  double totalBalance     = 0;
  double totalBankBalance = 0;
  double totalCashBalance = 0;
  double totalExpenses    = 0;
  double totalSalaries    = 0;
  double totalProfit      = 0;

  @override
  void initState() {
    super.initState();
    _fetchAllDataForDateRange(_startDate, _endDate);
  }

  Future<void> _fetchAllDataForDateRange(DateTime start, DateTime end) async {
    setState(() => _isLoading = true);
    try {
      final months     = _getMonthsInRange(start, end);
      final allBookings = <Map<String, dynamic>>[];
      final allExpenses = <Map<String, dynamic>>[];
      final allSalaries = <Map<String, dynamic>>[];

      for (final month in months) {
        final futures = await Future.wait([
          _apiService.fetchBookingsForMonth(month),
          _apiService.fetchExpensesForMonth(month),
          _apiService.fetchSalariesForMonth(month),
        ]);
        allBookings.addAll(futures[0]);
        allExpenses.addAll(futures[1]);
        allSalaries.addAll(futures[2]);
      }

      setState(() {
        _bookingsForSelectedRange = allBookings.where((b) {
          final d = DateTime.parse(b['checkIn']);
          return !d.isBefore(start) && !d.isAfter(end);
        }).toList();
        _expensesForSelectedRange = allExpenses.where((e) {
          if (e['date'] == null) return false;
          final d = DateTime.parse(e['date']);
          return !d.isBefore(start) && !d.isAfter(end);
        }).toList();
        _salariesForSelectedRange = allSalaries.where((s) {
          if (s['date'] == null) return false;
          final d = DateTime.parse(s['date']);
          return !d.isBefore(start) && !d.isAfter(end);
        }).toList();

        _calculateTotals();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch data. Please try again.')),
      );
    }
  }

  List<DateTime> _getMonthsInRange(DateTime start, DateTime end) {
    final months   = <DateTime>[];
    var current    = DateTime(start.year, start.month);
    final endMonth = DateTime(end.year, end.month);
    while (!current.isAfter(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
    return months;
  }

  void _calculateTotals() {
    totalRevenue = totalAdvance = totalBalance =
        totalBankBalance = totalCashBalance = totalExpenses = totalSalaries = 0;

    for (final b in _bookingsForSelectedRange) {
      final t  = double.tryParse(b['total'].toString())   ?? 0;
      final a  = double.tryParse(b['advance'].toString()) ?? 0;
      final bm = b['balanceMethod'];
      totalRevenue += t;
      totalAdvance += a;
      totalBalance += (t - a);
      if (bm == 'Bank') totalBankBalance += (t - a);
      if (bm == 'Cash') totalCashBalance += (t - a);
    }
    for (final e in _expensesForSelectedRange) {
      totalExpenses += double.tryParse(e['amount'].toString()) ?? 0;
    }
    for (final s in _salariesForSelectedRange) {
      totalSalaries += double.tryParse(s['amount'].toString()) ?? 0;
    }
    totalProfit = totalRevenue - totalExpenses - totalSalaries;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.indigo,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate   = picked.end;
      });
      _fetchAllDataForDateRange(_startDate, _endDate);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_monthAbbr[d.month - 1]} ${d.year}';

  String _fmtLkr(double v) {
    final abs = v.abs();
    if (abs >= 1000000) {
      return 'LKR ${(abs / 1000000).toStringAsFixed(2)}M';
    }
    return 'LKR ${abs.toStringAsFixed(2)}';
  }

  static const _monthAbbr = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final days      = _endDate.difference(_startDate).inDays + 1;
    final isProfit  = totalProfit >= 0;
    final resultColor = isProfit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
            ),
          ),
        ),
        title: const Text(
          'Profit Summary',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Range',
              style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Date range pill ──────────────────────────────────
                  GestureDetector(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 15, color: Colors.indigo.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_fmtDate(_startDate)}  –  ${_fmtDate(_endDate)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$days day${days != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_calendar_outlined,
                              size: 15, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Net result hero ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left accent stripe
                        Container(
                          width: 4,
                          height: 64,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: resultColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isProfit ? 'NET PROFIT' : 'NET LOSS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: resultColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _fmtLkr(totalProfit),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: resultColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Count badges
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _countBadge(Icons.hotel_rounded,
                                _bookingsForSelectedRange.length, Colors.indigo),
                            const SizedBox(height: 6),
                            _countBadge(Icons.receipt_outlined,
                                _expensesForSelectedRange.length, Colors.pink.shade400),
                            const SizedBox(height: 6),
                            _countBadge(Icons.people_outline_rounded,
                                _salariesForSelectedRange.length, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Ledger statement card ────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // — Income section —
                        _ledgerSectionHeader('INCOME'),
                        _ledgerRow(
                          label: 'Booking Revenue',
                          amount: totalRevenue,
                          color: const Color(0xFF16A34A),
                          bold: true,
                        ),
                        _ledgerRow(
                          label: 'Advance collected',
                          amount: totalAdvance,
                          color: Colors.grey.shade700,
                          indent: 1,
                        ),
                        _ledgerRow(
                          label: 'Balance due',
                          amount: totalBalance,
                          color: Colors.grey.shade700,
                          indent: 1,
                        ),
                        if (totalBankBalance > 0)
                          _ledgerRow(
                            label: 'via Bank Transfer',
                            amount: totalBankBalance,
                            color: Colors.grey.shade500,
                            indent: 2,
                            small: true,
                          ),
                        if (totalCashBalance > 0)
                          _ledgerRow(
                            label: 'via Cash',
                            amount: totalCashBalance,
                            color: Colors.grey.shade500,
                            indent: 2,
                            small: true,
                          ),

                        _ledgerDivider(),

                        // — Deductions section —
                        _ledgerSectionHeader('DEDUCTIONS'),
                        _ledgerRow(
                          label: 'Expenses',
                          amount: totalExpenses,
                          color: const Color(0xFFDC2626),
                          bold: true,
                          negate: true,
                        ),
                        _ledgerRow(
                          label: 'Salaries',
                          amount: totalSalaries,
                          color: const Color(0xFFEA580C),
                          bold: true,
                          negate: true,
                        ),

                        _ledgerDivider(thick: true),

                        // — Net —
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                          child: Row(
                            children: [
                              const Text(
                                'Net',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1B4B),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${isProfit ? '' : '−'}${_fmtLkr(totalProfit)}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: resultColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── AI button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiInsightsPage(
                            selectedMonth: _startDate,
                            totalRevenue: totalRevenue,
                            totalExpenses: totalExpenses,
                            totalSalaries: totalSalaries,
                            totalProfit: totalProfit,
                            bookings: _bookingsForSelectedRange,
                            expenses: _expensesForSelectedRange,
                            salaries: _salariesForSelectedRange,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.psychology_rounded, size: 18),
                      label: const Text(
                        'AI Business Insights',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Detail tabs ──────────────────────────────────────
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TabBar(
                            labelColor: Colors.indigo,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.indigo,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            tabs: [
                              Tab(text: 'Bookings (${_bookingsForSelectedRange.length})'),
                              Tab(text: 'Expenses (${_expensesForSelectedRange.length})'),
                              Tab(text: 'Salaries (${_salariesForSelectedRange.length})'),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 320,
                          child: TabBarView(
                            children: [
                              _buildBookingsList(),
                              _buildList(_expensesForSelectedRange, isExpense: true),
                              _buildList(_salariesForSelectedRange, isExpense: false),
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

  // ── Ledger components ──────────────────────────────────────────────────────

  Widget _ledgerSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _ledgerDivider({bool thick = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: thick ? 1 : 1,
        thickness: thick ? 1.5 : 0.8,
        color: thick ? Colors.grey.shade300 : Colors.grey.shade200,
      ),
    );
  }

  Widget _ledgerRow({
    required String label,
    required double amount,
    required Color color,
    int indent = 0,
    bool bold  = false,
    bool small = false,
    bool negate = false,
  }) {
    final leftPad   = 20.0 + indent * 16.0;
    final fontSize  = small ? 12.5 : (bold ? 14.5 : 13.5);
    final amtPrefix = negate ? '−' : '';

    return Padding(
      padding: EdgeInsets.fromLTRB(leftPad, 6, 20, 6),
      child: Row(
        children: [
          if (indent > 0) ...[
            Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: bold ? const Color(0xFF1E1B4B) : Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            '$amtPrefix${_fmtLkr(amount)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ── Detail list builders ───────────────────────────────────────────────────

  Widget _buildBookingsList() {
    if (_bookingsForSelectedRange.isEmpty) {
      return _emptyState(Icons.event_busy_rounded, 'No bookings');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      itemCount: _bookingsForSelectedRange.length,
      itemBuilder: (_, i) => _buildBookingCard(_bookingsForSelectedRange[i]),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool isExpense}) {
    if (items.isEmpty) {
      return _emptyState(
        isExpense ? Icons.receipt_long_outlined : Icons.people_outline,
        isExpense ? 'No expenses' : 'No salaries',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item   = items[i];
        final amount = double.tryParse(item['amount'].toString()) ?? 0;
        final name   = isExpense ? (item['expenseName'] ?? '–') : (item['employeeName'] ?? '–');
        final sub    = isExpense ? (item['category'] ?? '') : (item['salaryType'] ?? '');
        final color  = isExpense ? Colors.red.shade700 : Colors.orange.shade700;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    if (sub.isNotEmpty)
                      Text(sub,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Text(
                'LKR ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final isNew = booking['rooms'] != null &&
        (booking['rooms'] as List).isNotEmpty;
    final roomLabel = isNew
        ? (booking['rooms'] as List)
            .cast<Map<String, dynamic>>()
            .map((r) => 'Rm ${r['roomNumber']}')
            .join(', ')
        : 'Room ${booking['roomNumber'] ?? '?'}';
    final total = double.tryParse(booking['total'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roomLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                if ((booking['package'] ?? '').toString().isNotEmpty)
                  Text(
                    booking['package'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            'LKR ${total.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.indigo),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
