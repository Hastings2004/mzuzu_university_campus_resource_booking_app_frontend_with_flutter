import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/models/resource_model.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResourceDetails extends StatefulWidget {
  final ResourceModel resource;

  const ResourceDetails({Key? key, required this.resource}) : super(key: key);

  @override
  _ResourceDetailsState createState() => _ResourceDetailsState();
}

class _ResourceDetailsState extends State<ResourceDetails> {
  // User data - cached to avoid repeated SharedPreferences calls
  UserData? _userData;

  String? _selectedBookingType;

  final List<String> _bookingType = [
    'class',
    'staff_meeting',
    'university_activity',
    'student_meeting',
    'Other',
  ];

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
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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

      _userData = UserData(id: userId, name: userName, email: userEmail);

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
                        () => Navigator.of(context).pop(false), // User cancels
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop(true), // User confirms
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ), // Optional: make logout button red
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
        // Navigate to your login/auth screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        ); // Assuming '/' is your initial login route
      }
    }
  }

  // Optimized date selection with validation
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate =
        isStart
            ? (_selectedStartDate ?? DateTime.now())
            : (_selectedEndDate ?? _selectedStartDate ?? DateTime.now());

    final firstDate =
        isStart ? DateTime.now() : (_selectedStartDate ?? DateTime.now());

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
          // Clear end date if it's before new start date
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(pickedDate)) {
            _selectedEndDate = null;
            _selectedEndTime = null;
            _endTimeController.clear();
          }
        } else {
          _selectedEndDate = pickedDate;
        }
      });

      // Clear conflict cache when dates change
      _conflictCache.clear();
    }
  }

  // Optimized time selection
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime =
        isStart
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
          _startTimeController.text = _formatDateTime(
            _selectedStartDate,
            _selectedStartTime,
          );
        } else {
          _selectedEndTime = pickedTime;
          _endTimeController.text = _formatDateTime(
            _selectedEndDate,
            _selectedEndTime,
          );
        }
      });

      // Check for conflicts with debouncing
      _debounceConflictCheck();
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
    final startDateTime = _combineDateTime(
      _selectedStartDate!,
      _selectedStartTime!,
    );
    final endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

    final cacheKey =
        '${widget.resource.id}_${startDateTime.toIso8601String()}_${endDateTime.toIso8601String()}';

    // Check cache first
    if (_conflictCache.containsKey(cacheKey)) {
      return;
    }

    try {
      final response = await CallApi()
          .postData({
            'resource_id': widget.resource.id,
            'start_time': startDateTime.toIso8601String(),
            'end_time': endDateTime.toIso8601String(),
          }, 'bookings/check-availability')
          .timeout(const Duration(seconds: 5));

      final body = json.decode(response.body);
      final hasConflict = response.statusCode == 409;

      _conflictCache[cacheKey] = hasConflict;
      
      if (hasConflict && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Booking Conflict'),
            content: Text(
              'Time slot is not available: ${body['message']}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Conflict check failed: $e");
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Optimized notification sending
  Future<void> _sendNotification(String title, String message) async {
    if (_userData == null) return;

    try {
      await CallApi()
          .postData({
            'user_id': _userData!.id,
            'title': title,
            'message': message,
            'type': 'booking_status',
          }, 'notifications')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Notification failed: $e");
      // Don't show error to user for notification failures
    }
  }

  // Optimized booking function with better validation and error handling
  Future<void> _bookResource() async {
    if (!_isInitialized || _userData == null || _isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_validateBookingTime()) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = _combineDateTime(
        _selectedStartDate!,
        _selectedStartTime!,
      );
      final endDateTime = _combineDateTime(
        _selectedEndDate!,
        _selectedEndTime!,
      );

      final bookingData = {
        'user_id': _userData!.id,
        'resource_id': widget.resource.id,
        'start_time': startDateTime.toIso8601String(),
        'end_time': endDateTime.toIso8601String(),
        'purpose': _purposeController.text.trim(),
        'booking_type': _selectedBookingType?.toLowerCase(), // Default to 'Other' if empty
      };

      final response = await CallApi()
          .postData(bookingData, 'bookings')
          .timeout(const Duration(seconds: 15));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201 && responseBody['success'] == true) {
        await _handleBookingSuccess();
      } else {
        _handleBookingError(responseBody['message'] ?? 'Booking failed');
      }
    } on TimeoutException {
      _showErrorSnackBar('Request timeout. Please try again.');
    } catch (e) {
      debugPrint("Booking error: $e");
      _showErrorSnackBar('Failed to book resource. Please try again.');
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

    final startDateTime = _combineDateTime(
      _selectedStartDate!,
      _selectedStartTime!,
    );
    final endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

    if (startDateTime.isAfter(endDateTime) ||
        startDateTime.isAtSameMomentAs(endDateTime)) {
      _showErrorSnackBar('End time must be after start time.');
      return false;
    }

    if (endDateTime.isBefore(DateTime.now())) {
      _showErrorSnackBar(
        'Cannot book resources for a time that has already passed.',
      );
      return false;
    }

    // Check minimum booking duration (e.g., 30 minutes)
    if (endDateTime.difference(startDateTime).inMinutes < 30) {
      _showErrorSnackBar('Minimum booking duration is 30 minutes.');
      return false;
    }

    return true;
  }

  Future<void> _handleBookingSuccess() async {
    // Send notification in background
    unawaited(
      _sendNotification(
        'Booking Confirmed!',
        'Your booking for ${widget.resource.name} at ${widget.resource.location} '
            'from ${_startTimeController.text} to ${_endTimeController.text} has been confirmed.',
      ),
    );

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Booking Successful'),
              content: const Text(
                'Your resource has been booked successfully!',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResourcesScreen(),
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _handleBookingError(String message) {
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


  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          widget.resource.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: const Bottombar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 20, 148, 24)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 50, color: Colors.white),
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
          ..._buildDrawerItems(),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    final items = [
      DrawerItem(
        'Home',
        Icons.home,
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        ),
      ),
      DrawerItem(
        'Profile',
        Icons.person,
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ),
      ),
      DrawerItem(
        'Resources',
        Icons.grid_view,
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResourcesScreen()),
        ),
      ),
      DrawerItem(
        'Bookings',
        Icons.book_online,
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BookingScreen()),
        ),
      ),
      DrawerItem(
        'Notifications',
        Icons.notifications,
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        ),
      ),
      DrawerItem(
        'Settings',
        Icons.settings,
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ),
      ),
    ];

    return [
      ...items.map(
        (item) => ListTile(
          title: Text(item.title),
          leading: Icon(item.icon),
          onTap: item.onTap,
        ),
      ),
      const Divider(),
      ListTile(
        title: const Text('Logout'),
        leading: const Icon(Icons.logout, color: Colors.red),
        onTap: logout,
      ),
    ];
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildResourceInfo(),
              const SizedBox(height: 30),
              _buildBookingForm(),
              const SizedBox(height: 30),
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          widget.resource.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Location: ${widget.resource.description}',
          style: const TextStyle(fontSize: 20, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBookingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Booking Details:',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
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
          validator:
              (_) =>
                  _selectedStartDate == null || _selectedStartTime == null
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
          validator:
              (_) =>
                  _selectedEndDate == null || _selectedEndTime == null
                      ? 'Please select an end date and time'
                      : null,
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container( // Consider if this Container is truly necessary here, often it's not
            child: DropdownButtonFormField<String>(
              value: _selectedBookingType, // Set the current value
              decoration: const InputDecoration(
                labelText: 'Booking Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _bookingType.map((String type) { // Iterate over the list of types
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.replaceAll('_', ' ').toTitleCase()), // Optional: format for display
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBookingType = newValue; // Update the selected value
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a booking type';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
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

  Widget _buildBookButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookResource,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 20, 148, 24),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Book This Resource',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
      ),
    );
  }
}

// Helper classes
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

// String extension for toTitleCase
extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
