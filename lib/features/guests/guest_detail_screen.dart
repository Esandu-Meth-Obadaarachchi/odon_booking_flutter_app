import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odon_booking/core/api/api_service.dart';
import 'package:odon_booking/features/bookings/edit_booking_screen.dart';

class GuestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> guest;

  const GuestDetailScreen({super.key, required this.guest});

  @override
  State<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;

  String get _phone => (widget.guest['phone'] ?? '').toString();
  String get _name => (widget.guest['name'] ?? 'Guest').toString();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await _api.fetchGuestBookings(_phone);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ── Stats ────────────────────────────────────────────────────────────
  int _roomCount(Map<String, dynamic> b) {
    final rooms = b['rooms'];
    if (rooms is List && rooms.isNotEmpty) return rooms.length;
    return 1;
  }

  int get _totalRoomNights {
    return _bookings.fold<int>(0, (sum, b) {
      final n = (b['num_of_nights'] as num?)?.toInt() ?? 0;
      return sum + n * _roomCount(b);
    });
  }

  double get _totalRevenue {
    return _bookings.fold<double>(0, (sum, b) {
      final raw = b['total']?.toString() ?? '';
      final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      return sum + (double.tryParse(cleaned) ?? 0);
    });
  }

  DateTime? get _lastVisit {
    DateTime? latest;
    for (final b in _bookings) {
      final ci = b['checkIn'] != null ? DateTime.tryParse(b['checkIn'].toString()) : null;
      if (ci != null && (latest == null || ci.isAfter(latest))) latest = ci;
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          _name,
          style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        color: Colors.indigo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _buildHistoryHeader(),
            const SizedBox(height: 8),
            ..._buildHistoryBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(_phone, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
                if (_lastVisit != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Last visit ${DateFormat('dd MMM yyyy').format(_lastVisit!)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('${_bookings.length}', 'Bookings', Icons.book_online_rounded, Colors.indigo)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('$_totalRoomNights', 'Room-Nights', Icons.nights_stay_rounded, Colors.teal)),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'LKR ${NumberFormat('#,###').format(_totalRevenue)}',
            'Revenue',
            Icons.payments_rounded,
            Colors.green,
            valueFontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, {double valueFontSize = 16}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Icon(Icons.history_rounded, color: Colors.indigo, size: 18),
        const SizedBox(width: 6),
        const Text(
          'Booking History',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const Spacer(),
        if (_bookings.isNotEmpty)
          Text('${_bookings.length} total', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  List<Widget> _buildHistoryBody() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
        ),
      ];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.cloud_off, color: Colors.grey.shade400, size: 48),
              const SizedBox(height: 8),
              Text('Failed to load bookings', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ];
    }
    if (_bookings.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.grey.shade300, size: 48),
              const SizedBox(height: 8),
              Text('No bookings yet', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      ];
    }
    return _bookings.map(_buildBookingCard).toList();
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final ci = booking['checkIn'] != null ? DateTime.tryParse(booking['checkIn'].toString()) : null;
    final co = booking['checkOut'] != null ? DateTime.tryParse(booking['checkOut'].toString()) : null;
    final pkg = (booking['package'] ?? '').toString();
    final nights = (booking['num_of_nights'] as num?)?.toInt() ?? 0;
    final total = (booking['total'] ?? '').toString();
    final rooms = booking['rooms'];
    final isNew = rooms is List && rooms.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditBookingScreen(
                  booking: booking,
                  selectedDay: ci ?? DateTime.now(),
                ),
              ),
            );
            if (result == true) _loadBookings();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: package pill + dates
                Row(
                  children: [
                    _packagePill(pkg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ci != null && co != null
                            ? '${DateFormat('dd MMM').format(ci)} → ${DateFormat('dd MMM yyyy').format(co)}'
                            : 'Dates unavailable',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rooms + nights + total
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isNew)
                      ...rooms.map((r) {
                        final roomNum = (r['roomNumber'] ?? '').toString();
                        final roomType = (r['roomType'] ?? '').toString();
                        return _roomChip(roomNum, roomType);
                      })
                    else
                      _roomChip(
                        (booking['roomNumber'] ?? '?').toString(),
                        (booking['roomType'] ?? '').toString(),
                      ),
                    _infoChip(Icons.nights_stay, '${nights}n', Colors.indigo),
                    if (total.isNotEmpty) _infoChip(Icons.payments, 'LKR $total', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _packagePill(String pkg) {
    final color = _packageColor(pkg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pkg.isEmpty ? '—' : pkg,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _packageColor(String pkg) {
    switch (pkg) {
      case 'Full Board':  return const Color(0xFF16A34A);
      case 'Half Board':  return const Color(0xFF2563EB);
      case 'BnB':         return const Color(0xFF7C3AED);
      case 'Room Only':   return const Color(0xFF0891B2);
      case 'Dinner Only': return const Color(0xFFEA580C);
      default:            return Colors.grey;
    }
  }

  Widget _roomChip(String num, String type) {
    Color c;
    switch (type) {
      case 'Family Plus': c = Colors.deepOrange; break;
      case 'Family':      c = Colors.orange.shade700; break;
      case 'Triple':      c = Colors.teal; break;
      case 'Double':      c = Colors.indigo; break;
      default:            c = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        '#$num${type.isNotEmpty ? ' · $type' : ''}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
