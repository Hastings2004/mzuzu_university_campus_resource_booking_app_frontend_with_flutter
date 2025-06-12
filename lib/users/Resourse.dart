// import 'package:flutter/material.dart';
// import 'package:resource_booking_app/components/BottomBar.dart';
// import 'dart:convert'; // For JSON encoding/decoding
// import 'package:shared_preferences/shared_preferences.dart'; // For managing session

// import 'package:resource_booking_app/auth/Api.dart'; // Your custom API service
// import 'package:resource_booking_app/components/AppBar.dart';
// import 'package:resource_booking_app/models/resource_model.dart'; // Your custom resource model
// import 'package:resource_booking_app/users/Notification.dart';
// import 'package:resource_booking_app/users/ResourceDetails.dart'; // Ensure this uses ResourceModel
// import 'package:resource_booking_app/users/Booking.dart';
// import 'package:resource_booking_app/users/Home.dart';
// import 'package:resource_booking_app/users/Profile.dart';
// import 'package:resource_booking_app/users/Settings.dart';


// class ResourcesScreen extends StatefulWidget {
//   const ResourcesScreen({super.key});

//   @override
//   _ResourcesScreenState createState() => _ResourcesScreenState();
// }

// class _ResourcesScreenState extends State<ResourcesScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   bool _isSearching = false; // State to control search bar visibility
//   List<ResourceModel> _allResources = []; // To store all fetched resources
//   Future<List<ResourceModel>>? _resourcesFuture; // Future for fetching resources

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//     _resourcesFuture = _fetchResources(); // Initial fetch
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   // Fetches all resources from the API
//   Future<List<ResourceModel>> _fetchResources() async {
//     try {
//       final response = await CallApi().getData('resources'); // Adjust your API endpoint
//       final body = json.decode(response.body);

//       if (response.statusCode == 200 && body['success'] == true) {
//         List<dynamic> resourceJson = body['resources']; // Assuming 'resources' is the key in your JSON response
//         _allResources = resourceJson.map((json) => ResourceModel.fromJson(json)).toList();
//         return _allResources;
//       } else {
//         // Handle error message from API
//         throw Exception(body['message'] ?? 'Failed to load resources');
//       }
//     } catch (e) {
//       print('Error fetching resources: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load resources: $e')),
//         );
//       }
//       return []; // Return empty list on error
//     }
//   }

//   void _onSearchChanged() {
//     setState(() {
//       _searchQuery = _searchController.text.toLowerCase();
//     });
//   }

//   void _toggleSearch() {
//     setState(() {
//       _isSearching = !_isSearching;
//       if (!_isSearching) {
//         _searchController.clear();
//         _searchQuery = '';
//       }
//     });
//   }

//   void logout() async {
//     // Show a confirmation dialog
//     final bool confirmLogout = await showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Confirm Logout'),
//             content: const Text('Are you sure you want to log out?'),
//             actions: <Widget>[
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false), // User cancels
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.of(context).pop(true), // User confirms
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Optional: make logout button red
//                 child: const Text('Logout', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ) ??
//         false; 

//     if (confirmLogout) {
   
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.clear();

//       if (mounted) {
//         // Navigate to your login/auth screen and remove all previous routes
//         Navigator.of(context).pushNamedAndRemoveUntil(
//           '/',
//           (route) => false,
//         ); // Assuming '/' is your initial login route
       
//       }
//     }

//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: Bottombar(),
//       appBar: MyAppBar(
//         titleWidget: _isSearching
//             ? TextField(
//                 controller: _searchController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   hintText: 'Search by name, location, or description...',
//                   hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//                   border: InputBorder.none,
//                 ),
//               )
//             : const Text(
//                 "Resources",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//         onSearchPressed: _toggleSearch, // Pass the toggle function
//         isSearching: _isSearching, // Pass the current search state
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 color: Color.fromARGB(255, 20, 148, 24),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset("assets/images/logo.png", height: 50),
//                   const Text(
//                     'Mzuzu University',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const Text(
//                     'Campus Resource Booking',
//                     style: TextStyle(color: Colors.white, fontSize: 15),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               title: const Text('Home'),
//               leading: const Icon(Icons.home),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => Home()),
//                 );
//               },
//             ),
//             ListTile(
//               title: const Text('Profile'),
//               leading: const Icon(Icons.person),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfileScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               title: const Text('Resources'),
//               leading: const Icon(Icons.grid_view, color: Colors.blueAccent),
//               onTap: () {
//                 Navigator.pop(context); // Already on this screen, close drawer
//               },
//             ),
//             ListTile(
//               title: const Text('Bookings'),
//               leading: const Icon(Icons.book_online),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => BookingScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               title: const Text('Notifications'),
//               leading: const Icon(Icons.notifications),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const NotificationScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               title: const Text('Settings'),
//               leading: const Icon(Icons.settings),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const SettingsScreen()),
//                 );
//               },
//             ),
//             const Divider(), // Separator
//             ListTile(
//               title: const Text('Logout'),
//               leading: const Icon(Icons.logout, color: Colors.red),
//               onTap: logout,
//             ),
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//       body: FutureBuilder<List<ResourceModel>>(
//         future: _resourcesFuture, // Use the Future from initial fetch
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No resources available.'));
//           } else {
//             // Filter resources based on search query
//             final filteredResources = snapshot.data!.where((resource) {
//               if (_searchQuery.isEmpty) {
//                 return true; // Show all if search query is empty
//               }
//               final name = resource.name.toLowerCase();
//               final location = resource.location.toLowerCase();
//               final description = resource.description?.toLowerCase() ?? ''; // Include description in search

//               return name.contains(_searchQuery) ||
//                      location.contains(_searchQuery) ||
//                      description.contains(_searchQuery);
//             }).toList();

//             if (filteredResources.isEmpty && _searchQuery.isNotEmpty) {
//               return const Center(
//                 child: Text(
//                   'No matching resources found.',
//                   style: TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//               );
//             }

//             return ListView.builder(
//               itemCount: filteredResources.length,
//               padding: const EdgeInsets.all(8.0),
//               itemBuilder: (context, index) {
//                 final resource = filteredResources[index];
//                 String? imageUrl = resource.imageUrl;

//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Material(
//                     borderRadius: BorderRadius.circular(20),
//                     color: const Color.fromARGB(255, 255, 255, 255),
//                     elevation: 5, // Add a little shadow for better UI
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => 
//                             ResourceDetails(resource: resource)
//                           )
//                         );
//                       },
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(12.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   resource.name,
//                                   style: const TextStyle(
//                                     fontSize: 22,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.green,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Text(
//                                   'Location: ${resource.location}',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 5),
//                                  Text(
//                                   'Capacity: ${resource.capacity.toString()}',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 if (resource.status == "booked")
//                                   Text(
//                                     'Status: Booked',
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.red,
//                                     ),
//                                   )
//                                 else if (resource.status == "available")
//                                   Text(
//                                     'Status: Available',
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.green,
//                                     ),
//                                   )
//                                 else
//                                   Text(
//                                     'Status: ${resource.status}',
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.orange,
//                                     ),
//                                   ),
                                 
//                                 if (resource.description != null && resource.description!.isNotEmpty)
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 5.0),
//                                     child: Text(
//                                       resource.description!,
//                                       style: const TextStyle(
//                                         fontSize: 16,
//                                         color: Colors.black54,
//                                       ),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
/** import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date/time formatting

import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart'; // Assuming BottomBar is theme-aware
import 'package:resource_booking_app/models/resource_model.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/ResourceDetails.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Settings.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isSearchLoading = false;
  List<ResourceModel> _allResources = [];
  List<ResourceModel> _searchResults = []; // Now holds only resources from global search
  Future<List<ResourceModel>>? _resourcesFuture;
  Timer? _debounceTimer;

  // Global Search Parameters
  String _selectedSearchType = 'resources'; // 'resources', 'bookings', 'users'
  String _resourceTypeFilter = ''; // For resources search
  DateTime? _startTimeFilter; // For bookings search
  DateTime? _endTimeFilter; // For bookings search
  String _userIdFilter = ''; // For admin searching bookings/users
  bool _isAdmin = false; // Placeholder, set this based on user role

  // Define resource types for the dropdown (from previous context)
  final List<String> _resourceTypes = [
    'Meeting Room', 'Projector', 'Vehicle', 'Lab PC', 'Auditorium', 'Conference Hall',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _resourcesFuture = _fetchResources();
    _checkUserRole(); // Check user role on init
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = json.decode(userJson);
      setState(() {
        _isAdmin = user['user_type'] == 'admin';
      });
    }
  }

  Future<List<ResourceModel>> _fetchResources() async {
    try {
      final response = await CallApi().getData('resources');
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        List<dynamic> resourceJson = body['resources'];
        _allResources = resourceJson.map((json) => ResourceModel.fromJson(json)).toList();
        return _allResources;
      } else {
        throw Exception(body['message'] ?? 'Failed to load resources');
      }
    } catch (e) {
      print('Error fetching resources: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load resources: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return [];
    }
  }

  // Consolidated Global Search API call
  Future<void> _performGlobalSearch(String query) async {
  // Add a check here for the 'query' parameter
  if (query.isEmpty) { // Also consider if other filters are applied without a query
    setState(() {
      _searchResults = [];
      _isSearchLoading = false;
    });
    // Optionally show a message to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a search term.'),
          backgroundColor: Theme.of(context).colorScheme.tertiary, // Use a neutral color
        ),
      );
    }
    return; // Exit the function if query is empty
  }

  setState(() {
    _isSearchLoading = true;
  });

  try {
    final Map<String, String> queryParams = {
      'query': query, // Ensure 'query' is always present when making the call
    };

      // Add type-specific filters based on _selectedSearchType
      if (_selectedSearchType == 'resources') {
        queryParams['search_type'] = 'resources';
        if (_resourceTypeFilter.isNotEmpty) {
          queryParams['resource_type'] = _resourceTypeFilter;
        }
      } else if (_selectedSearchType == 'bookings') {
        queryParams['search_type'] = 'bookings';
        if (_startTimeFilter != null) {
          queryParams['start_time'] = _startTimeFilter!.toIso8601String();
        }
        if (_endTimeFilter != null) {
          queryParams['end_time'] = _endTimeFilter!.toIso8601String();
        }
        if (_isAdmin && _userIdFilter.isNotEmpty) {
          queryParams['user_id'] = _userIdFilter;
        }
      } else if (_selectedSearchType == 'users' && _isAdmin) {
        queryParams['search_type'] = 'users';
        if (_userIdFilter.isNotEmpty) {
          queryParams['user_id'] = _userIdFilter;
        }
      }

      final response = await CallApi().searchData('search/global', 'POST', body: queryParams);
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        List<ResourceModel> newSearchResults = [];
        if (body['results_by_type'] != null && body['results_by_type']['resources'] != null) {
          // Only process resource results for this screen
          List<dynamic> resourceResultsJson = body['results_by_type']['resources'];
          newSearchResults = resourceResultsJson
              .map((item) => ResourceModel.fromSearchData(item)) // Use fromSearchData if structure differs slightly
              .toList();
        }

        setState(() {
          _searchResults = newSearchResults;
          _isSearchLoading = false;
        });
      } else {
        throw Exception(body['message'] ?? 'Search failed');
      }
    } catch (e) {
      print('Error performing global search: $e');
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performGlobalSearch(query);
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _searchResults = [];
        _isSearchLoading = false;
        // Reset search filters when closing search bar
        _selectedSearchType = 'resources';
        _resourceTypeFilter = '';
        _startTimeFilter = null;
        _endTimeFilter = null;
        _userIdFilter = '';
      }
    });
  }

  void _showSearchOptions() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext to avoid conflicts
        return StatefulBuilder( // Use StatefulBuilder to update dialog content dynamically
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(
                'Search Options',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Type Selector
                    DropdownButtonFormField<String>(
                      value: _selectedSearchType,
                      decoration: InputDecoration(
                        labelText: 'Search For',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'resources', child: Text('Resources')),
                        const DropdownMenuItem(value: 'bookings', child: Text('Bookings')),
                        if (_isAdmin)
                          const DropdownMenuItem(value: 'users', child: Text('Users')),
                      ],
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          _selectedSearchType = newValue!;
                          // Clear type-specific filters when changing search type
                          _resourceTypeFilter = '';
                          _startTimeFilter = null;
                          _endTimeFilter = null;
                          _userIdFilter = '';
                        });
                      },
                      dropdownColor: Theme.of(context).colorScheme.surfaceVariant, // For dark mode
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),

                    // Resource Type Filter (conditional for resources)
                    if (_selectedSearchType == 'resources')
                      DropdownButtonFormField<String>(
                        value: _resourceTypeFilter.isEmpty ? null : _resourceTypeFilter,
                        decoration: InputDecoration(
                          labelText: 'Resource Type',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All Types')),
                          ..._resourceTypes.map((type) =>
                              DropdownMenuItem(value: type, child: Text(type))),
                        ],
                        onChanged: (String? newValue) {
                          setStateInDialog(() {
                            _resourceTypeFilter = newValue!;
                          });
                        },
                        dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    const SizedBox(height: 16),

                    // Start/End Time Pickers (conditional for bookings)
                    if (_selectedSearchType == 'bookings') ...[
                      ListTile(
                        title: Text(
                          _startTimeFilter == null
                              ? 'Select Start Time'
                              : 'Start: ${DateFormat('yyyy-MM-dd HH:mm').format(_startTimeFilter!)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _startTimeFilter ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            final TimeOfDay? timePicked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_startTimeFilter ?? DateTime.now()),
                            );
                            if (timePicked != null) {
                              setStateInDialog(() {
                                _startTimeFilter = DateTime(
                                  picked.year, picked.month, picked.day,
                                  timePicked.hour, timePicked.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                      ListTile(
                        title: Text(
                          _endTimeFilter == null
                              ? 'Select End Time'
                              : 'End: ${DateFormat('yyyy-MM-dd HH:mm').format(_endTimeFilter!)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _endTimeFilter ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            final TimeOfDay? timePicked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_endTimeFilter ?? DateTime.now()),
                            );
                            if (timePicked != null) {
                              setStateInDialog(() {
                                _endTimeFilter = DateTime(
                                  picked.year, picked.month, picked.day,
                                  timePicked.hour, timePicked.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ],

                    // User ID Filter (conditional for admin on bookings/users)
                    if (_isAdmin && (_selectedSearchType == 'bookings' || _selectedSearchType == 'users'))
                      TextFormField(
                        initialValue: _userIdFilter,
                        decoration: InputDecoration(
                          labelText: 'User ID (Admin)',
                          hintText: 'Optional: Enter User ID',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        onChanged: (value) {
                          setStateInDialog(() {
                            _userIdFilter = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Apply filters and re-run search if query exists
                    if (_searchQuery.isNotEmpty || _resourceTypeFilter.isNotEmpty || _startTimeFilter != null || _endTimeFilter != null || _userIdFilter.isNotEmpty) {
                      _performGlobalSearch(_searchQuery);
                    }
                    Navigator.pop(dialogContext); // Use dialogContext to dismiss the dialog
                  },
                  child: Text('Apply', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                TextButton(
                  onPressed: () {
                    setStateInDialog(() {
                      // Reset filters in dialog state
                      _selectedSearchType = 'resources';
                      _resourceTypeFilter = '';
                      _startTimeFilter = null;
                      _endTimeFilter = null;
                      _userIdFilter = '';
                    });
                    // You might want to also clear main screen search results or re-fetch all
                    // For now, it just resets the dialog filters. The next search will use new filters.
                  },
                  child: Text('Reset Filters', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void logout() async {
    final bool confirmLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                child: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.surface,
            titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20),
            contentTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ) ??
        false;

    if (confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  Widget _buildSearchResults() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isSearchLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(fontSize: 16, color: colorScheme.onBackground),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No matching resources found.',
              style: TextStyle(fontSize: 18, color: colorScheme.onBackground),
            ),
            const SizedBox(height: 8),
            Text(
              'Searched for: "$_searchQuery"',
              style: TextStyle(fontSize: 14, color: colorScheme.onBackground),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _searchResults = [];
                  _selectedSearchType = 'resources';
                  _resourceTypeFilter = '';
                  _startTimeFilter = null;
                  _endTimeFilter = null;
                  _userIdFilter = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchQuery.isEmpty) {
        // If search bar is active but no query and no results, show a hint
        return Center(
            child: Text(
                'Enter keywords or apply filters to search.',
                style: TextStyle(fontSize: 16, color: colorScheme.onBackground.withOpacity(0.7)),
                textAlign: TextAlign.center,
            ),
        );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final resource = _searchResults[index];
        return _buildResourceCard(resource);
      },
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceVariant, // Card background for dark mode
        elevation: 5,
        shadowColor: colorScheme.shadow,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceDetails(resource: resource),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search result highlight indicator
              if (_isSearching && _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary, // Primary color for highlight
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Search Result',
                    style: TextStyle(
                      color: colorScheme.onPrimary, // Text color on primary background
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary, // Green for resource name
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (resource.type.isNotEmpty)
                      Text(
                        'Type: ${resource.type}',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (resource.location != null && resource.location!.isNotEmpty)
                      Text(
                        'Location: ${resource.location}',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (resource.capacity != null && resource.capacity! > 0)
                      Text(
                        'Capacity: ${resource.capacity.toString()}',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (resource.status == "booked")
                      Text(
                        'Status: Booked',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.error, // Red for booked status
                        ),
                      )
                    else if (resource.status == "available")
                      Text(
                        'Status: Available',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.tertiary, // Green for available status
                        ),
                      )
                    else
                      Text(
                        'Status: ${resource.status}',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurfaceVariant, // A neutral color for other status
                        ),
                      ),
                    if (resource.description != null && resource.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          resource.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.7), // Less prominent text
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      bottomNavigationBar: const Bottombar(), // Ensure Bottombar uses theme
      appBar: MyAppBar(
        titleWidget: _isSearching
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colorScheme.onPrimary), // Text on app bar color
                      decoration: InputDecoration(
                        hintText: 'Search resources...',
                        hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.7)),
                        border: InputBorder.none,
                        suffixIcon: _isSearchLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune, color: colorScheme.onPrimary), // Icon on app bar color
                    onPressed: _showSearchOptions,
                    tooltip: 'Search Options',
                  ),
                ],
              )
            : Text(
                "Resources",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary, // Text on app bar color
                ),
              ),
        onSearchPressed: _toggleSearch,
        isSearching: _isSearching,
      ),
      drawer: Drawer(
        backgroundColor: colorScheme.surface, // Drawer background
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primary, // Drawer header background (Mzuzu University green)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/logo.png", height: 50),
                  Text(
                    'Mzuzu University',
                    style: TextStyle(
                      color: colorScheme.onPrimary, // Text on primary background
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Campus Resource Booking',
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 15),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Home', style: TextStyle(color: colorScheme.onSurface)),
              leading: Icon(Icons.home, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Home()),
                );
              },
            ),
            ListTile(
              title: Text('Profile', style: TextStyle(color: colorScheme.onSurface)),
              leading: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Resources', style: TextStyle(color: colorScheme.primary)), // Highlight current screen
              leading: Icon(Icons.grid_view, color: colorScheme.primary),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Bookings', style: TextStyle(color: colorScheme.onSurface)),
              leading: Icon(Icons.book_online, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Notifications', style: TextStyle(color: colorScheme.onSurface)),
              leading: Icon(Icons.notifications, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Settings', style: TextStyle(color: colorScheme.onSurface)),
              leading: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            Divider(color: colorScheme.outline), // Divider color
            ListTile(
              title: Text('Logout', style: TextStyle(color: colorScheme.error)),
              leading: Icon(Icons.logout, color: colorScheme.error),
              onTap: logout,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      body: _isSearching
          ? _buildSearchResults() // Show search results or instructions when search is active
          : FutureBuilder<List<ResourceModel>>(
              future: _resourcesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: colorScheme.error)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No resources available.', style: TextStyle(color: colorScheme.onBackground)));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final resource = snapshot.data![index];
                      return _buildResourceCard(resource);
                    },
                  );
                }
              },
            ),
    );
  }
} */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For managing session

import 'package:resource_booking_app/auth/Api.dart'; // Your custom API service
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/models/resource_model.dart'; // Your custom resource model
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/ResourceDetails.dart'; // Ensure this uses ResourceModel
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Settings.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false; // State to control search bar visibility
  bool _isSearchLoading = false; // Loading state for search
  List<ResourceModel> _allResources = []; // To store all fetched resources
  List<ResourceModel> _searchResults = []; // To store search results
  Future<List<ResourceModel>>? _resourcesFuture; // Future for fetching resources
  String _selectedSearchField = 'name'; // Default search field
  Timer? _debounceTimer; // For debouncing search requests

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _resourcesFuture = _fetchResources(); // Initial fetch
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Fetches all resources from the API
  Future<List<ResourceModel>> _fetchResources() async {
    try {
      final response = await CallApi().getData('resources'); // Adjust your API endpoint
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        List<dynamic> resourceJson = body['resources']; // Assuming 'resources' is the key in your JSON response
        _allResources = resourceJson.map((json) => ResourceModel.fromJson(json)).toList();
        return _allResources;
      } else {
        // Handle error message from API
        throw Exception(body['message'] ?? 'Failed to load resources');
      }
    } catch (e) {
      print('Error fetching resources: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resources: $e')),
        );
      }
      return []; // Return empty list on error
    }
  }

  // Binary search API call
  Future<void> _performBinarySearch(String query) async {
    if (query.isEmpty || query.length < 1) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    try {
      final requestBody = {
        'type': 'resources',
        'query': query,
        'field': _selectedSearchField,
      };

      final response = await CallApi().postData(requestBody, 'search');
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> resultsJson = body['results'] ?? [];
        List<ResourceModel> searchResults = [];
        
        for (var result in resultsJson) {
          // Extract the actual resource data from the search result
          var resourceData = result['data'];
          // Convert back to ResourceModel (you may need to adjust this based on your model structure)
          ResourceModel resource = ResourceModel(
            id: result['id'],
            name: resourceData['name'] ?? '',
            description: resourceData['description'] ?? '',
            status: resourceData['status'] ?? 'available',
            capacity: 0, // You may need to add capacity to your search result format
            location: '', // You may need to add location to your search result format
            imageUrl: null, // You may need to add imageUrl to your search result format
            // Add other fields as needed
          );
          searchResults.add(resource);
        }

        setState(() {
          _searchResults = searchResults;
          _isSearchLoading = false;
        });
      } else {
        throw Exception(body['message'] ?? 'Search failed');
      }
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  // Multi-field search API call
  Future<void> _performMultiFieldSearch(String query) async {
    if (query.isEmpty || query.length < 1) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    try {
      final requestBody = {
        'type': 'resources',
        'query': query,
        'fields': ['name', 'type', 'description'], // Search across multiple fields
      };

      final response = await CallApi().postData(requestBody, 'search/multi-field');
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> resultsJson = body['results'] ?? [];
        List<ResourceModel> searchResults = [];
        
        for (var result in resultsJson) {
          var resourceData = result['data'];
          ResourceModel resource = ResourceModel(
            id: result['id'],
            name: resourceData['name'] ?? '',            
            description: resourceData['description'] ?? '',
            status: resourceData['status'] ?? 'available',
            capacity: 0, // Add to your backend response if needed
            location: '', // Add to your backend response if needed
            imageUrl: null, // Add to your backend response if needed
          );
          searchResults.add(resource);
        }

        setState(() {
          _searchResults = searchResults;
          _isSearchLoading = false;
        });
      } else {
        throw Exception(body['message'] ?? 'Multi-field search failed');
      }
    } catch (e) {
      print('Error performing multi-field search: $e');
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Multi-field search failed: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query.toLowerCase();
    });

    // Debounce the search to avoid too many API calls
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        // Use multi-field search for better results
        _performMultiFieldSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearchLoading = false;
        });
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _searchResults = [];
        _isSearchLoading = false;
      }
    });
  }

  // Show search options dialog
  void _showSearchOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Search by:'),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedSearchField,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Resource Name')),
                  DropdownMenuItem(value: 'type', child: Text('Resource Type')),
                  DropdownMenuItem(value: 'description', child: Text('Description')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSearchField = newValue;
                    });
                    Navigator.pop(context);
                    // Re-perform search with new field if there's a query
                    if (_searchQuery.isNotEmpty) {
                      _performBinarySearch(_searchQuery);
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void logout() async {
    // Show a confirmation dialog
    final bool confirmLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // User cancels
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true), // User confirms
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Optional: make logout button red
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false; 

    if (confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to your login/auth screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        ); // Assuming '/' is your initial login route
      }
    }
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No matching resources found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Searched for: "$_searchQuery"',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _searchResults = [];
                });
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final resource = _searchResults[index];
        return _buildResourceCard(resource);
      },
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: const Color.fromARGB(255, 255, 255, 255),
        elevation: 5,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceDetails(resource: resource)
              )
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search result highlight indicator
              if (_isSearching && _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Search Result',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (resource.location!.isNotEmpty)
                      Text(
                        'Location: ${resource.location}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                   
                    const SizedBox(height: 5),
                    if (resource.capacity! > 0)
                      Text(
                        'Capacity: ${resource.capacity.toString()}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (resource.status == "booked")
                      const Text(
                        'Status: Booked',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      )
                    else if (resource.status == "available")
                      const Text(
                        'Status: Available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      )
                    else
                      Text(
                        'Status: ${resource.status}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.orange,
                        ),
                      ),
                    if (resource.description != null && resource.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          resource.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Bottombar(),
      appBar: MyAppBar(
        titleWidget: _isSearching
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search resources...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        suffixIcon: _isSearchLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: _showSearchOptions,
                    tooltip: 'Search Options',
                  ),
                ],
              )
            : const Text(
                "Resources",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        onSearchPressed: _toggleSearch,
        isSearching: _isSearching,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/logo.png", height: 50),
                  const Text(
                    'Mzuzu University',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
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
                  MaterialPageRoute(builder: (context) => Home()),
                );
              },
            ),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Resources'),
              leading: const Icon(Icons.grid_view, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context); // Already on this screen, close drawer
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
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: logout,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      body: _isSearching && _searchQuery.isNotEmpty
          ? _buildSearchResults() // Show search results when searching
          : FutureBuilder<List<ResourceModel>>(
              future: _resourcesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No resources available.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final resource = snapshot.data![index];
                      return _buildResourceCard(resource);
                    },
                  );
                }
              },
            ),
    );
  }
}