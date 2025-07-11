import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/booking.dart'; // Import the Booking model
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateBookingScreen extends StatefulWidget {
  // We now pass a Booking object instead of a ResourceModel
  final Booking booking;

  const UpdateBookingScreen({super.key, required this.booking});

  @override
  _UpdateBookingScreenState createState() => _UpdateBookingScreenState();
}

class _UpdateBookingScreenState extends State<UpdateBookingScreen> {
  // User data - cached to avoid repeated SharedPreferences calls
  UserData? _userData;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // Date/time selection
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;

  // State management
  bool _isLoading = false;
  bool _isInitialized = false;

  // Debouncer for API calls
  Timer? _debounceTimer;

  // Cache for conflict checking
  final Map<String, bool> _conflictCache = {};

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _initializeBookingData(); // Initialize form with existing booking data
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // New method to initialize form fields with existing booking data
  void _initializeBookingData() {
    final booking = widget.booking;

    _purposeController.text = booking.purpose;

    // Set initial date and time for start
    _selectedStartDate = booking.startTime;
    _selectedStartTime = TimeOfDay.fromDateTime(booking.startTime);
    _startTimeController.text = _formatDateTime(booking.startTime, TimeOfDay.fromDateTime(booking.startTime));

    // Set initial date and time for end
    _selectedEndDate = booking.endTime;
    _selectedEndTime = TimeOfDay.fromDateTime(booking.endTime);
    _endTimeController.text = _formatDateTime(booking.endTime, TimeOfDay.fromDateTime(booking.endTime));
  }

  // Optimized user data loading with caching
  Future<void> _initializeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name') ?? 'User';
      final userEmail = prefs.getString('user_email') ?? 'No Email';

      if (userId == null) {
        _handleUnauthenticated();
        return;
      }

      _userData = UserData(
        id: userId,
        name: userName,
        email: userEmail,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      _handleUnauthenticated();
    }
  }

  void _handleUnauthenticated() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Auth()),
        (route) => false,
      );
    }
  }

  // Optimized logout with better error handling
  void logout() async {
    final bool confirmLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  // Optimized date selection with validation
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_selectedStartDate ?? DateTime.now())
        : (_selectedEndDate ?? _selectedStartDate ?? DateTime.now());

    final firstDate = isStart
        ? DateTime.now()
        : (_selectedStartDate ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        if (isStart) {
          _selectedStartDate = pickedDate;
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(pickedDate)) {
            _selectedEndDate = null;
            _selectedEndTime = null;
            _endTimeController.clear();
          }
        } else {
          _selectedEndDate = pickedDate;
        }
      });
      _conflictCache.clear(); // Clear conflict cache when dates change
    }
  }

  // Optimized time selection
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = isStart
        ? (_selectedStartTime ?? TimeOfDay.now())
        : (_selectedEndTime ?? TimeOfDay.now());

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null && mounted) {
      setState(() {
        if (isStart) {
          _selectedStartTime = pickedTime;
          _startTimeController.text = _formatDateTime(_selectedStartDate, _selectedStartTime);
        } else {
          _selectedEndTime = pickedTime;
          _endTimeController.text = _formatDateTime(_selectedEndDate, _selectedEndTime);
        }
      });
      _debounceConflictCheck(); // Check for conflicts with debouncing
    }
  }

  // Debounced conflict checking
  void _debounceConflictCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_selectedStartDate != null &&
          _selectedStartTime != null &&
          _selectedEndDate != null &&
          _selectedEndTime != null) {
        _checkForConflicts();
      }
    });
  }

  // Background conflict checking
  Future<void> _checkForConflicts() async {
    final startDateTime = _combineDateTime(_selectedStartDate!, _selectedStartTime!);
    final endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

    final cacheKey =
        '${widget.booking.resourceId}_${startDateTime.toIso8601String()}_${endDateTime.toIso8601String()}';

    // Check cache first
    if (_conflictCache.containsKey(cacheKey)) {
      return;
    }

    try {
      final response = await CallApi().postData({
        'resource_id': widget.booking.resourceId,
        'start_time': startDateTime.toIso8601String(),
        'end_time': endDateTime.toIso8601String(),
        'exclude_booking_id': widget.booking.id, // Exclude current booking from conflict check
      }, 'bookings/check-availability').timeout(const Duration(seconds: 5));

      final body = json.decode(response.body);
      final hasConflict = response.statusCode == 409;

      _conflictCache[cacheKey] = hasConflict;

      if (hasConflict && mounted) {
        _showWarningSnackBar('Time slot may not be available: ${body['message']}');
      }
    } catch (e) {
      debugPrint("Conflict check failed: $e");
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Optimized notification sending
  Future<void> _sendNotification(String title, String message) async {
    if (_userData == null) return;

    try {
      await CallApi().postData({
        'user_id': _userData!.id,
        'title': title,
        'message': message,
        'type': 'booking_status',
      }, 'notifications').timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Notification failed: $e");
    }
  }

  // Function to update the booking
  Future<void> _updateBooking() async {
  if (!_isInitialized || _userData == null || _isLoading) return;

  if (!_formKey.currentState!.validate()) return;

  if (!_validateBookingTime()) return;

  setState(() => _isLoading = true);

  try {
    final startDateTime = _combineDateTime(_selectedStartDate!, _selectedStartTime!);
    final endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

    final updatedBookingData = {
      'user_id': _userData!.id,
      'resource_id': widget.booking.resourceId,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime.toIso8601String(),
      'purpose': _purposeController.text.trim(),
    };

    // Add debugging
    print('=== UPDATE BOOKING DEBUG ===');
    print('Booking ID: ${widget.booking.id}');
    print('API Endpoint: bookings/${widget.booking.id}');
    print('Update Data: ${json.encode(updatedBookingData)}');

    // Use a PUT request for updates
    final response = await CallApi().putData(
      updatedBookingData,
      'bookings/${widget.booking.id}',
    ).timeout(const Duration(seconds: 15));

    // Add response debugging
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('Response Headers: ${response.headers}');

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == true) {
      print('SUCCESS: Booking updated successfully');
      await _handleUpdateSuccess();
    } else {
      print('ERROR: ${responseBody['message'] ?? 'Booking update failed'}');
      _handleUpdateError(responseBody['message'] ?? 'Booking update failed');
    }
  } on TimeoutException {
    print('TIMEOUT: Request timeout');
    _showErrorSnackBar('Request timeout. Please try again.');
  } catch (e) {
    print("UPDATE BOOKING ERROR: $e");
    _showErrorSnackBar('Failed to update booking. Please try again.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  bool _validateBookingTime() {
    if (_selectedStartDate == null ||
        _selectedStartTime == null ||
        _selectedEndDate == null ||
        _selectedEndTime == null) {
      _showErrorSnackBar('Please select both start and end date/time.');
      return false;
    }

    final startDateTime = _combineDateTime(_selectedStartDate!, _selectedStartTime!);
    final endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

    if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
      _showErrorSnackBar('End time must be after start time.');
      return false;
    }

    // When updating, the booking might be for a past time if it was already made.
    // However, if the user is trying to extend it or change to a future time,
    // ensure the new end time is not in the past relative to now.
    if (endDateTime.isBefore(DateTime.now()) && !widget.booking.endTime.isBefore(DateTime.now())) {
      _showWarningSnackBar('You are updating a booking to end in the past. Confirm this is intended.');
      // return false; // Uncomment if you want to strictly prevent past end times
    }
     if (startDateTime.isBefore(DateTime.now()) && !widget.booking.startTime.isBefore(DateTime.now())) {
      _showWarningSnackBar('You are updating a booking to start in the past. Confirm this is intended.');
      // return false; // Uncomment if you want to strictly prevent past start times
    }


    // Check minimum booking duration (e.g., 30 minutes)
    if (endDateTime.difference(startDateTime).inMinutes < 30) {
      _showErrorSnackBar('Minimum booking duration is 30 minutes.');
      return false;
    }

    return true;
  }

  Future<void> _handleUpdateSuccess() async {
    // Send notification in background
    unawaited(_sendNotification(
      'Booking Updated!',
      'Your booking for ${widget.booking.resourceName} has been successfully updated '
          'from ${_startTimeController.text} to ${_endTimeController.text}.',
    ));

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Booking Updated Successfully'),
          content: const Text('Your booking has been updated!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to the BookingScreen or refresh it
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _handleUpdateError(String message) {
    _showErrorSnackBar(message);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showWarningSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          'Update Booking for ${widget.booking.resourceName}', // Dynamic title
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: const Bottombar(),
      drawer: Mydrawer(),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResourceInfo(),
              const SizedBox(height: 30),
              _buildBookingForm(),
              const SizedBox(height: 30),
              _buildUpdateButton(), // Changed button to update
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceInfo() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            widget.booking.resourceName, // Display resource name from booking
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Reference Number:  ${widget.booking.bookingReference}', // Display resource location from booking
            style: const TextStyle(fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          Text(
            'Location: ${widget.booking.resourceLocation}', // Display resource location from booking
            style: const TextStyle(fontSize: 20, color: Colors.black87),
          ),
          if (widget.booking.resourceDescription != null && widget.booking.resourceDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Description: ${widget.booking.resourceDescription}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          if (widget.booking.resourceCapacity != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Capacity: ${widget.booking.resourceCapacity}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Modify Booking Details:', // Changed title
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 15),
          _buildDateTimeField(
            controller: _startTimeController,
            label: 'Start Date & Time',
            onTap: () async {
              await _selectDate(context, true);
              if (_selectedStartDate != null) {
                await _selectTime(context, true);
              }
            },
            validator: (_) => _selectedStartDate == null || _selectedStartTime == null
                ? 'Please select a start date and time'
                : null,
          ),
          const SizedBox(height: 15),
          _buildDateTimeField(
            controller: _endTimeController,
            label: 'End Date & Time',
            onTap: () async {
              await _selectDate(context, false);
              if (_selectedEndDate != null) {
                await _selectTime(context, false);
              }
            },
            validator: (_) => _selectedEndDate == null || _selectedEndTime == null
                ? 'Please select an end date and time'
                : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _purposeController,
            decoration: const InputDecoration(
              labelText: 'Purpose of Booking',
              hintText: 'e.g., Meeting, Class, Event',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info_outline),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the purpose of the booking';
              }
              if (value.trim().length < 10) {
                return 'Purpose must be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      validator: validator,
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateBooking, // Call update function
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 20, 148, 24),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Update Booking', // Changed button text
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }
}

// Helper classes (keep these as they are, or modify if needed)
class UserData {
  final int id;
  final String name;
  final String email;

  UserData({required this.id, required this.name, required this.email});
}

class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DrawerItem(this.title, this.icon, this.onTap);
}