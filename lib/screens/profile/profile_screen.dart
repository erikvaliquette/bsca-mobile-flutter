import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/profile_model.dart';
import '../../widgets/sdg_icon_widget.dart';
import '../../widgets/validation_status_widget.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeProfileProvider();
      _isInitialized = true;
    }
  }

  Future<void> _initializeProfileProvider() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.fetchCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final user = authProvider.user;
    final profile = profileProvider.profile;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                // Refresh the profile data when returning from edit screen
                Provider.of<ProfileProvider>(context, listen: false).fetchCurrentUserProfile();
              });
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background Avatar Image
                Container(
                  height: avatarHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: profile?.avatarUrl != null
                    ? Image.network(
                        profile!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(profile?.fullName ?? user.email ?? ''),
                      )
                    : _buildAvatarFallback(profile?.fullName ?? user.email ?? ''),
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
                                    _getDisplayName(profile),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  // Country/Location
                                  if (profile?.preferences != null && profile!.preferences!['country'] != null)
                                    Text(
                                      profile.preferences!['country'],
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // User role or title (if available)
                            if (profile?.preferences != null && 
                                (profile!.preferences!['role'] != null || profile!.preferences!['title'] != null))
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                profile!.preferences!['role'] ?? profile!.preferences!['title'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // SDG Goals Section (moved up per user request)
                            if (profile?.sdgGoals != null && profile!.sdgGoals!.isNotEmpty)
                              _buildSection(
                                context,
                                'SDG Goals',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      children: profile!.sdgGoals!.map((goal) {
                                        // Extract SDG number from the goal name
                                        final sdgNumber = _extractSDGNumber(goal);
                                        if (sdgNumber != null) {
                                          return Tooltip(
                                            message: goal,
                                            child: SDGIconWidget(
                                              sdgNumber: sdgNumber,
                                              size: 60,
                                              showLabel: false,
                                              onTap: () {}, // No action needed in profile view
                                            ),
                                          );
                                        } else {
                                          // Fallback for goals that don't match SDG pattern
                                          return Chip(
                                            label: Text(goal),
                                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          );
                                        }
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              
                            // About/Bio Section
                            if (profile?.bio != null && profile!.bio!.isNotEmpty)
                              _buildSection(
                                context,
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
                                    profile!.bio!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            
                            // Certifications Section (moved up per user request)
                            if (profile?.certifications != null && profile!.certifications!.isNotEmpty)
                              _buildSection(
                                context,
                                'Certifications',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: profile!.certifications!.map((cert) => _buildCertificationItem(context, cert)).toList(),
                                ),
                              ),
                              
                            // Work History Section
                            if (profile?.workHistory != null && profile!.workHistory!.isNotEmpty)
                              _buildSection(
                                context,
                                'Work History',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: profile!.workHistory!.map((work) => _buildWorkHistoryItem(context, work)).toList(),
                                ),
                              ),
                              
                            // Education Section
                            if (profile?.education != null && profile!.education!.isNotEmpty)
                              _buildSection(
                                context,
                                'Education',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: profile!.education!.map((edu) => _buildEducationItem(context, edu)).toList(),
                                ),
                              ),
                              
                            // Default Settings Section
                            _buildSection(
                              context,
                              'Default Settings',
                              _buildDefaultSettingsSection(context),
                            ),
                              
                            // User ID (truncated for display)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'ID: ${_truncateId(user.id)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Help & Support and About sections
                            _buildProfileSection(
                              context,
                              Icons.help_outline,
                              'Help & Support',
                              () => _showFeatureComingSoon(context),
                            ),
                            
                            _buildProfileSection(
                              context,
                              Icons.info_outline,
                              'About',
                              () => _showFeatureComingSoon(context),
                            ),
                            
                            const SizedBox(height: 32),
                            // Sign out button
                            ElevatedButton.icon(
                              onPressed: () => _confirmSignOut(context),
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
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
  
  Widget _buildProfileSection(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _getDisplayName(ProfileModel? profile) {
    // First try to get first and last name directly from the ProfileModel
    if (profile != null) {
      // If both first and last name are available, combine them
      if (profile.firstName != null && profile.firstName!.isNotEmpty && 
          profile.lastName != null && profile.lastName!.isNotEmpty) {
        return '${profile.firstName} ${profile.lastName}';
      } 
      // If only first name is available
      else if (profile.firstName != null && profile.firstName!.isNotEmpty) {
        return profile.firstName!;
      } 
      // If only last name is available
      else if (profile.lastName != null && profile.lastName!.isNotEmpty) {
        return profile.lastName!;
      }
      
      // If not in the model fields, check preferences as fallback
      if (profile.preferences != null) {
        final firstName = profile.preferences!['first_name'];
        final lastName = profile.preferences!['last_name'];
        
        // If both first and last name are available in preferences, combine them
        if (firstName != null && firstName.isNotEmpty && 
            lastName != null && lastName.isNotEmpty) {
          return '$firstName $lastName';
        } 
        // If only first name is available in preferences
        else if (firstName != null && firstName.isNotEmpty) {
          return firstName;
        } 
        // If only last name is available in preferences
        else if (lastName != null && lastName.isNotEmpty) {
          return lastName;
        }
      }
    }
    
    // Fall back to fullName if available
    if (profile?.fullName != null && profile!.fullName!.isNotEmpty) {
      return profile.fullName!;
    }
    
    // Fall back to username if available
    if (profile?.username != null && profile!.username!.isNotEmpty) {
      return profile.username!;
    }
    
    // Last resort: return 'No Name'
    return 'No Name';
  }

  int? _extractSDGNumber(String goalName) {
    // First try to extract SDG number from format "SDG X"
    final regex = RegExp(r'SDG (\d+)');
    final match = regex.firstMatch(goalName);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    
    // If not in SDG X format, map from full goal name to number
    switch (goalName) {
      case 'No Poverty': return 1;
      case 'Zero Hunger': return 2;
      case 'Good Health and Well-being': return 3;
      case 'Quality Education': return 4;
      case 'Gender Equality': return 5;
      case 'Clean Water and Sanitation': return 6;
      case 'Affordable and Clean Energy': return 7;
      case 'Decent Work and Economic Growth': return 8;
      case 'Industry, Innovation and Infrastructure': return 9;
      case 'Reduced Inequalities': return 10;
      case 'Sustainable Cities and Communities': return 11;
      case 'Responsible Consumption and Production': return 12;
      case 'Climate Action': return 13;
      case 'Life Below Water': return 14;
      case 'Life on Land': return 15;
      case 'Peace, Justice and Strong Institutions': return 16;
      case 'Partnerships for the Goals': return 17;
      default: return null;
    }
  }

  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  Widget _buildCertificationItem(BuildContext context, Certification cert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.name ?? 'Certification',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (cert.issuingOrganization != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Issued by: ${cert.issuingOrganization}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (cert.issueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${cert.issueDate.toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
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

  Widget _buildWorkHistoryItem(BuildContext context, WorkHistory work) {
    String duration = '';
    if (work.startDate != null) {
      final startYear = work.startDate!.year.toString();
      if (work.isCurrent == true) {
        duration = '$startYear - Present';
      } else if (work.endDate != null) {
        final endYear = work.endDate!.year.toString();
        duration = '$startYear - $endYear';
      } else {
        duration = startYear;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work.title ?? 'Position',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (work.company != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      work.company!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      duration,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Verification badge
            if (work.organizationId != null)
              ValidationStatusWidget(
                userId: Provider.of<AuthProvider>(context, listen: false).user!.id,
                organizationId: work.organizationId,
                organizationName: work.company,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(BuildContext context, Education edu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              edu.degree ?? 'Education',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (edu.institution != null) ...[
              const SizedBox(height: 4),
              Text(
                edu.institution!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (edu.endDate != null) ...[
              const SizedBox(height: 4),
              Text(
                edu.endDate!.year.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ] else if (edu.startDate != null) ...[
              const SizedBox(height: 4),
              Text(
                edu.startDate!.year.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFeatureComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildDefaultSettingsSection(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Notifications
        _buildToggleSetting(
          context,
          'Email Notifications',
          false, // Default value
          (value) => _showFeatureComingSoon(context),
        ),
        
        // Push Notifications
        _buildToggleSetting(
          context,
          'Push Notifications',
          true, // Default value
          (value) => _showFeatureComingSoon(context),
        ),
        
        // Public Profile
        _buildToggleSetting(
          context,
          'Public Profile',
          true, // Default value
          (value) => _showFeatureComingSoon(context),
        ),
        
        // Electricity Grid
        _buildValueSetting(
          context,
          'Electricity Grid',
          'north_america',
          () => _showFeatureComingSoon(context),
        ),
        
        // Electricity Source
        _buildValueSetting(
          context,
          'Electricity Source',
          'hydro',
          () => _showFeatureComingSoon(context),
        ),
        
        // Transportation
        _buildValueSetting(
          context,
          'Transportation',
          'Car',
          () => _showFeatureComingSoon(context),
        ),
        
        // Fuel Type
        _buildValueSetting(
          context,
          'Fuel Type',
          'electric',
          () => _showFeatureComingSoon(context),
        ),
        

      ],
    );
  }
  
  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildToggleSetting(
    BuildContext context,
    String title,
    bool initialValue,
    Function(bool) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Switch(
          value: initialValue,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildValueSetting(
    BuildContext context,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(color: Colors.grey[600]),
        ),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildLinkSetting(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
