// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'room_selection_screen.dart';
import 'view_bookings_screen.dart';
import 'login_screen.dart'; // Import the login screen for navigating back to the login screen

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
            Expanded(
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
            const Divider(
              color: Colors.grey, // Color of the horizontal line
              thickness: 1, // Thickness of the line
            ),
            IconButton(
              icon: Icon(Icons.logout),
              color: Colors.red,
              onPressed: () {
                // Navigate back to the login screen
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
      ),
    );
  }
}
