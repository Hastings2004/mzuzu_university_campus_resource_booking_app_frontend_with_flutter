import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resource_booking_app/components/AppBar.dart'; // This might not be needed anymore
import 'package:resource_booking_app/read_data/getUserData.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final user = FirebaseAuth.instance.currentUser!;

  void logout(){
    FirebaseAuth.instance.signOut();
  }

  // We'll store the current user's document ID here
  String? currentUserDocID;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDocID(); // Fetch the current user's document ID on init
  }

  Future<void> _fetchCurrentUserDocID() async {
    // Assuming your user documents in Firestore are named by their UID
    currentUserDocID = user.uid;
    setState(() {}); // Rebuild the widget to display the user data
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const MyAppBar(title: "Home",),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
             DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 50
                  ),
                  Text(
                    'Mzuzu University',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    'Campus Resource Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Resources'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ResourcesScreen()));
              },
            ),
            ListTile(
              title: const Text('Booking'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
              },
            ),

            ListTile(
              title: const Text('Settings'), // Corrected typo
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                logout();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: currentUserDocID == null
                  ? const CircularProgressIndicator() // Show a loading indicator
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: ListTile(
                                title: Getuserdata(documentId: currentUserDocID!), // Display only the current user's data
                                subtitle: const Text("Your Profile Details:"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                                  },
                                ),),
                          ),
                          //const SizedBox(height: 10),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Center(
                                child: Card(
                                  child: ListTile(
                                    title: const Text("Make a Booking"),
                                    subtitle: const Text("Click here to make a booking"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => ResourcesScreen()));
                                      },
                                    ),
                                  ),
                                ),
                          ),
                        )
                        ],
                      )
                    ),
            ),

            /*const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Card(
                  child: ListTile(
                    title: const Text("Make a Booking"),
                    subtitle: const Text("Click here to make a booking"),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ResourcesScreen()));
                      },
                    ),
                  ),
                ),
              ),
            )*/
          ],
        )
      ),
    );

  }
}