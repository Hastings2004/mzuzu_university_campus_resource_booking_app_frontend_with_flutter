import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Register.dart';
import 'package:resource_booking_app/auth/login.dart';


class Authpage extends StatefulWidget {
  const Authpage({super.key});

  @override
  State<Authpage> createState() => _AuthpageState();
}

class _AuthpageState extends State<Authpage> {

  bool isLogin = true;

  void toggleScreens(){
    setState(() {
      isLogin = !isLogin;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLogin) {
      return LoginScreen(showRegisterScreen: toggleScreens );
    } else {
      return Register(showLoginScreen: toggleScreens);
    }
  }
}
