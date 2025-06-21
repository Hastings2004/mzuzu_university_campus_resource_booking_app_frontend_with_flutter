import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/booking_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For json.decode
import 'package:resource_booking_app/auth/Api.dart'; // API service
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/models/booking.dart'; // Import your new Booking model
import 'package:resource_booking_app/users/History.dart'; // Import your new Booking model


class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<List<Booking>>? _bookingsFuture;
  int? _userId; // To store the authenticated user's ID

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUserIdAndFetchBookings();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndFetchBookings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
    });
    if (_userId != null) {
      _bookingsFuture = fetchBookings();
    } else {
      // Handle case where user ID is not found (e.g., redirect to login)
      print("User ID not found in shared preferences. Redirecting to login.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Auth()), // Redirect to AuthGate or LoginScreen
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _toggleSearching() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  Future<List<Booking>> fetchBookings() async {
    try {
      
      final res = await CallApi().getData('bookings'); // Or 'bookings/user/$_userId' if needed
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        List<dynamic> bookingJson = body['bookings']; // Assuming 'bookings' is the key holding the array
        return bookingJson.map((json) => Booking.fromJson(json)).toList();
      } else {
        // Handle API error messages
        String errorMessage = body['message'] ?? 'Failed to load bookings.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print("Error fetching bookings: $e");
      throw Exception('Failed to fetch bookings: $e');
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
        ); // Assuming '/' is your initial login route
       
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Bottombar(),
      appBar: MyAppBar(
        titleWidget: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search bookings...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                ),
              )
            : const Text(
                "My Bookings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        onSearchPressed: _toggleSearching,
        isSearching: _isSearching,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
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
                  MaterialPageRoute(builder: (context) => Home()),
                );
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Resources'),
              leading: const Icon(Icons.grid_view),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ResourcesScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Bookings'),
              leading: const Icon(Icons.book_online, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context); // Already on this screen
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('History'),
              leading: const Icon(Icons.history),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Current Bookings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _userId == null // Show loading or error if user ID is not loaded
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Booking>>(
                    future: _bookingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'You have no active bookings.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      final allBookings = snapshot.data!;
                      final filteredBookings = allBookings.where((booking) {
                        final resourceName = booking.resourceName.toLowerCase();
                        final purpose = booking.purpose.toLowerCase();
                        final location = booking.resourceLocation.toLowerCase();
                        final status = booking.status.toLowerCase();

                        return resourceName.contains(_searchQuery) ||
                            purpose.contains(_searchQuery) ||
                            location.contains(_searchQuery) ||
                            status.contains(_searchQuery);
                      }).toList();

                      if (filteredBookings.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching bookings found.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          var booking = filteredBookings[index];
                          String formattedStartTime = DateFormat(
                            'MMM d, yyyy HH:mm', // Changed format to yyyy for clarity
                          ).format(booking.startTime);
                          String formattedEndTime = DateFormat(
                            'MMM d, yyyy HH:mm',
                          ).format(booking.endTime);

                          Color statusColor;
                          switch (booking.status.toLowerCase()) {
                            case 'pending':
                              statusColor = Colors.orange;
                              break;
                            case 'approved':
                              statusColor = Colors.green;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              break;
                            case 'cancelled':
                              statusColor = Colors.grey;
                              break;
                            default:
                              statusColor = Colors.grey;
                          }

                          return GestureDetector(
                            onTap: () {
                              // Handle tap if needed, e.g., navigate to booking details
                              print('Tapped on booking: ${booking.resourceName}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingDetailsPage(booking: booking),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                          booking.resourceName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Reference Number: ${booking.bookingReference}',
                                          style: const TextStyle(fontSize: 16, color: Colors.blue),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Location: ${booking.resourceLocation}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Purpose: ${booking.purpose}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 8),
                            
                                        // Add other resource details here
                                        if (booking.resourceDescription != null && booking.resourceDescription!.isNotEmpty) ...[
                                          Text(
                                            'Description: ${booking.resourceDescription}',
                                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (booking.resourceCapacity != null) ...[
                                          Text(
                                            'Capacity: ${booking.resourceCapacity}',
                                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                            
                            
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Start: $formattedStartTime',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'End: $formattedEndTime',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            booking.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}