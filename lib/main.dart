import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';

// Add this global navigator key for image processing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey, // Add this line for image processing
    home: HomeScreen(),
  ));
}