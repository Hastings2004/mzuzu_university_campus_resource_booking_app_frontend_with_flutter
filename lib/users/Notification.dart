import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/notification.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; 
import 'package:resource_booking_app/auth/Api.dart'; 


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadNotificationCount = 0; // New state for unread count

  @override
  void initState() {
    super.initState();
    _fetchNotificationsAndUnreadCount(); // Fetch both on screen load
  }

  // --- Utility & Logout ---
  void logout() async {
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

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
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

  void _showNotificationDetailDialog(
    BuildContext context,
    String title,
    String message,
    String timeAgo,
    int notificationId,
  ) {
    // Mark as read when the dialog is shown
    _markNotificationAsRead(notificationId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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

  // --- API Calls ---

  Future<void> _fetchNotificationsAndUnreadCount() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch all notifications
      final notificationsRes = await CallApi().getData('notifications');
      final notificationsBody = json.decode(notificationsRes.body);

      // Fetch unread count
      final unreadRes = await CallApi().getData('notifications/unread');
      final unreadBody = json.decode(unreadRes.body);

      if (notificationsRes.statusCode == 200 &&
          notificationsBody['success'] == true) {
        List<dynamic> notificationsJson = notificationsBody['notifications'];
        setState(() {
          _notifications =
              notificationsJson
                  .map((json) => NotificationModel.fromJson(json))
                  .toList();
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      } else {
        String errorMessage =
            notificationsBody['message'] ?? 'Failed to load notifications.';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }

      if (unreadRes.statusCode == 200 && unreadBody['success'] == true) {
        setState(() {
          _unreadNotificationCount = unreadBody['notifications'] ?? 0;
        });
      } else {
        debugPrint(
          "Failed to fetch unread notification count: ${unreadBody['message']}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching notifications or unread count: $e");
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

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      final response = await CallApi().postData(
        {},
        'notifications/$notificationId/mark-as-read',
      );
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        debugPrint("Notification $notificationId marked as read.");
        // Optimistically update the local list and unread count
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notificationId,
          );
          if (index != -1 && _notifications[index].status == 'unread') {
            _notifications[index].status = 'read'; // Correctly assign 'read'
            if (_unreadNotificationCount > 0) {
              _unreadNotificationCount--;
            }
          }
        });
        // You might want to re-fetch the entire list to ensure consistency,
        // especially if there are other changes, but optimistic update is faster.
        // _fetchNotificationsAndUnreadCount();
      } else {
        debugPrint("Failed to mark notification as read: ${body['message']}");
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Clear All Notifications"),
                content: const Text(
                  "Are you sure you want to clear all notifications?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Clear All",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final res = await CallApi().postData(
        {},
        'notifications/mark-all-as-read',
      ); // Use the new endpoint
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications cleared!')),
          );
        }
        // Refresh the list after clearing all
        _fetchNotificationsAndUnreadCount(); // Re-fetch to get updated statuses and count
      } else {
        String errorMessage =
            body['message'] ?? 'Failed to clear all notifications.';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      debugPrint("Error clearing all notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear all notifications: $e')),
        );
      }
    }
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const Bottombar(),
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
        elevation: 0,
        actions: [
          // Clear All Button
          TextButton(
            onPressed: _markAllNotificationsAsRead,
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      drawer: Mydrawer(),
      body:
          _isLoading
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    elevation: 3,
                    // Apply background color based on status
                    color:
                        notification.status == 'unread'
                            ? Colors.blue.shade50
                            : null,
                    child: ListTile(
                      leading: Icon(
                        // Corrected icon for read/unread state
                        notification.status == 'unread'
                            ? Icons.mail
                            : Icons.mark_email_read,
                        color:
                            notification.status == 'unread'
                                ? Colors.blueAccent
                                : Colors.grey,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          // Apply fontWeight based on status
                          fontWeight:
                              notification.status == 'unread'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.message),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showNotificationDetailDialog(
                          context,
                          notification.title,
                          notification.message,
                          timeAgo,
                          notification
                              .id, // Pass notification ID to mark as read
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
