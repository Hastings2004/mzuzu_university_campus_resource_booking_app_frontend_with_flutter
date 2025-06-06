import 'package:flutter/material.dart';
import 'package:resource_booking_app/admin/AdminHome.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:resource_booking_app/auth/AuthPage.dart';


class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  // A Future to hold the authentication status check
  late Future<bool> _isAuthenticatedFuture;

  @override
  void initState() {
    super.initState();
    _isAuthenticatedFuture = _checkAuthenticationStatus();
  }

  Future<bool> _checkAuthenticationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Assuming you store a token or user ID upon successful login
    // For example, 'token' or 'id'
    String? token = prefs.getString('token'); // Or prefs.getString('id');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _isAuthenticatedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While checking authentication status, show a loading indicator
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Handle error during SharedPreferences access
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Based on the authentication status
            if (snapshot.data == true) {
              // Retrieve role_id from SharedPreferences
              return FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, prefsSnapshot) {
                  if (prefsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (prefsSnapshot.hasError) {
                    return Center(child: Text('Error: ${prefsSnapshot.error}'));
                  } else {
                    final prefs = prefsSnapshot.data!;
                    int? roleId = prefs.getInt('role_id');
                    if (roleId == 1) { // Assuming 1 is the role_id for Admin
                      // Navigate to AdminHome
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Adminhome()),
                        );
                      });
                      return const SizedBox.shrink();
                    } else {
                      // Navigate to regular User Home
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Home()),
                        );
                      });
                      return const SizedBox.shrink();
                    }
                  }
                },
              );
            } else {
              // User is not authenticated, show AuthPage
              return Authpage();
            }
          }
        },
      ),
    );
  }
}