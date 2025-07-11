import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'dart:convert';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/EditProfile.dart';
import 'package:resource_booking_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'History.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await CallApi().getData('profile');
      final body = json.decode(res.body);
      print("API Response Body for user profile: $body");

      if (res.statusCode == 200 && body['success'] == true) {
        if (body.containsKey('user') && body['user'] is Map<String, dynamic>) {
          setState(() {
            _userProfile = UserModel.fromJson(body['user']);
          });
        } else {
          String errorMessage =
              'User data not found or invalid in response from /profile.';
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
          }
          print("Error: $errorMessage. Full body: $body");
        }
      } else {
        String errorMessage = body['message'] ?? 'Failed to load user profile.';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
        if (res.statusCode == 401 || res.statusCode == 403) {
          if (mounted) {
            logout(); // Force logout if unauthorized or forbidden
          }
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void logout() async {
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
                    onPressed:
                        () => Navigator.of(context).pop(false), // User cancels
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop(true), // User confirms
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ), // Optional: make logout button red
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
        // Navigate to your login/auth screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        ); // Assuming '/' is your initial login route
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (your existing build method)
    // Pay attention to where _userProfile is used, ensure it's not null before accessing properties
    return Scaffold(
      bottomNavigationBar: Bottombar(currentIndex: 3),
      appBar: MyAppBar(
        titleWidget: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Mydrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userProfile == null
              // Show a clear message if user data couldn't be loaded or isn't available
              ? const Center(
                child: Text(
                  "Failed to load user data. Please ensure you are logged in and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(
                          255,
                          220,
                          240,
                          220,
                        ), // Light green background
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_userProfile!.firstName} ${_userProfile!.lastName}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userProfile!.email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to the EditProfileScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditProfileScreen(
                                        userProfile: _userProfile!,
                                        userId: _userProfile!.id,
                                      ),
                                ),
                              ).then((_) {
                                // When returning from EditProfileScreen, refresh the data
                                _fetchUserData();
                              });
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                20,
                                148,
                                24,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Additional Details:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.person_outline,
                                    color: Colors.green,
                                  ),
                                  title: const Text('Full Name'),
                                  subtitle: Text(
                                    '${_userProfile!.firstName} ${_userProfile!.lastName}',
                                  ),
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.green,
                                  ),
                                  title: const Text('Email'),
                                  subtitle: Text(_userProfile!.email),
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                // ListTile(
                                //     leading: const Icon(Icons.phone_android, color: Colors.green),
                                //     title: const Text('Phone Number'),
                                //     subtitle: Text(_userProfile!.phoneNumber ?? 'Not specified'),
                                // ),
                                // const Divider(indent: 16, endIndent: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                  title: const Text('District'),
                                  subtitle: Text(
                                    _userProfile!.district ?? 'Not specified',
                                  ),
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                  title: const Text('Village'),
                                  subtitle: Text(
                                    _userProfile!.village ?? 'Not specified',
                                  ),
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                if (_userProfile!.studentId != null &&
                                    _userProfile!.studentId!.isNotEmpty)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.school,
                                      color: Colors.green,
                                    ),
                                    title: const Text('Student ID'),
                                    subtitle: Text(_userProfile!.studentId!),
                                  ),
                                if (_userProfile!.studentId != null &&
                                    _userProfile!.studentId!.isNotEmpty)
                                  const Divider(indent: 16, endIndent: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Account Management:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.lock_reset,
                                    color: Colors.orange,
                                  ),
                                  title: const Text('Change Password'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
