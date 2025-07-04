import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/users/issue_management_screen.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'package:resource_booking_app/users/RecommendationScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // State for announcements
  List<dynamic> _announcements = [];
  bool _isLoadingAnnouncements = true;

  // State for recommendations
  List<dynamic> _recommendations = [];
  bool _isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndBookingData();
    _fetchAnnouncements();
    _fetchRecommendations();
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
    setState(() {});

    if (_userId == null) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Fetch upcoming booking
    try {
      var res = await CallApi().getData('user/upcoming-booking');
      var body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        if (body['bookings'] != null && body['bookings'].isNotEmpty) {
          setState(() {
            _upcomingBooking = body['bookings'][0];
            print(_upcomingBooking);
          });
        } else {
          setState(() {
            _upcomingBooking = null;
          });
        }
      } else {
        print(
          "Error fetching upcoming bookings from API: ${body['message'] ?? 'Unknown error'}",
        );
        setState(() {
          _upcomingBooking = null; 
        });
      }
    } catch (e) {
      print("Network or parsing error fetching upcoming bookings: $e");
      setState(() {
        _upcomingBooking = null; 
      });
    } finally {
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  Future<void> _fetchAnnouncements() async {
    try {
      var res = await CallApi().getData('news');
      var body = json.decode(res.body);
      if (res.statusCode == 200) {
        // Assuming Laravel's paginated response, data is in 'data' key
        if (body['data'] != null && body['data'] is List) {
          if (mounted) {
            setState(() {
              _announcements = body['data'];
            });
          }
        }
      } else {
        print("Failed to load announcements");
      }
    } catch (e) {
      print("Error fetching announcements: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      var res = await CallApi().getData('recommendations/resources?limit=3');
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          setState(() {
            _recommendations = body['recommendations'] ?? [];
          });
        }
      } else {
        print(
          "Failed to load recommendations: ${body['message'] ?? 'Unknown error'}",
        );
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
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
                        () => Navigator.of(context).pop(false), 
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop(true), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Bottombar(currentIndex: 0),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Your Profile",
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
                                  builder: (context) => ProfileScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "View",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Welcome, $_firstName $_lastName!",
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
            
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
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
                                    'Unknown Resource',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Location: ${_upcomingBooking!['resource']['location'] ?? 'N/A'}',
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
                              builder: (context) => const BookingScreen(),
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
            const SizedBox(height: 10),
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
                      child:InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const RecommendationScreen(),
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
                                Icons.recommend,
                                size: 40,
                                color: Colors.purple,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Recommendations",
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
                              builder:
                                  (context) => IssueManagementScreen(),
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
                                Icons.report_problem_outlined,
                                size: 40,
                                color: Color.fromARGB(255, 81, 0, 255),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Report Issues",
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

            // Recommendations Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recommended for You",
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
                              builder: (context) => const ResourcesScreen(),
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
                  _isLoadingRecommendations
                      ? const Center(child: CircularProgressIndicator())
                      : _recommendations.isEmpty
                      ? Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const ListTile(
                          leading: Icon(Icons.recommend, color: Colors.orange),
                          title: Text("No recommendations available"),
                          subtitle: Text(
                            "Start booking resources to get personalized recommendations.",
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = _recommendations[index];
                          final resource = recommendation['resource'];
                          final score = recommendation['score'];
                          final reasons =
                              recommendation['reasons'] ?? ['Popular choice'];

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const ResourcesScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                resource['name'] ??
                                                    'Unknown Resource',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Location: ${resource['location'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (resource['capacity'] != null)
                                                Text(
                                                  'Capacity: ${resource['capacity']} people',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${score.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      children:
                                          (reasons as List<dynamic>).take(2).map(
                                            (reason) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  reason.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              );
                                            },
                                          ).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Announcements & News Section
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
                  _isLoadingAnnouncements
                      ? const Center(child: CircularProgressIndicator())
                      : _announcements.isEmpty
                      ? Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text("No new announcements"),
                          subtitle: Text("Check back later for updates."),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: const Icon(
                                Icons.campaign,
                                color: Colors.red,
                              ),
                              title: Text(announcement['title'] ?? 'No Title'),
                              subtitle: Text(
                                announcement['content'] ?? 'No Content',
                              ),
                            ),
                          );
                        },
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
