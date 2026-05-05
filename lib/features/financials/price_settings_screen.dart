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

  // controllers[package][roomType]
  late Map<String, Map<String, TextEditingController>> _controllers;
  late TextEditingController _driverRoomController;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var pkg in _packages)
        pkg: {for (var room in _roomTypes) room: TextEditingController()}
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
      final data = await _apiService.fetchPrices();
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
        SnackBar(content: Text('Failed to load prices: $e'), backgroundColor: Colors.red),
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
              room: double.tryParse(_controllers[pkg]![room]!.text) ?? 0.0
          }
      };
      final driverPrice =
          double.tryParse(_driverRoomController.text) ?? 2500.0;
      await _apiService.updatePrices(packages, driverPrice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices saved successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save prices: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Prices'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Prices',
                  onPressed: _savePrices,
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Driver Room Price card
                _buildDriverRoomCard(),
                const SizedBox(height: 12),
                // One card per package
                ..._packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPackageCard(pkg),
                    )),
              ],
            ),
    );
  }

  Widget _buildDriverRoomCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Driver Room (per night)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: _driverRoomController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(String package) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._roomTypes.map((room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(room)),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _controllers[package]![room],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            prefixText: 'LKR ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
