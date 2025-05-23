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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 500, // Adjust as needed
                    height: 700, // Adjust as needed
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10), // Optional: for rounded corners
                      child: Image.asset(
                        "assets/"+photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.person)); // Show a default icon on error
                        },
                      ),
                    ),
                  ),
                )
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '${data['first_name']} ${data['last_name']}\n'
                  '${data['email']}\n'
                  '${data['phone_number']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ]
      );
      },
      
    );
  }
}