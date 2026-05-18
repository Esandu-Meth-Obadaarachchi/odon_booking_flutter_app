import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odon_booking/core/api/api_service.dart';
import 'guest_detail_screen.dart';

class GuestsListScreen extends StatefulWidget {
  const GuestsListScreen({super.key});

  @override
  State<GuestsListScreen> createState() => _GuestsListScreenState();
}

class _GuestsListScreenState extends State<GuestsListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allGuests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuests();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guests = await _api.fetchGuests();
      if (!mounted) return;
      setState(() {
        _allGuests = guests;
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

  List<Map<String, dynamic>> get _filteredGuests {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _allGuests;
    return _allGuests.where((g) {
      final name = (g['name'] ?? '').toString().toLowerCase();
      final phone = (g['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  int get _totalBookings =>
      _allGuests.fold<int>(0, (sum, g) => sum + ((g['bookingCount'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    final guests = _filteredGuests;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Guests',
          style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSummary(),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadGuests,
              color: Colors.indigo,
              child: _buildBody(guests),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _summaryStat('${_allGuests.length}', 'Guests'),
          const SizedBox(width: 24),
          Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 24),
          _summaryStat('$_totalBookings', 'Total Bookings'),
        ],
      ),
    );
  }

  Widget _summaryStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or phone',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.indigo.shade300),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                  onPressed: () => _searchController.clear(),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> guests) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Failed to load guests', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (guests.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _searchController.text.isEmpty
                      ? 'No guests yet'
                      : 'No guests match "${_searchController.text}"',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
                if (_searchController.text.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Guests are added automatically when bookings\nare saved with a phone number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: guests.length,
      itemBuilder: (ctx, i) => _buildGuestCard(guests[i]),
    );
  }

  Widget _buildGuestCard(Map<String, dynamic> guest) {
    final name = (guest['name'] ?? 'Guest').toString();
    final phone = (guest['phone'] ?? '').toString();
    final bookingCount = (guest['bookingCount'] as num?)?.toInt() ?? 0;
    final lastBookingRaw = guest['lastBooking'];
    final lastBooking = lastBookingRaw is String && lastBookingRaw.isNotEmpty
        ? DateTime.tryParse(lastBookingRaw)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GuestDetailScreen(guest: guest)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      if (lastBooking != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.event, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              'Last: ${DateFormat('dd MMM yyyy').format(lastBooking)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _bookingPill(bookingCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookingPill(int count) {
    final isMulti = count > 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMulti ? Colors.indigo.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isMulti ? Colors.indigo : Colors.grey.shade700,
            ),
          ),
          Text(
            count == 1 ? 'stay' : 'stays',
            style: TextStyle(
              fontSize: 9,
              color: isMulti ? Colors.indigo.shade400 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
