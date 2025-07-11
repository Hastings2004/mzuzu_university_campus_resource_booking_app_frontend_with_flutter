import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/booking.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:intl/intl.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Booking>> _bookingHistoryFuture;

  @override
  void initState() {
    super.initState();
    _bookingHistoryFuture = _fetchBookingHistory();
  }

  Future<List<Booking>> _fetchBookingHistory() async {
    final response = await CallApi().getData('booking-history');
    if (response.statusCode == 200) {
      final List<dynamic> bookingData = json.decode(response.body);
      return bookingData.map((data) => Booking.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load booking history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(titleWidget: const Text("History", style: TextStyle(color: Colors.white),)), // Ensure MyAppBar accepts a Text widget
      bottomNavigationBar: const Bottombar(), 
      drawer: Mydrawer(), 
      body: FutureBuilder<List<Booking>>(
        future: _bookingHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No booking history found.'));
          } else {
            final bookings = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Booking History',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true, 
                    physics:
                    const NeverScrollableScrollPhysics(), 
                    itemCount: bookings.length, 
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resource: ${booking.resourceName}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Date: ${DateFormat.yMMMd().format(booking.startTime)}', 
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                              Text(
                                'Time: ${DateFormat.jm().format(booking.startTime)} - ${DateFormat.jm().format(booking.endTime)}', // Replace with actual time
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Status: ${booking.status}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(booking.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
