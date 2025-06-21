// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart'; // Make sure this import is correct

class ResourceDetails extends StatefulWidget {
  final DocumentSnapshot resourceDocument;

  const ResourceDetails({super.key, required this.resourceDocument});

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

  void logout() {
    FirebaseAuth.instance.signOut();
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
          _startTimeController.text = pickedTime.format(context); // Format and display
        });
      } else {
        setState(() {
          _selectedEndTime = pickedTime;
          _endTimeController.text = pickedTime.format(context); // Format and display
        });
      }
    }
  }

  // Combine date and time into a single DateTime object
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

      setState(() {
        _isLoading = true;
      });

      try {
        // --- START OF NEW CODE FOR BOOKING CHECK ---
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

          // Check for overlap:
          
          if (startDateTime.isBefore(existingEndTime) && endDateTime.isAfter(existingStartTime)) {
            isBooked = true;
            break; // Found an overlap, no need to check further
          }
        }

        if (isBooked) {
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
          
          return; // Stop the booking process
        }
        // --- END OF NEW CODE FOR BOOKING CHECK ---

        // Fetch user's full name from 'users' collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String userName = 'N/A';
        if (userDoc.exists) {
          userName = '${userDoc['first_name'] ?? ''} ${userDoc['last_name'] ?? ''}'.trim();
          if (userName.isEmpty) userName = 'N/A'; // Fallback if name fields are empty
        }

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
          'bookingDate': Timestamp.now(), // When the booking was made
          'status': 'approved', // You might want to add a status (e.g., pending, approved, rejected)
        });

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Booking Successful'),
              content: const Text('Your resource has been booked successfully!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
       
        Navigator.pop(context); // Go back after successful booking
      } catch (e) {
        print("Error booking resource: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book resource: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
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
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logo.png",
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
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Resources'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ResourcesScreen()));
              },
            ),
            ListTile(
              title: const Text('Booking'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'), // Corrected typo
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                logout();
                Navigator.pop(context);
              },
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
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
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
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
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
                    backgroundColor: Color.fromARGB(255, 20, 148, 24),
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