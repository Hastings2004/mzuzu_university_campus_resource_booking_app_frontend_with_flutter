import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/TextField.dart';
import 'package:resource_booking_app/auth/Api.dart'; // Import your API service
import 'dart:convert'; // For json.decode

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  final emailController = TextEditingController();
  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> passwordReset() async {
    // Basic validation
    if (emailController.text.trim().isEmpty) {
      _showErrorDialog("Please enter your email.");
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final data = {
        'email': emailController.text.trim(),
      };

      final res = await CallApi().postData(data, 'forgot-password'); // Adjust endpoint as per your API
      final body = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Assuming your API returns success if the email is sent
        if (body['success'] == true) { // Adjust 'success' key based on your API response
          _showSuccessDialog(
              "Password reset link sent to your email. Please check your inbox (and spam folder).");
        } else {
          // Handle specific backend errors if any
          _showErrorDialog(body['message'] ?? "Failed to send password reset link. Please try again.");
        }
      } else {
        // Handle other HTTP status codes (e.g., 400, 404, 500)
        String errorMessage = "Failed to send password reset link. Server error.";
        if (body.containsKey('message')) {
          errorMessage = body['message'];
        } else if (body.containsKey('errors') && body['errors']['email'] != null) {
          errorMessage = body['errors']['email'][0]; // Laravel validation error for email
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print("Error sending password reset: $e");
      _showErrorDialog("An error occurred. Please check your internet connection and try again.");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Optionally, navigate back to the login screen
                // Navigator.pop(context); // uncomment if you want to go back to login after success
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 17, 105, 20),
        elevation: 0,
        title: const Text(
          "Reset Password",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow on small screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "Enter your email address and we will send you a link to reset your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 20),
              MyTextField(
                hintText: "Email",
                controller: emailController,
                obscureText: false,
                prefixIcon: const Icon(Icons.email),
                keyboardType: TextInputType.emailAddress, // Added keyboard type
                validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required.';
                      }
                      return null;
                    },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator() // Show loading indicator
                  : MaterialButton(
                      onPressed: passwordReset,
                      color: const Color.fromARGB(255, 17, 105, 20),
                      height: 50,
                      minWidth: 200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        "Send Reset Link",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}