import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/booking.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/admin/AdminHome.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class BookingDashboard extends StatefulWidget {
  const BookingDashboard({super.key});

  @override
  State<BookingDashboard> createState() => _BookingDashboardState();
}

class _BookingDashboardState extends State<BookingDashboard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  // This variable isn't used after refactor, can remove if not needed elsewhere.

  Map<String, dynamic> _dashboardData = {
    'recentBookings': <Booking>[],
    'upcomingBookings': <Booking>[],
    'pendingBookings': <Booking>[],
    'totalBookings': 0,
    'approvedBookings': 0,
    'cancelledBookings': 0,
    'resourceUtilization': <Map<String, dynamic>>[],
  };

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      // Fetch different data sources
      final bookingsResponse = await CallApi().getData(
        'bookings?per_page=1000',
      );
      final recentResponse = await CallApi().getData('bookings-recent');

      if (bookingsResponse.statusCode == 200 &&
          recentResponse.statusCode == 200) {
        final bookingsBody = json.decode(bookingsResponse.body);
        final recentBody = json.decode(recentResponse.body);

        final allBookings =
            (bookingsBody['bookings'] as List?)
                    ?.map((booking) => Booking.fromJson(booking))
                    .toList() ??
                [];

        final recentBookings =
            (recentBody['bookings'] as List?)
                    ?.map((booking) => Booking.fromJson(booking))
                    .toList() ??
                [];

        // Calculate dashboard metrics
        final now = DateTime.now();
        final dashboardMetrics = {
          'recentBookings': recentBookings.take(5).toList(),
          'upcomingBookings': allBookings
              .where(
                (b) => b.status == 'approved' && b.startTime.isAfter(now),
              )
              .take(5)
              .toList(),
          'pendingBookings':
              allBookings.where((b) => b.status == 'pending').take(5).toList(),
          'totalBookings': allBookings.length,
          'approvedBookings':
              allBookings.where((b) => b.status == 'approved').length,
          'cancelledBookings':
              allBookings.where((b) => b.status == 'cancelled').length,
          'resourceUtilization': _calculateResourceUtilization(allBookings),
        };

        setState(() {
          _dashboardData = dashboardMetrics;
        });
      } else {
        setState(() {
          _error =
              'Failed to load dashboard data. Status: ${bookingsResponse.statusCode} / ${recentResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection and try again.';
      });
      print('Failed to fetch dashboard data: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _calculateResourceUtilization(
    List<Booking> bookings,
  ) {
    final Map<String, Map<String, dynamic>> resourceStats = {};

    for (final booking in bookings) {
      final resourceId = booking.resourceId.toString();
      if (!resourceStats.containsKey(resourceId)) {
        resourceStats[resourceId] = {
          'name': booking.resourceName,
          'totalBookings': 0,
          'totalHours': 0.0,
        };
      }
      resourceStats[resourceId]!['totalBookings'] =
          (resourceStats[resourceId]!['totalBookings'] as int) + 1;

      final start = booking.startTime;
      final end = booking.endTime;
      final hours = end.difference(start).inHours.toDouble();
      resourceStats[resourceId]!['totalHours'] =
          (resourceStats[resourceId]!['totalHours'] as double) + hours;
    }

    return resourceStats.values.toList()
      ..sort(
        (a, b) =>
            (b['totalBookings'] as int).compareTo(a['totalBookings'] as int),
      )
      ..take(5); // Show top 5
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'completed':
        return Colors.blue.shade600;
      case 'in_use':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildQuickActions() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2, // Adjusted for better look
          children: [
            _buildActionCard(
              Icons.search,
              'Find Resources',
              'Browse available resources',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResourcesScreen(),
                ),
              ),
            ),
            _buildActionCard(
              Icons.calendar_today,
              'My Bookings',
              'View your personal bookings',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingScreen()),
              ),
            ),
            _buildActionCard(
              Icons.dashboard,
              'Admin Dashboard', // Changed title
              'Manage all bookings and resources',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Adminhome()),
              ),
            ),
            _buildActionCard(
              Icons.add_box,
              'Add Resource',
              'Register a new resource',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResourcesScreen(), // Assuming this screen also has an add resource option or leads to one.
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon, // Changed to IconData
    String title,
    String description,
    VoidCallback onTap,
  ) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: secondaryColor), // Use secondary color for icons
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview Statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        // Metrics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2, // Consistent aspect ratio
          children: [
            _buildMetricCard(
              Icons.bar_chart, // Changed icon
              _dashboardData['totalBookings'].toString(),
              'Total Bookings',
            ),
            _buildMetricCard(
              Icons.check_circle_outline, // Changed icon
              _dashboardData['approvedBookings'].toString(),
              'Approved',
            ),
            _buildMetricCard(
              Icons.hourglass_empty, // Changed icon
              (_dashboardData['pendingBookings'] as List).length.toString(),
              'Pending',
            ),
            _buildMetricCard(
              Icons.cancel_outlined, // Changed icon
              _dashboardData['cancelledBookings'].toString(),
              'Cancelled',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Dashboard Sections
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Stack vertically for smaller screens
              return Column(
                children: [
                  _buildUpcomingBookings(),
                  const SizedBox(height: 24),
                  _buildResourceUtilization(),
                ],
              );
            } else {
              // Side by side for larger screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildUpcomingBookings()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildResourceUtilization()),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, String value, String label) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: secondaryColor),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    final upcomingBookings =
        _dashboardData['upcomingBookings'] as List<Booking>;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const Divider(height: 24, thickness: 1),
            if (upcomingBookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        'No upcoming bookings scheduled.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingBookings.length,
                itemBuilder: (context, index) {
                  final booking = upcomingBookings[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.resourceName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('MMM dd, yyyy HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.purpose,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(booking.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceUtilization() {
    final resourceUtilization =
        _dashboardData['resourceUtilization'] as List<Map<String, dynamic>>;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Resource Utilization',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const Divider(height: 24, thickness: 1),
            if (resourceUtilization.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline,
                          size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        'No resource utilization data available.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resourceUtilization.length,
                itemBuilder: (context, index) {
                  final resource = resourceUtilization[index];
                  double utilizationValue =
                      (resource['totalBookings'] / 10.0)
                          .clamp(0.0, 1.0); // Normalize for progress bar
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${resource['totalBookings']} bookings • ${(resource['totalHours'] as double).round()} hours',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100, // Adjust width as needed
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: utilizationValue,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(secondaryColor),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(utilizationValue * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    final recentBookings = _dashboardData['recentBookings'] as List<Booking>;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Bookings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        if (recentBookings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'No recent bookings to display.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, // Adjusted for slightly more height
            ),
            itemCount: recentBookings.length,
            itemBuilder: (context, index) {
              final booking = recentBookings[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.resourceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 17),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(booking.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${DateFormat('MMM dd, HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          booking.purpose,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 3, // Allow more lines for purpose
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    if (_loading) {
      return Scaffold(
        appBar: MyAppBar(
          titleWidget: Text(
            "Booking Dashboard",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onPrimaryColor,
            ),
          ),
        ),
        drawer: Mydrawer(), 
        bottomNavigationBar: const Bottombar(currentIndex: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: MyAppBar(
          titleWidget: Text(
            "Booking Dashboard",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onPrimaryColor,
            ),
          ),
        ),
        drawer: Mydrawer(), // Use the new _buildDrawer
        bottomNavigationBar: const Bottombar(currentIndex: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade700),
              const SizedBox(height: 24),
              Text(
                'Oops! An error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: const Bottombar(currentIndex: 0),
      appBar: MyAppBar(
        titleWidget: Text(
          "Booking Dashboard",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onPrimaryColor,
          ),
        ),
      ),
      drawer: Mydrawer(), 
      backgroundColor: Colors.grey[50], 
      body: SafeArea(
        child: RefreshIndicator( 
          onRefresh: _fetchDashboardData,
          color: primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header and Refresh Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome Back!', // More engaging title
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: _fetchDashboardData,
                      icon: Icon(Icons.refresh, color: primaryColor),
                      tooltip: 'Refresh dashboard',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12), // Larger radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15), // Softer shadow
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: onPrimaryColor, // Label color changes based on theme
                    unselectedLabelColor: Colors.grey[700],
                    indicator: BoxDecoration(
                      color: primaryColor, // Indicator matches primary color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'Overview', icon: Icon(Icons.leaderboard)), // Added icons
                      Tab(text: 'Recent', icon: Icon(Icons.history)),
                      Tab(text: 'Actions', icon: Icon(Icons.flash_on)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                          child: _buildOverview()), // Scrollable content
                      SingleChildScrollView(child: _buildRecentBookings()),
                      SingleChildScrollView(child: _buildQuickActions()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void logout() {
    // This function will navigate the user back to the first route in the navigation stack,
    // which is typically your login or splash screen.
    // Ensure this aligns with your app's navigation flow.
    print('User logged out');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  
}