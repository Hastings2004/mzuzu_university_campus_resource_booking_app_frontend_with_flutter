import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart'; // Import your API helper
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart'; // Corrected spelling for ResourcesScreen
import 'package:resource_booking_app/users/Settings.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'dart:convert'; // For JSON decoding

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Use SharedPreferences to get user data instead of FirebaseAuth
  int? _userId;
  String _firstName = 'User'; // Default value for welcome message
  String _lastName = '';
  String _userEmail = '';

  // Store upcoming booking details
  Map<String, dynamic>? _upcomingBooking;
  bool _isLoadingBookings = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndBookingData();
  }

  Future<void> _fetchCurrentUserAndBookingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    _firstName = prefs.getString('first_name') ?? "";
    _lastName = prefs.getString('last_name') ?? '';
    _userEmail = prefs.getString('user_email') ?? 'No Email';

    print(
      "User ID: $_userId, First_Name: $_firstName, Last_Name: $_lastName Email: $_userEmail",
    );
    setState(() {}); // Update the UI with initial user data

    if (_userId == null) {
      // If user ID is not found, means not logged in, navigate to login
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Fetch upcoming booking from your API
    try {
      var res = await CallApi().getData(
        'user/upcoming-booking',
      ); // Assuming an API endpoint like this
      var body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        if (body['bookings'] != null && body['bookings'].isNotEmpty) {
          // Assuming your API returns a list of bookings, take the first one
          setState(() {
            _upcomingBooking = body['bookings'][0];
            print(_upcomingBooking);
          });
        } else {
          setState(() {
            _upcomingBooking = null; // No upcoming bookings
          });
        }
      } else {
        print(
          "Error fetching upcoming bookings from API: ${body['message'] ?? 'Unknown error'}",
        );
        setState(() {
          _upcomingBooking = null; // Clear if error
        });
      }
    } catch (e) {
      print("Network or parsing error fetching upcoming bookings: $e");
      setState(() {
        _upcomingBooking = null; // Clear if error
      });
    } finally {
      setState(() {
        _isLoadingBookings = false;
      });
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
    return Scaffold(
      bottomNavigationBar: Bottombar(),
      appBar: MyAppBar(
        titleWidget: const Text(
          "Home",
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
              leading: const Icon(Icons.home, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context);
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
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Personalized Welcome Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Welcome, $_userEmail",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Today is ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Look at Upcoming Bookings Section
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Upcoming Bookings",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "View All",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _isLoadingBookings
                          ? const Center(child: CircularProgressIndicator())
                          : _upcomingBooking == null
                          ? const Text(
                            "You have no upcoming approved bookings.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _upcomingBooking!['resource']['name'] ??
                                    'Unknown Resource', // Adjust key as per API
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Location: ${_upcomingBooking!['resource']['location'] ?? 'N/A'}', // Adjust key as per API
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'From: ${DateFormat('MMM d, hh:mm a').format(DateTime.parse(_upcomingBooking!['start_time']))}', // Parse API date string
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'To: ${DateFormat('MMM d, hh:mm a').format(DateTime.parse(_upcomingBooking!['end_time']))}', // Parse API date string
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Go to Bookings',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Actions: Make a New Booking & View All Resources
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResourcesScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_box_outlined,
                                size: 40,
                                color: Colors.blue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "New Booking",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResourcesScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_view,
                                size: 40,
                                color: Colors.orange,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "All Resources",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Placeholder for Announcements/News
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Announcements & News",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Divider(),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.campaign, color: Colors.red),
                      title: Text("System Maintenance Scheduled!"),
                      subtitle: Text(
                        "Expected downtime on 28th May, 8 AM - 10 AM. Bookings may be affected.",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.celebration, color: Colors.purple),
                      title: Text("Resource Updates"),
                      subtitle: Text(
                        "Currently most resources are occupied due to classes",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
