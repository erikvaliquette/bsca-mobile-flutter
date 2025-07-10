import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/profile_model.dart';

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
              // Will implement edit profile functionality later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon'),
                ),
              );
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
                  
                  // Profile sections
                  _buildProfileSection(
                    context,
                    Icons.notifications_outlined,
                    'Notification Settings',
                    () => _showFeatureComingSoon(context),
                  ),
                  
                  _buildProfileSection(
                    context,
                    Icons.lock_outline,
                    'Privacy Settings',
                    () => _showFeatureComingSoon(context),
                  ),
                  
                  _buildProfileSection(
                    context,
                    Icons.language_outlined,
                    'Language',
                    () => _showFeatureComingSoon(context),
                  ),
                  
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile!.sdgGoals!.map((goal) => Chip(
                              label: Text(goal),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            )).toList(),
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
