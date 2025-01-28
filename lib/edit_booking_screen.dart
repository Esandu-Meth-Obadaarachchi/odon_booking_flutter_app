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
        title: const Text(
          "Edit Booking",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            const Text(
              'Edit Booking Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 20),

            // Styled Text Fields
            _buildStyledTextField(
              'Room Number',
              roomNumberController,
              icon: Icons.hotel,
            ),
            const SizedBox(height: 15),

            _buildStyledTextField(
              'Room Type',
              roomTypeController,
              icon: Icons.room_preferences,
            ),
            const SizedBox(height: 15),

            _buildStyledTextField(
              'Package Type',
              packageTypeController,
              icon: Icons.card_giftcard,
            ),
            const SizedBox(height: 15),

            _buildStyledTextField(
              'Extra Details',
              extraDetailsController,
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Perform basic validation
                      if (roomNumberController.text.isEmpty ||
                          roomTypeController.text.isEmpty ||
                          packageTypeController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all required fields')),
                        );
                        return;
                      }

                      final updatedBooking = {
                        'num_of_nights': booking['num_of_nights'],
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
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20), // Spacing between buttons
                  ElevatedButton.icon(
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
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text(
                      'Delete Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

// A reusable method to build styled text fields with icons
  Widget _buildStyledTextField(
      String label, TextEditingController controller,
      {IconData? icon, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.indigo) : null,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

}