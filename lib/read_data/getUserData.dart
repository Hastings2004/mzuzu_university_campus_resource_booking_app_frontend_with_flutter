import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Getuserdata extends StatelessWidget {
  
  final String documentId;

  const Getuserdata({required this.documentId});

  @override
  Widget build(BuildContext context) {

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(documentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No data found'));
        }
        

        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        String? photoUrl = data['photo']; // Assuming your field name is 'photoUrl'

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child:  Image.asset("assets/images/charity.jpg",
                  width: 140, // Adjust as needed
                  height: 150, // Adjust as needed
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.person)); // Show a default icon on error
                  },
                ),
                ),
                
                Text(
                    'Welcome ${data['first_name']} ${data['last_name']}',
                    style: TextStyle(
                      fontSize: 25, fontWeight: 
                        FontWeight.bold,
                        color: Colors.black,
                        )
                ),
                Text(
                    '${data['email']}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                    ),
                ),
                
              ]
            ),
          ),
        );
      },
      
    );
  }
}