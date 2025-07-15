import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/solution.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/services/solutions_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SolutionsScreen extends StatefulWidget {
  const SolutionsScreen({super.key});

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  List<Solution> _solutions = [];
  List<Solution> _filteredSolutions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final List<int> _selectedSDGGoals = []; // Made final as suggested by linter
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = [
    'All',
    'Supply Chain',
    'Carbon Management',
    'Waste Management',
    'ESG Reporting',
    'Energy Efficiency',
    'Water Management',
  ];

  @override
  void initState() {
    super.initState();
    _loadSolutions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSolutions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final solutions = await SolutionsService.getSolutions();
      setState(() {
        _solutions = solutions;
        _filteredSolutions = solutions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading solutions: ${e.toString()}')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSolutions = _solutions.where((solution) {
        // Apply SDG goals filter
        if (_selectedSDGGoals.isNotEmpty) {
          bool hasMatchingGoal = false;
          for (final goalId in _selectedSDGGoals) {
            if (solution.sdgGoals.contains(goalId)) {
              hasMatchingGoal = true;
              break;
            }
          }
          if (!hasMatchingGoal) return false;
        }
        
        // Apply category filter
        if (_selectedCategory != null && _selectedCategory != 'All') {
          if (solution.category != _selectedCategory) return false;
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final name = solution.name?.toLowerCase() ?? '';
          final description = solution.description?.toLowerCase() ?? '';
          final vendor = solution.vendorName?.toLowerCase() ?? '';
          
          if (!name.contains(query) && 
              !description.contains(query) && 
              !vendor.contains(query)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _toggleSDGGoal(int goalId) {
    setState(() {
      if (_selectedSDGGoals.contains(goalId)) {
        _selectedSDGGoals.remove(goalId);
      } else {
        _selectedSDGGoals.add(goalId);
      }
      _applyFilters();
    });
  }

  void _setCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solutions Marketplace'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover and showcase enterprise solutions for sustainable business practices.',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      InkWell(
                        onTap: () {
                          // Contact us action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact form coming soon')),
                          );
                        },
                        child: Text(
                          'Contact us',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Filter by SDG Goals:',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // SDG Goals filter
                SizedBox(
                  height: 80,
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (OverscrollIndicatorNotification overscroll) {
                      overscroll.disallowIndicator();
                      return true;
                    },
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: 5, // Show first 5 SDGs
                      // Add semantics for better accessibility
                      addSemanticIndexes: true,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final goal = SDGGoal.allGoals[index];
                        final isSelected = _selectedSDGGoals.contains(goal.id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () => _toggleSDGGoal(goal.id),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 3.0,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Container(
                                    color: goal.color,
                                    child: Center(
                                      child: Text(
                                        '${goal.id}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${goal.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search solutions',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                
                // Category filter chips
                SizedBox(
                  height: 50,
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (OverscrollIndicatorNotification overscroll) {
                      overscroll.disallowIndicator();
                      return true;
                    },
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _categories.length,
                      // Add semantics for better accessibility
                      addSemanticIndexes: true,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category || 
                                          (category == 'All' && _selectedCategory == null);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              _setCategory(selected ? 
                                          (category == 'All' ? null : category) : 
                                          null);
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context).colorScheme.primary.withAlpha(51), // Using withAlpha instead of deprecated withOpacity
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Info banner
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[700],
                        size: 24.0,
                      ),
                      const SizedBox(width: 12.0),
                      const Expanded(
                        child: Text(
                          'These solutions are examples for demonstration purposes only',
                          style: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Solutions list
                Expanded(
                  child: _filteredSolutions.isEmpty
                      ? const Center(
                          child: Text(
                            'No solutions found',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        )
                      : NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (OverscrollIndicatorNotification overscroll) {
                            overscroll.disallowIndicator();
                            return true;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredSolutions.length,
                            // Add semantics for better accessibility
                            addSemanticIndexes: true,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false,
                            // Use cacheExtent to improve scrolling performance
                            cacheExtent: 200,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final solution = _filteredSolutions[index];
                              return _buildSolutionCard(solution);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSolutionCard(Solution solution) {
    final sdgGoals = SDGGoal.getByIds(solution.sdgGoals);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SDG Icons
            if (sdgGoals.isNotEmpty)
              SizedBox(
                height: 40,
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sdgGoals.length > 4 ? 4 : sdgGoals.length,
                    // Add semantics for better accessibility
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.asset(
                          sdgGoals[index].iconPath,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: sdgGoals[index].color,
                              child: Center(
                                child: Text(
                                  '${sdgGoals[index].id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 12.0),
            
            // Solution name
            Text(
              solution.name ?? 'Unnamed Solution',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8.0),
            
            // Description
            Text(
              solution.description ?? 'No description available',
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12.0),
            
            // Category and vendor
            Row(
              children: [
                if (solution.category != null)
                  Chip(
                    label: Text(solution.category!),
                    backgroundColor: Colors.grey[200],
                  ),
                const Spacer(),
                if (solution.vendorName != null)
                  Text(
                    solution.vendorName!,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            // Pricing
            if (solution.pricingModel != null)
              Text(
                'Starting at ${solution.pricingModel}',
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            
            const SizedBox(height: 12.0),
            
            // Features
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: solution.features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16.0),
            
            // Visit website button
            if (solution.website != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(solution.website),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visit Website'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
