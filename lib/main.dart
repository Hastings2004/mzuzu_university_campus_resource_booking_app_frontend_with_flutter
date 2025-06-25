import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Resource Booking App',
      home: Auth(),
    );
  }
}
