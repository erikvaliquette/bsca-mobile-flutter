import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/business_connection_model.dart';
import '../../providers/business_connection_provider.dart';
import '../../services/supabase/supabase_client.dart';
import '../../widgets/sdg_icon_widget.dart';
import '../../widgets/validation_status_widget.dart';

class UserProfileScreen extends StatefulWidget {
  final BusinessConnection profile;
  final bool showConnectButton;

  const UserProfileScreen({
    super.key,
    required this.profile,
    this.showConnectButton = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _fullProfile;
  List<Map<String, dynamic>> _workHistory = [];
  List<Map<String, dynamic>> _education = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFullProfile();
  }

  Future<void> _fetchFullProfile() async {
    try {
      final client = SupabaseService.client;
      
      // Fetch full profile data with specific fields
      final profileResponse = await client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, headline, bio, about_me, company_name, industry, business_type, areas_of_expertise, products_services, country, location_city, website, experience_years, certifications, offering, seeking, sdg_focus, role_in_business, languages_spoken, trade_regions')
          .eq('id', widget.profile.counterpartyId)
          .single();

      // Try to fetch work history (handle gracefully if table doesn't exist)
      List<Map<String, dynamic>> workHistory = [];
      try {
        final workResponse = await client
            .from('work_history')
            .select()
            .eq('user_id', widget.profile.counterpartyId)
            .order('start_date', ascending: false);
        workHistory = List<Map<String, dynamic>>.from(workResponse ?? []);
      } catch (e) {
        print('Work history table not available: $e');
      }

      // Try to fetch education (handle gracefully if table doesn't exist)
      List<Map<String, dynamic>> education = [];
      try {
        final educationResponse = await client
            .from('education_history')
            .select()
            .eq('user_id', widget.profile.counterpartyId)
            .order('start_date', ascending: false);
        education = List<Map<String, dynamic>>.from(educationResponse ?? []);
      } catch (e) {
        print('Education table not available: $e');
      }

      setState(() {
        _fullProfile = profileResponse;
        _workHistory = workHistory;
        _education = education;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConnect() async {
    try {
      final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      await provider.sendConnectionRequest(widget.profile.counterpartyId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection request sent to ${widget.profile.name}')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending connection request: $e')),
        );
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final avatarHeight = screenHeight * 0.4; // 40% of screen height for avatar
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.profile.name, style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading profile: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchFullProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Background Avatar Image
                    Container(
                      height: avatarHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                      child: widget.profile.profileImageUrl != null && widget.profile.profileImageUrl!.isNotEmpty
                        ? Image.network(
                            widget.profile.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(widget.profile.name),
                          )
                        : _buildAvatarFallback(widget.profile.name),
                    ),
                    
                    // Scrollable Content
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Top Spacer
                        SliverToBoxAdapter(
                          child: SizedBox(height: avatarHeight - 40),
                        ),
                        
                        // Content Card
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                              const SizedBox(height: 30),
                              // User name and location
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  children: [
                                    // User name
                                    Text(
                                      widget.profile.name,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    // Location
                                    if (widget.profile.location != null && widget.profile.location!.isNotEmpty)
                                      Text(
                                        widget.profile.location!,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // User title or role (if available)
                              if (widget.profile.title != null && widget.profile.title!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  widget.profile.title!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // SDG Goals Section
                              if (widget.profile.sdgGoals != null && widget.profile.sdgGoals!.isNotEmpty)
                                _buildSection(
                                  'SDG Goals',
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          alignment: WrapAlignment.center,
                                          children: widget.profile.sdgGoals!.map((sdgNumber) {
                                            return Tooltip(
                                              message: 'SDG $sdgNumber',
                                              child: SDGIconWidget(
                                                sdgNumber: sdgNumber,
                                                size: 60,
                                                showLabel: false,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // About/Bio Section
                              if (_fullProfile != null && _fullProfile!['bio'] != null && _fullProfile!['bio'].toString().isNotEmpty)
                                _buildSection(
                                  'About',
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Theme.of(context).dividerColor),
                                    ),
                                    child: Text(
                                      _fullProfile!['bio'],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              
                              // Work History Section
                              if (_workHistory.isNotEmpty)
                                _buildSection(
                                  'Work History',
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _workHistory.map((work) => _buildWorkHistoryItem(context, work)).toList(),
                                  ),
                                ),
                              
                              // Education Section
                              if (_education.isNotEmpty)
                                _buildSection(
                                  'Education',
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _education.map((edu) => _buildEducationItem(context, edu)).toList(),
                                  ),
                                ),
                              
                              // Certifications Section
                              if (_fullProfile != null && _fullProfile!['certifications'] != null && (_fullProfile!['certifications'] as List).isNotEmpty)
                                _buildSection(
                                  'Certifications',
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: (_fullProfile!['certifications'] as List).map((cert) => 
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Theme.of(context).dividerColor),
                                        ),
                                        child: Text(
                                          cert.toString(),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      )
                                    ).toList(),
                                  ),
                                ),
                              
                              // Connect Button
                              if (widget.showConnectButton) ...[  
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Send Connection Request'),
                                      onPressed: _handleConnect,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        textStyle: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile Image or Initials
            widget.profile.profileImageUrl != null && widget.profile.profileImageUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(widget.profile.profileImageUrl!),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _getInitials(widget.profile.name),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
            const SizedBox(width: 16),
            
            // Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.profile.title != null && widget.profile.title!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.profile.title!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (widget.profile.location != null && widget.profile.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          widget.profile.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_fullProfile?['bio'] != null && _fullProfile!['bio'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _fullProfile!['bio'],
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildExpertiseAndServices() {
    if (_fullProfile == null) return const SizedBox.shrink();
    
    try {
      return Column(
        children: [
          if (_fullProfile!['areas_of_expertise'] != null && (_fullProfile!['areas_of_expertise'] as List).isNotEmpty) ...[
            _buildSection('Areas of Expertise', 
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_fullProfile!['areas_of_expertise'] as List)
                    .map((expertise) => Chip(
                      label: Text(expertise.toString()),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                    ))
                    .toList(),
              )
            ),
            const SizedBox(height: 24),
          ],
          if (_fullProfile!['products_services'] != null && (_fullProfile!['products_services'] as List).isNotEmpty) ...[
            _buildSection('Products & Services', 
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_fullProfile!['products_services'] as List)
                    .map((service) => Chip(
                      label: Text(service.toString()),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: TextStyle(color: Colors.green.shade700),
                    ))
                    .toList(),
              )
            ),
            const SizedBox(height: 24),
          ],
        ],
      );
    } catch (e) {
      print('Error building expertise and services: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessInfo() {
    if (_fullProfile == null) return const SizedBox.shrink();
    
    try {
      return _buildSection('Business Information', Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fullProfile!['company_name'] != null) ...[
            _buildInfoRow('Company', _fullProfile!['company_name']),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['industry'] != null) ...[
            _buildInfoRow('Industry', _fullProfile!['industry']),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['business_type'] != null) ...[
            _buildInfoRow('Business Type', _fullProfile!['business_type']),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['role_in_business'] != null) ...[
            _buildInfoRow('Role', _fullProfile!['role_in_business']),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['experience_years'] != null) ...[
            _buildInfoRow('Experience', '${_fullProfile!['experience_years']} years'),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['country'] != null || _fullProfile!['location_city'] != null) ...[
            _buildInfoRow('Location', 
              [_fullProfile!['location_city'], _fullProfile!['country']]
                .where((e) => e != null)
                .join(', ')
            ),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['website'] != null) ...[
            _buildInfoRow('Website', _fullProfile!['website']),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['languages_spoken'] != null && (_fullProfile!['languages_spoken'] as List).isNotEmpty) ...[
            _buildInfoRow('Languages', (_fullProfile!['languages_spoken'] as List).join(', ')),
            const SizedBox(height: 8),
          ],
          if (_fullProfile!['trade_regions'] != null && _fullProfile!['trade_regions'] is List && (_fullProfile!['trade_regions'] as List).isNotEmpty) ...[
            _buildInfoRow('Trade Regions', (_fullProfile!['trade_regions'] as List).join(', ')),
          ],
        ],
      ));
    } catch (e) {
      print('Error building business info: $e');
      return const SizedBox.shrink();
    }
  }
  


  Widget _buildSDGGoals() {
    if (_fullProfile == null || _fullProfile!['sdg_goals'] == null || !(_fullProfile!['sdg_goals'] is List) || (_fullProfile!['sdg_goals'] as List).isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildSection(
      'SDG Goals',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (_fullProfile!['sdg_goals'] as List).map((goal) {
          // Extract goal number from name (e.g., "Climate Action" -> 13)
          final goalName = goal.toString();
          int? goalNumber;
          
          // Map goal names to their corresponding numbers
          if (goalName.contains('Poverty')) goalNumber = 1;
          else if (goalName.contains('Hunger')) goalNumber = 2;
          else if (goalName.contains('Health')) goalNumber = 3;
          else if (goalName.contains('Education')) goalNumber = 4;
          else if (goalName.contains('Gender')) goalNumber = 5;
          else if (goalName.contains('Water')) goalNumber = 6;
          else if (goalName.contains('Energy')) goalNumber = 7;
          else if (goalName.contains('Work') || goalName.contains('Economic')) goalNumber = 8;
          else if (goalName.contains('Industry') || goalName.contains('Innovation')) goalNumber = 9;
          else if (goalName.contains('Inequalities')) goalNumber = 10;
          else if (goalName.contains('Cities') || goalName.contains('Communities')) goalNumber = 11;
          else if (goalName.contains('Consumption') || goalName.contains('Production')) goalNumber = 12;
          else if (goalName.contains('Climate')) goalNumber = 13;
          else if (goalName.contains('Life Below Water') || goalName.contains('Ocean')) goalNumber = 14;
          else if (goalName.contains('Life on Land')) goalNumber = 15;
          else if (goalName.contains('Peace') || goalName.contains('Justice') || goalName.contains('Institutions')) goalNumber = 16;
          else if (goalName.contains('Partnerships')) goalNumber = 17;
          
          return Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            child: goalNumber != null
              ? SDGIconWidget(sdgNumber: goalNumber)
              : Chip(
                  label: Text(goalName),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(color: Colors.green.shade700),
                ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutSection() {
    if (_fullProfile == null) return const SizedBox.shrink();
    
    try {
      return Column(
        children: [
          if (_fullProfile!['about_me'] != null || _fullProfile!['bio'] != null) ...[
            _buildSection('About', 
              Text(
                _fullProfile!['about_me'] ?? _fullProfile!['bio'] ?? '',
                style: const TextStyle(fontSize: 16, height: 1.5),
              )
            ),
            const SizedBox(height: 24),
          ],
          if (_fullProfile!['areas_of_expertise'] != null && (_fullProfile!['areas_of_expertise'] as List).isNotEmpty) ...[
            _buildSection('Areas of Expertise', 
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_fullProfile!['areas_of_expertise'] as List)
                    .map((expertise) => Chip(
                      label: Text(expertise.toString()),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                    ))
                    .toList(),
              )
            ),
            const SizedBox(height: 24),
          ],
          if (_fullProfile!['products_services'] != null && (_fullProfile!['products_services'] as List).isNotEmpty) ...[
            _buildSection('Products & Services', 
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_fullProfile!['products_services'] as List)
                    .map((service) => Chip(
                      label: Text(service.toString()),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: TextStyle(color: Colors.green.shade700),
                    ))
                    .toList(),
              )
            ),
            const SizedBox(height: 24),
          ],
          if (_fullProfile!['offering'] != null) ...[
            _buildSection('What I Offer', 
              Text(
                _fullProfile!['offering'],
                style: const TextStyle(fontSize: 16, height: 1.5),
              )
            ),
            const SizedBox(height: 24),
          ],
          if (_fullProfile!['seeking'] != null) ...[
            _buildSection('What I\'m Seeking', 
              Text(
                _fullProfile!['seeking'],
                style: const TextStyle(fontSize: 16, height: 1.5),
              )
            ),
            const SizedBox(height: 24),
          ],
          if (_fullProfile!['sdg_focus'] != null) ...[
            _buildSection('SDG Focus', 
              Text(
                _fullProfile!['sdg_focus'],
                style: const TextStyle(fontSize: 16, height: 1.5),
              )
            ),
          ],
      ],
    );
    } catch (e) {
      print('Error building about section: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // This method was duplicated - removed to fix compilation error

  Widget _buildWorkHistoryItem(BuildContext context, Map<String, dynamic> work) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  work['title'] ?? 'Position',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (work['verified'] == true && work['organization_id'] != null)
                ValidationStatusWidget(
                  userId: widget.profile.id,
                  organizationId: work['organization_id'],
                  organizationName: work['company'],
                ),
            ],
          ),
          if (work['company'] != null) ...[
            const SizedBox(height: 4),
            Text(
              work['company'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (work['start_date'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${work['start_date']} - ${work['end_date'] ?? 'Present'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
          if (work['description'] != null && work['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              work['description'],
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(BuildContext context, Map<String, dynamic> edu) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu['degree'] ?? 'Degree',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (edu['institution'] != null) ...[
            const SizedBox(height: 4),
            Text(
              edu['institution'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (edu['start_date'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${edu['start_date']} - ${edu['end_date'] ?? 'Present'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
          if (edu['description'] != null && edu['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              edu['description'],
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
