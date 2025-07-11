import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/booking.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'dart:convert';

import 'package:resource_booking_app/users/UpdateBookingScreen.dart';
import 'package:resource_booking_app/users/issue_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailsPage extends StatefulWidget {
  final Booking booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  // We'll use a local variable to manage the booking state for updates (e.g., cancellation)
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  // Function to handle booking cancellation
  Future<void> _cancelBooking() async {
    // Only allow cancellation if the status is pending or approved
    if (_currentBooking.status.toLowerCase() != 'pending' &&
        _currentBooking.status.toLowerCase() != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cannot be cancelled in its current state.'),
        ),
      );
      return;
    }

    final bool confirmCancel =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Cancellation'),
                content: const Text(
                  'Are you sure you want to cancel this booking? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Yes, Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false; // Default to false if dialog is dismissed

    if (!confirmCancel) {
      return; // User cancelled the dialog
    }

    try {
      final res = await CallApi().postData(
        {'status': 'cancelled'}, // Send the new status
        'bookings/${_currentBooking.id}/cancel', // Example endpoint for cancellation
      );
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _currentBooking = _currentBooking.copyWith(
            status: 'cancelled',
          ); // Update local state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully!')),
        );
        // Optionally, pop back to the previous screen or refresh the list
        // Navigator.pop(context, true); // Indicate success to the previous screen
      } else {
        String errorMessage = body['message'] ?? 'Failed to cancel booking.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      print("Error cancelling booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not cancel booking. $e')),
      );
    }
  }

  // Function to navigate to the update booking screen
  void _navigateToUpdateBooking() async {
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBookingScreen(booking: _currentBooking),
      ),
    );

    // If the update screen indicates a change, you might want to refresh details
    if (updated == true) {
      print("Booking potentially updated, consider refreshing data.");
    }
  }

  void _navigateToReportIssuePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReportIssuePage(
              resourceId: _currentBooking.resourceId,
              resourceName: _currentBooking.resourceName,
            ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (_currentBooking.status.toLowerCase()) {
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

    String formattedStartTime = DateFormat(
      'MMM d,EEEE HH:mm',
    ).format(_currentBooking.startTime);
    String formattedEndTime = DateFormat(
      'MMM d,EEEE HH:mm',
    ).format(_currentBooking.endTime);

    // Determine if actions (update/cancel) should be available
    final bool canModify =
        _currentBooking.status.toLowerCase() == 'pending' ||
        _currentBooking.status.toLowerCase() == 'approved'; // Or only pending

    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          _currentBooking.resourceName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: const Bottombar(),
      drawer: Mydrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Use Column to add buttons below the card
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _currentBooking.resourceName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currentBooking.bookingReference,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30, thickness: 1.5),
                    _buildDetailRow(
                      Icons.location_on,
                      'Location:',
                      _currentBooking.resourceLocation,
                    ),
                    _buildDetailRow(
                      Icons.description,
                      'Purpose:',
                      _currentBooking.purpose,
                    ),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Start Time:',
                      formattedStartTime,
                    ),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'End Time:',
                      formattedEndTime,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blueGrey),
                        const SizedBox(width: 10),
                        const Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentBooking.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_currentBooking.status == 'cancelled' ||
                _currentBooking.status == 'rejected' ||
                _currentBooking.status == 'expired')
            // Show a message if the booking is cancelled or rejected
            ...[
              Text(
                'This booking cannot be modified.',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            if (canModify) 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Update Booking'),
                        onPressed: _navigateToUpdateBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel Booking'),
                        onPressed: _cancelBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                     Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Report an Issue'),
                        onPressed: _navigateToReportIssuePage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10), 
           
          ],
        ),
      ),
    );
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Auth()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }
}
