import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Logo and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo/app_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SDG Network',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Business Sustainability & Carbon Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Mission Statement
          _buildSectionHeader('Our Mission'),
          const SizedBox(height: 16),
          const Text(
            'SDG Network empowers businesses and professionals to measure, track, and reduce their carbon footprint while building sustainable networks and contributing to the United Nations Sustainable Development Goals.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Key Features
          _buildSectionHeader('Key Features'),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.analytics,
            'Carbon Tracking',
            'Track and analyze your travel emissions with precision',
          ),
          _buildFeatureItem(
            Icons.people,
            'Professional Network',
            'Connect with sustainability professionals worldwide',
          ),
          _buildFeatureItem(
            Icons.business,
            'Organization Management',
            'Manage team carbon footprints and sustainability goals',
          ),
          _buildFeatureItem(
            Icons.public,
            'SDG Integration',
            'Contribute to UN Sustainable Development Goals',
          ),
          _buildFeatureItem(
            Icons.calculate,
            'Carbon Calculator',
            'Calculate emissions for various activities and scenarios',
          ),
          _buildFeatureItem(
            Icons.lightbulb,
            'Sustainability Solutions',
            'Discover actionable solutions for reducing your impact',
          ),
          
          const SizedBox(height: 32),
          
          // Company Information
          _buildSectionHeader('Company Information'),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Company',
            'SDG Network',
            Icons.business,
          ),
          _buildInfoCard(
            'Founded',
            '2019',
            Icons.calendar_today,
          ),
          _buildInfoCard(
            'Location',
            'Global',
            Icons.public,
          ),
          _buildInfoCard(
            'Industry',
            'Sustainability Technology',
            Icons.eco,
          ),
          
          const SizedBox(height: 32),
          
          // Links Section
          _buildSectionHeader('Connect With Us'),
          const SizedBox(height: 16),
          _buildLinkItem(
            Icons.language,
            'Website',
            'Visit our website',
            () => _launchURL('https://sdg-odd.tech'),
          ),
          _buildLinkItem(
            Icons.privacy_tip,
            'Privacy Policy',
            'Read our privacy policy',
            () => _launchURL('https://sdg-odd.tech/privacy'),
          ),
          _buildLinkItem(
            Icons.description,
            'Terms of Service',
            'View terms and conditions',
            () => _launchURL('https://sdg-odd.tech/terms-of-use'),
          ),
          _buildLinkItem(
            Icons.email,
            'Contact Us',
            'Get in touch with our team',
            () => _launchEmail(),
          ),
          
          const SizedBox(height: 32),
          
          // Social Media
          _buildSectionHeader('Follow Us'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                FontAwesomeIcons.linkedin,
                'LinkedIn',
                () => _launchURL('https://linkedin.com/company/bscaglobal'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Credits and Acknowledgments
          _buildSectionHeader('Acknowledgments'),
          const SizedBox(height: 16),
          const Text(
            'Special thanks to the United Nations for the Sustainable Development Goals framework, and to all the sustainability professionals working towards a better future.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            '© 2024 SDG Network. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
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

  Widget _buildFeatureItem(IconData icon, String title, String description) {
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
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
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

  Widget _buildLinkItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
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
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(height: 4),
            Text(
              platform,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hello@bsca.global',
      query: 'subject=SDG Network Mobile App Inquiry',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
