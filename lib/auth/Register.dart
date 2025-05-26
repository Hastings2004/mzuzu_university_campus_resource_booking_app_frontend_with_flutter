// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/components/TextField.dart';

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> addUserDetails(String uid) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "first_name": firstNameController.text.trim(),
      "last_name": lastNameController.text.trim(),
      "phone_number": phoneNumberController.text.trim(),
      "email": emailController.text.trim(),
      "email_verified": false, // New field to track email verification status
    });
  }

  Future<void> signUpUser() async {
    // Basic validation for empty fields
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        phoneNumberController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text("Please fill in all fields"),
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
      return;
    }

    // Password confirmation check
    if (!passwordConfirm()) {
      return; // If passwords don't match, passwordConfirm() already shows a dialog
    }

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
      // 1. Create User with Email and Password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. Send Email Verification
      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
      }

      // 3. Add User Details to Firestore (initially with email_verified: false)
      if (user != null && user.uid.isNotEmpty) {
        await addUserDetails(user.uid);
      }

      Navigator.pop(context); // Dismiss loading indicator

      // Show success and instructions for email verification
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Registration Successful!"),
            content: const Text(
                "A verification link has been sent to your email address. Please verify your email before logging in."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close success dialog
                  widget.showLoginScreen(); // Navigate to login screen
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Dismiss loading indicator on error

      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = "Password is too weak.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is not valid.";
      } else {
        errorMessage = "An unexpected error occurred: ${e.message}";
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(errorMessage),
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
    } catch (e) {
      Navigator.pop(context); // Dismiss loading indicator for other errors
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text("An error occurred: $e"),
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
  }

  bool passwordConfirm() {
    if (passwordController.text.trim() == confirmPasswordController.text.trim()) {
      return true;
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text("Passwords do not match"),
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
      return false;
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
                  const SizedBox(height: 20),
                  MyButton(
                    onTap: signUpUser,
                    text: "Sign Up",
                  ),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}