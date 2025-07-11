import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'dart:convert';
import 'package:resource_booking_app/users/issue_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueManagementScreen extends StatefulWidget {
  const IssueManagementScreen({super.key});

  @override
  State<IssueManagementScreen> createState() => _IssueManagementScreenState();
}

class _IssueManagementScreenState extends State<IssueManagementScreen> {
  bool _loadingIssues = false;
  String? _error;

  List<dynamic> _userIssues = [];

  void logout() async {
    // Show a confirmation dialog
    final bool confirmLogout =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  TextButton(
                    onPressed:
                        () => Navigator.of(context).pop(false), // User cancels
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop(true), // User confirms
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ), // Optional: make logout button red
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to your login screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        ); 
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserIssues();
  }

  Future<void> _loadUserIssues() async {
    setState(() {
      _loadingIssues = true;
      _error = null;
    });

    try {
      final response = await CallApi().getData('resource-issues');
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['data'] != null) {
        setState(() {
          _userIssues = body['data'] ?? [];
        });
      } else {
        setState(() {
          _error = 'Failed to load your issues. Please try again.';
          _userIssues = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading issues: $e';
        _userIssues = [];
      });
    } finally {
      setState(() {
        _loadingIssues = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

      
      appBar: MyAppBar(
        titleWidget: const Text(
          'My Reported Issues',
          style: TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: const Bottombar(),
      drawer: Mydrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const ReportIssuePage(
                              resourceId: 0,
                              resourceName: '',
                            ),
                      ),
                    );
                  },
                  child: Text(
                    'Report Issue',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.green),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            // Content based on view mode
            if (_loadingIssues)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_userIssues.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'You haven\'t reported any issues yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userIssues.length,
                itemBuilder: (context, index) {
                  final issue = _userIssues[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  issue['subject'] ?? 'No Subject',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (issue['status'] ?? 'pending')
                                      .toString()
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildIssueDetail(
                            'Resource',
                            issue['resource']?['name'] ?? 'Unknown',
                          ),
                          if (issue['description'] != null &&
                              issue['description'].toString().isNotEmpty)
                            _buildIssueDetail(
                              'Description',
                              issue['description'],
                            ),
                          if (issue['photo'] != null &&
                              issue['photo'].toString().isNotEmpty)
                            _buildIssueImage(issue['photo']),
                          _buildIssueDetail(
                            'Reported',
                            issue['created_at'] ?? '',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueImage(String photoUrl) {
    print('Attempting to load image from URL: $photoUrl');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photoUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
