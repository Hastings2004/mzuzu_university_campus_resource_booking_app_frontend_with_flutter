import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/models/user_model.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';


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
  Size get preferredSize => Size.fromHeight(
        bottomWidget == null ? 60 : 60 + bottomWidget!.preferredSize.height,
      );
}

class _MyAppBarState extends State<MyAppBar> {
  String _userFirstName = '';
  String _userLastName = '';

  UserModel? _userProfile; // Store the fetched user profile
  bool _isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Call the dedicated profile endpoint
      final res = await CallApi().getData('profile');
      final body = json.decode(res.body);
      print("API Response Body for user profile: $body"); // Debugging line

      if (res.statusCode == 200 && body['success'] == true) {
        if (body.containsKey('user') && body['user'] is Map<String, dynamic>) {
          setState(() {
            _userProfile = UserModel.fromJson(body['user']);
            // Update _userFirstName and _userLastName here
            _userFirstName = _userProfile?.firstName ?? '';
            _userLastName = _userProfile?.lastName ?? '';
          });
        } else {
          String errorMessage =
              'User data not found or invalid in response from /profile.';
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
          }
          print("Error: $errorMessage. Full body: $body");
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---
  // Function to generate user initials from first name and surname
  // ---
  String _getUserInitials() {
    String initials = '';

    // Use the state variables which are updated after _userProfile is set
    if (_userFirstName.isNotEmpty) {
      initials += _userFirstName.trim()[0].toUpperCase();
    }

    if (_userLastName.isNotEmpty) {
      initials += _userLastName.trim()[0].toUpperCase();
    }

    return initials.isEmpty ? 'U' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 20, 148, 24),
      centerTitle: true,
      title: widget.titleWidget,
      leading: IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      actions: <Widget>[
        // ---
        // Search Icon
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
        // Notification Icon
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
        // Profile Avatar with User Initials (First name + Surname)
        // ---
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20), // Add ripple effect
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18, // Slightly larger for better visibility
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ) // Show loading indicator
                  : Text(
                      _getUserInitials(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14, // Slightly larger font
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