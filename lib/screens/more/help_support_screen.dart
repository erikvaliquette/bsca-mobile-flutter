import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bug_report_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // FAQ Section
          _buildSectionHeader('Frequently Asked Questions'),
          const SizedBox(height: 16),
          _buildFAQItem(
            'How do I track my carbon emissions?',
            'Navigate to the Travel Emissions screen and tap "Start Tracking" to begin recording your trip. The app will automatically calculate emissions based on your transportation mode and fuel type.',
          ),
          _buildFAQItem(
            'How do I connect with other professionals?',
            'Go to the Network tab and use the Discover section to find and connect with other sustainability professionals. You can send connection requests and build your network.',
          ),
          _buildFAQItem(
            'How do I join an organization?',
            'Add your work history in your profile and request validation from your employer. Once approved, you\'ll be attributed to your organization and can access team features.',
          ),
          _buildFAQItem(
            'What are SDGs?',
            'Sustainable Development Goals (SDGs) are 17 global goals set by the United Nations to achieve a better and more sustainable future for all. You can explore and contribute to these goals through our platform.',
          ),
          _buildFAQItem(
            'How is my carbon footprint calculated?',
            'We use industry-standard emission factors based on your transportation mode, fuel type, and distance traveled. Different activities have different emission rates per kilometer.',
          ),
          
          const SizedBox(height: 32),
          
          // Contact Support Section
          _buildSectionHeader('Contact Support'),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'Get help via email',
            onTap: () => _launchEmail(),
          ),       
          const SizedBox(height: 32),
          
          // Resources Section
          _buildSectionHeader('Resources'),
          const SizedBox(height: 16),
          _buildResourceOption(
            icon: Icons.book,
            title: 'User Guide',
            subtitle: 'Complete guide to using SDG Network',
            onTap: () => _showComingSoon(context, 'User Guide'),
          ),
          _buildResourceOption(
            icon: Icons.bug_report,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BugReportScreen()),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // App Information
          _buildSectionHeader('App Information'),
          const SizedBox(height: 16),
          _buildInfoItem('App Version', '1.0.0'),
          _buildInfoItem('Last Updated', 'August 2025'),
          _buildInfoItem('Platform', 'iOS & Android'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hello@bsca.global',
      query: 'subject=SDG Network Mobile App Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+1-800-BSCA-HELP',
    );
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text('The $feature feature is currently being developed and will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
