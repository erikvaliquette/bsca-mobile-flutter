import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bsca_mobile_flutter/screens/sdg_marketplace/sdg_project_detail_screen.dart';

class SdgProject {
  final String id;
  final String title;
  final String description;
  final String? impact;
  final String? imageUrl;
  final String status;
  final String? location;
  final DateTime? deadline;
  final String? contactEmail;
  final List<int> sdgGoals;
  final String? skillsNeeded;

  SdgProject({
    required this.id,
    required this.title,
    required this.description,
    this.impact,
    this.imageUrl,
    required this.status,
    this.location,
    this.deadline,
    this.contactEmail,
    required this.sdgGoals,
    this.skillsNeeded,
  });

  factory SdgProject.fromJson(Map<String, dynamic> json) {
    // Safe getter for string values
    String? safeString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }
    
    // Completely rewritten goals parser to handle all possible data types
    List<int> parseGoals(dynamic goalsData) {
      // If null, return empty list
      if (goalsData == null) return [];
      
      // If already a list, convert elements to integers
      if (goalsData is List) {
        return goalsData
            .map((e) => e == null ? 0 : int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0) // Filter out invalid values
            .toList();
      }
      
      // If it's a string, try to parse it as JSON
      if (goalsData is String) {
        try {
          if (goalsData.trim().startsWith('[')) {
            final List<dynamic> parsed = jsonDecode(goalsData);
            return parsed
                .map((e) => e == null ? 0 : int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList();
          } else {
            // Single value as string
            final int? value = int.tryParse(goalsData);
            return value != null && value > 0 ? [value] : [];
          }
        } catch (_) {
          return [];
        }
      }
      
      // For any other type, try to convert to string then parse
      try {
        final String stringValue = goalsData.toString();
        if (stringValue.trim().startsWith('[')) {
          try {
            final List<dynamic> parsed = jsonDecode(stringValue);
            return parsed
                .map((e) => e == null ? 0 : int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList();
          } catch (_) {
            return [];
          }
        } else {
          final int? value = int.tryParse(stringValue);
          return value != null && value > 0 ? [value] : [];
        }
      } catch (_) {
        return [];
      }
    }

    // Handle the sdg_goals field with extra care
    List<int> sdgGoals = [];
    try {
      sdgGoals = parseGoals(json['sdg_goals']);
    } catch (e) {
      print('Error parsing SDG goals: $e');
      sdgGoals = [];
    }
    
    // Handle date parsing safely
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else {
          return DateTime.parse(dateValue.toString());
        }
      } catch (e) {
        print('Error parsing date: $e');
        return null;
      }
    }
    
    // Map project ID to the correct image URL if not specified
    String? getProjectImage(String projectId, String? providedImageUrl) {
      if (providedImageUrl != null && providedImageUrl.isNotEmpty) {
        return providedImageUrl;
      }
      
      // Map project ID to specific Supabase image
      switch(projectId) {
        case '1':
          return 'sdg-project-1.jpg';
        case '2':
          return 'sdg-project-2.jpg';
        case '3':
          return 'sdg-project-3.jpg';
        default:
          // For other projects, use a default image based on the ID number if possible
          try {
            int idNum = int.parse(projectId);
            int imageNum = ((idNum - 1) % 3) + 1; // Cycle between 1-3
            return 'sdg-project-$imageNum.jpg';
          } catch (_) {
            return 'sdg-project-1.jpg'; // Default to first image
          }
      }
    }
    
    // Get the project ID
    String projectId = json['id']?.toString() ?? '';
    
    return SdgProject(
      id: projectId,
      title: json['title']?.toString() ?? 'Untitled Project',
      description: json['description']?.toString() ?? '',
      impact: safeString(json['impact']),
      imageUrl: getProjectImage(projectId, safeString(json['image_url'])),
      status: json['status']?.toString() ?? 'Planning',
      location: safeString(json['location']),
      deadline: parseDate(json['deadline']),
      contactEmail: safeString(json['contact_email']),
      sdgGoals: sdgGoals,
      skillsNeeded: safeString(json['skills_needed']),
    );
  }
}

class SDGMarketplaceScreen extends StatefulWidget {
  const SDGMarketplaceScreen({super.key});

  @override
  State<SDGMarketplaceScreen> createState() => _SDGMarketplaceScreenState();
}

class _SDGMarketplaceScreenState extends State<SDGMarketplaceScreen> {
  List<SdgProject> _projects = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Projects';
  String _searchQuery = '';
  List<int> _selectedGoals = [];

  final List<String> _statusFilters = ['All Projects', 'Active', 'Planning', 'Completed'];

  // Map of SDG goals with their colors and icons
  final Map<int, Map<String, dynamic>> _sdgGoalsMap = {
    1: {'name': 'No Poverty', 'color': const Color(0xFFE5243B), 'icon': Icons.people_outline},
    2: {'name': 'Zero Hunger', 'color': const Color(0xFFDDA63A), 'icon': Icons.restaurant},
    3: {'name': 'Good Health', 'color': const Color(0xFF4C9F38), 'icon': Icons.favorite},
    4: {'name': 'Quality Education', 'color': const Color(0xFFC5192D), 'icon': Icons.school},
    5: {'name': 'Gender Equality', 'color': const Color(0xFFFF3A21), 'icon': Icons.wc},
    6: {'name': 'Clean Water', 'color': const Color(0xFF26BDE2), 'icon': Icons.water_drop},
    7: {'name': 'Affordable Energy', 'color': const Color(0xFFFCC30B), 'icon': Icons.bolt},
    8: {'name': 'Economic Growth', 'color': const Color(0xFFA21942), 'icon': Icons.trending_up},
    9: {'name': 'Industry & Innovation', 'color': const Color(0xFFFD6925), 'icon': Icons.factory},
    10: {'name': 'Reduced Inequalities', 'color': const Color(0xFFDD1367), 'icon': Icons.balance},
    11: {'name': 'Sustainable Cities', 'color': const Color(0xFFFD9D24), 'icon': Icons.location_city},
    12: {'name': 'Responsible Consumption', 'color': const Color(0xFFBF8B2E), 'icon': Icons.shopping_cart},
    13: {'name': 'Climate Action', 'color': const Color(0xFF3F7E44), 'icon': Icons.thermostat},
    14: {'name': 'Life Below Water', 'color': const Color(0xFF0A97D9), 'icon': Icons.water},
    15: {'name': 'Life on Land', 'color': const Color(0xFF56C02B), 'icon': Icons.forest},
    16: {'name': 'Peace & Justice', 'color': const Color(0xFF00689D), 'icon': Icons.balance_outlined},
    17: {'name': 'Partnerships', 'color': const Color(0xFF19486A), 'icon': Icons.handshake},
  };

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the response from Supabase
      final response = await SupabaseService.client
          .from('sdg_projects')
          .select('*')
          .order('created_at', ascending: false);
      
      // Debug the response
      print('Supabase response type: ${response.runtimeType}');
      
      // Handle different response types safely
      List<SdgProject> projects = [];
      
      if (response is List) {
        // Process each item with careful error handling
        for (var item in response) {
          try {
            if (item is Map<String, dynamic>) {
              projects.add(SdgProject.fromJson(item));
            } else {
              print('Skipping non-map item: $item');
            }
          } catch (itemError) {
            print('Error processing project item: $itemError');
            // Continue processing other items
          }
        }
      } else {
        print('Unexpected response format: $response');
      }

      // Update state with the projects we were able to parse
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchProjects: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: ${e.toString()}')),
        );
      }
    }
  }

  List<SdgProject> _getFilteredProjects() {
    return _projects.where((project) {
      // Apply status filter
      if (_selectedFilter != 'All Projects' && project.status != _selectedFilter) {
        return false;
      }

      // Apply SDG goals filter
      if (_selectedGoals.isNotEmpty && 
          !_selectedGoals.any((goal) => project.sdgGoals.contains(goal))) {
        return false;
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return project.title.toLowerCase().contains(query) ||
               project.description.toLowerCase().contains(query) ||
               (project.location?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  String _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // If no image URL is provided, use the first project image from Supabase
      return 'https://vufeuaoosussspqyskdw.supabase.co/storage/v1/object/public/site_images/sdg-project-1.jpg';
    }

    // If the URL is already a full URL, return it
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // If it's a project number, map to the corresponding image
    if (imageUrl == '1' || imageUrl == 'project1') {
      return 'https://vufeuaoosussspqyskdw.supabase.co/storage/v1/object/public/site_images/sdg-project-1.jpg';
    } else if (imageUrl == '2' || imageUrl == 'project2') {
      return 'https://vufeuaoosussspqyskdw.supabase.co/storage/v1/object/public/site_images/sdg-project-2.jpg';
    } else if (imageUrl == '3' || imageUrl == 'project3') {
      return 'https://vufeuaoosussspqyskdw.supabase.co/storage/v1/object/public/site_images/sdg-project-3.jpg';
    }
    
    // If it's a path without the full URL, construct the URL to the Supabase storage
    if (imageUrl.startsWith('/')) {
      // Remove leading slash if present
      imageUrl = imageUrl.substring(1);
    }
    
    // Handle double slashes in the path
    String path = imageUrl;
    if (path.contains('//')) {
      path = path.replaceAll('//', '/');
    }
    
    try {
      // Try to get the URL from Supabase storage
      final storageUrl = SupabaseService.client.storage.from('site_images').getPublicUrl(path);
      return storageUrl;
    } catch (e) {
      print('Error getting image URL: $e');
      // If there's an error, use the direct URL format
      return 'https://vufeuaoosussspqyskdw.supabase.co/storage/v1/object/public/site_images/$path';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _getFilteredProjects();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SDG Marketplace'),
      ),
      body: Column(
        children: [
          // Description section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Browse and join sustainable development projects making a real impact in communities around the world.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Status filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.purple.shade50,
                    selectedColor: Colors.purple.shade200,
                  ),
                );
              }).toList(),
            ),
          ),

          // SDG Goals filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by SDG Goals:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(17, (index) {
                      final goalNumber = index + 1;
                      final goalInfo = _sdgGoalsMap[goalNumber]!;
                      final isSelected = _selectedGoals.contains(goalNumber);
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGoals.remove(goalNumber);
                              } else {
                                _selectedGoals.add(goalNumber);
                              }
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: goalInfo['color'],
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected 
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            ),
                            child: Center(
                              child: Text(
                                '$goalNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Projects list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProjects.isEmpty
                    ? const Center(child: Text('No projects found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          return ProjectCard(
                            project: project,
                            sdgGoalsMap: _sdgGoalsMap,
                            getImageUrl: _getImageUrl,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to submit project screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submit Project feature coming soon')),
          );
        },
        label: const Text('Submit Project'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final SdgProject project;
  final Map<int, Map<String, dynamic>> sdgGoalsMap;
  final String Function(String?) getImageUrl;

  const ProjectCard({
    super.key,
    required this.project,
    required this.sdgGoalsMap,
    required this.getImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SdgProjectDetailScreen(
                project: project,
                sdgGoalsMap: sdgGoalsMap,
                getImageUrl: getImageUrl,
              ),
            ),
          );
        },
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project image with SDG goals overlay
          Stack(
            children: [
              // Project image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: getImageUrl(project.imageUrl),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              
              // SDG goals overlay
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: project.sdgGoals.take(3).map((goalId) {
                    final goalInfo = sdgGoalsMap[goalId];
                    if (goalInfo == null) return const SizedBox.shrink();
                    
                    return Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: goalInfo['color'],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$goalId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          
          // Project details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  project.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 16),
                
                // Status and location
                Row(
                  children: [
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: project.status == 'Active' 
                            ? Colors.green.shade100 
                            : project.status == 'Planning'
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        project.status,
                        style: TextStyle(
                          color: project.status == 'Active' 
                              ? Colors.green.shade800 
                              : project.status == 'Planning'
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Location
                    if (project.location != null && project.location!.isNotEmpty)
                      Text(
                        project.location!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
