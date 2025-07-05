import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/models/booking.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class BookingAnalytics extends StatefulWidget {
  const BookingAnalytics({super.key});

  @override
  State<BookingAnalytics> createState() => _BookingAnalyticsState();
}

class _BookingAnalyticsState extends State<BookingAnalytics> {
  bool _loading = true;
  String? _error;
  String _timeRange = 'month'; // month, quarter, year

  Map<String, dynamic> _analytics = {
    'totalBookings': 0,
    'pendingBookings': 0,
    'approvedBookings': 0,
    'cancelledBookings': 0,
    'completedBookings': 0,
    'upcomingBookings': 0,
    'recentBookings': <Booking>[],
    'monthlyStats': <Map<String, dynamic>>[],
    'resourceUtilization': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Fetch different analytics data
      final bookingsResponse = await CallApi().getData(
        'bookings?per_page=1000&status=all',
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

        // Calculate analytics
        final now = DateTime.now();
        final analyticsData = {
          'totalBookings': allBookings.length,
          'pendingBookings':
              allBookings.where((b) => b.status == 'pending').length,
          'approvedBookings':
              allBookings.where((b) => b.status == 'approved').length,
          'cancelledBookings':
              allBookings.where((b) => b.status == 'cancelled').length,
          'completedBookings':
              allBookings.where((b) => b.status == 'completed').length,
          'upcomingBookings':
              allBookings
                  .where(
                    (b) => b.status == 'approved' && b.startTime.isAfter(now),
                  )
                  .length,
          'recentBookings': recentBookings.take(5).toList(),
          'monthlyStats': _calculateMonthlyStats(allBookings),
          'resourceUtilization': _calculateResourceUtilization(allBookings),
        };

        setState(() {
          _analytics = analyticsData;
        });
      } else {
        setState(() {
          _error = 'Failed to load analytics data';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection and try again.';
      });
      print('Failed to fetch analytics: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _calculateMonthlyStats(List<Booking> bookings) {
    final Map<String, Map<String, dynamic>> months = {};

    for (final booking in bookings) {
      final month = DateFormat('yyyy-MM').format(booking.startTime);
      if (!months.containsKey(month)) {
        months[month] = {
          'total': 0,
          'approved': 0,
          'pending': 0,
          'cancelled': 0,
        };
      }
      months[month]!['total'] = (months[month]!['total'] as int) + 1;
      months[month]![booking.status] =
          (months[month]![booking.status] as int?) ?? 0 + 1;
    }

    return months.entries
        .map((entry) => {'month': entry.key, ...entry.value})
        .toList()
      ..sort((a, b) => b['month'].compareTo(a['month']))
      ..take(6);
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
      ..take(5);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'in_use':
        return const Color.fromARGB(255, 17, 105, 20);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading analytics...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 17, 105, 20),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _timeRange,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _timeRange = newValue;
                        });
                        _fetchAnalytics();
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'month',
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(
                        value: 'quarter',
                        child: Text('This Quarter'),
                      ),
                      DropdownMenuItem(value: 'year', child: Text('This Year')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildSummaryCard(
                    '📊',
                    _analytics['totalBookings'].toString(),
                    'Total Bookings',
                  ),
                  _buildSummaryCard(
                    '⏳',
                    _analytics['pendingBookings'].toString(),
                    'Pending',
                  ),
                  _buildSummaryCard(
                    '✅',
                    _analytics['approvedBookings'].toString(),
                    'Approved',
                  ),
                  _buildSummaryCard(
                    '📅',
                    _analytics['upcomingBookings'].toString(),
                    'Upcoming',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Charts Section
              Row(
                children: [
                  Expanded(child: _buildMonthlyChart()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildResourceUtilization()),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Bookings
              _buildRecentBookings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 17, 105, 20),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Booking Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 17, 105, 20),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  (_analytics['monthlyStats'] as List<Map<String, dynamic>>)
                      .map(
                        (stat) => Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor('approved'),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        height:
                                            (stat['approved'] as int) /
                                            (stat['total'] as int) *
                                            120,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor('pending'),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        height:
                                            (stat['pending'] as int) /
                                            (stat['total'] as int) *
                                            120,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor('cancelled'),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        height:
                                            (stat['cancelled'] as int) /
                                            (stat['total'] as int) *
                                            120,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMM yy').format(
                                  DateFormat('yyyy-MM').parse(stat['month']),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                stat['total'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceUtilization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resource Utilization',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 17, 105, 20),
            ),
          ),
          const SizedBox(height: 16),
          ...(_analytics['resourceUtilization'] as List<Map<String, dynamic>>)
              .map(
                (resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          resource['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${resource['totalBookings']} bookings',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${(resource['totalHours'] as double).round()} hours',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((resource['totalBookings'] as int) / 10)
                                .clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor('approved'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 17, 105, 20),
            ),
          ),
          const SizedBox(height: 16),
          ...(_analytics['recentBookings'] as List<Booking>)
              .map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.resourceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(booking.startTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                          color: _getStatusColor(booking.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
