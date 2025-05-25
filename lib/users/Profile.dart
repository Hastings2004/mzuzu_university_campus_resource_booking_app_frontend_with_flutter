import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resource_booking_app/components/AppBar.dart'; // Your updated custom AppBar
import 'package:resource_booking_app/read_data/getUserData.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Ensure this is `ResourcesScreen`
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/EditProfile.dart'; // Import the new EditProfileScreen

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  String? currentUserDocID;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDocID();
  }

  Future<void> _fetchCurrentUserDocID() async {
    currentUserDocID = user.uid;
    setState(() {});
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text( // Now requires a Widget
          "Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // No onSearchPressed and isSearching for the Profile screen's AppBar
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration( // Added const for BoxDecoration
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 50,
                  ),
                  const Text( // Added const for Text
                    'Mzuzu University',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text( // Added const for Text
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
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Already on Profile, just close the drawer
              },
            ),
            ListTile(
              title: const Text('Resources'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ResourcesScreen()));
              },
            ),
            ListTile(
              title: const Text('Booking'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => BookingScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                logout();
                // Pop all routes until the first route (usually login/welcome)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: currentUserDocID == null
            ? const CircularProgressIndicator()
            : Column(
                children: [
                  const Padding( // Added const for Padding
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Your Profile Details:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Getuserdata(documentId: currentUserDocID!),
                        ),
                      ),
                    ),
                  ),
                  // Add an "Edit Profile" button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to the EditProfileScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              userDocId: currentUserDocID!, // Pass the user's document ID
                            ),
                          ),
                        ).then((_) {
                          // Optional: Refresh data after returning from EditProfileScreen
                          // This ensures any changes are reflected immediately
                          setState(() {
                            // You might want to re-fetch if Getuserdata doesn't listen to changes
                            // For now, assuming Getuserdata is a StatelessWidget and needs a refresh
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 20, 148, 24), // Green color
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}