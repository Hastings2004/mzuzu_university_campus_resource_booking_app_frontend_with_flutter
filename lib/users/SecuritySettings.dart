import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/BookingCalendar.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Resourse.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  // Static navigation helper
  static Future<void> navigate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
    );
  }

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  // 2FA
  bool twoFactorEnabled = false;
  String qrCodeData = '';
  List<String> backupCodes = [];
  bool showBackupCodes = false;
  String verificationCode = '';
  bool twoFactorLoading = false;
  String twoFactorMessage = '';
  String twoFactorError = '';

  // Sessions
  List<Map<String, dynamic>> activeSessions = [];
  bool sessionLoading = false;
  String sessionMessage = '';
  String sessionError = '';

  // Privacy
  String profileVisibility = 'public';
  bool dataSharing = true;
  bool emailNotifications = true;
  bool privacyLoading = false;
  String privacyMessage = '';
  String privacyError = '';

  // General loading
  bool get isBusy => twoFactorLoading || sessionLoading || privacyLoading;

  // Placeholder for user email (replace with real user context if available)
  String userEmail = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetch2FAStatus(),
      _fetchActiveSessions(),
      _fetchPrivacySettings(),
    ]);
  }

  // --- 2FA Section ---
  Future<void> _fetch2FAStatus() async {
    // If you have a user context, get twoFactorEnabled from there
    // For now, assume disabled by default
    setState(() {
      twoFactorEnabled = false;
    });
  }

  Future<void> _enable2FA() async {
    setState(() {
      twoFactorLoading = true;
      twoFactorError = '';
      twoFactorMessage = '';
    });
    try {
      final response = await CallApi().postData({}, 'user/2fa/setup');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          qrCodeData = data['qr_code'] ?? '';
          backupCodes = List<String>.from(data['backup_codes'] ?? []);
          twoFactorMessage =
              '2FA setup initiated. Scan the QR code and enter the verification code.';
        });
      } else {
        setState(() {
          twoFactorError = 'Failed to setup 2FA: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        twoFactorError = 'Network error: $e';
      });
    } finally {
      setState(() {
        twoFactorLoading = false;
      });
    }
  }

  Future<void> _verify2FA() async {
    if (verificationCode.length != 6) {
      setState(() => twoFactorError = 'Please enter a 6-digit code.');
      return;
    }
    setState(() {
      twoFactorLoading = true;
      twoFactorError = '';
    });
    try {
      final response = await CallApi().postData({
        'code': verificationCode,
      }, 'user/2fa/verify');
      if (response.statusCode == 200) {
        setState(() {
          twoFactorEnabled = true;
          qrCodeData = '';
          backupCodes = [];
          verificationCode = '';
          twoFactorMessage = '2FA enabled successfully!';
        });
        _showSnackBar('2FA enabled successfully!', Colors.green);
      } else {
        setState(() {
          twoFactorError = 'Verification failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        twoFactorError = 'Network error: $e';
      });
    } finally {
      setState(() {
        twoFactorLoading = false;
      });
    }
  }

  Future<void> _disable2FA() async {
    setState(() {
      twoFactorLoading = true;
      twoFactorError = '';
    });
    try {
      final response = await CallApi().deleteData('user/2fa/disable');
      if (response.statusCode == 200) {
        setState(() {
          twoFactorEnabled = false;
          twoFactorMessage = '2FA disabled successfully!';
        });
        _showSnackBar('2FA disabled successfully!', Colors.green);
      } else {
        setState(() {
          twoFactorError = 'Failed to disable 2FA: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        twoFactorError = 'Network error: $e';
      });
    } finally {
      setState(() {
        twoFactorLoading = false;
      });
    }
  }

  // --- Session Management ---
  Future<void> _fetchActiveSessions() async {
    setState(() {
      sessionLoading = true;
      sessionError = '';
    });
    try {
      final response = await CallApi().getData('user/sessions');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          activeSessions = List<Map<String, dynamic>>.from(
            data['sessions'] ?? [],
          );
        });
      } else {
        setState(() {
          sessionError = 'Failed to fetch sessions: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        sessionError = 'Network error: $e';
      });
    } finally {
      setState(() {
        sessionLoading = false;
      });
    }
  }
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
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }


  Future<void> _logoutAllDevices() async {
    setState(() {
      sessionLoading = true;
      sessionMessage = '';
      sessionError = '';
    });
    try {
      final response = await CallApi().deleteData('user/sessions/logout-all');
      if (response.statusCode == 200) {
        setState(() {
          activeSessions.clear();
          sessionMessage = 'Logged out from all devices successfully';
        });
        _showSnackBar('Logged out from all devices', Colors.green);
      } else {
        setState(() {
          sessionError = 'Failed to logout all devices: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        sessionError = 'Network error: $e';
      });
    } finally {
      setState(() {
        sessionLoading = false;
      });
    }
  }

  Future<void> _logoutSession(String sessionId) async {
    setState(() {
      sessionLoading = true;
      sessionError = '';
    });
    try {
      final response = await CallApi().deleteData('user/sessions/$sessionId');
      if (response.statusCode == 200) {
        setState(() {
          activeSessions.removeWhere((s) => s['id'].toString() == sessionId);
          sessionMessage = 'Session logged out successfully';
        });
        _showSnackBar('Session logged out', Colors.green);
      } else {
        setState(() {
          sessionError = 'Failed to logout session: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        sessionError = 'Network error: $e';
      });
    } finally {
      setState(() {
        sessionLoading = false;
      });
    }
  }

  // --- Privacy Settings ---
  Future<void> _fetchPrivacySettings() async {
    setState(() {
      privacyLoading = true;
      privacyError = '';
    });
    try {
      final response = await CallApi().getData('user/privacy');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileVisibility = data['profile_visibility'] ?? 'public';
          dataSharing = data['data_sharing'] ?? true;
          emailNotifications = data['email_notifications'] ?? true;
        });
      } else {
        setState(() {
          privacyError =
              'Failed to fetch privacy settings: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        privacyError = 'Network error: $e';
      });
    } finally {
      setState(() {
        privacyLoading = false;
      });
    }
  }

  Future<void> _updatePrivacySettings() async {
    setState(() {
      privacyLoading = true;
      privacyMessage = '';
      privacyError = '';
    });
    try {
      final response = await CallApi().putData({
        'profile_visibility': profileVisibility,
        'data_sharing': dataSharing,
        'email_notifications': emailNotifications,
      }, 'user/privacy');
      if (response.statusCode == 200) {
        setState(() {
          privacyMessage = 'Privacy settings updated successfully';
        });
        _showSnackBar('Privacy settings updated', Colors.green);
      } else {
        setState(() {
          privacyError =
              'Failed to update privacy settings: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        privacyError = 'Network error: $e';
      });
    } finally {
      setState(() {
        privacyLoading = false;
      });
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Bottombar(currentIndex: 0),
      appBar: MyAppBar(
        titleWidget: const Text(
          "Security Settings",
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 148, 24),
              ),
              child: Column(
                children: [
                  Image(
                    image: AssetImage("assets/images/logo.png"),
                    height: 50,
                  ),
                  Text(
                    'Mzuzu University',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Campus Resource Booking',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Home(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Resources'),
              leading: const Icon(Icons.grid_view),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResourcesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Bookings'),
              leading: const Icon(Icons.book_online),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              },
            ),
           
            ListTile(
              title: const Text('Booking Calendar'),
              leading: const Icon(Icons.calendar_month),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingCalendar(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Report Issue'),
              leading: const Icon(Icons.report),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IssueManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('History'),
              leading: const Icon(Icons.history),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTwoFactorSection(),
                const SizedBox(height: 32),
                _buildSessionManagementSection(),
                const SizedBox(height: 32),
                _buildPrivacySettingsSection(),
              ],
            ),
          ),
          if (isBusy)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTwoFactorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Two-Factor Authentication',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${twoFactorEnabled ? "Enabled" : "Disabled"}',
              style: TextStyle(
                color: twoFactorEnabled ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            if (!twoFactorEnabled)
              ElevatedButton(
                onPressed: twoFactorLoading ? null : _enable2FA,
                child: Text(twoFactorLoading ? 'Setting up...' : 'Enable 2FA'),
              )
            else
              ElevatedButton(
                onPressed: twoFactorLoading ? null : _disable2FA,
                child: Text(twoFactorLoading ? 'Disabling...' : 'Disable 2FA'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            if (qrCodeData.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 16),
                 QrImageView(
                    data: qrCodeData,
                    size: 200,
                  ), const SizedBox(height: 8),
                   TextField(
                    decoration: const InputDecoration(
                      labelText: 'Enter verification code',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (val) => setState(() => verificationCode = val),
                  ),
                  ElevatedButton(
                    onPressed: twoFactorLoading ? null : _verify2FA,
                    child: Text(twoFactorLoading ? 'Verifying...' : 'Verify'),
                  ),
                ],
              ),
            if (backupCodes.isNotEmpty && showBackupCodes)
              Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Backup Codes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...backupCodes.map((code) => Text(code)),
                ],
              ),
            if (backupCodes.isNotEmpty)
              TextButton(
                onPressed:
                    () => setState(() => showBackupCodes = !showBackupCodes),
                child: Text(
                  showBackupCodes ? 'Hide Backup Codes' : 'Show Backup Codes',
                ),
              ),
            if (twoFactorMessage.isNotEmpty)
              Text(
                twoFactorMessage,
                style: const TextStyle(color: Colors.green),
              ),
            if (twoFactorError.isNotEmpty)
              Text(twoFactorError, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: sessionLoading ? null : _logoutAllDevices,
                  child: Text(
                    sessionLoading ? 'Logging out...' : 'Logout All Devices',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: sessionLoading ? null : _fetchActiveSessions,
                  child: const Text('Refresh Sessions'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Active Sessions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sessionLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              )
            else if (activeSessions.isEmpty)
              const Text('No active sessions found.'),
            ...activeSessions.map(
              (session) => ListTile(
                title: Text(session['device'] ?? 'Unknown Device'),
                subtitle: Text(
                  '${session['location'] ?? 'Unknown Location'} • Last active: '
                  '${session['last_active'] ?? ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed:
                      sessionLoading
                          ? null
                          : () => _logoutSession(session['id'].toString()),
                ),
              ),
            ),
            if (sessionMessage.isNotEmpty)
              Text(sessionMessage, style: const TextStyle(color: Colors.green)),
            if (sessionError.isNotEmpty)
              Text(sessionError, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: profileVisibility,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(value: 'friends', child: Text('Friends Only')),
              ],
              onChanged:
                  privacyLoading
                      ? null
                      : (val) =>
                          setState(() => profileVisibility = val ?? 'public'),
              decoration: const InputDecoration(
                labelText: 'Profile Visibility',
              ),
            ),
            SwitchListTile(
              title: const Text(
                'Allow data sharing for analytics and improvements',
              ),
              value: dataSharing,
              onChanged:
                  privacyLoading
                      ? null
                      : (val) => setState(() => dataSharing = val),
            ),
            SwitchListTile(
              title: const Text('Receive email notifications'),
              value: emailNotifications,
              onChanged:
                  privacyLoading
                      ? null
                      : (val) => setState(() => emailNotifications = val),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: privacyLoading ? null : _updatePrivacySettings,
              child: Text(
                privacyLoading ? 'Updating...' : 'Update Privacy Settings',
              ),
            ),
            if (privacyMessage.isNotEmpty)
              Text(privacyMessage, style: const TextStyle(color: Colors.green)),
            if (privacyError.isNotEmpty)
              Text(privacyError, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
