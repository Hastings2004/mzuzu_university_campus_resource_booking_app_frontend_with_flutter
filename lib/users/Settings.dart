import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/terms.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/SecuritySettings.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/TextField.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'History.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userEmail; // To store the current user's email

  // Controllers for updating email and password
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  // Form Keys for dialogs to enable validation
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _deleteAccountFormKey =
      GlobalKey<FormState>(); // For password confirmation during delete

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
      final response = await CallApi().getData(
        'user/settings',
      ); // Adjust endpoint as needed
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          _emailNotificationsEnabled =
              body['settings']['email_notifications'] ?? true;
          _smsNotificationsEnabled =
              body['settings']['sms_notifications'] ?? false;
        });
      } else {
        debugPrint("Failed to load notification settings: ${body['message']}");
      }
    } catch (e) {
      debugPrint("Error loading notification settings: $e");
    }
  }

  // Update notification settings via API
  Future<void> _updateNotificationSettings(
    bool emailEnabled,
    bool smsEnabled,
  ) async {
    try {
      final data = {
        'email_notifications': emailEnabled,
        'sms_notifications': smsEnabled,
      };
      final response = await CallApi().postData(
        data,
        'user/update-notification-settings',
      ); // Adjust endpoint
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                body['message'] ?? 'Notification settings updated.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                body['message'] ?? 'Failed to update notification settings.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating notification settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error updating notification settings. Please try again.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final bool confirmLogout =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Confirm Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  TextButton(
                    onPressed:
                        () => Navigator.of(context).pop(false), // User cancels
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop(true), // User confirms
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
      // Clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to your login/auth screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => Auth(),
          ), // Use AuthPage for explicit navigation
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
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
    );

    try {
      final data = {
        'new_email': _newEmailController.text.trim(),
        'current_password': _currentPasswordController.text.trim(),
      };
      final response = await CallApi().postData(
        data,
        'user/update-email',
      ); // Adjust endpoint
      final body = json.decode(response.body);

      if (mounted) Navigator.pop(context); // Dismiss loading indicator

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          _showSuccessDialog(
            body['message'] ??
                "Email updated successfully! Please check your new email for verification if required.",
          );
          // Update local email in shared preferences
          SharedPreferences localStorage =
              await SharedPreferences.getInstance();
          await localStorage.setString(
            'email',
            _newEmailController.text.trim(),
          );
          setState(() {
            _userEmail = _newEmailController.text.trim();
          });
        }
        _newEmailController.clear();
        _currentPasswordController.clear();
      } else {
        if (mounted) {
          _showErrorDialog(
            body['message'] ?? 'Failed to update email. Please try again.',
          );
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
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
    );

    try {
      final data = {
        'current_password': _currentPasswordController.text.trim(),
        'password': _newPasswordController.text.trim(),
        'password_confirmation': _confirmNewPasswordController.text.trim(),
      };

      final response = await CallApi().patchData(data, 'user/change-password');
      final body = json.decode(response.body);

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          _showSuccessDialog(
            body['message'] ?? "Password updated successfully!",
          );
        }
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      } else {
        if (mounted) {
          _showErrorDialog(
            body['message'] ?? 'Failed to update password. Please try again.',
          );
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
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  "Delete Account",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  "Are you sure you want to delete your account? This action cannot be undone. You will be permanently logged out.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Confirm Password to Delete Account",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                    Navigator.pop(
                      context,
                      _currentPasswordController.text.trim(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (password == null || password.isEmpty) {
      if (mounted)
        _showErrorDialog("Password confirmation failed or was cancelled.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
    );

    try {
      final data = {'current_password': password};
      final response = await CallApi().postData(data, 'user/delete-account');
      final body = json.decode(response.body);

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          _showSuccessDialog(
            body['message'] ?? "Account deleted successfully!",
          );
        }
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        await localStorage.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Auth()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            body['message'] ?? 'Failed to delete account. Please try again.',
          );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Error",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Success",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: const Bottombar(),
      appBar: MyAppBar(
        titleWidget: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onSearchPressed: () {},
        isSearching: false,
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
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
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
              leading: const Icon(Icons.settings, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('History'),
              leading: const Icon(Icons.history),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 30),

            // Account Settings Section
            
            _buildSettingsSection(
              title: "Account Settings",
              icon: Icons.account_circle,
              children: [
                _buildSettingsTile(
                  icon: Icons.policy,
                  title: "Security Settings",
                  subtitle: "Your security settings",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecuritySettingsScreen(),
                      ),
                    );
                  },
                ),
                
                _buildSettingsTile(
                  icon: Icons.email,
                  title: "Change Email",
                  subtitle: "Update your email address",
                  onTap: () {
                    _newEmailController.clear();
                    _currentPasswordController.clear();
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              "Change Email Address",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                                    prefixIcon: const Icon(
                                      Icons.alternate_email,
                                    ),
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
                                  const SizedBox(height: 15),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Update Email",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: "Change Password",
                  subtitle: "Update your password",
                  onTap: () {
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmNewPasswordController.clear();
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              "Change Password",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Form(
                              key: _passwordFormKey,
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
                                  const SizedBox(height: 15),
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
                                  const SizedBox(height: 15),
                                  MyTextField(
                                    controller: _confirmNewPasswordController,
                                    hintText: "Confirm New Password",
                                    obscureText: true,
                                    prefixIcon: const Icon(
                                      Icons.vpn_key_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Confirm password is required';
                                      }
                                      if (value !=
                                          _newPasswordController.text) {
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Update Password",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                
              ],
            ),

            // Notification Settings Section
            _buildSettingsSection(
              title: "Notification Settings",
              icon: Icons.notifications,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      "Email Notifications",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text("Receive notifications via email"),
                    value: _emailNotificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _emailNotificationsEnabled = value;
                      });
                      _updateNotificationSettings(
                        value,
                        _smsNotificationsEnabled,
                      );
                    },
                    activeColor: Colors.green,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      "SMS Notifications",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text("Receive notifications via SMS"),
                    value: _smsNotificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _smsNotificationsEnabled = value;
                      });
                      _updateNotificationSettings(
                        _emailNotificationsEnabled,
                        value,
                      );
                    },
                    activeColor: Colors.green,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),

            _buildSettingsSection(
              title: "Legal & About",
              icon: Icons.info,
              children: [
                _buildSettingsTile(
                  icon: Icons.policy,
                  title: "Privacy Policy",
                  subtitle: "Read our privacy policy",
                  onTap: () {
                    _showInfoDialog(
                      "Privacy Policy",
                      "Link to your app's privacy policy will open here.",
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: "Terms of Service",
                  subtitle: "Read our terms of service",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: "About App",
                  subtitle: "Version 1.0.1 • Developed by Hastings Hastings",
                  onTap: () {
                    _showInfoDialog(
                      "About Resource Booking App",
                      "Version: 1.0.1\nDeveloped by Hastings.\nThis app allows users to book resources on campus easily and efficiently.",
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent settings sections
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // Helper widget to build consistent settings tiles
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
