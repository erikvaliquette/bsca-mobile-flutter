import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:intl/intl.dart';

class ActivitiesScreen extends StatelessWidget {
  final List<Activity> activities;

  const ActivitiesScreen({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    // Sort activities by date, most recent first
    final sortedActivities = List<Activity>.from(activities)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedActivities.length,
        itemBuilder: (context, index) {
          final activity = sortedActivities[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4.0),
                    ),
                    child: Image.network(
                      activity.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 60),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildActivityTypeChip(activity.type),
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, yyyy').format(activity.date),
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (activity.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          activity.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityTypeChip(String? type) {
    IconData icon;
    String label;
    Color color;

    switch (type?.toLowerCase()) {
      case 'event':
        icon = Icons.event;
        label = 'Event';
        color = Colors.blue;
        break;
      case 'initiative':
        icon = Icons.lightbulb;
        label = 'Initiative';
        color = Colors.green;
        break;
      case 'achievement':
        icon = Icons.emoji_events;
        label = 'Achievement';
        color = Colors.amber;
        break;
      case 'announcement':
        icon = Icons.campaign;
        label = 'Announcement';
        color = Colors.purple;
        break;
      case 'infrastructure':
        icon = Icons.business;
        label = 'Infrastructure';
        color = Colors.teal;
        break;
      case 'community':
        icon = Icons.people;
        label = 'Community';
        color = Colors.deepOrange;
        break;
      case 'product':
        icon = Icons.shopping_bag;
        label = 'Product';
        color = Colors.indigo;
        break;
      default:
        icon = Icons.info;
        label = type ?? 'Other';
        color = Colors.grey;
        break;
    }

    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
