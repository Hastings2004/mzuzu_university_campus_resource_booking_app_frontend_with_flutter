import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For json.decode
import 'package:resource_booking_app/auth/Api.dart'; // Your API service
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Assuming this is ResourcesScreen
import 'package:resource_booking_app/users/Settings.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // We no longer directly use FirebaseAuth.instance.currentUser
  // The user's ID would be passed or fetched via SharedPreferences if needed for API calls.
  // For notifications, the API usually determines the user based on the authenticated token.

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications(); // Fetch notifications on screen load
  }

  void logout() async {
    // Show a confirmation dialog
    final bool confirmLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // User cancels
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true), // User confirms
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Optional: make logout button red
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false; 

    if (confirmLogout) {
   
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to your login/auth screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        ); // Assuming '/' is your initial login route
       
      }
    }

  }
  
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await CallApi().getData('notifications'); // Your API endpoint for notifications
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        List<dynamic> notificationsJson = body['notifications'];
        setState(() {
          _notifications = notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          // Sort by timestamp in descending order, if not already sorted by API
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      } else {
        String errorMessage = body['message'] ?? 'Failed to load notifications.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to dismiss a single notification
  Future<void> _dismissNotification(int notificationId) async {
    try {
      /* Assuming a DELETE request for dismissing a notification
      final res = await CallApi().deleteData('notifications/$notificationId'); // e.g., DELETE /api/notifications/1
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification dismissed!')),
          );
        }
        // Refresh the list after dismissal
        _fetchNotifications();
      } else {
        String errorMessage = body['message'] ?? 'Failed to dismiss notification.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }*/
    } catch (e) {
      print("Error dismissing notification: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss notification: $e')),
        );
      }
    }
  }

  // Function to dismiss all notifications
  Future<void> _dismissAllNotifications() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Clear All Notifications"),
            content: const Text("Are you sure you want to clear all notifications?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Clear All", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // Assuming a POST or DELETE request for clearing all notifications
      final res = await CallApi().postData({}, 'notifications/clear-all'); // e.g., POST /api/notifications/clear-all
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications cleared!')),
          );
        }
        // Refresh the list after clearing all
        _fetchNotifications();
      } else {
        String errorMessage = body['message'] ?? 'Failed to clear all notifications.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      print("Error clearing all notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear all notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Bottombar(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 148, 24),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            tooltip: "Clear All Notifications",
            onPressed: _dismissAllNotifications,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 50,
                  ),
                  const Text(
                    'Mzuzu University',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Campus Resource Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Resources'),
              leading: const Icon(Icons.grid_view),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
              },
            ),
            ListTile(
              title: const Text('Bookings'),
              leading: const Icon(Icons.book_online),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BookingScreen()));
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        "No new notifications",
                        style: TextStyle(fontSize: 22, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];

                    String timeAgo = _getTimeAgo(notification.timestamp);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.notification_important, color: Colors.blueAccent),
                        title: Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              timeAgo,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => _dismissNotification(notification.id),
                          tooltip: "Dismiss",
                        ),
                        onTap: () {
                          _showNotificationDetailDialog(
                              context, notification.title, notification.message, timeAgo);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).round()} months ago';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).round()} weeks ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  void _showNotificationDetailDialog(BuildContext context, String title, String message, String timeAgo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 10),
              Text(
                'Received: $timeAgo',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}