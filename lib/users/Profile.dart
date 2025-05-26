import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/read_data/getUserData.dart'; // Assuming this fetches user data
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Ensure this is `ResourcesScreen`
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/EditProfile.dart'; // Your EditProfileScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // Use const constructor

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser; // Make it nullable
  String? currentUserDocID;
  String _firstName = 'Loading...';
  String _lastName = '';
  String _email = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      currentUserDocID = user!.uid;
      _email = user!.email ?? 'No Email'; // Get email from FirebaseAuth

      // Fetch additional user data from Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _firstName = userData['first_name'] ?? 'N/A';
            _lastName = userData['last_name'] ?? 'N/A';
            // You can fetch other fields like phone, student ID, etc. here
          });
        } else {
          setState(() {
            _firstName = 'User Data';
            _lastName = 'Not Found';
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() {
          _firstName = 'Error';
          _lastName = '';
        });
      }
    } else {
      // Handle case where user is null (not logged in, though unlikely to reach here)
      setState(() {
        _firstName = 'Not Logged In';
        _email = 'N/A';
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Navigate to your login/auth screen
      // e.g., Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center items
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
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context); // Already on profile screen, close drawer
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
      body: user == null || currentUserDocID == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 220, 240, 220), // Light green background
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
                    // Future: Use NetworkImage(user?.photoURL ?? 'default_avatar.png')
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_firstName $_lastName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _email,
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
                          builder: (context) => EditProfileScreen(
                            userDocId: currentUserDocID!,
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
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color.fromARGB(255, 20, 148, 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
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
                          leading: const Icon(Icons.person_outline, color: Colors.green),
                          title: const Text('Full Name'),
                          subtitle: Text('$_firstName $_lastName'),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.email_outlined, color: Colors.green),
                          title: const Text('Email'),
                          subtitle: Text(_email),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        // Example of another detail you might fetch from Firestore
                        // ListTile(
                        //   leading: const Icon(Icons.phone, color: Colors.green),
                        //   title: const Text('Phone Number'),
                        //   subtitle: Text(userPhoneNumber ?? 'N/A'),
                        // ),
                        // const Divider(indent: 16, endIndent: 16),
                        // ListTile(
                        //   leading: const Icon(Icons.school, color: Colors.green),
                        //   title: const Text('Student ID'),
                        //   subtitle: Text(userStudentId ?? 'N/A'),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section for Account Management
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
                          leading: const Icon(Icons.lock_reset, color: Colors.orange),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Implement navigation to a Change Password screen
                            //ScaffoldMessenger.of(context).showSnackBar(
                             // const SnackBar(content: Text('Change Password functionality coming soon!')),
                            //);
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> SettingsScreen()));
                          },
                        ),
                        // You could add "Delete Account" here as well
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