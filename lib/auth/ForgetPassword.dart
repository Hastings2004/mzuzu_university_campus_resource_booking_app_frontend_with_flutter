import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/TextField.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {

  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async{
    if(emailController.text.isEmpty){
      showDialog(
        context: context, 
        builder: (context) {
          return AlertDialog(
            content: const Text("Please enter your email"),
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
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim()
      );
      
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context, 
        builder: (context) {
          return AlertDialog(
            content: Text(e.message.toString()),
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
    } finally {
      Navigator.pop(context);
      showDialog(
        context: context, 
        builder: (context) {
          return AlertDialog(
            content: const Text("Password reset link sent to your email"),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 17, 105, 20),
        elevation: 0,
        title: const Text("Reset Password", 
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Text(
                "Enter your email address and we will send you a link to reset your password",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[700]
                ),
              )
            ),
            SizedBox(height: 20),

            MyTextField(
              hintText: "Email", 
              controller: emailController, 
              obscureText: false,
              prefixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: 20),

            MaterialButton(
              onPressed: passwordReset,
              color: const Color.fromARGB(255, 17, 105, 20),
              height: 50,
              minWidth: 200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
              child: const Text("Send Reset Link",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),
              )
            )
          ],
        ),
        
      ),
   
    );
  }

 
}