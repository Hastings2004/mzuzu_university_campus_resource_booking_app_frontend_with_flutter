import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/components/terms.dart';
import 'package:resource_booking_app/users/SecuritySettings.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/TextField.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userEmail; 

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

  // Notification toggles
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSettings(); 
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
      // _userId = localStorage.getInt('user_id'); 
    });
  }

  // Load notification settings from API
  Future<void> _loadNotificationSettings() async {
    try {
      final response = await CallApi().getData(
        '',
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
      drawer: Mydrawer(),
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
