import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/BookingCalendar.dart';
import 'package:resource_booking_app/users/BookingDashboard.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mydrawer extends StatelessWidget {
  const Mydrawer({super.key});

  void logout(BuildContext context) async {
    // Show a confirmation dialog
    final bool confirmLogout =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 20, 148, 24)),
            child: Column(
              children: [
                Image(image: AssetImage("assets/images/logo.png"), height: 50),
                Text(
                  'Mzuzu University',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Campus Resource Booking',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Home'),
            leading: const Icon(Icons.home, color: Colors.blueAccent),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Profile'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Resources'),
            leading: const Icon(Icons.grid_view),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResourcesScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Bookings'),
            leading: const Icon(Icons.book_online),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BookingScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Booking Dashboard'),
            leading: const Icon(Icons.dashboard),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingDashboard(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Booking Calendar'),
            leading: const Icon(Icons.calendar_month),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingCalendar(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            leading: const Icon(Icons.notifications),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Report Issue'),
            leading: const Icon(Icons.report),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const IssueManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('History'),
            leading: const Icon(Icons.history),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}
