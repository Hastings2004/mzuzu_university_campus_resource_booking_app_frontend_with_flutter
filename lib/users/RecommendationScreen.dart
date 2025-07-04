import 'package:flutter/material.dart';
import 'package:resource_booking_app/auth/Api.dart';
import 'package:resource_booking_app/components/AppBar.dart';
import 'package:resource_booking_app/components/BottomBar.dart';
import 'package:resource_booking_app/users/ResourceDetails.dart';
import 'package:resource_booking_app/models/resource_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      }
    } catch (e) {
      print('Error loading personalized recommendations: $e');
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
      }
    } catch (e) {
      print('Error loading user preferences: $e');
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
      }
    } catch (e) {
      print('Error loading popular resources: $e');
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
      }
    } catch (e) {
      print('Error loading trending resources: $e');
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
      }
    } catch (e) {
      print('Error loading recently booked resources: $e');
    }
  }

  Future<void> _handleTimeBasedSearch() async {
    if (_preferredTime == null) {
      setState(() {
        _error = 'Please select a preferred time.';
      });
      return;
    }

    setState(() {
      _isTimeLoading = true;
      _error = null;
    });

    try {
      var res = await CallApi().getData(
        'recommendations/resources/time-based?preferred_time=${_preferredTime!.toIso8601String()}&limit=6',
      );
      var body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _timeBasedRecommendations = body['recommendations'] ?? [];
        });
      } else {
        setState(() {
          _error =
              body['message'] ?? 'Failed to get time-based recommendations.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get time-based recommendations. Please try again.';
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
    };
    return icons[category] ?? '📋';
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
    final imageUrl =
        resourceData['image_url'] ??
        resourceData['image'] ??
        resourceData['photo'] ??
        resourceData['photo_url'] ??
        resourceData['image_path'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          // Create a ResourceModel from the resource data
          final resourceModel = ResourceModel(
            id: resourceData['id'],
            name: resourceData['name'] ?? 'Unknown Resource',
            description: resourceData['description'] ?? '',
            location: resourceData['location'] ?? '',
            capacity: resourceData['capacity'],
            imageUrl:
                resourceData['image_url'] ??
                resourceData['image'] ??
                resourceData['photo'] ??
                resourceData['photo_url'] ??
                resourceData['image_path'],
            type: resourceData['type'] ?? resourceData['category'] ?? 'Unknown',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResourceDetails(
                    resource: resourceModel,
                    resourceId: resourceData['id'],
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey[200],
              ),
              child:
                  imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                _getRecommendationIcon(
                                  resourceData['category'] ?? '',
                                ),
                                style: const TextStyle(fontSize: 40),
                              ),
                            );
                          },
                        ),
                      )
                      : Container(
                        alignment: Alignment.center,
                        child: Text(
                          _getRecommendationIcon(
                            resourceData['category'] ?? '',
                          ),
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resourceData['name'] ?? 'Unknown Resource',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                          resourceData['location'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
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
                        '${resourceData['capacity'] ?? 'N/A'} people',
                        style: const TextStyle(
                          fontSize: 12,
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
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  if (reasons != null && reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Why recommended:',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children:
                          (reasons as List<dynamic>).take(2).map((reason) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reason.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
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

  Widget _buildUserPreferences() {
    if (_userPreferences == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_userPreferences!['favorite_categories'] != null &&
            (_userPreferences!['favorite_categories'] as List).isNotEmpty) ...[
          const Text(
            'Favorite Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                (_userPreferences!['favorite_categories'] as List).map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getRecommendationIcon(cat['category'])),
                        const SizedBox(width: 8),
                        Text(
                          cat['category'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cat['percentage']}%',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (_userPreferences!['preferred_times'] != null &&
            (_userPreferences!['preferred_times'] as List).isNotEmpty) ...[
          const Text(
            'Preferred Times',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                (_userPreferences!['preferred_times'] as List).map((time) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          time['time'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${time['count']} bookings',
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
        if (_userPreferences!['average_capacity'] != null) ...[
          const Text(
            'Capacity Preference',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              'You typically book resources with capacity around ${_userPreferences!['average_capacity']} people',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        titleWidget: const Text(
          "Recommendations",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: Bottombar(currentIndex: 0),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading personalized recommendations...'),
                    ],
                  ),
                )
                : Column(
                  children: [
                    if (_error != null)
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
                            Expanded(child: Text(_error!)),
                          ],
                        ),
                      ),
                    Container(
                      color: Colors.green[50],
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.white,
                        tabs: const [
                          Tab(icon: Icon(Icons.star), text: 'Personalized'),
                          Tab(
                            icon: Icon(Icons.access_time),
                            text: 'Time-Based',
                          ),
                          Tab(icon: Icon(Icons.trending_up), text: 'Popular'),
                          Tab(
                            icon: Icon(Icons.local_fire_department),
                            text: 'Trending',
                          ),
                          Tab(icon: Icon(Icons.history), text: 'Recent'),
                          Tab(icon: Icon(Icons.person), text: 'My Patterns'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Personalized Tab
                          _buildPersonalizedTab(),
                          // Time-Based Tab
                          _buildTimeBasedTab(),
                          // Popular Tab
                          _buildPopularTab(),
                          // Trending Tab
                          _buildTrendingTab(),
                          // Recent Tab
                          _buildRecentTab(),
                          // Preferences Tab
                          _buildPreferencesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildPersonalizedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized for You',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on your booking history and preferences',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_personalizedRecommendations.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
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
            )
          else
            _buildEmptyState(
              'No personalized recommendations available yet. Start booking resources to get personalized suggestions!',
            ),
        ],
      ),
    );
  }

  Widget _buildTimeBasedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time-Based Recommendations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find resources available at your preferred time',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Select Preferred Time'),
                    subtitle: Text(
                      _preferredTime != null
                          ? DateFormat(
                            'MMM d, yyyy h:mm a',
                          ).format(_preferredTime!)
                          : 'Tap to select',
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _preferredTime = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _preferredTime != null && !_isTimeLoading
                              ? _handleTimeBasedSearch
                              : null,
                      child:
                          _isTimeLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('Find Available Resources'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_timeBasedRecommendations.isNotEmpty) ...[
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _timeBasedRecommendations.length,
              itemBuilder: (context, index) {
                final item = _timeBasedRecommendations[index];
                return _buildResourceCard(
                  item,
                  score: item['score']?.toDouble(),
                  reasons: [item['reason']],
                  showScore: true,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPopularTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Resources',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Most frequently booked resources',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_popularResources.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _popularResources.length,
              itemBuilder: (context, index) {
                return _buildResourceCard(_popularResources[index]);
              },
            )
          else
            _buildEmptyState('No popular resources data available.'),
        ],
      ),
    );
  }

  Widget _buildTrendingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Resources',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Resources with increasing popularity',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_trendingResources.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _trendingResources.length,
              itemBuilder: (context, index) {
                return _buildResourceCard(_trendingResources[index]);
              },
            )
          else
            _buildEmptyState('No trending resources data available.'),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recently Booked',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Resources you\'ve booked recently',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_recentlyBooked.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _recentlyBooked.length,
              itemBuilder: (context, index) {
                final item = _recentlyBooked[index];
                final resource = item['resource'] ?? item;
                return _buildResourceCard(resource);
              },
            )
          else
            _buildEmptyState(
              'No recent bookings found. Start booking resources to see them here!',
            ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Booking Patterns',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Insights into your resource booking behavior',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_userPreferences != null)
            _buildUserPreferences()
          else
            _buildEmptyState(
              'No booking history available to analyze patterns.',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
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
        ],
      ),
    );
  }
}
