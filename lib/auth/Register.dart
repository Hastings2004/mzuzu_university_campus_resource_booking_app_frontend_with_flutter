import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/components/TextField.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future addUserDetails() async{
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if(uid != null){
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "first_name": firstNameController.text.trim(),
        "last_name": lastNameController.text.trim(),
        "reg_number": regNumberController.text.trim(),
        "phone_number": phoneNumberController.text.trim(),
        "email": emailController.text.trim(),
      });
    }
  }
  Future signUpUser() async{

    if(emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        regNumberController.text.isEmpty
    ){
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
                    child: const Text("OK")
                )
              ],
            );
          }
      );
      return;
    }


    if(passwordConfirm()){

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
      );

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim()
        );
        // ignore: use_build_context_synchronously

        // Add user details to the database
        addUserDetails();
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {

        Navigator.pop(context);

        if(e.code == 'weak-password') {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: const Text("Password is too weak"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK")
                    )
                  ],
                );
              }
          );
        } else if (e.code == 'email-already-in-use') {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: const Text("Email already in use"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK")
                    )
                  ],
                );
              }
          );

        } else if (e.code == 'invalid-email') {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: const Text("Invalid email"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK")
                    )
                  ],
                );
              }
          );
        } else {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: const Text("An error occurred"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK")
                    )
                  ],
                );
              }
          );
        }
      }
    }
  }



  bool passwordConfirm() {
    if(passwordController.text.trim() == confirmPasswordController.text.trim()){
      return true;
    }else{
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text("Password do not match"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("OK")
                )
              ],
            );
          }
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