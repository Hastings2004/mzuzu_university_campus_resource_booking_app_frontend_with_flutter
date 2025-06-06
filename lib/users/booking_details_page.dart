// lib/users/BookingDetailsPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/models/booking.dart'; // Make sure to import your Booking model
import 'package:resource_booking_app/auth/Api.dart'; // Import your API service for network calls
import 'dart:convert'; // For json.decode

import 'package:resource_booking_app/users/UpdateBookingScreen.dart'; // Import the new Update Booking Screen

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
            content: Text('Booking cannot be cancelled in its current state.')),
      );
      return;
    }

    final bool confirmCancel = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content:
            const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed

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
              status: 'cancelled'); // Update local state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully!')),
        );
        // Optionally, pop back to the previous screen or refresh the list
        // Navigator.pop(context, true); // Indicate success to the previous screen
      } else {
        String errorMessage = body['message'] ?? 'Failed to cancel booking.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
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
    // You might want to pass the current booking details to the update screen
    // and expect a result back (e.g., if the update was successful)
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBookingScreen(booking: _currentBooking),
      ),
    );

    // If the update screen indicates a change, you might want to refresh details
    if (updated == true) {
      // In a real app, you'd re-fetch the booking details to ensure they are up-to-date
      // For simplicity here, we'll just show a message.
      print("Booking potentially updated, consider refreshing data.");
      // If your UpdateBookingScreen passes back the updated booking object, you could do:
      // setState(() {
      //   _currentBooking = updatedBookingObject;
      // });
    }
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

    String formattedStartTime = DateFormat('MMM d,EEEE HH:mm').format(_currentBooking.startTime);
    String formattedEndTime = DateFormat('MMM d,EEEE HH:mm').format(_currentBooking.endTime);

    // Determine if actions (update/cancel) should be available
    final bool canModify = _currentBooking.status.toLowerCase() == 'pending' ||
                           _currentBooking.status.toLowerCase() == 'approved'; // Or only pending

    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          _currentBooking.resourceName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: const Bottombar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Use Column to add buttons below the card
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
                      child: Text(
                        _currentBooking.resourceName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1.5),
                    _buildDetailRow(
                      Icons.location_on,
                      'Location:',
                      _currentBooking.resourceLocation,
                    ),
                    _buildDetailRow(Icons.description, 'Purpose:', _currentBooking.purpose),
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
                        Chip(
                          label: Text(
                            _currentBooking.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: statusColor.withOpacity(0.1),
                          side: BorderSide(color: statusColor, width: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (canModify) // Only show buttons if the booking can be modified
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToUpdateBooking,
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Update Booking', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
                      onPressed: _cancelBooking,
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}