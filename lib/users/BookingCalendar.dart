import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/BookingDashboard.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/models/booking.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookingCalendar extends StatefulWidget {
  const BookingCalendar({Key? key}) : super(key: key);

  @override
  _BookingCalendarState createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _error;
  bool _isLoading = false;
  List<Booking> _allBookings = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
    _loadUserIdAndFetchBookings();
  }

  // --- Core Logic and Data Fetching ---

  Future<void> _loadUserIdAndFetchBookings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
    });

    if (_userId != null) {
      _fetchBookings();
    } else {
      setState(() {
        _error = 'User not authenticated. Please login again.';
      });
    }
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await CallApi().getData('monthly-bookings?per_page=1000');
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        List<dynamic> bookingJson = body['bookings'];
        final bookings =
            bookingJson.map((json) => Booking.fromJson(json)).toList();

        setState(() {
          _allBookings = bookings;
        });
      } else {
        String errorMessage = body['message'] ?? 'Failed to load bookings.';
        setState(() {
          _error = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection and try again.';
      });
      print('Failed to fetch bookings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Booking> _getBookingsForDate(DateTime day) {
    return _allBookings.where((booking) {
      final bookingDate = DateTime(
        booking.startTime.year,
        booking.startTime.month,
        booking.startTime.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);
      return bookingDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  List<String> _getEventMarkersForDate(DateTime day) {
    return _getBookingsForDate(
      day,
    ).map((booking) => booking.resourceName).toList();
  }

  String _formatBookingTime(Booking booking) {
    final startTime = DateFormat('HH:mm').format(booking.startTime);
    final endTime = DateFormat('HH:mm').format(booking.endTime);
    return '${booking.resourceName} ($startTime - $endTime)';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'completed':
        return Colors.blue.shade600;
      case 'in_use':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // --- UI Building Methods (Styled and Cleaned Up) ---

  Widget _buildCalendarTile(DateTime day, DateTime focusedDay) {
    final bool isBooked = _getBookingsForDate(day).isNotEmpty;
    final bool isToday = isSameDay(day, DateTime.now());
    final bool isSelected = isSameDay(day, _selectedDate);

    // Get the primary color from the theme
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            isSelected
                ? primaryColor
                : isToday
                ? primaryColor.withOpacity(0.2)
                : isBooked
                ? Colors.lightGreen.shade200.withOpacity(0.5)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border:
            isSelected
                ? Border.all(color: primaryColor, width: 2)
                : isToday
                ? Border.all(color: primaryColor.withOpacity(0.5), width: 1)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color:
                  isSelected
                      ? Colors.white
                      : isSameDay(day, _focusedDate)
                      ? Colors.black87
                      : Colors.grey,
              fontWeight:
                  isBooked || isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          if (isBooked && !isSelected && !isToday)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 5,
              width: 5,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8.0,
        children: [
          _buildFilterChip('All', true),
          _buildFilterChip('Rooms', false),
          _buildFilterChip('Equipment', false),
          _buildFilterChip('Vehicles', false),
          _buildFilterChip('Facilities', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Implement your filter logic here based on 'label'
        print('Filter "$label" selected: $selected');
      },
      selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color:
            isSelected
                ? Theme.of(context).colorScheme.secondary
                : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side:
          isSelected
              ? BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1,
              )
              : BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSelectedDateBookings() {
    if (_selectedDate == null) {
      return const SizedBox.shrink();
    }
    final selectedBookings = _getBookingsForDate(_selectedDate!);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings for ${DateFormat('EEEE, MMMM d, y').format(_selectedDate!)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          if (selectedBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'No bookings scheduled for this date.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedBookings.length,
              itemBuilder: (context, index) {
                final booking = selectedBookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.resourceName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (booking.purpose.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  booking.purpose,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking.status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                booking.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                // Handle viewing specific booking details
                                print(
                                  'View details for booking ID: ${booking.id}',
                                );
                              },
                            ),
                          ],
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar Legend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          _legendItem(
            color: Theme.of(context).colorScheme.primary,
            text: 'Selected Day',
            isCircle: true,
          ),
          _legendItem(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            text: 'Today',
            isCircle: true,
          ),
          _legendItem(
            color: Colors.lightGreen.shade200.withOpacity(0.5),
            text: 'Days with Bookings',
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String text,
    bool isCircle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void logout() {
    print('User logged out');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Get primary color from theme for consistent styling
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    if (_isLoading) {
      return Scaffold(
        appBar: MyAppBar(
          titleWidget: Text(
            "Booking Calendar",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onPrimaryColor,
            ),
          ),
        ),
        drawer: Mydrawer(),
        bottomNavigationBar: const Bottombar(currentIndex: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading bookings...',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: MyAppBar(
          titleWidget: Text(
            "Booking Calendar",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onPrimaryColor,
            ),
          ),
        ),
        drawer: Mydrawer(),
        bottomNavigationBar: Bottombar(currentIndex: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade700),
              const SizedBox(height: 24),
              Text(
                'Oops! An error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: const Bottombar(currentIndex: 0),
      appBar: MyAppBar(
        titleWidget: Text(
          "Booking Calendar",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onPrimaryColor,
          ),
        ),
      ),
      drawer:  Mydrawer(),
      backgroundColor: Colors.grey[50], // Light background for the body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking Calendar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchBookings,
                    icon: Icon(Icons.refresh, color: primaryColor),
                    tooltip: 'Refresh calendar',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filters
              _buildFilters(),
              const SizedBox(height: 24),

              // Calendar Content (Responsive Layout)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 800) {
                      // Mobile layout - stack vertically
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            // Calendar widget container
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDate,
                                selectedDayPredicate:
                                    (day) => isSameDay(_selectedDate, day),
                                calendarFormat: CalendarFormat.month,
                                eventLoader: _getEventMarkersForDate,
                                startingDayOfWeek: StartingDayOfWeek.monday,
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  weekendTextStyle: const TextStyle(
                                    color: Colors.red,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: Colors.black87,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: Colors.black87,
                                  ),
                                  titleTextStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDate = selectedDay;
                                    _focusedDate = focusedDay;
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDate = focusedDay;
                                  });
                                },
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder:
                                      (context, day, focusedDay) =>
                                          _buildCalendarTile(day, focusedDay),
                                  selectedBuilder:
                                      (context, day, focusedDay) =>
                                          _buildCalendarTile(day, focusedDay),
                                  todayBuilder:
                                      (context, day, focusedDay) =>
                                          _buildCalendarTile(day, focusedDay),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ), // Spacing between calendar and details
                            // Selected day bookings and legend
                            _buildSelectedDateBookings(),
                            const SizedBox(height: 24),
                            _buildLegend(),
                          ],
                        ),
                      );
                    } else {
                      // Desktop layout - side by side
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2, // Calendar takes more space
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDate,
                                selectedDayPredicate:
                                    (day) => isSameDay(_selectedDate, day),
                                calendarFormat: CalendarFormat.month,
                                eventLoader: _getEventMarkersForDate,
                                startingDayOfWeek: StartingDayOfWeek.monday,
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  weekendTextStyle: const TextStyle(
                                    color: Colors.red,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: const BoxDecoration(
                                    color:
                                        Colors
                                            .transparent, // Markers are built into _buildCalendarTile
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: Colors.black87,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: Colors.black87,
                                  ),
                                  titleTextStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDate = selectedDay;
                                    _focusedDate = focusedDay;
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDate = focusedDay;
                                  });
                                },
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder:
                                      (context, day, focusedDay) =>
                                          _buildCalendarTile(day, focusedDay),
                                  selectedBuilder:
                                      (context, day, focusedDay) =>
                                          _buildCalendarTile(day, focusedDay),
                                  todayBuilder:
                                      (context, day, focusedDay) =>
                                          _buildCalendarTile(day, focusedDay),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 24,
                          ), // Spacing between calendar and sidebar

                          Expanded(
                            flex: 1, // Sidebar takes less space
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildSelectedDateBookings(),
                                  const SizedBox(height: 24),
                                  _buildLegend(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
