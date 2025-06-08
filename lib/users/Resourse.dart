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
                    if (resource.location.isNotEmpty)
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