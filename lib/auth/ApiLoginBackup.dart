import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart'; // Assuming this handles http requests
import 'package:resource_booking_app/auth/ForgetPassword.dart';
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/components/TextField.dart';
import 'dart:convert';
import 'package:resource_booking_app/users/Home.dart';
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
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // 3. Prepare data for the API request
      var data = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      // 4. Make the API call using your CallApi class
      // Ensure your CallApi().postData handles headers like 'Content-Type': 'application/json'
      var res = await CallApi().postData(data, 'login');
      var body = json.decode(res.body);

      // 5. Dismiss the loading indicator
      Navigator.pop(context);

      // 6. Handle API response
      if (res.statusCode == 200 && body['success'] == true) {
        // Assuming your Laravel API returns a 'token' upon successful login
        final String token = body['token'];

        // Store the token using shared_preferences for future authenticated requests
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', token);

        // Navigate to the home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        // Handle login errors from Laravel API based on response structure
        String displayMessage = "Login failed. Please try again.";

        if (body.containsKey('errors')) {
          // Laravel validation errors (e.g., if you use validation rules)
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
          // General error message from Laravel (e.g., 'Invalid credentials')
          displayMessage = body['message'];
        }

        setState(() {
          _errorMessage = displayMessage;
        });
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      // Catch any network or parsing errors
      Navigator.pop(context); // Pop the loading indicator in case of an exception
      setState(() {
        _errorMessage = "Could not connect to the server. Please check your internet connection or try again later.";
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
            )
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              // Replaced TextField with MyTextField
              MyTextField(
                controller: _emailController,
                hintText: "Email",
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
              ),
              const SizedBox(height: 10),
              // Replaced TextField with MyTextField
              MyTextField(
                controller: _passwordController,
                hintText: "Password",
                obscureText: true,
                prefixIcon: const Icon(Icons.lock),
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
                onTap: widget.showRegisterScreen, // Use showRegisterScreen
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
              )
            ],
          ),
        ),
      ),
    );
  }
}