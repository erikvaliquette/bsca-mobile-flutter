import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bsca_mobile_flutter/screens/organization/carbon_footprint_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/team_members_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/activities_screen.dart';
import 'package:intl/intl.dart';

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
            const SizedBox(height: 24),
            _buildSDGSection(context),
            const SizedBox(height: 24),
            _buildSustainabilityMetricsSection(context),
            const SizedBox(height: 24),
            _buildCarbonFootprintSection(context),
            const SizedBox(height: 24),
            _buildTeamSection(context),
            const SizedBox(height: 24),
            _buildActivitiesSection(context),
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
            if (organization.logoUrl != null && organization.logoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  organization.logoUrl!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.business,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              organization.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (organization.location != null && organization.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(organization.location!),
                ],
              ),
            ],
            if (organization.foundedYear != null) ...[
              const SizedBox(height: 8),
              Text('Founded in ${organization.foundedYear}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              organization.description ?? 'No description available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSDGSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SDG Focus Areas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (organization.sdgFocusAreas != null &&
                organization.sdgFocusAreas!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: organization.sdgFocusAreas!.map((sdg) {
                  return Chip(
                    label: Text(sdg),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              )
            else
              const Text('No SDG focus areas specified'),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilityMetricsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sustainability Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (organization.sustainabilityMetrics == null || 
                organization.sustainabilityMetrics!.isEmpty)
              const Text('No sustainability metrics available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: organization.sustainabilityMetrics!.length,
                itemBuilder: (context, index) {
                  final metric = organization.sustainabilityMetrics![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getIconForMetric(metric.name),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                metric.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (metric.description != null && metric.description!.isNotEmpty) ...[
                          Text(
                            metric.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                        ],
                        LinearProgressIndicator(
                          value: metric.target != null && metric.target! > 0
                              ? metric.value / metric.target!
                              : metric.value / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current: ${metric.value}${metric.unit ?? '%'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (metric.target != null)
                              Text(
                                'Target: ${metric.target}${metric.unit ?? '%'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonFootprintSection(BuildContext context) {
    final carbonFootprint = organization.carbonFootprint;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Carbon Footprint',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (carbonFootprint != null)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarbonFootprintScreen(
                            carbonFootprint: carbonFootprint,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (carbonFootprint == null)
              const Text('No carbon footprint data available')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.co2,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${carbonFootprint.totalEmissions} ${carbonFootprint.unit}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${carbonFootprint.year})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (carbonFootprint.reductionGoal != null && 
                      carbonFootprint.reductionTarget != null) ...[
                    Text(
                      'Reduction Goal: ${carbonFootprint.reductionGoal}% by ${DateTime.now().year + 5}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: carbonFootprint.totalEmissions > 0 ? 
                        (carbonFootprint.totalEmissions - (carbonFootprint.reductionTarget ?? 0)) / 
                        (carbonFootprint.totalEmissions * (carbonFootprint.reductionGoal ?? 1) / 100) : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: ${carbonFootprint.totalEmissions} ${carbonFootprint.unit}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Target: ${carbonFootprint.reductionTarget} ${carbonFootprint.unit}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (organization.teamMembers != null && 
                    organization.teamMembers!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamMembersScreen(
                            teamMembers: organization.teamMembers!,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (organization.teamMembers == null || 
                organization.teamMembers!.isEmpty)
              const Text('No team members available')
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: organization.teamMembers!.length > 5 
                      ? 5 
                      : organization.teamMembers!.length,
                  itemBuilder: (context, index) {
                    final member = organization.teamMembers![index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                                ? NetworkImage(member.photoUrl!)
                                : null,
                            child: member.photoUrl == null || member.photoUrl!.isEmpty
                                ? Text(
                                    member.name.isNotEmpty ? member.name.substring(0, 1) : '?',
                                    style: const TextStyle(fontSize: 24),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            member.name.isNotEmpty ? member.name.split(' ').first : 'Unknown',
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (organization.activities != null && 
                    organization.activities!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivitiesScreen(
                            activities: organization.activities!,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (organization.activities == null || 
                organization.activities!.isEmpty)
              const Text('No recent activities available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: organization.activities!.length > 3 
                    ? 3 
                    : organization.activities!.length,
                itemBuilder: (context, index) {
                  final activity = organization.activities![index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: _getIconForActivityType(activity.type),
                    ),
                    title: Text(activity.title),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(activity.date),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (organization.website != null && organization.website!.isNotEmpty)
              InkWell(
                onTap: () async {
                  final url = Uri.parse(organization.website!.startsWith('http') 
                      ? organization.website! 
                      : 'https://${organization.website!}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          organization.website!,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('No website available'),
          ],
        ),
      ),
    );
  }

  Icon _getIconForMetric(String metricName) {
    final name = metricName.toLowerCase();
    if (name.contains('energy') || name.contains('renewable')) {
      return const Icon(Icons.bolt, color: Colors.amber);
    } else if (name.contains('water')) {
      return const Icon(Icons.water_drop, color: Colors.blue);
    } else if (name.contains('waste')) {
      return const Icon(Icons.delete_outline, color: Colors.green);
    } else if (name.contains('carbon') || name.contains('emission')) {
      return const Icon(Icons.co2, color: Colors.grey);
    } else {
      return const Icon(Icons.eco, color: Colors.green);
    }
  }

  Icon _getIconForActivityType(String? type) {
    if (type == null) return const Icon(Icons.event);
    
    final activityType = type.toLowerCase();
    if (activityType.contains('event')) {
      return const Icon(Icons.event);
    } else if (activityType.contains('award') || activityType.contains('achievement')) {
      return const Icon(Icons.emoji_events);
    } else if (activityType.contains('initiative') || activityType.contains('project')) {
      return const Icon(Icons.lightbulb);
    } else if (activityType.contains('partnership')) {
      return const Icon(Icons.handshake);
    } else if (activityType.contains('certification')) {
      return const Icon(Icons.verified);
    } else if (activityType.contains('report') || activityType.contains('publication')) {
      return const Icon(Icons.description);
    } else if (activityType.contains('milestone')) {
      return const Icon(Icons.flag);
    } else {
      return const Icon(Icons.star);
    }
  }
}
