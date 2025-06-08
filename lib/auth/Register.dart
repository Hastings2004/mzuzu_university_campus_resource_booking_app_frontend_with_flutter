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
  State<Register> createState() => _ApiRegisterState(); // Changed state class name for consistency
}

class _ApiRegisterState extends State<Register> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  String? _userType; // New variable for user type (student/staff)
  final List<String> _userTypes = ['Student', 'Staff']; // Options for the dropdown

  String? _errorMessage; // To display error messages below the form

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
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

    // Client-side validation: Check for empty fields and user type selection
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        _userType == null) {
      _showErrorDialog("Please fill in all fields and select a user type.");
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
        "first_name": firstNameController.text.trim(),
        "last_name": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "password_confirmation": confirmPasswordController.text,
        "user_type": _userType!.toLowerCase(), // Send as 'student' or 'staff' to backend
      };

      // Make the API call using your CallApi class
      var res = await CallApi().postData(data, 'register/'); // Your Laravel registration API endpoint
      var body = json.decode(res.body);

      // Dismiss the loading indicator
      if (mounted) {
        Navigator.pop(context);
      }

      // Handle API response
      if (res.statusCode == 200 && body['success'] == true) {
        // Assuming your Laravel API returns a 'token', 'user_id', 'user_name', and 'user_email' upon successful registration
        final String token = body['token'];
        final int userId = body['user']['id']; // Assuming your user object has an 'id'
        final String userName = body['user']['first_name'] + ' ' + body['user']['last_name']; // Combine for display
        final String userEmail = body['user']['email'];


        // Store user data and token using shared_preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_email', userEmail);
        await prefs.setString('user_type', _userType!.toLowerCase()); // Store user type

        // Navigate to the home screen upon successful registration
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()), // Navigate to Home screen
          );
        }
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
      if (mounted) {
        Navigator.pop(context); // Pop the loading indicator in case of an exception
      }
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
      // Use LayoutBuilder to get the available height
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Constrain the content to at least the height of the screen
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // Minimum height is screen height
              ),
              child: IntrinsicHeight( // Make column take only as much height as its children need, but not less than minHeight
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Keep your padding here
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
                      crossAxisAlignment: CrossAxisAlignment.center, // Horizontally center children within the column
                      children: [
                        const SizedBox(height: 30), // Initial spacing or logo top margin
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'First name is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: lastNameController,
                          obscureText: false,
                          hintText: "Last name",
                          keyboardType: TextInputType.name,
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Last name is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // New Dropdown for User Type
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0), // Padding is applied to the Column's parent, so this can be 0.0 or adjusted as needed
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 1.5),
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.grey.shade200,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _userType,
                                hint: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0), // Adjust padding for hint
                                  child: Text('Select User Type'),
                                ),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                style: TextStyle(color: Colors.grey[700], fontSize: 16),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _userType = newValue;
                                  });
                                },
                                items: _userTypes.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0), // Adjust padding for items
                                      child: Text(value),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: emailController,
                          obscureText: false,
                          hintText: "Email",
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: passwordController,
                          obscureText: true,
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          hintText: "Confirm password",
                          prefixIcon: const Icon(Icons.lock_reset),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm password is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
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

                        MyButton(onTap: signUpUser, text: "Sign Up"),
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
        },
      ),
    );
  }
}