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
  bool _rememberMe = false; // State for the 'Remember me' checkbox

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
        // You might send _rememberMe status to your API if your backend supports it
        // "remember_me": _rememberMe,
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
      backgroundColor: Colors.grey[200], // Light grey background
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // Minimum height is screen height
              ),
              child: IntrinsicHeight(
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch content horizontally
                    children: [
                      // Welcome Card (Green)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Card(
                          margin: EdgeInsets.zero, // No extra margin as padding is used
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          color: const Color.fromARGB(255, 27, 218, 33),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "Welcome to Mzuzu University Resource Booking App \n Your Gateway to Effortless Booking!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Spacing between welcome card and main login card

                      // Main Login Card (White)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(25.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Make column take minimum height
                              children: [
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
                                  padding: const EdgeInsets.symmetric(horizontal: 0.0), // Adjust padding as needed
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out remember me and forget password
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                _rememberMe = newValue!;
                                              });
                                            },
                                            activeColor: Color.fromARGB(255, 17, 105, 20), // Green checkbox
                                          ),
                                          const Text(
                                            "Remember me",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54, // Or desired color
                                            ),
                                          ),
                                        ],
                                      ),
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
                                const SizedBox(height: 20), // Increased spacing for the button
                                MyButton(onTap: loginUser, text: "Login"),
                                const SizedBox(height: 20), // Increased spacing for the register link
                                GestureDetector(
                                  onTap: widget.showRegisterScreen,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Flexible space to push content to center if screen is tall enough
                      if (constraints.maxHeight > 0)
                        const Spacer(),
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