import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';

class MyMunu extends StatelessWidget {
  MyMunu({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  void logout(){
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 20, 148, 24),
          ),
          child: Column(
            children: [
              Image.asset(
                "images/logo.png",
                height: 50
              ),
              Text(
                'Mzuzu University',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
              ),
              Text(
                'Campus Resource Booking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          title: const Text('Home'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
          },
        ),
        ListTile(
          title: const Text('Profile'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          },
        ),
        ListTile(
          title: const Text('Resources'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ResourcesScreen()));
          },
        ),
        ListTile(
          title: const Text('Booking'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
          },
        ),
        ListTile(
          title: const Text('Setings'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
          },
        ),
        ListTile(
          title: const Text('Logout'),
          onTap: () {
            logout();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}