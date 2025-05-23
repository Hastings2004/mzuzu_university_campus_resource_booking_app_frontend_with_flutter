import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/ForgetPassword.dart';
import 'package:resource_booking_app/components/Button.dart';
import 'package:resource_booking_app/components/TextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resource_booking_app/read_data/MyList.dart';
import 'package:resource_booking_app/users/Home.dart';

class LoginScreen extends StatefulWidget {

  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});


  @override
  State<LoginScreen> createState() => __LoginScreenState();
}

class __LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future loginUser() async {
    // Implement login functionality here

    if(_emailController.text.isEmpty || _passwordController.text.isEmpty){
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

    try{
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim()
      );

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()), // Replace HomeScreen() with your actual home screen widget
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      if (e.code == 'user-not-found') {
        wrongEmailMessage();
      } else if (e.code == 'wrong-password') {
        wrongPasswordMessage();
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void emptyFieldMessage(){
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
  }

  void wrongEmailMessage(){
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text("Wrong Email"),
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

  void wrongPasswordMessage(){
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text("Password is incorrect"),
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