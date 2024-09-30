import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {

  final String baseUrl = 'http://192.168.1.26:3000'; // Replace with your actual server URL

  // Future<String> _getLocalIpAddress() async {
  //   try {
  //     List<NetworkInterface> interfaces = await NetworkInterface.list();
  //     for (var interface in interfaces) {
  //       for (var address in interface.addresses) {
  //         if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
  //           return address.address; // Return the first found IPv4 address
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print('Error getting IP address: $e');
  //     throw Exception('Failed to get local IP address');
  //   }
  //   return '127.0.0.1'; // Fallback to localhost if no IP is found
  // }
  //
  // Future<String> _getBaseUrl() async {
  //   String ip = await _getLocalIpAddress();
  //   print(ip);
  //   return 'http://$ip:3000'; // Adjust port if needed
  // }

  Future<List<Map<String, dynamic>>> fetchFutureBookings(DateTime fromDate) async {
    //final String baseUrl = await _getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/bookings?fromCheckIn=${fromDate.toIso8601String()}'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch future bookings: ${response.reasonPhrase}');
    }
  }
  // Fetch bookings for the selected date range
  Future<List<Map<String, dynamic>>> fetchBookingsForDateRange(DateTime checkInDate, DateTime checkOutDate) async {
    //final String baseUrl = await _getBaseUrl();
    final String checkIn = checkInDate.toIso8601String();
    final String checkOut = checkOutDate.toIso8601String();

    final url = Uri.parse('$baseUrl/bookings?checkIn=$checkIn&checkOut=$checkOut');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the response and convert it into a List of Maps
        final List<dynamic> data = json.decode(response.body);
        return data.map((booking) => booking as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch bookings');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      throw Exception('Failed to fetch bookings');
    }
  }
  Future<List<Map<String, dynamic>>> fetchBookingsForMonth(DateTime month) async {
    //final String baseUrl = await _getBaseUrl();
    // Get the start and end of the selected month
    final String startOfMonth = DateTime(month.year, month.month, 1).toIso8601String();
    final String endOfMonth = DateTime(month.year, month.month + 1, 0).toIso8601String();

    // API call to fetch bookings where checkIn and checkOut fall within the selected month
    final response = await http.get(Uri.parse('$baseUrl/bookings?checkInStart=$startOfMonth&checkOutEnd=$endOfMonth'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch bookings for the selected month: ${response.reasonPhrase}');
    }
  }


  Future<List<Map<String, dynamic>>> fetchBookings(DateTime date) async {
    //final String baseUrl = await _getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/bookings?checkIn=${date.toIso8601String()}'));

    if (response.statusCode == 200) {
      List<dynamic> bookings = json.decode(response.body);
      return bookings.map((booking) => Map<String, dynamic>.from(booking)).toList();
    } else {
      throw Exception('Failed to load bookings: ${response.reasonPhrase}');
    }
  }



  Future<void> updateBooking(String id, Map<String, String> updatedBooking) async {
    //final String baseUrl = await _getBaseUrl();
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
    //final String baseUrl = await _getBaseUrl();
    final response = await http.delete(Uri.parse('$baseUrl/bookings/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete booking: ${response.body}');
    }
  }


  Future<void> addBooking(Map<String, dynamic> newBooking) async {
    //final String baseUrl = await _getBaseUrl();
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
