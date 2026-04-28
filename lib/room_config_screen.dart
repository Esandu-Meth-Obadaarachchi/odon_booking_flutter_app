import 'package:flutter/material.dart';
import 'api_service.dart';

class RoomConfigScreen extends StatefulWidget {
  @override
  _RoomConfigScreenState createState() => _RoomConfigScreenState();
}

class _RoomConfigScreenState extends State<RoomConfigScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final config = await _apiService.fetchRoomConfig();
      setState(() {
        _rooms = List<Map<String, dynamic>>.from(
          (config['rooms'] as List).map((r) => Map<String, dynamic>.from(r)),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load room config: $e')),
      );
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await _apiService.updateRoomConfig(_rooms);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room configuration saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groundRooms = _rooms.where((r) => r['floor'] == 'Ground').toList();
    final upperRooms = _rooms.where((r) => r['floor'] == 'Upper').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Room Configuration',
          style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _saveConfig,
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegend(),
                  const SizedBox(height: 20),
                  if (groundRooms.isNotEmpty) ...[
                    _buildFloorHeader('Ground Floor'),
                    const SizedBox(height: 10),
                    ...groundRooms.map((r) => _buildRoomRow(r)),
                    const SizedBox(height: 20),
                  ],
                  if (upperRooms.isNotEmpty) ...[
                    _buildFloorHeader('Upper Floor'),
                    const SizedBox(height: 10),
                    ...upperRooms.map((r) => _buildRoomRow(r)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Room Type Guide', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Double: 2 pax  |  Double + extra bed → Triple: 3 pax', style: TextStyle(fontSize: 13)),
          const Text('Family: 4 pax  |  Family + extra bed → Family Plus: 5 pax', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          const Text('Blocked rooms cannot be selected when adding bookings.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFloorHeader(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
    );
  }

  Widget _buildRoomRow(Map<String, dynamic> room) {
    final index = _rooms.indexWhere((r) => r['roomNumber'] == room['roomNumber']);
    final isBlocked = room['isBlocked'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isBlocked ? Colors.red.shade50 : Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      room['roomNumber'].toString().padLeft(3, '0'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isBlocked ? Colors.red : Colors.indigo,
                      ),
                    ),
                    if (isBlocked)
                      Icon(Icons.lock, size: 12, color: Colors.red.shade400),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: room['baseType'] as String,
                decoration: InputDecoration(
                  labelText: 'Base Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ['Family', 'Double']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null && index >= 0) {
                    setState(() => _rooms[index]['baseType'] = val);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text('Blocked', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Switch(
                  value: isBlocked,
                  onChanged: (val) {
                    if (index >= 0) setState(() => _rooms[index]['isBlocked'] = val);
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
