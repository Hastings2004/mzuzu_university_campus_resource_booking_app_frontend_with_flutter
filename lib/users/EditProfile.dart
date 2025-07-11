import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/AuthPage.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/components/MyDrawer.dart';
import 'package:resource_booking_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final int userId;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required UserModel userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _physicalAddressController =
      TextEditingController();
  final TextEditingController _postalAddressController =
      TextEditingController();

  bool _isLoading = true;
  String _currentRole = 'user';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _physicalAddressController.dispose();
    _postalAddressController.dispose();
    super.dispose();
  }

  void logout() async {
    try {
      final res = await CallApi().getData('logout');
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Authpage()),
          );
        }
      } else {
        print("Logout failed: ${body['message']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logout failed: ${body['message'] ?? "Please try again."}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Exception during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out. Please check your connection.'),
          ),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await CallApi().getData('profile');
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        UserProfile user = UserProfile.fromJson(body['user']);
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _emailController.text = user.email;
        _currentRole = user.userType ?? 'user';
        _phoneController.text = user.phoneNumber ?? '';
        _idController.text = user.identityNumber ?? '';
        _districtController.text = user.district ?? '';
        _villageController.text = user.village ?? '';
        _physicalAddressController.text = user.physicalAddress ?? '';
        _postalAddressController.text = user.postalAddress ?? '';
      } else {
        String errorMessage = body['message'] ?? 'Failed to load user data.';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load user data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      // Additional client-side validation
      String? validationError = _validateFields();
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      print('Updating user with ID: ${widget.userId}');

      final data = {
        'phone': _phoneController.text.trim(),
        'identity_number': _idController.text.trim(),
        'district': _districtController.text.trim(),
        'village': _villageController.text.trim(),
        'physical_address': _physicalAddressController.text.trim(),
        'post_address': _postalAddressController.text.trim(),
      };

      print('Sending data: $data');

      try {
        final res = await CallApi().putData(
          data,
          'users/${widget.userId}/update',
        );
        final body = json.decode(res.body);

        print('Response status: ${res.statusCode}');
        print('Response body: $body');

        if (res.statusCode == 200 && body['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Profile Updated'),
                  content: const Text(
                    'Your profile has been updated successfully!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            ).then((_) {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        } else {
          String errorMessage = 'Failed to update profile.';

          // Handle validation errors (422 status code)
          if (res.statusCode == 422 && body['errors'] != null) {
            // Extract validation errors
            Map<String, dynamic> errors = body['errors'];
            List<String> errorMessages = [];

            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.cast<String>());
              }
            });

            errorMessage =
                errorMessages.isNotEmpty
                    ? errorMessages.join('\n')
                    : body['message'] ?? 'Validation failed.';
          } else {
            errorMessage = body['message'] ?? 'Failed to update profile.';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print("Error updating profile: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile. Please try again: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String? _validateFields() {
    // Check field lengths according to Laravel validation rules
    // Note: first_name, last_name, and email are non-editable, so we don't validate them here

    if (_phoneController.text.trim().length > 30) {
      return 'Phone number cannot exceed 30 characters';
    }

    if (_idController.text.trim().length > 255) {
      return 'Identity number cannot exceed 255 characters';
    }

    if (_districtController.text.trim().length > 255) {
      return 'District cannot exceed 255 characters';
    }

    if (_villageController.text.trim().length > 255) {
      return 'Village cannot exceed 255 characters';
    }

    // Check if required fields are not empty
    if (_phoneController.text.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (_districtController.text.trim().isEmpty) {
      return 'District is required';
    }

    if (_villageController.text.trim().isEmpty) {
      return 'Village is required';
    }

    if (_physicalAddressController.text.trim().isEmpty) {
      return 'Physical address is required';
    }

    if (_postalAddressController.text.trim().isEmpty) {
      return 'Postal address is required';
    }

    return null; // No validation errors
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        onSearchPressed: () {},
        isSearching: false,
      ),
      bottomNavigationBar: const Bottombar(),
      drawer: Mydrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Your Information',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstNameController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _lastNameController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          // Add more robust phone number validation if needed
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'Staff ID / Student ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        // Validator for specific ID format can be added here
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your district';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _villageController,
                        decoration: const InputDecoration(
                          labelText: 'Village',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your village';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _physicalAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Physical Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your physical address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _postalAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Postal Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your postal address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 15),

                      ListTile(
                        leading: const Icon(
                          Icons.verified_user,
                          color: Colors.blueGrey,
                        ),
                        title: Text('User Role ${_currentRole}'),
                        subtitle: Text(
                          _currentRole.isNotEmpty ? _currentRole : 'N/A',
                        ),
                        tileColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _updateProfile, // Disable button while loading
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              20,
                              148,
                              24,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
