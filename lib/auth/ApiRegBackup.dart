import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart'; // Assuming this handles http requests
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/components/TextField.dart'; // Assuming this is your custom text field widget
import 'dart:convert';
import 'package:resource_booking_app/users/Home.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for storing the token

class Register extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const Register({super.key, required this.showLoginScreen});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final regNumberController = TextEditingController();

  String? _errorMessage; // To display error messages below the form

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    regNumberController.dispose();
    super.dispose();
  }

  // --- Helper for showing error dialogs ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Registration Failed"),
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

  void signUpUser() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Client-side validation: Check for empty fields
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        regNumberController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    // Client-side validation: Check if passwords match
    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog("Passwords do not match. Please try again.");
      return;
    }

    // Show loading indicator
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
      // Prepare data for the API request
      var data = {
        "name": firstNameController.text.trim(), // Use first_name as per common Laravel convention
        "last_name": lastNameController.text.trim(),
        "registration_number": regNumberController.text.trim(), // Use registration_number
        "phone_number": phoneNumberController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "password_confirmation": confirmPasswordController.text,
      };

      // Make the API call using your CallApi class
      // Ensure your CallApi().postData handles headers like 'Content-Type': 'application/json'
      var res = await CallApi().postData(data, 'register'); // Your Laravel registration API endpoint
      var body = json.decode(res.body);

      // Dismiss the loading indicator
      Navigator.pop(context);

      // Handle API response
      if (res.statusCode == 200 && body['success'] == true) {
        // Assuming your Laravel API returns a 'token' upon successful registration
        final String token = body['token'];

        // Store the token using shared_preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Navigate to the home screen upon successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        // Handle registration errors from Laravel API based on response structure
        String displayMessage = "Registration failed. Please try again.";

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
          // General error message from Laravel (e.g., 'Email already taken')
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
      print("Registration Error: $e"); // Log the error for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Image.asset(
                    "assets/images/logo.png", // Ensure this path is correct
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Resource Booking App",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 17, 105, 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 17, 105, 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: firstNameController,
                    obscureText: false,
                    hintText: "First name",
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: lastNameController,
                    obscureText: false,
                    hintText: "Last name",
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: regNumberController,
                    obscureText: false,
                    hintText: "Registration number",
                    keyboardType: TextInputType.text, // Or TextInputType.number if it's purely numeric
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: phoneNumberController,
                    obscureText: false,
                    hintText: "Phone number",
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: emailController,
                    obscureText: false,
                    hintText: "Email",
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    obscureText: true,
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    hintText: "Confirm password",
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                  const SizedBox(height: 20), // Reduced spacing slightly
                  // Display error message if any
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  MyButton(onTap: signUpUser, text: "Sign Up",),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: widget.showLoginScreen,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.green[700], fontSize: 16),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Login now",
                          style: TextStyle(color: Colors.blue[700], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}