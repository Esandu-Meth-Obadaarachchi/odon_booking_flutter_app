import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.1.48:1000'; // Replace with your actual server URL

  // Method to fetch future bookings starting from a given date
  Future<List<Map<String, dynamic>>> fetchFutureBookings(DateTime fromDate) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings?fromDate=${fromDate.toIso8601String()}'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch future bookings: ${response.reasonPhrase}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookings(DateTime date) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings?date=${date.toIso8601String()}'));

    if (response.statusCode == 200) {
      List<dynamic> bookings = json.decode(response.body);
      return bookings.map((booking) => Map<String, dynamic>.from(booking)).toList();
    } else {
      throw Exception('Failed to load bookings: ${response.reasonPhrase}');
    }
  }


  Future<void> updateBooking(String id, Map<String, String> updatedBooking) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedBooking),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update booking: ${response.reasonPhrase}');
    }
  }

  Future<void> deleteBooking(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/bookings/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete booking: ${response.body}');
    }
  }


  Future<void> addBooking(Map<String, dynamic> newBooking) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(newBooking),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add booking: ${response.reasonPhrase}');
    }
  }


}
