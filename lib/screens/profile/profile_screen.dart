import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/profile_model.dart';
import '../../utils/sdg_icons.dart';
import '../../widgets/sdg_icon_widget.dart';
import '../../services/sdg_icon_service.dart';
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Profile avatar
                  profileProvider.isLoading
                      ? const CircularProgressIndicator()
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          backgroundImage: profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null,
                          child: profile?.avatarUrl == null
                              ? Text(
                                  _getInitials(profile?.fullName ?? user.email ?? ''),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                  const SizedBox(height: 24),
                  // User name or email
                  Text(
                    profile?.fullName ?? profile?.username ?? user.email ?? 'No email',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  // User email if name is available
                  if (profile?.fullName != null || profile?.username != null)
                    Text(
                      user.email ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  // User bio if available
                  if (profile?.bio != null && profile!.bio!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Text(
                        profile!.bio!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // User ID (truncated for display)
                  Text(
                    'ID: ${_truncateId(user.id)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  
                  // Profile sections removed - now edited in edit_profile_screen.dart
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 32),
                  
                  // SDG Goals Section
                  if (profile?.sdgGoals != null && profile!.sdgGoals!.isNotEmpty)
                    _buildSection(
                      context,
                      'SDG Goals',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your selected Sustainable Development Goals:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
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
                          const SizedBox(height: 8),
                          Text(
                            'Total: ${profile!.sdgGoals!.length} goals',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
                    
                  // Certifications Section
                  if (profile?.certifications != null && profile!.certifications!.isNotEmpty)
                    _buildSection(
                      context,
                      'Certifications',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: profile!.certifications!.map((cert) => _buildCertificationItem(context, cert)).toList(),
                      ),
                    ),
                  
                  // Default Settings Section
                  if (profile?.preferences != null && profile!.preferences!.isNotEmpty)
                    _buildSection(
                      context,
                      'Default Settings',
                      _buildDefaultSettingsSection(context, profile!.preferences!),
                    ),
                    
                  const SizedBox(height: 32),
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
                ],
              ),
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
  
  void _showFeatureComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon'),
      ),
    );
  }
  
  Future<void> _confirmSignOut(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
    
    if (result == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}

String _getInitials(String name) {
  if (name.isEmpty) return '';
  final nameParts = name.split(' ');
  if (nameParts.length > 1) {
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }
  return name[0].toUpperCase();
}

String _truncateId(String id) {
  if (id.length <= 8) return id;
  return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
}

Widget _buildSection(BuildContext context, String title, Widget content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      content,
      const SizedBox(height: 8),
    ],
  );
}

Widget _buildWorkHistoryItem(BuildContext context, WorkHistory work) {
  final dateFormat = (date) => date?.year.toString() ?? 'Present';
  final dateRange = '${dateFormat(work.startDate)} - ${work.isCurrent == true ? 'Present' : dateFormat(work.endDate)}';
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            work.position ?? 'Position',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            work.company ?? 'Company',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (work.description != null && work.description!.isNotEmpty) ...[  
            const SizedBox(height: 8),
            Text(work.description!),
          ],
        ],
      ),
    ),
  );
}

Widget _buildEducationItem(BuildContext context, Education education) {
  final dateFormat = (date) => date?.year.toString() ?? 'Present';
  final dateRange = '${dateFormat(education.startDate)} - ${education.isCurrent == true ? 'Present' : dateFormat(education.endDate)}';
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            education.degree ?? 'Degree',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            education.institution ?? 'Institution',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          if (education.fieldOfStudy != null) ...[  
            Text(
              education.fieldOfStudy!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            dateRange,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCertificationItem(BuildContext context, Certification cert) {
  final dateFormat = (date) => date != null ? '${date.month}/${date.year}' : 'N/A';
  final issueDate = dateFormat(cert.issueDate);
  final expiryDate = cert.expirationDate != null ? dateFormat(cert.expirationDate) : 'No Expiration';
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cert.name ?? 'Certification',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cert.issuingOrganization ?? 'Issuing Organization',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Issued: $issueDate${cert.expirationDate != null ? ' · Expires: $expiryDate' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (cert.credentialId != null) ...[  
            const SizedBox(height: 4),
            Text(
              'Credential ID: ${cert.credentialId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (cert.credentialUrl != null) ...[  
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // TODO: Open URL
              },
              child: Text(
                'View Credential',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildDefaultSettingsSection(BuildContext context, Map<String, dynamic> preferences) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Email Notifications
      ListTile(
        title: const Text('Email Notifications'),
        trailing: Icon(
          preferences['email_notifications'] == true ? Icons.toggle_on : Icons.toggle_off,
          color: preferences['email_notifications'] == true ? Theme.of(context).colorScheme.primary : Colors.grey,
          size: 32,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      
      // Push Notifications
      ListTile(
        title: const Text('Push Notifications'),
        trailing: Icon(
          preferences['push_notifications'] == true ? Icons.toggle_on : Icons.toggle_off,
          color: preferences['push_notifications'] == true ? Theme.of(context).colorScheme.primary : Colors.grey,
          size: 32,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      
      // Public Profile
      ListTile(
        title: const Text('Public Profile'),
        trailing: Icon(
          preferences['public_profile'] == true ? Icons.toggle_on : Icons.toggle_off,
          color: preferences['public_profile'] == true ? Theme.of(context).colorScheme.primary : Colors.grey,
          size: 32,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      
      // Language
      if (preferences['language'] != null) ListTile(
        title: const Text('Language'),
        trailing: Text(
          preferences['language'].toString(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      
      // Display any other preferences
      ...preferences.entries
        .where((entry) => !['email_notifications', 'push_notifications', 'public_profile', 'language'].contains(entry.key))
        .map((entry) => ListTile(
          title: Text(_formatPreferenceKey(entry.key)),
          trailing: Text(
            entry.value.toString(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          contentPadding: EdgeInsets.zero,
        )),
    ],
  );
}

String _formatPreferenceKey(String key) {
  // Convert snake_case to Title Case
  return key
      .split('_')
      .map((word) => word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '')
      .join(' ');
}

/// Extract SDG number from goal name
/// Examples: "SDG 1: No Poverty" -> 1, "Climate Action" -> 13
int? _extractSDGNumber(String goal) {
  // Check if the goal starts with "SDG" followed by a number
  final sdgPattern = RegExp(r'SDG\s*(\d+)');
  final match = sdgPattern.firstMatch(goal);
  
  if (match != null && match.groupCount >= 1) {
    return int.tryParse(match.group(1)!);
  }
  
  // If not in SDG format, try to match by goal name
  final goalNameMap = {
    'No Poverty': 1,
    'Zero Hunger': 2,
    'Good Health and Well-being': 3,
    'Quality Education': 4,
    'Gender Equality': 5,
    'Clean Water and Sanitation': 6,
    'Affordable and Clean Energy': 7,
    'Decent Work and Economic Growth': 8,
    'Industry, Innovation and Infrastructure': 9,
    'Reduced Inequalities': 10,
    'Sustainable Cities and Communities': 11,
    'Responsible Consumption and Production': 12,
    'Climate Action': 13,
    'Life Below Water': 14,
    'Life on Land': 15,
    'Peace, Justice and Strong Institutions': 16,
    'Partnerships for the Goals': 17,
  };
  
  // Check for exact matches or if the goal contains the name
  for (final entry in goalNameMap.entries) {
    if (goal == entry.key || goal.contains(entry.key)) {
      return entry.value;
    }
  }
  
  return null;
}
