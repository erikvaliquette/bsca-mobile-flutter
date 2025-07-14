import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganizationProfileScreen extends StatelessWidget {
  final Organization organization;

  const OrganizationProfileScreen({
    super.key,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
            if (organization.sdgFocusAreas != null &&
                organization.sdgFocusAreas!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSDGSection(context),
            ],
            const SizedBox(height: 24),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (organization.logoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  organization.logoUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.business, size: 60),
                    );
                  },
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.business, size: 60),
              ),
            const SizedBox(height: 16),
            Text(
              organization.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (organization.location != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    organization.location!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (organization.description != null)
              Text(
                organization.description!,
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                'No description available.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSDGSection(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SDG Focus Areas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: organization.sdgFocusAreas!
                  .map((sdg) => _buildSDGChip(context, sdg))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSDGChip(BuildContext context, String sdg) {
    // Extract the SDG number to determine the color
    final RegExp regExp = RegExp(r'SDG (\d+)');
    final match = regExp.firstMatch(sdg);
    final int sdgNumber = match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
    
    // SDG colors (simplified)
    final List<Color> sdgColors = [
      Colors.red,           // SDG 1: No Poverty
      Colors.yellow[700]!,  // SDG 2: Zero Hunger
      Colors.green,         // SDG 3: Good Health and Well-being
      Colors.red[900]!,     // SDG 4: Quality Education
      Colors.red[400]!,     // SDG 5: Gender Equality
      Colors.blue,          // SDG 6: Clean Water and Sanitation
      Colors.yellow,        // SDG 7: Affordable and Clean Energy
      Colors.red[800]!,     // SDG 8: Decent Work and Economic Growth
      Colors.orange,        // SDG 9: Industry, Innovation and Infrastructure
      Colors.pink,          // SDG 10: Reduced Inequality
      Colors.amber,         // SDG 11: Sustainable Cities and Communities
      Colors.amber[800]!,   // SDG 12: Responsible Consumption and Production
      Colors.green[800]!,   // SDG 13: Climate Action
      Colors.blue[800]!,    // SDG 14: Life Below Water
      Colors.green[600]!,   // SDG 15: Life on Land
      Colors.blue[900]!,    // SDG 16: Peace, Justice and Strong Institutions
      Colors.blue[300]!,    // SDG 17: Partnerships for the Goals
    ];
    
    final Color chipColor = sdgNumber > 0 && sdgNumber <= sdgColors.length 
        ? sdgColors[sdgNumber - 1] 
        : Colors.grey;
    
    return Chip(
      label: Text(
        sdg,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (organization.website != null)
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Website'),
                subtitle: Text(organization.website!),
                onTap: () => _launchURL(organization.website!),
              ),
            if (organization.location != null)
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                subtitle: Text(organization.location!),
                onTap: () => _launchMaps(organization.location!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchMaps(String location) async {
    final Uri uri = Uri.parse('https://maps.google.com/?q=$location');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch maps for $location';
    }
  }
}
