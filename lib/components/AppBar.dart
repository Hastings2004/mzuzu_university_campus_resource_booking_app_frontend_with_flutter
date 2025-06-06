import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget titleWidget;
  final PreferredSizeWidget? bottomWidget;
  final VoidCallback? onSearchPressed;
  final bool isSearching;
 
  const MyAppBar({
    super.key,
    required this.titleWidget,
    this.bottomWidget,
    this.onSearchPressed,
    this.isSearching = false,
    
  });

  @override
  State<MyAppBar> createState() => _MyAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(bottomWidget == null ? 60 : 60 + bottomWidget!.preferredSize.height);
}

class _MyAppBarState extends State<MyAppBar> {
  String _userFirstName = '';
  String _userLastName = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ---
  // Function to load user data from SharedPreferences
  // ---
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _userFirstName = prefs.getString('first_name') ?? '';
      _userLastName = prefs.getString('last_name') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // ---
    // Generate initials based on the loaded first and last names
    // ---
    String initials = '';
    if (_userFirstName.isNotEmpty) {
      initials += _userFirstName[0].toUpperCase();
    }
    if (_userLastName.isNotEmpty) {
      initials += _userLastName[0].toUpperCase();
    }

    // Fallback if no initials can be generated (e.g., if names are empty or not loaded yet)
    if (initials.isEmpty) {
      initials = 'HC'; // 'User Buddy' or 'Unknown' default initials
    }

    return AppBar(
      backgroundColor: const Color.fromARGB(255, 20, 148, 24),
      centerTitle: true,
      title: widget.titleWidget,
      leading: IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: const Icon(
          Icons.menu,
          color: Colors.white,
        ),
      ),
      actions: <Widget>[
        // ---
        // Search Icon (remains unchanged)
        // ---
        if (widget.onSearchPressed != null)
          IconButton(
            icon: Icon(
              widget.isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: widget.onSearchPressed,
          ),
        // ---
        // Notification Icon (remains unchanged)
        // ---
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
        ),
        // ---
        // Modified Profile Icon to show Initials
        // ---
        Padding(
          padding: const EdgeInsets.only(right: 8.0), // Add some padding on the right
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: CircleAvatar(
              backgroundColor: Colors.white, // White circle background
              radius: 16, // Adjust size as needed
              child: Text(
                initials,
                style: TextStyle(
                  color: Theme.of(context).primaryColor, // Use app's primary color for text
                  fontSize: 12, // Adjust font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: widget.bottomWidget,
    );
  }
}