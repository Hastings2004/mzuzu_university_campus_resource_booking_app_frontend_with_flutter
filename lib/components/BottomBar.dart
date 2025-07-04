import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';

class Bottombar extends StatelessWidget {
  final int currentIndex;

  const Bottombar({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color.fromARGB(255, 20, 148, 24),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home,
              color: currentIndex == 0 ? Colors.blue : Colors.white,
              weight: 20,
              size: 30,
            ),
            onPressed: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.grid_view,
              color: currentIndex == 1 ? Colors.blue : Colors.white,
              weight: 20,
              size: 30,
            ),
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResourcesScreen(),
                  ),
                );
              }
            },
          ),
          IconButton(
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              }
            },
            icon: Icon(
              Icons.book_online,
              color: currentIndex == 2 ? Colors.blue : Colors.white,
              weight: 20,
              size: 30,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: currentIndex == 3 ? Colors.blue : Colors.white,
              weight: 20,
              size: 30,
            ),
            onPressed: () {
              if (currentIndex != 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
