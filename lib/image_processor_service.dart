//AIzaSyBj3LrgKOM8dmQqu9SWeiqmj2CUjG-tmSM
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImageProcessorService {
  static const String _geminiApiKey = 'AIzaSyBj3LrgKOM8dmQqu9SWeiqmj2CUjG-tmSM'; // Replace with your actual API key
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final ImagePicker _picker = ImagePicker();

  // Updated method - no longer needs type parameter since we extract everything
  Future<List<Map<String, dynamic>>> processImage(BuildContext context) async {
    try {
      print('Starting image processing for all data');

      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) {
        print('No image source selected');
        return [];
      }

      print('Image source selected: $source');

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Compress image to reduce API costs
      );
      if (image == null) {
        print('No image selected');
        return [];
      }

      print('Image selected: ${image.path}');

      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('Image converted to base64, size: ${base64Image.length} characters');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing image with AI...'),
            ],
          ),
        ),
      );

      // Process with Gemini AI - now extracts all data
      final extractedData = await _processWithGemini(base64Image);

      // Close loading dialog
      Navigator.of(context).pop();

      print('Extraction completed, found ${extractedData.length} items');
      return extractedData;
    } catch (e) {
      // Close loading dialog if it's open
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      print('Error in processImage: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFFEF4444)),
              title: Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFFEF4444)),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Updated method - now extracts all data without type filtering
  Future<List<Map<String, dynamic>>> _processWithGemini(String base64Image) async {
    try {
      print('Sending request to Gemini API...');
      final prompt = _getUnifiedPrompt();

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1, // Low temperature for more consistent output
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 4096, // Increased from 2048 to handle more data
        }
      };

      print('Making HTTP request to Gemini...');
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          print('Gemini response text: $text');
          return _parseGeminiResponse(text);
        } else {
          print('No candidates in response');
          throw Exception('No data extracted from image - candidates empty');
        }
      } else if (response.statusCode == 400) {
        print('Bad request - likely API key issue or invalid request format');
        throw Exception('Invalid API request. Please check your API key.');
      } else if (response.statusCode == 403) {
        print('Forbidden - API key might be invalid or quota exceeded');
        throw Exception('API access denied. Please check your API key.');
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in _processWithGemini: $e');
      rethrow;
    }
  }

  // New unified prompt that extracts all data
  String _getUnifiedPrompt() {
    return '''
Analyze this image and extract ALL financial data including both expenses and salary/payment information. Look for tables, lists, or any structured data containing names/descriptions and amounts.

Please extract the data and format it as JSON array with this structure:
[
  {
    "itemName": "John Doe" or "Office Supplies",
    "amount": 50000,
    "date": "${DateTime.now().toIso8601String()}",
    "suggestedType": "salary" or "expense",
    "suggestedCategory": "Monthly" or "Food" or "Utilities" etc,
    "description": "Any additional context or reason if available"
  }
]

Instructions:
- Extract ALL visible names/descriptions and their corresponding amounts
- For suggestedType: analyze if it looks like a person's name (likely salary) or item/service (likely expense)
- For suggestedCategory: 
  - If suggestedType is "salary": use "Monthly", "Weekly", "OT", "Commission"
  - If suggestedType is "expense": use "Food", "Utilities", "Maintenance", "Supplies", "Transportation", "Marketing", "Equipment", "Other"
- Use current date/time for the date field
- Only include entries where both name and amount are clearly visible
- Convert amounts to numbers (remove currency symbols, commas)
- Add any additional context in description field
- Return only valid JSON, no additional text or explanations
- If no data is found, return empty array []
''';
  }

  // Updated parsing method
  List<Map<String, dynamic>> _parseGeminiResponse(String response) {
    try {
      print('Raw response length: ${response.length}');
      print('Raw response: $response');

      // Clean the response to extract JSON
      String cleanedResponse = response.trim();

      // Remove markdown formatting if present
      cleanedResponse = cleanedResponse.replaceAll('```json', '').replaceAll('```', '').trim();

      // Try to find JSON array in the response
      final jsonStart = cleanedResponse.indexOf('[');
      final jsonEnd = cleanedResponse.lastIndexOf(']');

      print('JSON start: $jsonStart, JSON end: $jsonEnd');

      // If we have a complete JSON array, try to parse it normally
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
        print('Extracted JSON string: $jsonString');

        try {
          final List<dynamic> jsonArray = jsonDecode(jsonString);
          print('Successfully parsed JSON array with ${jsonArray.length} items');

          // Convert to List<Map<String, dynamic>> and validate data
          final result = jsonArray.map((item) {
            if (item is Map<String, dynamic>) {
              final parsedItem = {
                'itemName': item['itemName']?.toString() ?? '',
                'amount': _parseAmount(item['amount']),
                'date': item['date']?.toString() ?? DateTime.now().toIso8601String(),
                'suggestedType': item['suggestedType']?.toString() ?? 'expense',
                'suggestedCategory': item['suggestedCategory']?.toString() ?? 'Other',
                'description': item['description']?.toString() ?? '',
              };
              print('Parsed item: $parsedItem');
              return parsedItem;
            }
            return <String, dynamic>{};
          }).where((item) => item.isNotEmpty).toList();

          print('Final result count: ${result.length}');
          return result;
        } catch (jsonError) {
          print('JSON decode error: $jsonError');
          // Fall through to incomplete JSON parsing
        }
      }

      // If normal JSON parsing failed or JSON is incomplete, try to extract objects manually
      print('Attempting to parse incomplete/malformed JSON...');
      return _parseIncompleteJson(cleanedResponse);

    } catch (e) {
      print('Error parsing Gemini response: $e');
      print('Response was: $response');
      return [];
    }
  }

  // Helper method to parse incomplete JSON
  List<Map<String, dynamic>> _parseIncompleteJson(String jsonString) {
    try {
      print('Attempting to parse incomplete JSON...');

      List<Map<String, dynamic>> validItems = [];

      // Find complete objects by looking for pattern: { ... }
      // More aggressive pattern to catch incomplete objects
      final objectPattern = RegExp(r'\{[^{}]*"itemName"[^{}]*"amount"[^{}]*\}', multiLine: true, dotAll: true);
      final matches = objectPattern.allMatches(jsonString);

      print('Found ${matches.length} potential object matches');

      for (final match in matches) {
        try {
          final objectString = match.group(0)!;
          print('Trying to parse object: $objectString');

          final Map<String, dynamic> item = jsonDecode(objectString);

          if (item.containsKey('itemName') && item.containsKey('amount')) {
            final parsedItem = {
              'itemName': item['itemName']?.toString() ?? '',
              'amount': _parseAmount(item['amount']),
              'date': item['date']?.toString() ?? DateTime.now().toIso8601String(),
              'suggestedType': item['suggestedType']?.toString() ?? 'expense',
              'suggestedCategory': item['suggestedCategory']?.toString() ?? 'Other',
              'description': item['description']?.toString() ?? '',
            };
            validItems.add(parsedItem);
            print('Successfully parsed object: $parsedItem');
          }
        } catch (e) {
          print('Failed to parse object: $e');
          continue;
        }
      }

      // If the regex approach didn't work, try line-by-line parsing
      if (validItems.isEmpty) {
        print('Regex approach failed, trying line-by-line parsing...');
        validItems = _parseLineByLine(jsonString);
      }

      print('Recovered ${validItems.length} items from incomplete JSON');
      return validItems;
    } catch (e) {
      print('Error in incomplete JSON parsing: $e');
      return [];
    }
  }

  // Alternative parsing method - extract data line by line
  List<Map<String, dynamic>> _parseLineByLine(String jsonString) {
    try {
      print('Attempting line-by-line parsing...');

      List<Map<String, dynamic>> validItems = [];
      final lines = jsonString.split('\n');

      String? currentItemName;
      double? currentAmount;
      String? currentDate;
      String? currentType;
      String? currentCategory;
      String? currentDescription;

      for (String line in lines) {
        line = line.trim().replaceAll(',', '').replaceAll('"', '');

        if (line.contains('itemName:')) {
          currentItemName = line.split(':').last.trim();
        } else if (line.contains('amount:')) {
          currentAmount = _parseAmount(line.split(':').last.trim());
        } else if (line.contains('date:')) {
          currentDate = line.split(':').last.trim();
        } else if (line.contains('suggestedType:')) {
          currentType = line.split(':').last.trim();
        } else if (line.contains('suggestedCategory:')) {
          currentCategory = line.split(':').last.trim();
        } else if (line.contains('description:')) {
          currentDescription = line.split(':').last.trim();
        }

        // When we hit a closing brace or start of new object, save current item
        if (line.contains('}') && currentItemName != null && currentAmount != null) {
          final parsedItem = {
            'itemName': currentItemName,
            'amount': currentAmount,
            'date': currentDate ?? DateTime.now().toIso8601String(),
            'suggestedType': currentType ?? 'expense',
            'suggestedCategory': currentCategory ?? 'Other',
            'description': currentDescription ?? '',
          };
          validItems.add(parsedItem);
          print('Line-by-line parsed item: $parsedItem');

          // Reset for next item
          currentItemName = null;
          currentAmount = null;
          currentDate = null;
          currentType = null;
          currentCategory = null;
          currentDescription = null;
        }
      }

      print('Line-by-line parsing found ${validItems.length} items');
      return validItems;
    } catch (e) {
      print('Error in line-by-line parsing: $e');
      return [];
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) {
      // Remove currency symbols, commas, and spaces
      final cleanedAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanedAmount) ?? 0.0;
    }
    return 0.0;
  }
}

// Add this global navigator key to your main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();