import 'package:flutter/material.dart';
import 'api_service.dart';

class EditBookingScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final DateTime selectedDay;
  final ApiService _apiService = ApiService();
  late ValueNotifier<String?> balanceMethodNotifier = ValueNotifier<String?>(null);
  String  balance = "N/A";
  EditBookingScreen({required this.booking, required this.selectedDay});

  void calBalance(TextEditingController totalController, TextEditingController advanceController) {
    try {
      final int total = int.tryParse(totalController.text) ?? 0;
      final int advance = int.tryParse(advanceController.text) ?? 0;
      balance = (total - advance).toString(); // Corrected type conversion
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Controllers for form fields
    TextEditingController roomNumberController = TextEditingController(text: booking['roomNumber'] as String? ?? '');
    TextEditingController roomTypeController = TextEditingController(text: booking['roomType'] as String? ?? '');
    TextEditingController packageTypeController = TextEditingController(text: booking['package'] as String? ?? '');
    TextEditingController extraDetailsController = TextEditingController(text: booking['extraDetails'] as String? ?? '');
    TextEditingController totalController = TextEditingController(text: booking['total'] as String? ?? '');
    TextEditingController advanceController = TextEditingController(text: booking['advance'] as String? ?? '');
    balanceMethodNotifier = ValueNotifier<String?>(
      (booking['balanceMethod'] == "Bank" || booking['balanceMethod'] == "Cash")
          ? booking['balanceMethod'] as String?
          : null, // Default to null if missing
    );
    totalController.addListener(() {
      calBalance(totalController, advanceController);
    });

    advanceController.addListener(() {
      calBalance(totalController, advanceController);
    });

    calBalance(totalController, advanceController);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Booking",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold,color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
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

            _buildStyledTextField(
              'total cost',
              totalController,
              icon: Icons.monetization_on,
              maxLines: 1,
            ),

            const SizedBox(height: 30),

            _buildStyledTextField(
              'Advance',
              advanceController,
              icon: Icons.attach_money_rounded,
              maxLines: 1,
            ),
            const SizedBox(height: 30),

            Text(
              " Balance : $balance",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 30),


            const Text("Select Balance Method:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),

            const SizedBox(height: 10),

            ValueListenableBuilder<String?>(
              valueListenable: balanceMethodNotifier,
              builder: (context, selectedMethod, child) {
                return Row(
                  children: [
                    Checkbox(
                      value: selectedMethod == "Bank",
                      onChanged: (bool? value) {
                        balanceMethodNotifier.value = value == true ? "Bank" : null;
                      },
                      activeColor: Colors.indigo,
                    ),
                    const Text("Bank", style: TextStyle(fontSize: 16)),

                    const SizedBox(width: 20),

                    Checkbox(
                      value: selectedMethod == "Cash",
                      onChanged: (bool? value) {
                        balanceMethodNotifier.value = value == true ? "Cash" : null;
                      },
                      activeColor: Colors.indigo,
                    ),
                    const Text("Cash", style: TextStyle(fontSize: 16)),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
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
                          packageTypeController.text.isEmpty ) {
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
                        'total' :  totalController.text,
                        'advance' :  advanceController.text,
                        'balanceMethod' : balanceMethodNotifier.value
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