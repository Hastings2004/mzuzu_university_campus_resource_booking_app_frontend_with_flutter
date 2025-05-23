import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GetResource extends StatelessWidget {
  
  const GetResource({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CollectionReference resources =
        FirebaseFirestore.instance.collection('resources');

    return StreamBuilder<QuerySnapshot>(
      stream: resources.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No resources found'));
        }

        // If data is available, build a list of resources
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            String? photoUrl = data['photo']; // Assuming your field name is 'photo'

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          width: 500, // Adjust as needed
                          height: 700, // Adjust as needed
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset( // Changed to Image.network to load from URL
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child: Icon(Icons.image)); // Or any other error indicator
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'Name: ${data['name'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Capacity: ${data['capacity'] ?? 'N/A'}'),
                  Text('Location: ${data['location'] ?? 'N/A'}'),
                  const Divider(), // Added a divider between resources for better visual separation
                ],
              ),
            );
          },
        );
      },
    );
  }
}