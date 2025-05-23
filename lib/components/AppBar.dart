import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Settings.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {

  final String title;
  const MyAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 20, 148, 24),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        }, 
        icon: const Icon(Icons.menu, color: Colors.white,),
    ), 
    actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.notifications,color: Colors.white),
        onPressed: () {
          // Handle notification button press
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => NotificationScreen(),
          ));
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () {
          // Handle settings button press
          Navigator.push(context, MaterialPageRoute(
            builder: (context) =>  SettingsScreen(),
          ));
        },
      ),
      
    ],
    );
  }
}