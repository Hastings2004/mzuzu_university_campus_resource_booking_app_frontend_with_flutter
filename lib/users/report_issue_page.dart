import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:http/http.dart' as http;
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ReportIssuePage extends StatefulWidget {
  final int resourceId;
  final String resourceName;

  const ReportIssuePage({
    super.key,
    required this.resourceId,
    required this.resourceName,
  });

  @override
  _ReportIssuePageState createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TextEditingController _nameController;

  XFile? _photo;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.resourceName);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photo = pickedFile;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      http.StreamedResponse response;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/resource-issues'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['subject'] = _subjectController.text;
      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;

      if (_photo != null) {
        if (kIsWeb) {
          final photoBytes = await _photo!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'photo',
              photoBytes,
              filename: _photo!.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('photo', _photo!.path),
          );
        }
      }

      response = await request.send();

      final responseBody = await response.stream.bytesToString();
      final decodedBody = json.decode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _subjectController.clear();
          _descriptionController.clear();
          _nameController.text = widget.resourceName;
          _photo = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop after a delay to show success message
        Future.delayed(
          const Duration(seconds: 2),
          () => Navigator.of(context).pop(),
        );
      } else {
        throw Exception(decodedBody['message'] ?? 'Failed to report issue.');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: const Bottombar(),
      drawer: Mydrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report Issue for: ${widget.resourceName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Resource Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Resource name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g., Projector not working',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Provide more details about the issue...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attach Photo (Optional)',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Select Photo'),
                    onPressed: _pickPhoto,
                  ),
                  if (_photo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Selected: ${_photo!.name}'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Report'),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
