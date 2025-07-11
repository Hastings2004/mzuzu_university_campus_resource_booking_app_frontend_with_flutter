import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/auth/Auth.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/resource_model.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResourceDetails extends StatefulWidget {
  final ResourceModel resource;

  const ResourceDetails({
    super.key,
    required this.resource,
    required resourceId,
  });

  @override
  _ResourceDetailsState createState() => _ResourceDetailsState();
}

class _ResourceDetailsState extends State<ResourceDetails> {
  UserData? _userData;

  String? _selectedBookingType;
  //String? _selectedPriority;
  String _bookingOption = "single_day";

  final List<String> _bookingType = [
    'class',
    'staff_meeting',
    'university_activity',
    'student_meeting',
    'church_meeting',
    'Other',
  ];

  //final List<String> _priority = ['low', 'medium', 'high', 'urgent'];

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
  PlatformFile? _supportingDocument;

  // State management
  bool _isLoading = false;
  bool _isInitialized = false;
  bool? _isResourceAvailable;

  // Debouncer for API calls
  Timer? _debounceTimer;

  // Cache for conflict checking
  final Map<String, bool> _conflictCache = {};

  
  DateTime _selectedCalendarDate = DateTime.now();
  List<Map<String, dynamic>> _resourceBookings = [];
  List<Map<String, dynamic>> _bookingsForSelectedDate = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _loadResourceBookings();
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
        // Load resource bookings after initialization
        _loadResourceBookings();
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

  void logout() async {
    final bool confirmLogout =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
      _isResourceAvailable = null;
    }
  }

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

  void _debounceConflictCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (_selectedStartDate != null &&
          _selectedStartTime != null &&
          _selectedEndDate != null &&
          _selectedEndTime != null) {
        _checkForConflicts();
      } else {
        setState(() {
          _isResourceAvailable = null;
        });
      }
    });
  }

  // Enhanced conflict checking with suggestions (similar to handleAvailabilityCheck in React)
  Future<void> _checkForConflicts() async {
    setState(() {
      _isResourceAvailable = null;
      _suggestions = []; 
    });

    DateTime fullStartTime, fullEndTime;

    if (_bookingOption == "single_day") {
      if (_selectedStartDate == null ||
          _selectedStartTime == null ||
          _selectedEndTime == null) {
        return;
      }
      fullStartTime = _combineDateTime(
        _selectedStartDate!,
        _selectedStartTime!,
      );
      fullEndTime = _combineDateTime(_selectedStartDate!, _selectedEndTime!);

      // Validate single day booking spans only one day
      if (fullStartTime.day != fullEndTime.day ||
          fullStartTime.month != fullEndTime.month ||
          fullStartTime.year != fullEndTime.year) {
        if (mounted) {
          setState(() {
            _isResourceAvailable = false;
          });
          _showErrorSnackBar(
            "For 'Single Day' booking, start and end times must be on the same day.",
          );
        }
        return;
      }
    } else {
      if (_selectedStartDate == null ||
          _selectedStartTime == null ||
          _selectedEndDate == null ||
          _selectedEndTime == null) {
        return;
      }
      fullStartTime = _combineDateTime(
        _selectedStartDate!,
        _selectedStartTime!,
      );
      fullEndTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);

      // Validate multi-day booking is actually multi-day (at least 2 days)
      final diffTime = fullEndTime.difference(fullStartTime);
      final diffDays = diffTime.inDays;
      if (diffDays < 2) {
        if (mounted) {
          setState(() {
            _isResourceAvailable = false;
          });
          _showErrorSnackBar(
            "For 'Multi Day' booking, the duration must be at least 2 full days.",
          );
        }
        return;
      }
    }

    if (fullStartTime.isAfter(fullEndTime) ||
        fullStartTime.isAtSameMomentAs(fullEndTime)) {
      if (mounted) {
        setState(() {
          _isResourceAvailable = false;
        });
        _showErrorSnackBar(
          "End time must be after start time for availability check.",
        );
      }
      return;
    }

    if (fullEndTime.isBefore(DateTime.now())) {
      if (mounted) {
        setState(() {
          _isResourceAvailable = false;
        });
        _showErrorSnackBar(
          "Cannot check availability for a time that has already passed.",
        );
      }
      return;
    }

    final cacheKey =
        '${widget.resource.id}_${fullStartTime.toIso8601String()}_${fullEndTime.toIso8601String()}';

    if (_conflictCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _isResourceAvailable = !_conflictCache[cacheKey]!;
        });
      }
      return;
    }

    try {
      final response = await CallApi()
          .postData({
            'resource_id': widget.resource.id,
            'start_time': fullStartTime.toIso8601String(),
            'end_time': fullEndTime.toIso8601String(),
          }, 'bookings/check-availability')
          .timeout(const Duration(seconds: 5));

      final body = json.decode(response.body);
      final hasConflict = response.statusCode == 409;

      _conflictCache[cacheKey] = hasConflict;

      if (mounted) {
        setState(() {
          _isResourceAvailable = !hasConflict;
        });
      }

      if (hasConflict && mounted) {
        // Check for suggestions in the response
        if (body['suggestions'] != null) {
          setState(() {
            _suggestions = List<Map<String, dynamic>>.from(body['suggestions']);
          });
        } else {
          // Try to get suggestions from a separate endpoint
          try {
            final suggestionsResponse = await CallApi()
                .postData({
                  'resource_id': widget.resource.id,
                  'start_time': fullStartTime.toIso8601String(),
                  'end_time': fullEndTime.toIso8601String(),
                }, 'bookings/get-suggestions')
                .timeout(const Duration(seconds: 3));

            final suggestionsData = json.decode(suggestionsResponse.body);
            if (suggestionsData['suggestions'] != null) {
              setState(() {
                _suggestions = List<Map<String, dynamic>>.from(
                  suggestionsData['suggestions'],
                );
              });
            }
          } catch (suggestionsError) {
            debugPrint('No suggestions available: $suggestionsError');
          }
        }

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Booking Conflict'),
                content: Text(
                  'Time slot is not available: ${body['message'] ?? 'Unknown conflict'}\n\n'
                  '${_suggestions.isNotEmpty ? 'Alternative time slots are available below.' : ''}',
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
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isResourceAvailable = false;
        });
        _showErrorSnackBar('Availability check timed out. Please try again.');
      }
    } catch (e) {
      debugPrint("Conflict check failed: $e");
      if (mounted) {
        setState(() {
          _isResourceAvailable = false;
        });
        _showErrorSnackBar('Failed to check availability. Please try again.');
      }
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _sendNotification(String title, String message) async {
    if (_userData == null) return;

    try {
      final response = await CallApi()
          .postData({
            'user_id': _userData!.id,
            'title': title,
            'message': message,
            'type': 'booking_status',
          }, 'notifications')
          .timeout(const Duration(seconds: 5));

      final body = json.decode(response.body);
      if (response.statusCode == 201) {
        debugPrint("Notification sent successfully: ${body['message']}");
      } else {
        debugPrint("Failed to send notification: ${body['message']}");
      }
    } on TimeoutException {
      debugPrint("Notification send timed out.");
    } catch (e) {
      debugPrint("Notification failed: $e");
    }
  }

  Future<void> _bookResource() async {
    if (!_isInitialized || _userData == null || _isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if ((_selectedBookingType == 'student_meeting' ||
            _selectedBookingType == 'university_activity' ||
            _selectedBookingType == 'church_meeting' ||
            _selectedBookingType == 'Other') &&
        _supportingDocument == null) {
      _showErrorSnackBar(
        'A supporting document is required for this booking type.',
      );
      return;
    }

    if (!_validateBookingTime()) return;

    if (_isResourceAvailable == false) {
      _showErrorSnackBar(
        'The selected time slot is not available. Please choose another.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime startDateTime, endDateTime;
      if (_bookingOption == "single_day") {
        startDateTime = _combineDateTime(
          _selectedStartDate!,
          _selectedStartTime!,
        );
        endDateTime = _combineDateTime(_selectedStartDate!, _selectedEndTime!);
      } else {
        startDateTime = _combineDateTime(
          _selectedStartDate!,
          _selectedStartTime!,
        );
        endDateTime = _combineDateTime(_selectedEndDate!, _selectedEndTime!);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://127.0.0.1:8000/api/bookings"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['user_id'] = _userData!.id.toString();
      request.fields['resource_id'] = widget.resource.id.toString();
      request.fields['start_time'] = startDateTime.toIso8601String();
      request.fields['end_time'] = endDateTime.toIso8601String();
      request.fields['purpose'] = _purposeController.text.trim();
      if (_selectedBookingType != null) {
        request.fields['booking_type'] = _selectedBookingType!.toLowerCase();
      }
      // if (_selectedPriority != null) {
      //   request.fields['priority'] = _selectedPriority!.toLowerCase();
      // }

      if (_supportingDocument != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'supporting_document',
              _supportingDocument!.bytes!,
              filename: _supportingDocument!.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'supporting_document',
              _supportingDocument!.path!,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final decodedBody = json.decode(responseBody);

      if (streamedResponse.statusCode == 201 &&
          decodedBody['success'] == true) {
        await _handleBookingSuccess();
      } else {
        _handleBookingError(
          decodedBody['message'] ?? 'Booking failed. Unknown error.',
        );
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
    if (_bookingOption == "single_day") {
      if (_selectedStartDate == null ||
          _selectedStartTime == null ||
          _selectedEndTime == null) {
        _showErrorSnackBar('Please select date and both start and end time.');
        return false;
      }
      final startDateTime = _combineDateTime(
        _selectedStartDate!,
        _selectedStartTime!,
      );
      final endDateTime = _combineDateTime(
        _selectedStartDate!,
        _selectedEndTime!,
      );
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
      if (endDateTime.difference(startDateTime).inMinutes < 30) {
        _showErrorSnackBar('Minimum booking duration is 30 minutes.');
        return false;
      }
    } else {
      if (_selectedStartDate == null ||
          _selectedEndDate == null ||
          _selectedStartTime == null ||
          _selectedEndTime == null) {
        _showErrorSnackBar('Please select start/end date and time.');
        return false;
      }
      final startDateTime = _combineDateTime(
        _selectedStartDate!,
        _selectedStartTime!,
      );
      final endDateTime = _combineDateTime(
        _selectedEndDate!,
        _selectedEndTime!,
      );
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
      if (endDateTime.difference(startDateTime).inMinutes < 30) {
        _showErrorSnackBar('Minimum booking duration is 30 minutes.');
        return false;
      }
    }
    return true;
  }

  Future<void> _handleBookingSuccess() async {
    // Send notification in background
    unawaited(
      _sendNotification(
        'BOOKING CONFIRMED',
        'Your booking for ${widget.resource.name} at ${widget.resource.description} '
            'from ${_startTimeController.text} to ${_endTimeController.text} has been confirmed.',
      ),
    );

    // Clear suggestions and reload bookings
    setState(() {
      _suggestions = [];
    });
    await _loadResourceBookings();

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

  Future<void> _pickSupportingDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _supportingDocument = result.files.first;
      });
    }
  }

  // NEW: Load resource bookings
  Future<void> _loadResourceBookings() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final response = await CallApi().getData(
        'resources/${widget.resource.id}/bookings',
      );
      final data = json.decode(response.body);

      if (data['bookings'] != null) {
        final List<Map<String, dynamic>> bookings =
            List<Map<String, dynamic>>.from(data['bookings']);

        // Categorize bookings by status
        final categorizedBookings =
            bookings.map((booking) {
              final startTime = DateTime.parse(booking['start_time']);
              final endTime = DateTime.parse(booking['end_time']);
              final now = DateTime.now();

              // Determine if booking is currently in use
              bool isInUse = false;
              if (booking['status'] == 'approved') {
                isInUse = now.isAfter(startTime) && now.isBefore(endTime);
              }

              return {...booking, 'is_in_use': isInUse};
            }).toList();

        setState(() {
          _resourceBookings = categorizedBookings;
          _updateBookingsForSelectedDate();
        });
      }
    } catch (e) {
      debugPrint("Failed to load resource bookings: $e");
    } finally {
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  // NEW: Update bookings for selected calendar date
  void _updateBookingsForSelectedDate() {
    final selectedDate = _selectedCalendarDate;
    final bookings =
        _resourceBookings.where((booking) {
          final start = DateTime.parse(booking['start_time']);
          final end = DateTime.parse(booking['end_time']);

          // Check if the selected date falls within the booking period
          final startDate = DateTime(start.year, start.month, start.day);
          final endDate = DateTime(end.year, end.month, end.day);
          final selectedDateOnly = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );

          return selectedDateOnly.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              selectedDateOnly.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();

    setState(() {
      _bookingsForSelectedDate = bookings;
    });
  }

  // NEW: Check if a date has bookings
  bool _isDateBooked(DateTime date) {
    return _resourceBookings.any((booking) {
      final start = DateTime.parse(booking['start_time']);
      final end = DateTime.parse(booking['end_time']);

      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      final checkDate = DateTime(date.year, date.month, date.day);

      return checkDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          checkDate.isBefore(endDate.add(const Duration(days: 1)));
    });
  }

  // NEW: Handle calendar date selection
  void _onCalendarDateSelected(DateTime date) {
    setState(() {
      _selectedCalendarDate = date;
    });
    _updateBookingsForSelectedDate();
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resource Availability Calendar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            CalendarDatePicker(
              initialDate: _selectedCalendarDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: _onCalendarDateSelected,
              selectableDayPredicate: (date) {
                // Allow selection of future dates
                return date.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildBookingsForSelectedDate(),
          ],
        ),
      ),
    );
  }

  // NEW: Build bookings for selected date
  Widget _buildBookingsForSelectedDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bookings on ${DateFormat('MMM d, yyyy').format(_selectedCalendarDate)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        if (_bookingsForSelectedDate.isEmpty)
          const Text(
            'No bookings for this date.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          ...(_bookingsForSelectedDate
              .map(
                (booking) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    booking['is_in_use'] == true
                                        ? Colors.orange
                                        : booking['status'] == 'approved'
                                        ? Colors.green
                                        : Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking['is_in_use'] == true
                                    ? 'IN USE'
                                    : booking['status'].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              booking['purpose'] ?? 'No purpose specified',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'From: ${DateFormat('MMM d, h:mm a').format(DateTime.parse(booking['start_time']))}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'To: ${DateFormat('MMM d, h:mm a').format(DateTime.parse(booking['end_time']))}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList()),
      ],
    );
  }

  // NEW: Build suggestions section
  Widget _buildSuggestionsSection() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggested Alternatives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            ...(_suggestions
                .map(
                  (suggestion) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('Resource ID: ${suggestion['resource_id']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start: ${DateFormat('MMM d, h:mm a').format(DateTime.parse(suggestion['start_time']))}',
                          ),
                          Text(
                            'End: ${DateFormat('MMM d, h:mm a').format(DateTime.parse(suggestion['end_time']))}',
                          ),
                          if (suggestion['type'] != null)
                            Text('Type: ${suggestion['type']}'),
                          if (suggestion['preference_score'] != null)
                            Text('Score: ${suggestion['preference_score']}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _bookSuggestion(suggestion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Book This'),
                      ),
                    ),
                  ),
                )
                .toList()),
          ],
        ),
      ),
    );
  }

  // NEW: Book a suggestion
  Future<void> _bookSuggestion(Map<String, dynamic> suggestion) async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final response = await CallApi().postData({
        'resource_id': suggestion['resource_id'],
        'start_time': suggestion['start_time'],
        'end_time': suggestion['end_time'],
        'purpose': _purposeController.text.trim(),
        'booking_type': _selectedBookingType?.toLowerCase() ?? 'other',
        'user_id': _userData!.id.toString(),
      }, 'bookings');

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _showSuccessSnackBar('Booking created successfully!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResourcesScreen()),
          );
        }
      } else {
        _showErrorSnackBar(data['message'] ?? 'Failed to book suggestion.');
      }
    } catch (e) {
      debugPrint("Suggestion booking error: $e");
      _showErrorSnackBar('Failed to book suggestion. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // NEW: Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
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
      drawer: Mydrawer(),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Main booking form section
          Center(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //_buildResourceInfo(),
                  _buildCalendar(),
                  const SizedBox(height: 30),
                  _buildBookingForm(),
                  const SizedBox(height: 30),
                  _buildAvailabilityStatus(),
                  const SizedBox(height: 30),
                  _buildBookButton(),
                ],
              ),
            ),
          ),

          // Suggestions section
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 30),
            _buildSuggestionsSection(),
          ],

          // Calendar and booking status section
          
          
        ],
      ),
    );
  }

  Widget _buildResourceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.location_on, color: Colors.green),
          title: Text(
            widget.resource.location,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.info, color: Colors.green),
          title: Text(
            widget.resource.description ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.people, color: Colors.green),
          title: Text(
            widget.resource.capacity.toString(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
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
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 15),
        // Booking Option (Single Day / Multi Day)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: DropdownButtonFormField<String>(
            value: _bookingOption,
            decoration: const InputDecoration(
              labelText: 'Booking Duration',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_month),
            ),
            items: const [
              DropdownMenuItem(value: "single_day", child: Text("Single Day")),
              DropdownMenuItem(value: "multi_day", child: Text("Multi Day")),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _bookingOption = newValue!;
                _selectedStartDate = null;
                _selectedEndDate = null;
                _selectedStartTime = null;
                _selectedEndTime = null;
                _startTimeController.clear();
                _endTimeController.clear();
                _isResourceAvailable =
                    null; // Reset availability on option change
                _conflictCache.clear();
              });
            },
          ),
        ),
        const SizedBox(height: 15),
        // Date and Time fields
        if (_bookingOption == "single_day") ...[
          // Single date picker
          _buildDateField(
            label: 'Date',
            selectedDate: _selectedStartDate,
            onTap: () async {
              await _selectDate(context, true);
            },
            validator:
                (_) =>
                    _selectedStartDate == null ? 'Please select a date' : null,
          ),
          const SizedBox(height: 15),
          // Start time
          _buildTimeField(
            controller: _startTimeController,
            label: 'Start Time',
            selectedTime: _selectedStartTime,
            onTap: () async {
              await _selectTime(context, true);
            },
            validator:
                (_) =>
                    _selectedStartTime == null
                        ? 'Please select a start time'
                        : null,
          ),
          const SizedBox(height: 15),
          // End time
          _buildTimeField(
            controller: _endTimeController,
            label: 'End Time',
            selectedTime: _selectedEndTime,
            onTap: () async {
              await _selectTime(context, false);
            },
            validator:
                (_) =>
                    _selectedEndTime == null
                        ? 'Please select an end time'
                        : null,
          ),
        ] else ...[
          // Multi day: start date
          _buildDateField(
            label: 'Start Date',
            selectedDate: _selectedStartDate,
            onTap: () async {
              await _selectDate(context, true);
            },
            validator:
                (_) =>
                    _selectedStartDate == null
                        ? 'Please select a start date'
                        : null,
          ),
          const SizedBox(height: 15),
          // End date
          _buildDateField(
            label: 'End Date',
            selectedDate: _selectedEndDate,
            onTap: () async {
              await _selectDate(context, false);
            },
            validator:
                (_) =>
                    _selectedEndDate == null
                        ? 'Please select an end date'
                        : null,
          ),
          const SizedBox(height: 15),
          // Start time
          _buildTimeField(
            controller: _startTimeController,
            label: 'Start Time',
            selectedTime: _selectedStartTime,
            onTap: () async {
              await _selectTime(context, true);
            },
            validator:
                (_) =>
                    _selectedStartTime == null
                        ? 'Please select a start time'
                        : null,
          ),
          const SizedBox(height: 15),
          // End time
          _buildTimeField(
            controller: _endTimeController,
            label: 'End Time',
            selectedTime: _selectedEndTime,
            onTap: () async {
              await _selectTime(context, false);
            },
            validator:
                (_) =>
                    _selectedEndTime == null
                        ? 'Please select an end time'
                        : null,
          ),
        ],
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: DropdownButtonFormField<String>(
            value: _selectedBookingType,
            decoration: const InputDecoration(
              labelText: 'Booking Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items:
                _bookingType.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toTitleCase()),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedBookingType = newValue;
                if (newValue != 'student_meeting' &&
                    newValue != 'university_activity' &&
                    newValue != 'church_meeting' &&
                    newValue != 'Other') {
                  _supportingDocument = null;
                }
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
        if (_selectedBookingType == 'student_meeting' ||
            _selectedBookingType == 'university_activity' ||
            _selectedBookingType == 'church_meeting' ||
            _selectedBookingType == 'Other') ...[
          const SizedBox(height: 15),
          _buildSupportingDocumentField(),
        ],
        if(widget.resource.specialApproval == 'yes')...[
           const SizedBox(height: 15),
          _buildSupportingDocumentField(),
        ],
        const SizedBox(height: 15),
        // Priority Dropdown
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 0.0),
        //   child: DropdownButtonFormField<String>(
        //     value: _selectedPriority,
        //     decoration: const InputDecoration(
        //       labelText: 'Priority',
        //       border: OutlineInputBorder(),
        //       prefixIcon: Icon(Icons.priority_high),
        //     ),
        //     items:
        //         _priority.map((String priority) {
        //           return DropdownMenuItem<String>(
        //             value: priority,
        //             child: Text(priority.toTitleCase()),
        //           );
        //         }).toList(),
        //     onChanged: (String? newValue) {
        //       setState(() {
        //         _selectedPriority = newValue;
        //       });
        //     },
        //     validator: (value) {
        //       if (value == null || value.isEmpty) {
        //         return 'Please select a priority level';
        //       }
        //       return null;
        //     },
        //   ),
        // ),
        // const SizedBox(height: 15),
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

  Widget _buildSupportingDocumentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supporting Document (Required)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText:
                _supportingDocument == null
                    ? 'No document selected'
                    : _supportingDocument!.name,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.attach_file),
            suffixIcon: IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _pickSupportingDocument,
            ),
          ),
          onTap: _pickSupportingDocument,
          validator: (value) {
            if (_selectedBookingType == 'student_meeting' ||
                _selectedBookingType == 'university_activity' ||
                _selectedBookingType == 'church_meeting' ||
                _selectedBookingType == 'Other') {
              if (_supportingDocument == null) {
                return 'Please upload a supporting document.';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  // New helper for date field
  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: TextEditingController(
        text:
            selectedDate == null
                ? ''
                : DateFormat('yyyy-MM-dd').format(selectedDate),
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      onTap: onTap,
      validator: validator,
    );
  }

  // New helper for time field
  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required TimeOfDay? selectedTime,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      onTap: onTap,
      validator: validator,
    );
  }

  Widget _buildAvailabilityStatus() {
    if (_isResourceAvailable == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 10),
          Text(
            'Checking Availability...',
            style: TextStyle(
              color: Colors.green[500],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    } else if (_isResourceAvailable!) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text(
            'Resource Available!',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    } else {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 10),
          Text(
            'Resource Not Available',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBookButton() {
    return Center(
      child: ElevatedButton(
        onPressed:
            _isLoading || _isResourceAvailable == false ? null : _bookResource,
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

// Helper classes (unchanged)
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

// String extension for toTitleCase (unchanged)
extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
