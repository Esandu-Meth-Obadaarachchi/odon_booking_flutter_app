import 'package:flutter/material.dart';
import 'room_selection_screen.dart';
import 'view_bookings_screen.dart';
import 'login_screen.dart';

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
            // Logo at the top center
            Expanded(
              flex: 1,  // Reduced flex value to allocate less space for the logo
              child: Center(
                child: Image.asset(
                  'assets/logo.JPG',
                  height: 300,  // Adjusted the logo size to be smaller
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Spacer between the image and button section

            // Button Section
            Expanded(
              flex: 2,  // Increased flex value to allocate more space for the button container
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Light grey background color
                      border: Border.all(color: Colors.grey), // Border color
                      borderRadius: BorderRadius.circular(10.0), // Border radius
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoomSelectionScreen(
                                      floor: 'Ground Floor',
                                      rooms: 5,
                                      startingRoomNumber: 1,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.indigo, // Adjust button color
                              ),
                              child: const Text('Ground Floor'),
                            ),
                            const SizedBox(height: 20, width: 30),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoomSelectionScreen(
                                      floor: 'First Floor',
                                      rooms: 7,
                                      startingRoomNumber: 101,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.indigo, // Adjust button color
                              ),
                              child: const Text('First Floor'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                            backgroundColor: Colors.indigo, // Adjust button color
                          ),
                          child: const Text('View Bookings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer Section
            const SizedBox(height: 70),
            const Divider(
              color: Colors.grey, // Color of the horizontal line
              thickness: 1, // Thickness of the line
            ),
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