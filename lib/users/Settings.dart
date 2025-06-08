import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Auth.dart'; 
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For managing session
import 'package:resource_booking_app/auth/Api.dart'; // Your custom API service
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart'; // Assuming you have this
import 'package:resource_booking_app/components/TextField.dart'; // Assuming you have this for input
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Corrected to ResourcesScreen - make sure the file name is 'Resources.dart'
import 'package:resource_booking_app/auth/AuthPage.dart'; // Import your AuthPage for logout navigation

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userEmail; // To store the current user's email

  // Controllers for updating email and password
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  // Form Keys for dialogs to enable validation
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _deleteAccountFormKey = GlobalKey<FormState>(); // For password confirmation during delete

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
      // _userId = localStorage.getInt('user_id'); // userId not directly used in this screen, can remove if not needed
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
        debugPrint("Failed to load notification settings: ${body['message']}");
      }
    } catch (e) {
      debugPrint("Error loading notification settings: $e");
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
      debugPrint("Error updating notification settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating notification settings. Please try again.')),
        );
      }
    }
  }

  Future<void> _logout() async {
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmLogout) {
      // Clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to your login/auth screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Auth()), // Use AuthPage for explicit navigation
          (route) => false,
        );
      }
    }
  }

  // --- Account Management Functions (API based) ---

  // Function to change email
  Future<void> _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) return; // Validate form

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
    if (!_passwordFormKey.currentState!.validate()) return; // Validate form

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = {
        'current_password': _currentPasswordController.text.trim(),
        'password': _newPasswordController.text.trim(),
        'password_confirmation': _confirmNewPasswordController.text.trim(),
      };
      // Assuming your change-password endpoint uses PATCH/PUT, adjust if it's POST
      final response = await CallApi().patchData(data, 'user/change-password'); // Or .putData()
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

    _currentPasswordController.clear(); // Clear before using for confirmation
    String? password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Password to Delete Account"),
        content: Form(
          key: _deleteAccountFormKey, // Use a form key for validation
          child: MyTextField(
            controller: _currentPasswordController,
            obscureText: true,
            hintText: "Enter current password",
            prefixIcon: const Icon(Icons.lock),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required to delete account.';
              }
              return null;
            },
          ),
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
              if (_deleteAccountFormKey.currentState!.validate()) {
                Navigator.pop(context, _currentPasswordController.text.trim());
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) {
      if (mounted) _showErrorDialog("Password confirmation failed or was cancelled.");
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
            MaterialPageRoute(builder: (context) => Auth()), // Navigate to AuthPage
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
          title: const Text("Error", style: TextStyle(color: Colors.red)),
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
          title: const Text("Success", style: TextStyle(color: Colors.green)),
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      bottomNavigationBar: const Bottombar(), // Use your Bottombar widget
      appBar: MyAppBar(
        titleWidget: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onSearchPressed: () {}, // Provide an empty function if search is not needed
        isSearching: false, // Indicate if search is active
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
            _buildDrawerTile(Icons.home, 'Home', () => Home()),
            _buildDrawerTile(Icons.person, 'Profile', () => const ProfileScreen()),
            _buildDrawerTile(Icons.grid_view, 'Resources', () => const ResourcesScreen()),
            _buildDrawerTile(Icons.book_online, 'Bookings', () => BookingScreen()),
            _buildDrawerTile(Icons.notifications, 'Notifications', () => const NotificationScreen()),
            _buildDrawerTile(Icons.settings, 'Settings', () => Navigator.pop(context), isActive: true),
            const Divider(),
            _buildDrawerTile(Icons.logout, 'Logout', _logout, isDestructive: true),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current User",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.green),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _userEmail != null ? "Logged in as:\n$_userEmail" : "Loading user email...",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Account Settings Section
            _buildSettingsSection(
              title: "Account Settings",
              children: [
                _buildSettingsTile(
                  icon: Icons.email,
                  title: "Change Email",
                  onTap: () {
                    _newEmailController.clear();
                    _currentPasswordController.clear();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Change Email Address"),
                        content: Form(
                          key: _emailFormKey, // Attach form key
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MyTextField(
                                controller: _newEmailController,
                                hintText: "New Email",
                                obscureText: false,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.alternate_email),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter new email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              MyTextField(
                                controller: _currentPasswordController,
                                hintText: "Current Password",
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Current password is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
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
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: "Change Password",
                  onTap: () {
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmNewPasswordController.clear();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Change Password"),
                        content: Form(
                          key: _passwordFormKey, // Attach form key
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MyTextField(
                                controller: _currentPasswordController,
                                hintText: "Current Password",
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Current password is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              MyTextField(
                                controller: _newPasswordController,
                                hintText: "New Password",
                                obscureText: true,
                                prefixIcon: const Icon(Icons.vpn_key),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'New password is required';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              MyTextField(
                                controller: _confirmNewPasswordController,
                                hintText: "Confirm New Password",
                                obscureText: true,
                                prefixIcon: const Icon(Icons.vpn_key_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirm password is required';
                                  }
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
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
                _buildSettingsTile(
                  icon: Icons.delete_forever,
                  title: "Delete Account",
                  color: Colors.red,
                  onTap: _deleteAccount,
                ),
              ],
            ),

            // Notification Settings Section
            _buildSettingsSection(
              title: "Notification Settings",
              children: [
                SwitchListTile(
                  title: const Text("Email Notifications"),
                  value: _emailNotificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _emailNotificationsEnabled = value;
                    });
                    _updateNotificationSettings(value, _smsNotificationsEnabled);
                  },
                  activeColor: Colors.green,
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
                  activeColor: Colors.green,
                ),
              ],
            ),

            // Legal & About Section
            _buildSettingsSection(
              title: "Legal & About",
              children: [
                _buildSettingsTile(
                  icon: Icons.policy,
                  title: "Privacy Policy",
                  onTap: () {
                    _showInfoDialog("Privacy Policy", "Link to your app's privacy policy will open here.");
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: "Terms of Service",
                  onTap: () {
                    _showInfoDialog("Terms of Service", "Link to your app's terms of service will open here.");
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: "About App",
                  onTap: () {
                    _showInfoDialog(
                        "About Resource Booking App", "Version: 1.0.0\nDeveloped by Hastings.\nThis app allows users to book resources on campus easily and efficiently.");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent settings sections
  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const Divider(color: Colors.grey),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // Helper widget to build consistent settings tiles
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // Helper widget for drawer tiles
  Widget _buildDrawerTile(IconData icon, String title, Function onTapCallback, {bool isActive = false, bool isDestructive = false}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.blueAccent : (isDestructive ? Colors.red : Colors.black87),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      leading: Icon(
        icon,
        color: isActive ? Colors.blueAccent : (isDestructive ? Colors.red : Colors.grey),
      ),
      onTap: () {
        // Close the drawer before navigating
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Execute the navigation logic
        if (onTapCallback is Function()) {
          onTapCallback();
        } else if (onTapCallback is Widget Function()) { // For cases where a new route is returned
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => onTapCallback()));
        }
      },
    );
  }
}