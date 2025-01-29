import 'package:flutter/material.dart';
import 'room_selection_screen.dart';
import 'view_bookings_screen.dart';
import 'login_screen.dart';
import ' add_inventory_item_screen.dart';
import 'calculate_profit_page.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Hotel Room Booking',
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
            // Logo Section
            Expanded(
              flex: 1,
              child: Center(
                child: Image.asset(
                  'assets/logo.JPG',
                  height: 300,
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              flex: 2, // Allocate space for the container
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity, // Makes the container span the full width
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Light grey background color
                      border: Border.all(color: Colors.grey), // Border color
                      borderRadius: BorderRadius.circular(10.0), // Border radius
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Wrap content vertically
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoomSelectionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.indigo,
                          ),
                          child: const Text('Add New Booking'),
                        ),
                        const SizedBox(height: 20), // Space between buttons
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewBookingsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.indigo,
                          ),
                          child: const Text('View Bookings'),
                        ),
                        const SizedBox(height: 20), // Space between buttons
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddInventoryItemScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.indigo,
                          ),
                          child: const Text('Inventory Management'),
                        ),
                        const SizedBox(height: 20), // Space between buttons
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CalculateProfitPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.indigo,
                          ),
                          child: const Text('Profit Calculator'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer Section
            const SizedBox(height: 70),
            const Divider(color: Colors.grey, thickness: 1),
            Column(
              children: [
                const Text(
                  'Made by Esandu Obadaarachchi',
                  style: TextStyle(
                    fontFamily: 'Dancing Script',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ODON (Pvt) Ltd',
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.logout),
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                          (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}