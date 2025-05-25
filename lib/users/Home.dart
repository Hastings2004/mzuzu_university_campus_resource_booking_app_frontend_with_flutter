import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resource_booking_app/components/AppBar.dart'; // Your updated custom AppBar
import 'package:resource_booking_app/read_data/getUserData.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Corrected spelling for ResourcesScreen
import 'package:resource_booking_app/users/Settings.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final user = FirebaseAuth.instance.currentUser!;

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  // We'll store the current user's document ID here
  String? currentUserDocID;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDocID(); // Fetch the current user's document ID on init
  }

  Future<void> _fetchCurrentUserDocID() async {
    // Assuming your user documents in Firestore are named by their UID
    currentUserDocID = user.uid;
    setState(() {}); // Rebuild the widget to display the user data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text( // Use titleWidget as your AppBar now expects a Widget
          "Home",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // No onSearchPressed and isSearching for the Home screen's AppBar
        // This ensures the search icon does not appear on the Home screen.
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
                children: [
                  Image.asset("assets/images/logo.png", height: 50),
                  const Text(
                    'Mzuzu University',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Campus Resource Booking',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                // Already on Home, just close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Resources'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResourcesScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Booking'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Settings'), // Corrected typo
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
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
      // Wrap the entire Column in a SingleChildScrollView
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Align content to start
          children: [
            const SizedBox(height: 10), // Spacing below welcome text
            // Display user profile card
            currentUserDocID == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Show a loading indicator
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ), // Consistent padding
                    child: Card(
                      elevation: 4, // Add some shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ), // Rounded corners
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(
                          16.0,
                        ), // Padding inside ListTile
                        title: const Center(
                          child: Text(
                            "Your Profile",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            Getuserdata(
                              documentId: currentUserDocID!,
                            ), // Display current user's data
                            const SizedBox(height: 8),
                            const Text(
                              "Click here to view/edit your profile details.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.green,
                          ), // Changed icon for modern look
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 10),

            // Make a New Booking Card (leading to ResourcesScreen for new booking)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: const Text(
                    "Make a New Booking",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Browse available resources and make a reservation.",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResourcesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
// View My Bookings Card (leading to BookingScreen)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: const Text(
                    "My Current Bookings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Review your upcoming and past reservations.",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // View All Resources Card (leading to ResourcesScreen)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: const Text(
                    "View All Resources",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "See all available resources in the system.",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResourcesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            
            const SizedBox(height: 20), // Add some space at the bottom
          ],
        ),
      ),
    );
  }
}