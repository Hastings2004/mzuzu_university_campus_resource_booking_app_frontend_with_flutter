import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Settings.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Change title to be a Widget instead of just a String
  final Widget titleWidget;
  final PreferredSizeWidget? bottomWidget; // Optional bottom widget for search bar
  final VoidCallback? onSearchPressed; // Callback for search icon press
  final bool isSearching; // To change the icon (search/close)

  const MyAppBar({
    super.key,
    required this.titleWidget,
    this.bottomWidget,
    this.onSearchPressed,
    this.isSearching = false, // Default to not searching
  });

  @override
  Size get preferredSize => Size.fromHeight(bottomWidget == null ? 60 : 60 + bottomWidget!.preferredSize.height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 20, 148, 24),
      centerTitle: true,
      title: titleWidget, // Use the provided widget for the title
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
        // Search Icon
        if (onSearchPressed != null) // Only show if a callback is provided
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: onSearchPressed,
          ),
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            // Handle notification button press
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(),
                ));
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            // Handle settings button press
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ));
          },
        ),
      ],
      bottom: bottomWidget, // Use the provided widget for the bottom
    );
  }
}