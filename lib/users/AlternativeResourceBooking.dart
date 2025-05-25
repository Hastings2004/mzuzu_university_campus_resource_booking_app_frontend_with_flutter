// lib/users/AlternativeResourcesScreen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:resource_booking_app/components/AppBar.dart';

class AlternativeResourcesScreen extends StatelessWidget {
  final List<DocumentSnapshot> alternativeResources;
  final String bookingPurpose;
  final int estimatedPeople;
  final DateTime startTime;
  final DateTime endTime;

  const AlternativeResourcesScreen({
    Key? key,
    required this.alternativeResources,
    required this.bookingPurpose,
    required this.estimatedPeople,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        titleWidget: Text(
          "Available Alternatives",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: alternativeResources.isEmpty
          ? const Center(
              child: Text(
                'No alternative resources found for your criteria.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Based on your request:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('• People: $estimatedPeople'),
                      Text('• Start: ${DateFormat('MMM d, yyyy HH:mm').format(startTime)}'),
                      Text('• End: ${DateFormat('MMM d, yyyy HH:mm').format(endTime)}'),
                      Text('• Purpose: $bookingPurpose'),
                      const SizedBox(height: 10),
                      const Text(
                        'Please choose from the following available resources:',
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: alternativeResources.length,
                    itemBuilder: (context, index) {
                      var resource = alternativeResources[index];
                      String name = resource['name'] ?? 'N/A';
                      String location = resource['location'] ?? 'N/A';
                      int capacity = resource['capacity'] ?? 0;
                      String? photoUrl = resource['image'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (photoUrl != null && photoUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    photoUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 80);
                                    },
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Location: $location',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Capacity: $capacity people',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  // Re-confirm and book this alternative resource
                                  await _confirmAndBookAlternative(
                                    context,
                                    resource,
                                    bookingPurpose,
                                    estimatedPeople,
                                    startTime,
                                    endTime,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 20, 148, 24),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Book This Alternative',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmAndBookAlternative(
    BuildContext context,
    DocumentSnapshot resource,
    String purpose,
    int estimatedPeople,
    DateTime start,
    DateTime end,
  ) async {
    final user = FirebaseAuth.instance.currentUser!;
    // Optional: Add a confirmation dialog here before booking
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: Text(
              'Are you sure you want to book ${resource['name']} from ${DateFormat('HH:mm').format(start)} to ${DateFormat('HH:mm').format(end)} on ${DateFormat('MMM d, yyyy').format(start)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Fetch user's full name
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String userName = 'N/A';
        if (userDoc.exists) {
          userName = '${userDoc['first_name'] ?? ''} ${userDoc['last_name'] ?? ''}'.trim();
          if (userName.isEmpty) userName = 'N/A';
        }

        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user.uid,
          'userName': userName,
          'userEmail': user.email,
          'resourceId': resource.id,
          'resourceName': resource['name'],
          'resourceLocation': resource['location'],
          'startTime': Timestamp.fromDate(start),
          'endTime': Timestamp.fromDate(end),
          'purpose': purpose,
          'estimatedPeople': estimatedPeople,
          'bookingDate': Timestamp.now(),
          'status': 'pending', // Set to pending for approval
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking request for ${resource['name']} sent successfully!')),
        );
        // Pop back to the main booking screen or home
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/bookings');
        // You might want to pop twice if you go back to the original ResourceDetails screen, then to Bookings.
        // Or directly to the home screen if that's preferred.
      } catch (e) {
        print("Error booking alternative resource: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book alternative: $e')),
        );
      }
    }
  }
}