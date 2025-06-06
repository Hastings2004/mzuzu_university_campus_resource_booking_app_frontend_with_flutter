import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For managing session
import 'package:resource_booking_app/auth/Api.dart'; // Your custom API service
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/TextField.dart'; // Assuming you have this for input
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // This should be ResourcesScreen


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userEmail; // To store the current user's email
  // To store the current user's ID

  // Controllers for updating email and password
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  // Notification toggles
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSettings(); // Load settings when screen initializes
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // Load user data from shared preferences
  void _loadUserData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = localStorage.getString('email');
// Assuming you store user_id
    });
  }

  // Load notification settings from API
  Future<void> _loadNotificationSettings() async {
    try {
      final response = await CallApi().getData('user/settings'); // Adjust endpoint as needed
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          _emailNotificationsEnabled = body['settings']['email_notifications'] ?? true;
          _smsNotificationsEnabled = body['settings']['sms_notifications'] ?? false;
        });
      } else {
        print("Failed to load notification settings: ${body['message']}");
      }
    } catch (e) {
      print("Error loading notification settings: $e");
    }
  }

  // Update notification settings via API
  Future<void> _updateNotificationSettings(bool emailEnabled, bool smsEnabled) async {
    try {
      final data = {
        'email_notifications': emailEnabled,
        'sms_notifications': smsEnabled,
      };
      final response = await CallApi().postData(data, 'user/update-notification-settings'); // Adjust endpoint
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Notification settings updated.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Failed to update notification settings.')),
          );
        }
      }
    } catch (e) {
      print("Error updating notification settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating notification settings. Please try again.')),
        );
      }
    }
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
        ); 
       
      }
    }

  }
  // --- Account Management Functions (API based) ---

  // Function to change email
  Future<void> _changeEmail() async {
    if (_newEmailController.text.trim().isEmpty) {
      if (mounted) _showErrorDialog("New email cannot be empty.");
      return;
    }
    if (_newEmailController.text.trim() == _userEmail) {
      if (mounted) _showErrorDialog("New email cannot be the same as the current email.");
      return;
    }
    if (_currentPasswordController.text.trim().isEmpty) {
      if (mounted) _showErrorDialog("Please enter your current password to change email.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = {
        'new_email': _newEmailController.text.trim(),
        'current_password': _currentPasswordController.text.trim(),
      };
      final response = await CallApi().postData(data, 'user/update-email'); // Adjust endpoint
      final body = json.decode(response.body);

      if (mounted) Navigator.pop(context); // Dismiss loading indicator

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          _showSuccessDialog(
              body['message'] ?? "Email updated successfully! Please check your new email for verification if required.");
          // Update local email in shared preferences
          SharedPreferences localStorage = await SharedPreferences.getInstance();
          await localStorage.setString('email', _newEmailController.text.trim());
          setState(() {
            _userEmail = _newEmailController.text.trim();
          });
        }
        _newEmailController.clear();
        _currentPasswordController.clear();
      } else {
        if (mounted) {
          _showErrorDialog(body['message'] ?? 'Failed to update email. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading indicator
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $e');
      }
    }
  }

  // Function to change password
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.trim().isEmpty ||
        _newPasswordController.text.trim().isEmpty ||
        _confirmNewPasswordController.text.trim().isEmpty) {
      if (mounted) _showErrorDialog("Please fill all password fields.");
      return;
    }
    if (_newPasswordController.text.trim() != _confirmNewPasswordController.text.trim()) {
      if (mounted) _showErrorDialog("New passwords do not match.");
      return;
    }
    if (_newPasswordController.text.trim().length < 6) {
      if (mounted) _showErrorDialog("New password must be at least 6 characters long.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = {
        'current_password': _currentPasswordController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
        'new_password_confirmation': _confirmNewPasswordController.text.trim(),
      };
      final response = await CallApi().postData(data, 'user/update-password'); // Adjust endpoint
      final body = json.decode(response.body);

      if (mounted) Navigator.pop(context); // Dismiss loading indicator

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          _showSuccessDialog(body['message'] ?? "Password updated successfully!");
        }
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      } else {
        if (mounted) {
          _showErrorDialog(body['message'] ?? 'Failed to update password. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading indicator
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $e');
      }
    }
  }

  // Function to delete account
  Future<void> _deleteAccount() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Account"),
            content: const Text(
                "Are you sure you want to delete your account? This action cannot be undone. You will be permanently logged out."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) {
      return;
    }

    _currentPasswordController.clear();
    String? password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Password to Delete Account"),
        content: MyTextField(
          controller: _currentPasswordController,
          obscureText: true,
          hintText: "Enter current password",
          prefixIcon: const Icon(Icons.lock),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _currentPasswordController.text.trim());
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) {
      if (mounted) _showErrorDialog("Password is required to delete account.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = {'current_password': password};
      final response = await CallApi().postData(data, 'user/delete-account'); // Adjust endpoint
      final body = json.decode(response.body);

      if (mounted) Navigator.pop(context); // Dismiss loading indicator

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          _showSuccessDialog(body['message'] ?? "Account deleted successfully!");
        }
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        await localStorage.clear(); // Clear local storage completely
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Auth()), // Go back to auth gate
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(body['message'] ?? 'Failed to delete account. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading indicator
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $e');
      }
    }
  }

  // --- Helper Dialogs ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
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

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(),
      appBar: MyAppBar(
        titleWidget: const Text(
          "Settings",
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
                  Image(image: AssetImage("assets/images/logo.png"), height: 50),
                  Text(
                    'Mzuzu University',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
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
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
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
              leading: const Icon(Icons.notifications),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context); // Already on settings screen, close drawer
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userEmail != null)
              Text(
                "Logged in as: \n $_userEmail",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              )
            else
              const Text(
                "Loading user email...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 20),

            // --- Account Settings Section ---
            const Text(
              "Account Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Change Email"),
              onTap: () {
                _newEmailController.clear();
                _currentPasswordController.clear();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Change Email Address"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyTextField(
                          controller: _newEmailController,
                          hintText: "New Email",
                          obscureText: false,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: _currentPasswordController,
                          hintText: "Current Password",
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: _changeEmail,
                        child: const Text("Update Email"),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              onTap: () {
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmNewPasswordController.clear();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Change Password"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyTextField(
                          controller: _currentPasswordController,
                          hintText: "Current Password",
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: _newPasswordController,
                          hintText: "New Password",
                          obscureText: true,
                          prefixIcon: const Icon(Icons.vpn_key),
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: _confirmNewPasswordController,
                          hintText: "Confirm New Password",
                          obscureText: true,
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: _changePassword,
                        child: const Text("Update Password"),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
              onTap: _deleteAccount,
            ),
            const SizedBox(height: 30),

            // --- Notification Settings Section ---
            const Text(
              "Notification Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Email Notifications"),
              value: _emailNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _emailNotificationsEnabled = value;
                });
                _updateNotificationSettings(value, _smsNotificationsEnabled);
              },
            ),
            SwitchListTile(
              title: const Text("SMS Notifications"),
              value: _smsNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _smsNotificationsEnabled = value;
                });
                _updateNotificationSettings(_emailNotificationsEnabled, value);
              },
            ),
            const SizedBox(height: 30),

            // --- Legal & About Section ---
            const Text(
              "Legal & About",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.policy),
              title: const Text("Privacy Policy"),
              onTap: () {
                _showInfoDialog("Privacy Policy", "Link to your app's privacy policy will open here.");
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text("Terms of Service"),
              onTap: () {
                _showInfoDialog("Terms of Service", "Link to your app's terms of service will open here.");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About App"),
              onTap: () {
                _showInfoDialog(
                    "About Resource Booking App", "Version: 1.0.0\nDeveloped by Hastings.\nThis app allows users to book resources on campus easily and efficiently.");
              },
            ),
          ],
        ),
      ),
    );
  }
}