import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/TextField.dart'; // Assuming you have this for input
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart'; // Import NotificationScreen
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Ensure this is ResourcesScreen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  // Controllers for updating email and password
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  // Notification toggles (example)
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Pop all routes until the first (usually your splash/auth check screen)
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Then navigate to your actual login/authentication screen
      // Example: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
      // Replace `AuthScreen` with the actual name of your initial authentication screen
    }
  }

  // --- Account Management Functions ---

  // Function to re-authenticate user
  Future<bool> _reauthenticateUser(String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'wrong-password') {
        message = 'Incorrect current password.';
      } else if (e.code == 'user-not-found') {
        message = 'User not found. Please log in again.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your current password.';
      } else {
        message = 'Failed to re-authenticate: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(message);
      }
      return false;
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred during re-authentication: $e');
      }
      return false;
    }
  }

  // Function to change email
  Future<void> _changeEmail() async {
    if (_newEmailController.text.trim().isEmpty) {
      if (mounted) _showErrorDialog("New email cannot be empty.");
      return;
    }
    if (_newEmailController.text.trim() == user.email!) {
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
      bool reauthenticated = await _reauthenticateUser(_currentPasswordController.text.trim());
      if (!reauthenticated) {
        if (mounted) Navigator.pop(context); // Dismiss loading indicator
        return;
      }

      await user.updateEmail(_newEmailController.text.trim());
      await user.sendEmailVerification(); // Send verification to new email

      // Update Firestore document with new email and reset email_verified status
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "email": _newEmailController.text.trim(),
        "email_verified": false, // Mark as unverified until new email is confirmed
      });

      if (mounted) {
        Navigator.pop(context); // Dismiss loading indicator
        _showSuccessDialog(
            "Email updated successfully! A verification link has been sent to your new email. Please verify it.");
      }
      _newEmailController.clear();
      _currentPasswordController.clear();
      // Optional: You might want to log the user out here to force re-login and verification
      // if (mounted) {
      //   logout();
      // }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading indicator
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'The new email is already in use by another account.';
      } else if (e.code == 'invalid-email') {
        message = 'The new email address is not valid.';
      } else if (e.code == 'requires-recent-login') {
        message = 'You need to log in again to update your email. Please log out and then log back in.';
      } else {
        message = 'Failed to update email: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(message);
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
      bool reauthenticated = await _reauthenticateUser(_currentPasswordController.text.trim());
      if (!reauthenticated) {
        if (mounted) Navigator.pop(context); // Dismiss loading indicator
        return;
      }

      await user.updatePassword(_newPasswordController.text.trim());
      if (mounted) {
        Navigator.pop(context); // Dismiss loading indicator
        _showSuccessDialog("Password updated successfully!");
      }
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading indicator
      String message;
      if (e.code == 'weak-password') {
        message = 'The new password is too weak.';
      } else if (e.code == 'requires-recent-login') {
        message = 'You need to log in again to update your password. Please log out and then log back in.';
      } else {
        message = 'Failed to update password: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(message);
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
    // Show confirmation dialog first
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone. You will be permanently logged out."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) {
      return;
    }

    // Show password input dialog for re-authentication
    _currentPasswordController.clear(); // Clear before showing
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
              Navigator.pop(context); // Dismiss dialog
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
      bool reauthenticated = await _reauthenticateUser(password);
      if (!reauthenticated) {
        if (mounted) Navigator.pop(context); // Dismiss loading indicator
        return;
      }

      // Delete user data from Firestore first
      await FirebaseFirestore.instance.collection("users").doc(user.uid).delete();

      // Delete user from Firebase Authentication
      await user.delete();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading indicator
        _showSuccessDialog("Account deleted successfully!");
      }
      _currentPasswordController.clear();
      logout(); // Log out and navigate to login/auth screen
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading indicator
      String message;
      if (e.code == 'requires-recent-login') {
        message = 'You need to log in again to delete your account. Please log out and then log back in.';
      } else if (e.code == 'user-mismatch') {
        message = 'The provided credentials do not match the current user.';
      } else {
        message = 'Failed to delete account: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(message);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const DrawerHeader( // Added const
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                children: [
                  Image(image: AssetImage("assets/images/logo.png"), height: 50), // Corrected image usage
                  Text(
                    'Mzuzu University',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Campus Resource Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
              title: const Text('Notifications'), // Corrected typo
              leading: const Icon(Icons.notifications), // No longer highlight here
              onTap: () {
                // Navigate to NotificationScreen
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings, color: Colors.blueAccent), // Highlight current page
              onTap: () {
                // Already on settings screen, close drawer
                Navigator.pop(context);
              },
            ),
            const Divider(), // Separator
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
            Text(
              "Logged in as: ${user.email!}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                _newEmailController.clear(); // Clear previous inputs
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
                  // TODO: Implement logic to save this preference to Firestore/local storage
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email notifications ${value ? 'enabled' : 'disabled'}')),
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text("SMS Notifications"),
              value: _smsNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _smsNotificationsEnabled = value;
                  // TODO: Implement logic to save this preference to Firestore/local storage
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('SMS notifications ${value ? 'enabled' : 'disabled'}')),
                  );
                });
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
                // Implement navigation to a Privacy Policy page or open a URL
                _showInfoDialog("Privacy Policy", "Link to your app's privacy policy will open here.");
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text("Terms of Service"),
              onTap: () {
                // Implement navigation to a Terms of Service page or open a URL
                _showInfoDialog("Terms of Service", "Link to your app's terms of service will open here.");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About App"),
              onTap: () {
                _showInfoDialog(
                    "About Resource Booking App", "Version: 1.0.0\nDeveloped by Mzuzu University ICT Students.\nThis app allows users to book resources on campus easily and efficiently.");
              },
            ),
          ],
        ),
      ),
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
}