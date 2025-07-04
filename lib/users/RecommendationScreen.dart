
import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/Booking.dart';
import 'package:resource_booking_app/users/History.dart';
import 'package:resource_booking_app/users/Notification.dart';
import 'package:resource_booking_app/users/Profile.dart'; 
import 'package:resource_booking_app/users/ResourceDetails.dart';
import 'package:resource_booking_app/models/resource_model.dart'; // Make sure this path is correct
import 'package:intl/intl.dart'; // For date formatting
import 'package:resource_booking_app/users/Resourse.dart';
import 'dart:convert';

import 'package:resource_booking_app/users/Settings.dart';
import 'package:resource_booking_app/users/user_issues.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // State for different recommendation types
  List<dynamic> _personalizedRecommendations = [];
  Map<String, dynamic>? _userPreferences;
  List<dynamic> _popularResources = [];
  List<dynamic> _trendingResources = [];
  List<dynamic> _recentlyBooked = [];

  // Time-based recommendations
  DateTime? _preferredTime;
  List<dynamic> _timeBasedRecommendations = [];
  bool _isTimeLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all recommendation types in parallel
      await Future.wait([
        _loadPersonalizedRecommendations(),
        _loadUserPreferences(),
        _loadPopularResources(),
        _loadTrendingResources(),
        _loadRecentlyBookedResources(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load recommendations: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPersonalizedRecommendations() async {
    try {
      var res = await CallApi().getData('recommendations/resources?limit=8');
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _personalizedRecommendations = body['recommendations'] ?? [];
        });
      } else {
        // Handle API specific error messages
        _error = body['message'] ?? 'Failed to load personalized recommendations.';
      }
    } catch (e) {
      debugPrint('Error loading personalized recommendations: $e');
      // If there's an existing error, append or set a new one if null
      if (_error == null) _error = 'Network error: Could not load personalized recommendations.';
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      var res = await CallApi().getData('recommendations/user/preferences');
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _userPreferences = body['preferences'];
        });
      } else {
        _error = body['message'] ?? 'Failed to load user preferences.';
      }
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      if (_error == null) _error = 'Network error: Could not load user preferences.';
    }
  }

  Future<void> _loadPopularResources() async {
    try {
      var res = await CallApi().getData('resources?limit=6&sort=popularity');
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _popularResources = body['data'] ?? [];
        });
      } else {
        _error = body['message'] ?? 'Failed to load popular resources.';
      }
    } catch (e) {
      debugPrint('Error loading popular resources: $e');
      if (_error == null) _error = 'Network error: Could not load popular resources.';
    }
  }

  Future<void> _loadTrendingResources() async {
    try {
      var res = await CallApi().getData('resources-trending');
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _trendingResources = body['resources'] ?? [];
        });
      } else {
        _error = body['message'] ?? 'Failed to load trending resources.';
      }
    } catch (e) {
      debugPrint('Error loading trending resources: $e');
      if (_error == null) _error = 'Network error: Could not load trending resources.';
    }
  }

  Future<void> _loadRecentlyBookedResources() async {
    try {
      var res = await CallApi().getData('resources-recently-booked');
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _recentlyBooked = body['resources'] ?? body['bookings'] ?? [];
        });
      } else {
        _error = body['message'] ?? 'Failed to load recently booked resources.';
      }
    } catch (e) {
      debugPrint('Error loading recently booked resources: $e');
      if (_error == null) _error = 'Network error: Could not load recently booked resources.';
    }
  }

  Future<void> _handleTimeBasedSearch() async {
    if (_preferredTime == null) {
      setState(() {
        _error = 'Please select a preferred time to search.';
      });
      return;
    }

    setState(() {
      _isTimeLoading = true;
      _error = null; // Clear previous errors for this specific search
      _timeBasedRecommendations = []; // Clear previous results
    });

    try {
      var res = await CallApi().getData(
        'recommendations/resources/time-based?preferred_time=${_preferredTime!.toIso8601String()}&limit=6',
      );
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _timeBasedRecommendations = body['recommendations'] ?? [];
          if (_timeBasedRecommendations.isEmpty) {
            _error = 'No resources found for the selected time.';
          }
        });
      } else {
        setState(() {
          _error = body['message'] ?? 'Failed to get time-based recommendations.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: Could not get time-based recommendations. Please try again.';
      });
    } finally {
      setState(() {
        _isTimeLoading = false;
      });
    }
  }

  String _getRecommendationIcon(String category) {
    const icons = {
      'classrooms': '🏫',
      'ict_labs': '💻',
      'science_labs': '🧪',
      'auditorium': '🎭',
      'sports': '⚽',
      'cars': '🚗',
      'meeting_rooms': '🗓️',
      'laboratories': '🔬',
      'library': '📚',
      'gym': '💪',
      'conference_room': '🤝',
      'lecture_hall': '🎓',
    };
    return icons[category.toLowerCase()] ?? '📋';
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildResourceCard(
    dynamic resource, {
    double? score,
    List<dynamic>? reasons,
    bool showScore = false,
  }) {
    if (resource == null) return const SizedBox.shrink();

    final resourceData = resource['resource'] ?? resource;
    final String name = resourceData['name'] ?? 'Unknown Resource';
    final String location = resourceData['location'] ?? 'N/A';
    final int? capacity = resourceData['capacity'];
    final String category = resourceData['type'] ?? resourceData['category'] ?? 'Unknown';

    // Prioritize image URLs from different possible keys
    String? imageUrl;
    if (resourceData['image_url'] != null && resourceData['image_url'].isNotEmpty) {
      imageUrl = resourceData['image_url'];
    } else if (resourceData['image'] != null && resourceData['image'].isNotEmpty) {
      imageUrl = resourceData['image'];
    } else if (resourceData['photo'] != null && resourceData['photo'].isNotEmpty) {
      imageUrl = resourceData['photo'];
    } else if (resourceData['photo_url'] != null && resourceData['photo_url'].isNotEmpty) {
      imageUrl = resourceData['photo_url'];
    } else if (resourceData['image_path'] != null && resourceData['image_path'].isNotEmpty) {
      imageUrl = resourceData['image_path'];
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Adjusted horizontal margin for full width in list
      clipBehavior: Clip.antiAlias, // Ensures content respects card borders
      child: InkWell(
        onTap: () {
          final resourceModel = ResourceModel(
            id: resourceData['id'],
            name: name,
            description: resourceData['description'] ?? '',
            location: location,
            capacity: capacity,
            imageUrl: imageUrl,
            type: category,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceDetails(
                resource: resourceModel,
                resourceId: resourceData['id'], // Pass the actual ID
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder with error handling
            Container(
              height: 180, // Increased height for single-column view
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _getRecommendationIcon(category),
                              style: const TextStyle(fontSize: 40),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _getRecommendationIcon(category),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
            ),
            Padding( // No need for Expanded around this padding since it's in a Column directly
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18, // Slightly larger font for single column
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // Limit name to 2 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis if it overflows
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded( 
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14, 
                            color: Colors.grey,
                          ),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${capacity ?? 'N/A'} people',
                        style: const TextStyle(
                          fontSize: 14, // Slightly larger font for single column
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (showScore && score != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(score * 100).round()}% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Slightly larger font for single column
                        ),
                      ),
                    ),
                  ],
                  if (reasons != null && reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Why recommended:',
                      style: TextStyle(
                        fontSize: 12, // Slightly larger font for single column
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (reasons).take(3).map((reason) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            reason.toString(),
                            style: const TextStyle(
                              fontSize: 12, // Slightly larger font for single column
                              color: Colors.black54,
                            ),
                            maxLines: 1, // Ensure reason tags don't overflow
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- User Preferences Display ---
  Widget _buildUserPreferences() {
    if (_userPreferences == null || _userPreferences!.isEmpty) {
      return _buildEmptyState(
          'No booking history available to analyze patterns.');
    }

    // Check if there's any actual preference data to display
    final bool hasFavoriteCategories = _userPreferences!['favorite_categories'] != null &&
        (_userPreferences!['favorite_categories'] as List).isNotEmpty;
    final bool hasPreferredTimes = _userPreferences!['preferred_times'] != null &&
        (_userPreferences!['preferred_times'] as List).isNotEmpty;
    final bool hasAverageCapacity = _userPreferences!['average_capacity'] != null;

    if (!hasFavoriteCategories && !hasPreferredTimes && !hasAverageCapacity) {
      return _buildEmptyState('No specific booking patterns detected yet. Book resources to see your patterns here!');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFavoriteCategories) ...[
            const Text(
              'Favorite Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_userPreferences!['favorite_categories'] as List)
                  .map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Keep row content compact
                    children: [
                      Text(
                        _getRecommendationIcon(cat['category'] ?? 'unknown'),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible( // Ensures text wraps/truncates
                        child: Text(
                          cat['category'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cat['percentage'] ?? 0}%',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (hasPreferredTimes) ...[
            const Text(
              'Preferred Times',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_userPreferences!['preferred_times'] as List).map((time) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                     boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Keep column content compact
                    children: [
                      Text(
                        time['time'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${time['count'] ?? 0} bookings',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (hasAverageCapacity) ...[
            const Text(
              'Capacity Preference',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, // Ensures the container takes full width
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
                 boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
              ),
              child: Text(
                'You typically book resources with capacity around ${_userPreferences!['average_capacity'] ?? 'N/A'} people',
                style: const TextStyle(fontSize: 16, color: Colors.orangeAccent),
                textAlign: TextAlign.center, // Center the text for better readability
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // --- Tab-Specific Widgets (MODIFIED TO USE ListView.builder) ---

  Widget _buildPersonalizedTab() {
    return Column( // Changed from SingleChildScrollView directly to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0), // Adjust padding for title
          child: Text(
            'Personalized for You',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20), // Adjust padding for subtitle
          child: Text(
            'Based on your booking history and preferences',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _personalizedRecommendations.isNotEmpty
                ? Expanded( // Wrap ListView.builder in Expanded
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12), // Add horizontal padding to the list itself
                      itemCount: _personalizedRecommendations.length,
                      itemBuilder: (context, index) {
                        final item = _personalizedRecommendations[index];
                        return _buildResourceCard(
                          item,
                          score: item['score']?.toDouble(),
                          reasons: item['reasons'],
                          showScore: true,
                        );
                      },
                    ),
                  )
                : _buildEmptyState(
                    'No personalized recommendations available yet. Start booking resources to get personalized suggestions!',
                  ),
      ],
    );
  }

  Widget _buildTimeBasedTab() {
    return Column( // Changed from SingleChildScrollView directly to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Time-Based Recommendations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Text(
            'Find resources available at your preferred time',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding for the date picker card
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                    title: const Text('Select Preferred Date & Time', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      _preferredTime != null
                          ? DateFormat('MMM d,yyyy h:mm a').format(_preferredTime!) // Corrected date format example
                          : 'Tap to select',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _preferredTime ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)), // Allow selecting for a year
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_preferredTime ?? DateTime.now()),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _preferredTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                            _error = null; // Clear any previous error specific to this search
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _preferredTime != null && !_isTimeLoading
                          ? _handleTimeBasedSearch
                          : null,
                      icon: _isTimeLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: _isTimeLoading
                          ? const Text('Searching...')
                          : const Text('Find Available Resources'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_error != null && !_isTimeLoading && _timeBasedRecommendations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        const SizedBox(height: 20),
        _isTimeLoading && _timeBasedRecommendations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _timeBasedRecommendations.isNotEmpty
                ? Expanded( // Wrap ListView.builder in Expanded
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12), // Add horizontal padding to the list itself
                      itemCount: _timeBasedRecommendations.length,
                      itemBuilder: (context, index) {
                        final item = _timeBasedRecommendations[index];
                        return _buildResourceCard(
                          item,
                          score: item['score']?.toDouble(),
                          reasons: item['reason'] != null ? [item['reason']] : null,
                          showScore: true,
                        );
                      },
                    ),
                  )
                : (_preferredTime != null && !_isTimeLoading && _error == null)
                    ? _buildEmptyState('No resources found for the selected time.')
                    : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildPopularTab() {
    return Column( // Changed from SingleChildScrollView directly to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Popular Resources',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Text(
            'Most frequently booked resources',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _popularResources.isNotEmpty
                ? Expanded( // Wrap ListView.builder in Expanded
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12), // Add horizontal padding to the list itself
                      itemCount: _popularResources.length,
                      itemBuilder: (context, index) {
                        return _buildResourceCard(_popularResources[index]);
                      },
                    ),
                  )
                : _buildEmptyState('No popular resources data available.'),
      ],
    );
  }

  Widget _buildTrendingTab() {
    return Column( // Changed from SingleChildScrollView directly to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Trending Resources',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Text(
            'Resources with increasing popularity',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _trendingResources.isNotEmpty
                ? Expanded( // Wrap ListView.builder in Expanded
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12), // Add horizontal padding to the list itself
                      itemCount: _trendingResources.length,
                      itemBuilder: (context, index) {
                        return _buildResourceCard(_trendingResources[index]);
                      },
                    ),
                  )
                : _buildEmptyState('No trending resources data available.'),
      ],
    );
  }

  Widget _buildRecentTab() {
    return Column( // Changed from SingleChildScrollView directly to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Recently Booked',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Text(
            'Resources you\'ve booked recently',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentlyBooked.isNotEmpty
                ? Expanded( // Wrap ListView.builder in Expanded
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12), // Add horizontal padding to the list itself
                      itemCount: _recentlyBooked.length,
                      itemBuilder: (context, index) {
                        final item = _recentlyBooked[index];
                        final resource = item['resource'] ?? item;
                        return _buildResourceCard(resource);
                      },
                    ),
                  )
                : _buildEmptyState(
                    'No recent bookings found. Start booking resources to see them here!',
                  ),
      ],
    );
  }

  Widget _buildPreferencesTab() {
    // This tab is already a Column and contains non-list content, so it's mostly fine.
    // The main scrollability comes from its SingleChildScrollView.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Booking Patterns',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          const SizedBox(height: 8),
          const Text(
            'Insights into your resource booking behavior',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildUserPreferences(),
        ],
      ),
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20), // Add some space below the message
            if (!_isLoading && _error != null) // Offer retry only if there's an error from initial load
              ElevatedButton.icon(
                onPressed: _loadRecommendations,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Loading Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Bottombar(currentIndex: 0),
      appBar: MyAppBar(
        titleWidget: const Text(
          "Home",
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
              leading: const Icon(Icons.home, color: Colors.blueAccent),
              onTap: () {
                Navigator.pop(context);
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
      body: SafeArea(
        child: _isLoading &&
                _personalizedRecommendations.isEmpty &&
                _popularResources.isEmpty &&
                _trendingResources.isEmpty &&
                _recentlyBooked.isEmpty &&
                _userPreferences == null &&
                _error == null // Only show initial loading if no data and no error yet
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your recommendations...'),
                  ],
                ),
              )
            : Column(
                children: [
                  if (_error != null && !_isLoading && _timeBasedRecommendations.isEmpty) // General error display (not for time-based if its specific)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadRecommendations,
                            child: const Text('Retry', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  Material(
                    elevation: 4,
                    child: Container(
                      color: Theme.of(context).cardColor,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(icon: Icon(Icons.star), text: 'Personalized'),
                          Tab(icon: Icon(Icons.access_time), text: 'Time-Based'),
                          Tab(icon: Icon(Icons.trending_up), text: 'Popular'),
                          Tab(icon: Icon(Icons.local_fire_department), text: 'Trending'),
                          Tab(icon: Icon(Icons.history), text: 'Recent'),
                          Tab(icon: Icon(Icons.person), text: 'My Patterns'),
                        ],
                      ),
                    ),
                  ),
                  Expanded( // This Expanded is essential to give TabBarView all available space
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPersonalizedTab(),
                        _buildTimeBasedTab(),
                        _buildPopularTab(),
                        _buildTrendingTab(),
                        _buildRecentTab(),
                        _buildPreferencesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void logout() {
  }
}