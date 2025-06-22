import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resource_booking_app/users/user_issues.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart'; 
import 'package:resource_booking_app/models/resource_model.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/ResourceDetails.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/Home.dart';
import 'package:resource_booking_app/users/Profile.dart';
import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/History.dart';

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
  List<ResourceModel> _searchResults = []; 
  Future<List<ResourceModel>>? _resourcesFuture;
  Timer? _debounceTimer;

  // Global Search Parameters
  String _selectedSearchType = 'resources'; 
  String _resourceTypeFilter = ''; 
  DateTime? _startTimeFilter; 
  DateTime? _endTimeFilter; 
  String _userIdFilter = ''; 
  bool _isAdmin = false; 

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
    // Determine if any filters are applied (including an empty main query)
    final bool hasFiltersApplied = _resourceTypeFilter.isNotEmpty || 
                                  _startTimeFilter != null || 
                                  _endTimeFilter != null || 
                                  _userIdFilter.isNotEmpty;

    // If query is empty AND no other filters are applied, don't send the request.
    if (query.isEmpty && !hasFiltersApplied) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a search term or apply filters.'),
            backgroundColor: Theme.of(context).colorScheme.tertiary, 
          ),
        );
      }
      return; 
    }

    setState(() {
      _isSearchLoading = true;
    });

    try {
      // Use dynamic for values in queryParams as they can be String or DateTime objects (converted to String)
      final Map<String, dynamic> queryParams = {}; 

      // ONLY add 'query' if it's not empty
      if (query.isNotEmpty) {
        queryParams['query'] = query;
      }

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

      // Debugging: Print what you're sending
      print('Sending search request with params: $queryParams');

      // Convert all values in queryParams to String for the API call
      final Map<String, String> stringParams = queryParams.map((key, value) => MapEntry(key, value.toString()));
      final response = await CallApi().searchData('search/global?${Uri(queryParameters: stringParams).query}', 'GET');
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        List<ResourceModel> newSearchResults = [];
        if (body['results_by_type'] != null && body['results_by_type']['resources'] != null) {
          // Only process resource results for this screen
          List<dynamic> resourceResultsJson = body['results_by_type']['resources'];
          newSearchResults = resourceResultsJson
              .map((item) => ResourceModel.fromSearchData(item)) 
              .toList();
        }

        setState(() {
          _searchResults = newSearchResults;
          _isSearchLoading = false;
        });
      } else {
        // If the backend returns a 422, it will have validation errors in the body
        String errorMessage = body['message'] ?? 'Search failed.';
        if (body['errors'] != null) {
          // You can parse specific validation errors here if needed
          // Assuming 'errors' is a Map<String, dynamic> where values are lists of strings
          List<String> errorMessages = [];
          (body['errors'] as Map<String, dynamic>).forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else if (value is String) {
              errorMessages.add(value);
            }
          });
          if (errorMessages.isNotEmpty) {
            errorMessage += "\n${errorMessages.join(', ')}";
          }
        }
        throw Exception(errorMessage);
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
      // Always call _performGlobalSearch with the current _searchQuery.
      // The _performGlobalSearch method now handles the empty query/no filters logic.
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
        _selectedSearchType = 'resources'; // Reset filter values to initial state
        _resourceTypeFilter = '';
        _startTimeFilter = null;
        _endTimeFilter = null;
        _userIdFilter = '';
      } else {
        
      }
    });
  }

  void _showSearchOptions() {
   
    String tempSelectedSearchType = _selectedSearchType;
    String tempResourceTypeFilter = _resourceTypeFilter;
    DateTime? tempStartTimeFilter = _startTimeFilter;
    DateTime? tempEndTimeFilter = _endTimeFilter;
    String tempUserIdFilter = _userIdFilter;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { 
        return StatefulBuilder( 
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
                      value: tempSelectedSearchType, // Use temp state
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
                          tempSelectedSearchType = newValue!;
                          // Clear type-specific filters when changing search type in dialog
                          tempResourceTypeFilter = '';
                          tempStartTimeFilter = null;
                          tempEndTimeFilter = null;
                          tempUserIdFilter = '';
                        });
                      },
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest, // For dark mode
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),

                    // Resource Type Filter (conditional for resources)
                    if (tempSelectedSearchType == 'resources')
                      DropdownButtonFormField<String>(
                        value: tempResourceTypeFilter.isEmpty ? null : tempResourceTypeFilter,
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
                            tempResourceTypeFilter = newValue!;
                          });
                        },
                        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    const SizedBox(height: 16),

                    // Start/End Time Pickers (conditional for bookings)
                    if (tempSelectedSearchType == 'bookings') ...[
                      ListTile(
                        title: Text(
                          tempStartTimeFilter == null
                              ? 'Select Start Time'
                              : 'Start: ${DateFormat('yyyy-MM-dd HH:mm').format(tempStartTimeFilter!)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempStartTimeFilter ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            final TimeOfDay? timePicked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(tempStartTimeFilter ?? DateTime.now()),
                            );
                            if (timePicked != null) {
                              setStateInDialog(() {
                                tempStartTimeFilter = DateTime(
                                  pickedDate.year, pickedDate.month, pickedDate.day,
                                  timePicked.hour, timePicked.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                      ListTile(
                        title: Text(
                          tempEndTimeFilter == null
                              ? 'Select End Time'
                              : 'End: ${DateFormat('yyyy-MM-dd HH:mm').format(tempEndTimeFilter!)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempEndTimeFilter ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            final TimeOfDay? timePicked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(tempEndTimeFilter ?? DateTime.now()),
                            );
                            if (timePicked != null) {
                              setStateInDialog(() {
                                tempEndTimeFilter = DateTime(
                                  pickedDate.year, pickedDate.month, pickedDate.day,
                                  timePicked.hour, timePicked.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ],

                    // User ID Filter (conditional for admin on bookings/users)
                    if (_isAdmin && (tempSelectedSearchType == 'bookings' || tempSelectedSearchType == 'users'))
                      TextFormField(
                        initialValue: tempUserIdFilter,
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
                            tempUserIdFilter = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Apply filters to main state and trigger search
                    setState(() {
                      _selectedSearchType = tempSelectedSearchType;
                      _resourceTypeFilter = tempResourceTypeFilter;
                      _startTimeFilter = tempStartTimeFilter;
                      _endTimeFilter = tempEndTimeFilter;
                      _userIdFilter = tempUserIdFilter;
                    });
                    // Re-run search with potentially updated filters (and current _searchQuery)
                    _performGlobalSearch(_searchQuery);
                    Navigator.pop(dialogContext); // Dismiss the dialog
                  },
                  child: Text('Apply', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                TextButton(
                  onPressed: () {
                    setStateInDialog(() {
                      // Reset filters in dialog's temporary state
                      tempSelectedSearchType = 'resources';
                      tempResourceTypeFilter = '';
                      tempStartTimeFilter = null;
                      tempEndTimeFilter = null;
                      tempUserIdFilter = '';
                    });
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
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
            ),
          ],
        ),
      );
    }

    // If search is active (search bar is shown) and no results, and either query or filters are present
    if (_isSearching && _searchResults.isEmpty && 
        (_searchQuery.isNotEmpty || _resourceTypeFilter.isNotEmpty || 
         _startTimeFilter != null || _endTimeFilter != null || _userIdFilter.isNotEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No matching results found for your search criteria.',
              style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
              textAlign: TextAlign.center,
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
                  _isSearching = false; // Close search bar as well
                });
                _resourcesFuture = _fetchResources(); // Re-fetch all original resources
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
              child: const Text('Clear Search & Filters'),
            ),
          ],
        ),
      );
    }

    // If search bar is active but no query and no filters, show a hint
    if (_isSearching && _searchResults.isEmpty && _searchQuery.isEmpty && 
        _resourceTypeFilter.isEmpty && _startTimeFilter == null && _endTimeFilter == null && _userIdFilter.isEmpty) {
        return Center(
            child: Text(
                'Enter keywords or apply filters to search.',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
            ),
        );
    }

    // If search is not active, or search is active and has results, display results
    if (_isSearching && _searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _searchResults.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final resource = _searchResults[index];
          return _buildResourceCard(resource);
        },
      );
    } 
    // If not searching, display all resources
    else if (!_isSearching) {
      return FutureBuilder<List<ResourceModel>>(
        future: _resourcesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: colorScheme.error)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No resources available.',
                style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
              ),
            );
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
      );
    }

    return const SizedBox.shrink();
  }


  Widget _buildResourceCard(ResourceModel resource) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceContainerHighest, 
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
              if (_isSearching && (_searchQuery.isNotEmpty || _resourceTypeFilter.isNotEmpty || _startTimeFilter != null || _endTimeFilter != null || _userIdFilter.isNotEmpty))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary, 
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Search Result',
                    style: TextStyle(
                      color: colorScheme.onPrimary, 
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
                        color: colorScheme.primary, 
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
                    if (resource.location.isNotEmpty)
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
                          color: colorScheme.onSurfaceVariant,
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
              title: const Text('Report Issue'),
              leading: const Icon(Icons.report),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IssueManagementScreen()));
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
            ListTile(
              title: Text('History', style: TextStyle(color: colorScheme.onSurface)),
              leading: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Logout', style: TextStyle(color: colorScheme.error)),
              leading: Icon(Icons.logout, color: colorScheme.error),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: _buildSearchResults(),
    );
  }
}