import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';

class Bottombar extends StatelessWidget {
  const Bottombar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color.fromARGB(255, 20, 148, 24),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white, weight: 20, size: 30),
            onPressed: () {
              // Handle home button press
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.white, weight: 20, size: 30),
            onPressed: () {
              // Handle search button press
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ResourcesScreen()),
                );
            },
          ),
          IconButton(
            onPressed: (){
              // Handle booking button press
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) =>  BookingScreen()),
                );
            }, 
                icon: Icon(Icons.book_online, color: Colors.white, weight: 20, size: 30,)
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white, weight: 20, size: 30),
            
            onPressed: () {
              // Handle profile button press
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
            },
          ),
        ],
      ),
    );
  }
}