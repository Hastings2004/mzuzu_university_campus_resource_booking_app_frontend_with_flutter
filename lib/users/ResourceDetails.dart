// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';

class ResourceDetails extends StatefulWidget {
  final DocumentSnapshot resourceDocument;

  const ResourceDetails({Key? key, required this.resourceDocument}) : super(key: key);

  @override
  _ResourceDetailsState createState() => _ResourceDetailsState();
}

class _ResourceDetailsState extends State<ResourceDetails> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;

  bool _isLoading = false; // To show loading state during booking

  @override
  void dispose() {
    _purposeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to the authentication screen or login screen after logout
    if (mounted) { // Check if the widget is still in the tree
      Navigator.of(context).popUntil((route) => route.isFirst);
      // You might want to push to your AuthPage or Login page directly here
      // e.g., Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthPage()));
    }
  }

  // Function to pick a date
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate != null) {
      if (isStart) {
        setState(() {
          _selectedStartDate = pickedDate;
        });
      } else {
        setState(() {
          _selectedEndDate = pickedDate;
        });
      }
    }
  }

  // Function to pick a time
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      if (isStart) {
        setState(() {
          _selectedStartTime = pickedTime;
          _startTimeController.text = _formatDateTime(_selectedStartDate, _selectedStartTime);
        });
      } else {
        setState(() {
          _selectedEndTime = pickedTime;
          _endTimeController.text = _formatDateTime(_selectedEndDate, _selectedEndTime);
        });
      }
    }
  }

  // Helper to format DateTime for display
  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return '${dt.toLocal().toIso8601String().split('T').first} ${time.format(context)}';
  }

  // Combine date and time into a single DateTime object
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Function to send a notification to the user
  Future<void> _sendNotification(String userId, String title, String message) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
        'read': false, // Optional: for read/unread status
      });
      print("Notification sent to user $userId: $title - $message");
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> _bookResource() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStartDate == null || _selectedStartTime == null ||
          _selectedEndDate == null || _selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both start and end date/time.')),
        );
        return;
      }

      final startDateTime = _combineDateTime(_selectedStartDate!, _selectedStartTime!);
      final endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

      if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      // Ensure booking is not in the past
      if (endDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot book resources for a time that has already passed.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Query for existing bookings of this resource that overlap with the requested time
        final QuerySnapshot existingBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('resourceId', isEqualTo: widget.resourceDocument.id)
            .where('status', isEqualTo: 'approved') // Only consider 'approved' bookings as conflicts
            .get();

        bool isBooked = false;
        for (var doc in existingBookings.docs) {
          final existingStartTime = (doc['startTime'] as Timestamp).toDate();
          final existingEndTime = (doc['endTime'] as Timestamp).toDate();

          // Check for overlap: (StartA < EndB) && (EndA > StartB)
          if (startDateTime.isBefore(existingEndTime) && endDateTime.isAfter(existingStartTime)) {
            isBooked = true;
            break; // Found an overlap, no need to check further
          }
        }

        if (isBooked) {
          if (mounted) { // Check if widget is still mounted before showing dialog
            showDialog(context: context, builder: (context) {
              return AlertDialog(
                title: const Text('Booking Conflict'),
                content: const Text('Resource is already booked for the selected time slot. Please choose another time.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            });
          }
          return; // Stop the booking process
        }

        // Fetch user's full name from 'users' collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String userName = 'N/A';
        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          userName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
          if (userName.isEmpty) userName = 'N/A'; // Fallback if name fields are empty
        }

        // Add new booking to 'bookings' collection
        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user.uid,
          'userName': userName,
          'userEmail': user.email,
          'resourceId': widget.resourceDocument.id,
          'resourceName': widget.resourceDocument['name'],
          'resourceLocation': widget.resourceDocument['location'],
          'startTime': Timestamp.fromDate(startDateTime),
          'endTime': Timestamp.fromDate(endDateTime),
          'purpose': _purposeController.text.trim(),
          'bookingDate': Timestamp.now(),
          'status': 'approved', // Status set to approved immediately for this flow
        });

        // Update resource status to 'booked' in the 'resources' collection
        // This marks the resource as "booked" in its own document, not just its availability via bookings.
        // You might consider adding fields like 'lastBookedBy', 'lastBookingEndTime' if needed.
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.resourceDocument.id)
            .update({'status': 'booked'}); // Assuming a 'status' field in your resource document

        // Send a notification to the user about the successful booking
        await _sendNotification(
          user.uid,
          'Booking Confirmed!',
          'Your booking for ${widget.resourceDocument['name']} at ${widget.resourceDocument['location']} '
              'from ${_startTimeController.text} to ${_endTimeController.text} has been confirmed.',
        );

        if (mounted) { // Check if widget is still mounted before showing dialog and navigating
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Booking Successful'),
                content: const Text('Your resource has been booked successfully and a notification has been sent!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );

          // After successful booking and notification, navigate back to the Resources screen or Home
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
        }
      } catch (e) {
        print("Error booking resource: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to book resource: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? photoUrl = widget.resourceDocument['image'];
    String name = widget.resourceDocument['name'];
    String location = widget.resourceDocument['location'];

    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          name, // Use the resource name as the title
          style: const TextStyle(
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/logo.png", // Ensure this path is correct
                    height: 50,
                  ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Resources'),
              leading: const Icon(Icons.grid_view),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
              },
            ),
            ListTile(
              title: const Text('Bookings'),
              leading: const Icon(Icons.book_online),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BookingScreen()));
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Image.asset(
                      photoUrl,
                      height: 200, // Adjusted height for more content space
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Location: $location',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Booking Details:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Start Time Text Field
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Date & Time',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      await _selectDate(context, true);
                      if (_selectedStartDate != null) {
                        await _selectTime(context, true);
                      }
                    },
                  ),
                ),
                readOnly: true, // Make it read-only, user picks from dialog
                validator: (value) {
                  if (_selectedStartDate == null || _selectedStartTime == null) {
                    return 'Please select a start date and time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // End Time Text Field
              TextFormField(
                controller: _endTimeController,
                decoration: InputDecoration(
                  labelText: 'End Date & Time',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      await _selectDate(context, false);
                      if (_selectedEndDate != null) {
                        await _selectTime(context, false);
                      }
                    },
                  ),
                ),
                readOnly: true, // Make it read-only, user picks from dialog
                validator: (value) {
                  if (_selectedEndDate == null || _selectedEndTime == null) {
                    return 'Please select an end date and time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Purpose Text Field
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Booking',
                  hintText: 'e.g., Meeting, Class, Event',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 3, // Allow multiple lines for purpose
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the purpose of the booking';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookResource, // Disable button if loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 20, 148, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Book This Resource',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}