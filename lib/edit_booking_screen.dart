// lib/edit_booking_screen.dart

import 'package:flutter/material.dart';

class EditBookingScreen extends StatefulWidget {
  final Map<String, String> booking;
  final DateTime selectedDay;

  EditBookingScreen({required this.booking, required this.selectedDay});

  @override
  _EditBookingScreenState createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late TextEditingController _roomTypeController;
  late TextEditingController _packageTypeController;
  late TextEditingController _extraDetailsController;

  @override
  void initState() {
    super.initState();
    _roomTypeController = TextEditingController(text: widget.booking['roomType']);
    _packageTypeController = TextEditingController(text: widget.booking['packageType']);
    _extraDetailsController = TextEditingController(text: widget.booking['extraDetails']);
  }

  @override
  void dispose() {
    _roomTypeController.dispose();
    _packageTypeController.dispose();
    _extraDetailsController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Save changes logic goes here
    // For now, we'll just pop the screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Booking',
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
            TextField(
              controller: _roomTypeController,
              decoration: InputDecoration(labelText: 'Room Type'),
            ),
            TextField(
              controller: _packageTypeController,
              decoration: InputDecoration(labelText: 'Package Type'),
            ),
            TextField(
              controller: _extraDetailsController,
              decoration: InputDecoration(labelText: 'Extra Details'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
