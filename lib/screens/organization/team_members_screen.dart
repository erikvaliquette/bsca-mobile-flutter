import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMembersScreen extends StatelessWidget {
  final List<TeamMember> teamMembers;

  const TeamMembersScreen({
    super.key,
    required this.teamMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: teamMembers.length,
        itemBuilder: (context, index) {
          final member = teamMembers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: member.photoUrl != null
                        ? NetworkImage(member.photoUrl!)
                        : null,
                    child: member.photoUrl == null
                        ? Text(
                            _getInitials(member.name),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (member.role != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            member.role!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (member.email != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _launchEmail(member.email!),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.email,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  member.email!,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0];
      
      if (nameParts.length > 1) {
        initials += nameParts[nameParts.length - 1][0];
      }
    }
    
    return initials.toUpperCase();
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email to $email';
    }
  }
}
