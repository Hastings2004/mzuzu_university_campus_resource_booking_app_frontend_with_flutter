import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resource_booking_app/components/AppBar.dart'; 

class ResourceDetails extends StatefulWidget {
  final DocumentSnapshot resourceDocument;

  const ResourceDetails({
    super.key, 
    required this.resourceDocument
  });

  @override
  State<ResourceDetails> createState() => _ResourceDetailsState();
}

class _ResourceDetailsState extends State<ResourceDetails> {
  @override
  Widget build(BuildContext context) {
    String? photoUrl = widget.resourceDocument['image'];
    String name = widget.resourceDocument['name'];
    String location = widget.resourceDocument['location'];
    String? description = widget.resourceDocument['description']; // Assuming you might have a description field

    return Scaffold(
      appBar: MyAppBar(
        titleWidget: Text(
          name, // Use the resource name as the title
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              Center(
                child: Image.asset(
                  photoUrl,
                  height: 300,
                  width: double.infinity, // Take full width
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 150); // Fallback for missing image
                  },
                ),
              ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green, // Example styling
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Location: $location',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            if (description != null && description.isNotEmpty)
              Text(
                'Description: $description',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            // Add more details as needed from your document
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement booking logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking $name... (Not implemented yet)')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 20, 148, 24), // Use your app's primary color
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Book This Resource',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}