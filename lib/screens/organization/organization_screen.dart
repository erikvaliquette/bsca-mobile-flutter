import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/screens/organization/organization_profile_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/carbon_footprint_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/team_members_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/activities_screen.dart';
import 'package:intl/intl.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch organization data when the screen loads
    Future.microtask(() =>
        Provider.of<OrganizationProvider>(context, listen: false)
            .fetchOrganization());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
      ),
      body: Consumer<OrganizationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading organization data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(provider.error ?? 'Unknown error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchOrganization();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final organization = provider.organization;
          if (organization == null) {
            return const Center(child: Text('No organization data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrganizationHeader(organization),
                const SizedBox(height: 24),
                _buildSectionTitle('Overview'),
                _buildOverviewCard(organization),
                const SizedBox(height: 24),
                _buildSectionTitle('Sustainability Metrics'),
                _buildSustainabilityMetricsCard(organization),
                const SizedBox(height: 24),
                _buildSectionTitle('Carbon Footprint'),
                _buildCarbonFootprintCard(organization),
                const SizedBox(height: 24),
                _buildSectionTitle('Team'),
                _buildTeamCard(organization),
                const SizedBox(height: 24),
                _buildSectionTitle('Recent Activities'),
                _buildActivitiesCard(organization),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrganizationHeader(Organization organization) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (organization.logoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  organization.logoUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.business, size: 40),
                    );
                  },
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.business, size: 40),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (organization.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            organization.location!,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (organization.website != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            organization.website!,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Organization organization) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (organization.description != null)
              Text(
                organization.description!,
                style: const TextStyle(fontSize: 16),
              ),
            if (organization.sdgFocusAreas != null &&
                organization.sdgFocusAreas!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'SDG Focus Areas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: organization.sdgFocusAreas!
                    .map((sdg) => Chip(
                          label: Text(sdg),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrganizationProfileScreen(
                        organization: organization,
                      ),
                    ),
                  );
                },
                child: const Text('View Full Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilityMetricsCard(Organization organization) {
    if (organization.sustainabilityMetrics == null ||
        organization.sustainabilityMetrics!.isEmpty) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No sustainability metrics available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            for (var metric in organization.sustainabilityMetrics!)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    if (metric.icon != null)
                      Icon(metric.icon, size: 24)
                    else
                      const Icon(Icons.check_circle_outline, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: double.tryParse(metric.value)! / 100,
                            backgroundColor: Colors.grey[200],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${metric.value}${metric.unit ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonFootprintCard(Organization organization) {
    if (organization.carbonFootprint == null) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No carbon footprint data available'),
          ),
        ),
      );
    }

    final carbonFootprint = organization.carbonFootprint!;
    final reductionPercentage = carbonFootprint.reductionAchieved != null && 
                               carbonFootprint.reductionGoal != null
        ? (carbonFootprint.reductionAchieved! / carbonFootprint.reductionGoal!) * 100
        : 0.0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Emissions: ${carbonFootprint.totalEmissions} ${carbonFootprint.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (carbonFootprint.reductionGoal != null) ...[
              const SizedBox(height: 16),
              Text(
                'Reduction Goal: ${carbonFootprint.reductionGoal} ${carbonFootprint.unit}',
              ),
              const SizedBox(height: 8),
              if (carbonFootprint.reductionAchieved != null) ...[
                Text(
                  'Progress: ${carbonFootprint.reductionAchieved} ${carbonFootprint.unit} (${reductionPercentage.toStringAsFixed(1)}%)',
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: reductionPercentage / 100,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ],
            if (carbonFootprint.categories != null &&
                carbonFootprint.categories!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Emission Categories:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              for (var category in carbonFootprint.categories!.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        IconData(
                          int.tryParse(category.icon ?? '0xe25c') ?? 0xe25c,
                          fontFamily: 'MaterialIcons',
                        ),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(category.name),
                      ),
                      Text(
                        '${category.value} ${carbonFootprint.unit}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(Organization organization) {
    if (organization.teamMembers == null || organization.teamMembers!.isEmpty) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No team members available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: organization.teamMembers!.length,
                itemBuilder: (context, index) {
                  final member = organization.teamMembers![index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: member.photoUrl != null
                              ? NetworkImage(member.photoUrl!)
                              : null,
                          child: member.photoUrl == null
                              ? Text(member.name.substring(0, 1))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member.name.split(' ')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
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
                child: const Text('View All Team Members'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesCard(Organization organization) {
    if (organization.recentActivities == null ||
        organization.recentActivities!.isEmpty) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No recent activities available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var activity in organization.recentActivities!.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activity.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image.network(
                          activity.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 30),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Icon(Icons.event, size: 30),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(activity.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (activity.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              activity.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivitiesScreen(
                        activities: organization.recentActivities!,
                      ),
                    ),
                  );
                },
                child: const Text('View All Activities'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
