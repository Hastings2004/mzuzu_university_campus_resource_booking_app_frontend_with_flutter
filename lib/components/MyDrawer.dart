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

class Mydrawer extends StatefulWidget {
  const Mydrawer({super.key});

  @override
  State<Mydrawer> createState() => _MydrawerState();
}

class _MydrawerState extends State<Mydrawer> {
  // Track the selected index to highlight the current drawer item
  int? _selectedIndex;
  
  void logout(BuildContext context) async {
    final bool confirmLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
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

  // Helper method to navigate and update selected index
  void _onItemTap(BuildContext context, Widget screen, int index) {
    setState(() {
      _selectedIndex = index;
    });
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (_selectedIndex == null) {
      if (currentRoute == '/') { 
        _selectedIndex = 0; 
      } else if (currentRoute == '/profile') { 
         _selectedIndex = 1; 
      }
      
    }


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

          _buildDrawerItem(
            context,
            Icons.home,
            'Home',
            0, // Index 0
            const BookingDashboard(), 
          ),
          _buildDrawerItem(
            context,
            Icons.person,
            'Profile',
            1, // Index 1
            const ProfileScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.grid_view,
            'Resources',
            2, // Index 2
            const ResourcesScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.book_online,
            'Bookings',
            3, // Index 3
            BookingScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.dashboard,
            'Booking Dashboard',
            4, // Index 4
            const BookingDashboard(), 
          ),
          _buildDrawerItem(
            context,
            Icons.calendar_month,
            'Booking Calendar',
            5, // Index 5
            const BookingCalendar(),
          ),
          _buildDrawerItem(
            context,
            Icons.notifications,
            'Notifications',
            6, // Index 6
            const NotificationScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.report,
            'Report Issue',
            7, // Index 7
            const IssueManagementScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.settings,
            'Settings',
            8, // Index 8
            const SettingsScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.history,
            'History',
            9, // Index 9
            const HistoryScreen(),
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

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, int index, Widget screen) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : null, 
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      leading: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : null, 
      ),
      tileColor: isSelected ? Colors.blueAccent.withOpacity(0.1) : null, 
      onTap: () {
        if (!isSelected) {
          _onItemTap(context, screen, index);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}