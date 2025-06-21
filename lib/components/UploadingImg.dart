import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final user = FirebaseAuth.instance.currentUser!;

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading =
      false; // Track upload state to show progress, disable buttons

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Ensure WidgetsFlutterBinding is called *before* using the picker.
      WidgetsFlutterBinding.ensureInitialized(); // <--- IMPORTANT
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String fileName = path.basename(_imageFile!.path);
    firebase_storage.Reference storageRef = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child('images/$fileName');

    try {
      // Use UploadTask for better progress indication
      firebase_storage.UploadTask uploadTask = storageRef.putFile(_imageFile!);

      // Attach a listener to the uploadTask to get snapshot events.
      uploadTask.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
        // Track the upload progress.
        double progress =
            snapshot.totalBytes != 0 ? snapshot.bytesTransferred / snapshot.totalBytes : 0;
        print('Upload progress: ${progress * 100}%');
        // You could show this progress in a ProgressIndicator.
      }, onError: (error) {
        // Handle errors during the upload.  Important!
        print('Error during upload: $error');
        setState(() {
          _isUploading =
              false; // IMPORTANT:  Set uploading to false on error!
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      });

      // Await the upload to complete and get the snapshot.
      await uploadTask; //  <-- Await here

      // Get the download URL.  This is done AFTER the upload is complete.
      String downloadURL = await storageRef.getDownloadURL();
      print('Image uploaded successfully! Download URL: $downloadURL');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded! URL: $downloadURL'),
          duration: const Duration(seconds: 5),
        ),
      );

      setState(() {
        _isUploading = false; // Set uploading to false on success
        _imageFile = null; // Clear the selected image after successful upload
      });
    } catch (e) {
      // Catch any errors that occur during the upload process.
      print('Error uploading image: $e');
      setState(() {
        _isUploading =
            false; // IMPORTANT: Also set uploading to false in the general catch
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text(
          "Upload Image",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                children: [
                  Image.asset("images/logo.png", height: 50),
                  const Text(
                    'Mzuzu University',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Campus Resource Booking',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Home()));
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Resources'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ResourcesScreen()));
              },
            ),
            ListTile(
              title: const Text('Booking'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => BookingScreen()));
              },
            ),
            ListTile(
              title: const Text('Setings'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                logout();
                Navigator.pop(context);
              },
            ),
            Text(
              user.email!,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              const Text('No image selected.'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Text('Camera'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadImageToFirebase,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}

