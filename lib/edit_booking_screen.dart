import 'package:flutter/material.dart';
import 'api_service.dart';

class EditBookingScreen extends StatelessWidget {
  final Map<String, String> booking;
  final DateTime selectedDay;
  final ApiService _apiService = ApiService();

  EditBookingScreen({required this.booking, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    TextEditingController roomNumberController = TextEditingController(text: booking['roomNumber']);
    TextEditingController roomTypeController = TextEditingController(text: booking['roomType']);
    TextEditingController packageTypeController = TextEditingController(text: booking['packageType']);
    TextEditingController extraDetailsController = TextEditingController(text: booking['extraDetails']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: roomNumberController,
              decoration: InputDecoration(labelText: 'Room Number'),
            ),
            TextField(
              controller: roomTypeController,
              decoration: InputDecoration(labelText: 'Room Type'),
            ),
            TextField(
              controller: packageTypeController,
              decoration: InputDecoration(labelText: 'Package Type'),
            ),
            TextField(
              controller: extraDetailsController,
              decoration: InputDecoration(labelText: 'Extra Details'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updatedBooking = {
                  'roomNumber': roomNumberController.text,
                  'roomType': roomTypeController.text,
                  'packageType': packageTypeController.text,
                  'extraDetails': extraDetailsController.text,
                  'date': selectedDay.toIso8601String(),
                };

                try {
                  await _apiService.updateBooking(booking['_id']!, updatedBooking);
                  Navigator.pop(context, true);  // Indicate that an update occurred
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update booking: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.deleteBooking(booking['_id']!);
                  Navigator.pop(context, true);  // Indicate that a deletion occurred
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete booking: $e')),
                  );
                }
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
