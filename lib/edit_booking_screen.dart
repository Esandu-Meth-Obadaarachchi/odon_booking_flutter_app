import 'package:flutter/material.dart';
import 'api_service.dart';

class EditBookingScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final DateTime selectedDay;
  final ApiService _apiService = ApiService();

  EditBookingScreen({required this.booking, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    // Controllers for form fields
    TextEditingController roomNumberController = TextEditingController(text: booking['roomNumber'] as String? ?? '');
    TextEditingController roomTypeController = TextEditingController(text: booking['roomType'] as String? ?? '');
    TextEditingController packageTypeController = TextEditingController(text: booking['package'] as String? ?? '');
    TextEditingController extraDetailsController = TextEditingController(text: booking['extraDetails'] as String? ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Booking",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Booking Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 20),
            // Styled Text Fields
            _buildStyledTextField('Room Number', roomNumberController),
            const SizedBox(height: 10),
            _buildStyledTextField('Room Type', roomTypeController),
            const SizedBox(height: 10),
            _buildStyledTextField('Package Type', packageTypeController),
            const SizedBox(height: 10),
            _buildStyledTextField('Extra Details', extraDetailsController),
            const SizedBox(height: 30),
            // Save Button
            ElevatedButton(
              onPressed: () async {
                final updatedBooking = {
                  'num_of_nights':booking['num_of_nights'],
                  'roomNumber': roomNumberController.text,
                  'roomType': roomTypeController.text,
                  'package': packageTypeController.text,
                  'extraDetails': extraDetailsController.text,
                  'checkIn': booking['checkIn'],
                  'checkOut': booking['checkOut'],

                };

                try {
                  final id = booking['_id'] as String?;
                  if (id == null) {
                    throw Exception('Booking ID is missing');
                  }
                  await _apiService.updateBooking(id, updatedBooking);
                  Navigator.pop(context, true); // Indicate that an update occurred
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update booking: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            // Delete Button
            ElevatedButton(
              onPressed: () async {
                try {
                  final id = booking['_id'] as String?;
                  if (id == null) {
                    throw Exception('Booking ID is missing');
                  }
                  await _apiService.deleteBooking(id);
                  Navigator.pop(context, true); // Indicate that a deletion occurred
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete booking: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A reusable method to build styled text fields
  Widget _buildStyledTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.indigo),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

}