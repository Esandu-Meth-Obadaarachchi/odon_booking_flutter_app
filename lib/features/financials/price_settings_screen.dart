import 'package:flutter/material.dart';
import 'package:odon_booking/core/api/api_service.dart';

class PriceSettingsScreen extends StatefulWidget {
  @override
  _PriceSettingsScreenState createState() => _PriceSettingsScreenState();
}

class _PriceSettingsScreenState extends State<PriceSettingsScreen> {
  final _apiService = ApiService();

  static const List<String> _packages = [
    'Full Board',
    'Half Board',
    'Bed and Breakfast',
    'Room Only',
    'Room + Dinner',
  ];

  static const List<String> _roomTypes = [
    'Single',
    'Double',
    'Triple',
    'Family',
    'Family Plus',
  ];

  // Package accent colors — distinct, not all indigo
  static const Map<String, Color> _packageColors = {
    'Full Board':        Color(0xFF16A34A),
    'Half Board':        Color(0xFF2563EB),
    'Bed and Breakfast': Color(0xFF7C3AED),
    'Room Only':         Color(0xFF0891B2),
    'Room + Dinner':     Color(0xFFEA580C),
  };

  static const Map<String, IconData> _packageIcons = {
    'Full Board':        Icons.restaurant_menu_rounded,
    'Half Board':        Icons.dining_rounded,
    'Bed and Breakfast': Icons.free_breakfast_rounded,
    'Room Only':         Icons.hotel_rounded,
    'Room + Dinner':     Icons.dinner_dining_rounded,
  };

  static const Map<String, String> _packageAbbr = {
    'Full Board':        'FB',
    'Half Board':        'HB',
    'Bed and Breakfast': 'B&B',
    'Room Only':         'RO',
    'Room + Dinner':     'RD',
  };

  late Map<String, Map<String, TextEditingController>> _controllers;
  late TextEditingController _driverRoomController;

  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var pkg in _packages)
        pkg: {for (var room in _roomTypes) room: TextEditingController()},
    };
    _driverRoomController = TextEditingController();
    _fetchPrices();
  }

  @override
  void dispose() {
    for (var pkg in _controllers.values) {
      for (var c in pkg.values) c.dispose();
    }
    _driverRoomController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrices() async {
    try {
      final data     = await _apiService.fetchPrices();
      final packages = data['packages'] as Map<String, dynamic>;
      for (var pkg in _packages) {
        final rooms = packages[pkg] as Map<String, dynamic>? ?? {};
        for (var room in _roomTypes) {
          final price = (rooms[room] as num?)?.toDouble() ?? 0.0;
          _controllers[pkg]![room]!.text = price.toStringAsFixed(2);
        }
      }
      _driverRoomController.text =
          ((data['driverRoomPrice'] as num?)?.toDouble() ?? 2500.0)
              .toStringAsFixed(2);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load prices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrices() async {
    setState(() => _saving = true);
    try {
      final packages = <String, Map<String, double>>{
        for (var pkg in _packages)
          pkg: {
            for (var room in _roomTypes)
              room: double.tryParse(_controllers[pkg]![room]!.text) ?? 0.0,
          },
      };
      final driverPrice = double.tryParse(_driverRoomController.text) ?? 2500.0;
      await _apiService.updatePrices(packages, driverPrice);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prices saved'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Room Prices',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _savePrices,
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.indigo.shade600, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Prices are per night in LKR. Changes apply to new bookings.',
                          style: TextStyle(fontSize: 13, color: Colors.indigo.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Driver room
                _buildDriverCard(),
                const SizedBox(height: 20),

                // Column headers
                _buildColumnHeaders(),
                const SizedBox(height: 8),

                // Package rows
                ..._packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildPackageRow(pkg),
                    )),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildDriverCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.directions_car_rounded, color: Colors.amber.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Room',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    'Per night',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: _driverRoomController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                decoration: InputDecoration(
                  prefixText: 'LKR ',
                  prefixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.indigo, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const SizedBox(width: 110),
          ..._roomTypes.map(
            (room) => Expanded(
              child: Text(
                room,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageRow(String package) {
    final color = _packageColors[package] ?? Colors.indigo;
    final icon  = _packageIcons[package] ?? Icons.hotel_rounded;
    final abbr  = _packageAbbr[package] ?? package;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Package label — fixed 110px
            SizedBox(
              width: 110,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      abbr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Price fields
            ..._roomTypes.map(
              (room) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: TextFormField(
                    controller: _controllers[package]![room],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
