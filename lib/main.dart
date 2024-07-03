import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
            'Hotel Room Booking',
          style:
          color: Colors.white, // Set the title text color to white
          fontFamily: 'CustomFont', // Set the custom font family
          fontWeight: FontWeight.bold, // Set the font weight if needed
        ),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
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
                backgroundColor: Colors.red, // foreground
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
                backgroundColor: Colors.red, // foreground
              ),
              child: const Text('First Floor'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomSelectionScreen extends StatefulWidget {
  final String floor;
  final int rooms;
  final int startingRoomNumber;

  RoomSelectionScreen({
    required this.floor,
    required this.rooms,
    required this.startingRoomNumber,
  });

  @override
  _RoomSelectionScreenState createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  DateTime? _selectedDate;
  String? _roomType;
  String? _packageType;
  final TextEditingController _extraDetailsController = TextEditingController();
  Set<int> _selectedRooms = {};

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.floor),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Room Type'),
              items: ['Family', 'Family Plus', 'Triple', 'Double']
                  .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _roomType = value;
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Package Type'),
              items: ['Full Board', 'Half Board', 'Room Only', 'BnB']
                  .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _packageType = value;
                });
              },
            ),
            TextField(
              controller: _extraDetailsController,
              decoration: InputDecoration(labelText: 'Extra Details'),
              maxLines: 3,
            ),
            const SizedBox(height: 50),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 rooms per row
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: widget.rooms,
                itemBuilder: (context, index) {
                  int roomNumber = widget.startingRoomNumber + index;
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedRooms.contains(roomNumber)) {
                          _selectedRooms.remove(roomNumber);
                        } else {
                          _selectedRooms.add(roomNumber);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: _selectedRooms.contains(roomNumber)
                          ? Colors.green
                          : Colors.white,
                    ),
                    child: Text(
                      roomNumber.toString().padLeft(3, '0'), // Format room number to 3 digits
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}