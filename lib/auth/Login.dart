import 'package:flutter/material.dart';
import 'package:resource_booking_app/admin/AdminHome.dart';
import 'package:resource_booking_app/auth/Api.dart'; // Assuming this handles http requests
import 'package:resource_booking_app/auth/ForgetPassword.dart';
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/components/TextField.dart';
import 'dart:convert';
import 'package:resource_booking_app/users/Home.dart'; // Assuming this is the default user home
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> loginUser() async {
    // 1. Validate input fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    setState(() {
      _errorMessage = null; // Clear any previous error messages
    });

    // 2. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // 3. Prepare data for the API request
      var data = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      // 4. Make the API call using your CallApi class
      var res = await CallApi().postData(data, 'login');
      var body = json.decode(res.body);

      // 5. Dismiss the loading indicator
      Navigator.pop(context);

      // 6. Handle API response
      if (res.statusCode == 200 && body['success'] == true) {
        // Assuming your Laravel API returns a 'token' and 'user' object upon successful login
        final String token = body['token'];
        final Map<String, dynamic> user = body['user']; // Get user data

        // Store the token and user data using shared_preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('user_id', user['id']);

        // Handle potentially null values safely
        // String firstName = user['first_name'] ?? '';
        // String lastName = user['last_name'] ?? '';
        // String fullName = '$firstName $lastName'.trim();

        await prefs.setString('first_name', user['first_name']);
        await prefs.setString('last_name', user['last_name']);
        await prefs.setString('user_email', user['email'] ?? '');
        await prefs.setInt('user_role_id', user['role_id'] ?? 0);

        // Navigate based on user role
        if (user['role_id'] == 1) {
          // Assuming 1 is the role_id for Admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Adminhome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );
        }
      } else {
        // Handle login errors from Laravel API based on response structure
        String displayMessage = "Login failed. Please try again.";

        if (body.containsKey('errors')) {
          Map<String, dynamic> errors = body['errors'];
          List<String> errorMessages = [];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
          displayMessage = errorMessages.join('\n');
        } else if (body.containsKey('message')) {
          displayMessage = body['message'];
        }

        setState(() {
          _errorMessage = displayMessage;
        });
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      // Catch any network or parsing errors
      Navigator.pop(
        context,
      ); // Pop the loading indicator in case of an exception
      setState(() {
        _errorMessage =
            "Could not connect to the server. Please check your internet connection or try again later.";
      });
      _showErrorDialog(_errorMessage!);
      print("Login Error: $e"); // Log the error for debugging
    }
  }

  // --- Helper for showing error dialogs ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Login Failed"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Use LayoutBuilder to get the available height
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Constrain the content to at least the height of the screen
            // This ensures the Column's mainAxisAlignment.center works even if content is small
            // but also allows scrolling if the content overflows.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    constraints.maxHeight, // Minimum height is screen height
              ),
              child: IntrinsicHeight(
                // Make column take only as much height as its children need, but not less than minHeight
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center, // Vertically center the content
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center, // Horizontally center children within the column
                    children: [
                      // Using Spacer to push content to the center if there's extra space,
                      // but they won't interfere if content overflows and scrolling is needed.
                      // const Spacer(), // Optional: adds flexible space above
                      const SizedBox(
                        height: 50,
                      ), // Initial spacing or logo top margin
                      Image.asset("assets/images/logo.png", height: 100),
                      const SizedBox(height: 20),
                      const Text(
                        "Resource Booking App",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 17, 105, 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 17, 105, 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      MyTextField(
                        controller: _emailController,
                        hintText: "Email",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required to login.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      MyTextField(
                        controller: _passwordController,
                        hintText: "Password",
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required to login.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Forgetpassword(),
                                  ),
                                );
                              },
                              child: Text(
                                "Forget password?",
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      MyButton(onTap: loginUser, text: "Login"),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap:
                            widget.showRegisterScreen, // Use showRegisterScreen
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Register now",
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // const Spacer(), // Optional: adds flexible space below
                      // This ensures that if the content is smaller than the screen,
                      // the remaining space is filled, allowing the Column to center itself.
                      // If the content is larger, this has no effect, and scrolling occurs.
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
