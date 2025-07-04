import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EmailVerification extends StatefulWidget {
  final String userEmail;
  const EmailVerification({super.key, required this.userEmail});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Check verification status after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkVerificationStatus();
    });
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
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Call the resend verification email API
      var res = await CallApi().postData({}, 'resend-verification-email');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          _successMessage =
              "Verification email sent successfully! Please check your inbox.";
        });
        _showSuccessDialog(_successMessage!);
      } else {
        setState(() {
          _errorMessage =
              body['message'] ??
              "Failed to resend verification email. Please try again.";
        });
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Network error. Please check your connection and try again.";
      });
      _showErrorDialog(_errorMessage!);
      print("Resend verification error: $e");
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // Call the verification status check API
      var res = await CallApi().getData('email/verification-status');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        bool isVerified = body['verified'] ?? false;

        if (isVerified) {
          // Email is verified, navigate to home
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          }
        } else {
          // Email not verified yet, stay on this screen
          setState(() {
            _successMessage =
                "Please check your email and click the verification link.";
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "Failed to check verification status. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Network error. Please check your connection and try again.";
      });
      print("Check verification status error: $e");
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo and title
              Image.asset("assets/images/logo.png", height: 100),
              const SizedBox(height: 20),
              const Text(
                "Email Verification Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 17, 105, 20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Email icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 60,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 30),

              // Instructions
              const Text(
                "We've sent a verification email to:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.userEmail,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 17, 105, 20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              const Text(
                "Please check your email and click the verification link to activate your account.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 30),

              // Check verification button
              SizedBox(
                width: double.infinity,
                child: MyButton(
                  onTap: _isChecking ? null : _checkVerificationStatus,
                  text: _isChecking ? "Checking..." : "I've Verified My Email",
                ),
              ),
              const SizedBox(height: 15),

              // Resend email button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isResending
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            "Resend Verification Email",
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
              const SizedBox(height: 20),

              // Help text
              const Text(
                "Didn't receive the email? Check your spam folder or try resending.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
