import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/BookingDashboard.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Make sure to import intl for DateFormat

// Assuming all other necessary classes (Bottombar, MyAppBar, etc.)
// and functions (isSameDay) are already implemented and imported.

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

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
    _fetchBookings();
  }

  // --- Core Logic and Data Fetching (Keep this as per your original intent) ---

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Simulate a network request
      await Future.delayed(const Duration(seconds: 2));
      // Example of an error (uncomment to test error state)
      // throw Exception('Failed to load bookings. Please check your internet connection.');

      // After successful fetch, you might process your bookings here
      // For now, no changes to _bookingsMap for this example.
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // This function should return a list of events for a given day.
  // It's crucial for `TableCalendar`'s `eventLoader`.
  // Ensure your actual booking data structure is handled here.
  List<dynamic> _getBookingsForDate(DateTime day) {
    // Example: Return dummy data for specific dates
    if (day.day == 10 && day.month == 7) {
      return ['Meeting with John (9 AM - 10 AM)', 'Project Review (2 PM - 3 PM)'];
    }
    if (day.day == 15 && day.month == 7) {
      return ['Lab Session (10 AM - 12 PM)'];
    }
    if (day.day == 20 && day.month == 7) {
      return ['Classroom A Booking (1 PM - 4 PM)'];
    }
    return [];
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
        color: isSelected
            ? primaryColor
            : isToday
                ? primaryColor.withOpacity(0.2)
                : isBooked
                    ? Colors.lightGreen.shade200.withOpacity(0.5) // Softer green for booked days
                    : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: isSelected
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
              color: isSelected
                  ? Colors.white
                  : isSameDay(day, _focusedDate)
                      ? Colors.black87
                      : Colors.grey, // Dim out days not in current month
              fontWeight: isBooked || isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isBooked && !isSelected && !isToday) // Show a small dot for booked days not selected/today
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 5,
              width: 5,
              decoration: BoxDecoration(
                color: primaryColor, // Dot color matches primary
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
          _buildFilterChip('All', true), // Example: 'All' is selected
          _buildFilterChip('Rooms', false),
          _buildFilterChip('Equipment', false),
          _buildFilterChip('Vehicles', false), // Added another example filter
          _buildFilterChip('Facilities', false), // Another example
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
        color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: isSelected ? BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1) : BorderSide.none,
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
              physics: const NeverScrollableScrollPhysics(), // To prevent inner scrolling issues
              itemCount: selectedBookings.length,
              itemBuilder: (context, index) {
                final booking = selectedBookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Theme.of(context).colorScheme.secondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.toString(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        // You can add more details or actions here, e.g., view button
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
                          onPressed: () {
                            // Handle viewing specific booking details
                            print('View details for: $booking');
                          },
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

  Widget _legendItem({required Color color, required String text, bool isCircle = false}) {
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
    // This function will navigate the user back to the first route in the navigation stack,
    // which is typically your login or splash screen.
    // Ensure this aligns with your app's navigation flow.
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 16),
              Text('Loading bookings...', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
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
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/images/logo.png", // Verify this path in your pubspec.yaml
                    height: 60,
                    color: Colors.white, // Optional: tint logo white
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mzuzu University',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Campus Resource Booking',
                    style: TextStyle(color: onPrimaryColor.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: Icon(Icons.home, color: Theme.of(context).colorScheme.secondary),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person, color: Colors.blueGrey),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Resources'),
              leading: const Icon(Icons.grid_view, color: Colors.green),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResourcesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Bookings'),
              leading: const Icon(Icons.book_online, color: Colors.orange),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Booking Dashboard'),
              leading: const Icon(Icons.dashboard, color: Colors.purple),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingDashboard(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Booking Calendar'),
              leading: const Icon(Icons.calendar_month, color: Colors.teal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingCalendar(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications, color: Colors.amber),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Report Issue'),
              leading: const Icon(Icons.report, color: Colors.deepOrange),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IssueManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings, color: Colors.grey),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('History'),
              leading: const Icon(Icons.history, color: Colors.brown),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              onTap: logout,
            ),
          ],
        ),
      ),
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
                                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                                calendarFormat: CalendarFormat.month,
                                eventLoader: _getBookingsForDate,
                                startingDayOfWeek: StartingDayOfWeek.monday,
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  weekendTextStyle: const TextStyle(color: Colors.red),
                                  todayDecoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: const BoxDecoration(
                                    color: Colors.transparent, // Markers are built into _buildCalendarTile
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
                                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
                                  titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  defaultBuilder: (context, day, focusedDay) => _buildCalendarTile(day, focusedDay),
                                  selectedBuilder: (context, day, focusedDay) => _buildCalendarTile(day, focusedDay),
                                  todayBuilder: (context, day, focusedDay) => _buildCalendarTile(day, focusedDay),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24), // Spacing between calendar and details

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
                                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                                calendarFormat: CalendarFormat.month,
                                eventLoader: _getBookingsForDate,
                                startingDayOfWeek: StartingDayOfWeek.monday,
                                calendarStyle: CalendarStyle(
                                  outsideDaysVisible: false,
                                  weekendTextStyle: const TextStyle(color: Colors.red),
                                  todayDecoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: const BoxDecoration(
                                    color: Colors.transparent, // Markers are built into _buildCalendarTile
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
                                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
                                  titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  defaultBuilder: (context, day, focusedDay) => _buildCalendarTile(day, focusedDay),
                                  selectedBuilder: (context, day, focusedDay) => _buildCalendarTile(day, focusedDay),
                                  todayBuilder: (context, day, focusedDay) => _buildCalendarTile(day, focusedDay),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24), // Spacing between calendar and sidebar

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