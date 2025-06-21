import 'package:flutter/material.dart';
import 'package:resource_booking_app/admin/AdminHome.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/auth/Login.dart';
import 'package:resource_booking_app/auth/Register.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
