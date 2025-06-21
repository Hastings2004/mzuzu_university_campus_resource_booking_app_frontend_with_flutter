import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  Future<void> _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Auth()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text(
          "Terms and Conditions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage("assets/images/logo.png"),
                    height: 50,
                  ),
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
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: const Text('Resources'),
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
              leading: const Icon(Icons.book_online_outlined),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('History'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined, color: Colors.black54),
              title: const Text('Terms and Conditions'),
              onTap: () {
                Navigator.pop(context); // Already on this screen
              },
              tileColor: Colors.grey[200],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildTermSection(
              '1. Introduction',
              'Welcome to the Mzuzu University Campus Resource Booking App. By using our app, you agree to comply with and be bound by the following terms and conditions of use, which together with our privacy policy govern our relationship with you in relation to this app.',
            ),
            _buildTermSection(
              '2. Use of the App',
              'This app is for the exclusive use of students and staff of Mzuzu University for booking campus resources. The use of this app for any unauthorized purpose is strictly prohibited.',
            ),
            _buildTermSection(
              '3. Booking Policy',
              'All bookings are subject to availability and approval by the university administration. We reserve the right to cancel or modify bookings as necessary. Users must adhere to the specific rules and regulations associated with each resource.',
            ),
            _buildTermSection(
              '4. User Conduct',
              'Users are expected to conduct themselves in a responsible and respectful manner. Any misuse of the resources or the app, including but not limited to vandalism, unauthorized access, or booking for non-academic purposes, will result in disciplinary action.',
            ),
            _buildTermSection(
              '5. Cancellation Policy',
              'If you need to cancel a booking, please do so at least 24 hours in advance to make the resource available to others. Failure to cancel in a timely manner may result in suspension of booking privileges.',
            ),
            _buildTermSection(
              '6. Liability',
              'The university is not responsible for any personal items lost or stolen in the booked resources. Users are responsible for any damage caused to university property during their booking period.',
            ),
            _buildTermSection(
              '7. Amendments',
              'We may revise these terms and conditions from time to time. The revised terms will apply to the use of our app from the date of publication. Please check this page regularly to ensure you are familiar with the current version.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(content),
        const SizedBox(height: 16),
      ],
    );
  }
}
