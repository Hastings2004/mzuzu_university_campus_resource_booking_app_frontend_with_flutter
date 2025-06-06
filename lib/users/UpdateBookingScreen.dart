import 'package:flutter/material.dart';
import 'package:resource_booking_app/models/booking.dart';
import 'package:resource_booking_app/components/AppBar.dart'; // Assuming you have this
import 'package:resource_booking_app/components/BottomBar.dart'; // Assuming you have this

class UpdateBookingScreen extends StatefulWidget {
  final Booking booking;

  const UpdateBookingScreen({super.key, required this.booking});

  @override
  State<UpdateBookingScreen> createState() => _UpdateBookingScreenState();
}

class _UpdateBookingScreenState extends State<UpdateBookingScreen> {
  // You would typically have TextEditingControllers for each field to be updated
  // For example:
  // late TextEditingController _purposeController;
  // DateTime? _selectedStartTime;
  // DateTime? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing booking data
    // _purposeController = TextEditingController(text: widget.booking.purpose);
    // _selectedStartTime = widget.booking.startTime;
    // _selectedEndTime = widget.booking.endTime;
  }

  @override
  void dispose() {
    // _purposeController.dispose();
    super.dispose();
  }

  void _saveUpdatedBooking() {
    // Implement logic to save updated booking
    // This would typically involve:
    // 1. Getting updated values from controllers/selected dates.
    // 2. Making an API call (e.g., PUT or PATCH) to your backend.
    // 3. Handling success/failure (e.g., showing a SnackBar, popping the screen).

    // For demonstration, just print and navigate back
    print('Saving updated booking for ID: ${widget.booking.id}');
    // Navigator.pop(context, true); // Pass true to indicate a successful update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          'Update Booking for ${widget.booking.resourceName}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: const Bottombar(), // Assuming you want this
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking ID: ${widget.booking.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Here you would build your form fields for updating the booking
              // Example:
              // TextField(
              //   controller: _purposeController,
              //   decoration: const InputDecoration(labelText: 'Purpose'),
              // ),
              // const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () async {
              //     // Logic to pick a new start time/date
              //   },
              //   child: Text('Change Start Time: ${DateFormat('MMM d, yyyy HH:mm').format(_selectedStartTime!)}'),
              // ),
              // const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: _saveUpdatedBooking,
              //   child: const Text('Save Changes'),
              // ),
              // Placeholder for the form
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      'Update form goes here!',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // In a real app, _saveUpdatedBooking() would be called after validating form
                        _saveUpdatedBooking();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulating update success!')),
                        );
                        Navigator.pop(context); // Go back after "saving"
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Simulate Save Updates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}