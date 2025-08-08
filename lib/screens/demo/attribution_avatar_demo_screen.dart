import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/widgets/attribution_avatar_widget.dart';

/// Demo screen to showcase attribution avatars for Targets, Actions, and Activities
class AttributionAvatarDemoScreen extends StatelessWidget {
  const AttributionAvatarDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribution Avatar Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attribution Avatar System',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This system shows user/organization avatars to indicate attribution for SDG Targets, Actions, and Activities.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CompactAttributionAvatar(
                          organizationId: null,
                          userId: 'demo-user',
                        ),
                        const SizedBox(width: 8),
                        const Text('Personal (Green) - User\'s personal items'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CompactAttributionAvatar(
                          organizationId: 'demo-org',
                          userId: 'demo-user',
                        ),
                        const SizedBox(width: 8),
                        const Text('Organizational (Blue) - Organization items'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // SDG Target Example
            Text(
              'SDG Target Example',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Target 7.2',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Personal Target Avatar
                    const CompactAttributionAvatar(
                      organizationId: null,
                      userId: 'demo-user',
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Increase renewable energy share (Personal)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Action Example
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.blue.withValues(alpha: 0.05),
                          ),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ACTION',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Organizational Action Avatar
                                const CompactAttributionAvatar(
                                  organizationId: 'demo-org',
                                  userId: 'demo-user',
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Install Solar Panels (Organizational)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    // Activity Example 1
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              'COMPLETED',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Personal Activity Avatar
                                          const CompactAttributionAvatar(
                                            organizationId: null,
                                            userId: 'demo-user',
                                          ),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text(
                                              'Get solar quotes (Personal)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Activity Example 2
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              'IN_PROGRESS',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Organizational Activity Avatar
                                          const CompactAttributionAvatar(
                                            organizationId: 'demo-org',
                                            userId: 'demo-user',
                                          ),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text(
                                              'Install panels on office building (Organizational)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Avatar Sizes Demo
            Text(
              'Avatar Sizes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CompactAttributionAvatar(
                          organizationId: null,
                          userId: 'demo-user',
                        ),
                        const SizedBox(width: 12),
                        const Text('Compact (20px) - Used in lists'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const AttributionAvatarWidget(
                          organizationId: 'demo-org',
                          userId: 'demo-user',
                          size: 24.0,
                        ),
                        const SizedBox(width: 12),
                        const Text('Default (24px) - Standard size'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const LargeAttributionAvatar(
                          organizationId: null,
                          userId: 'demo-user',
                        ),
                        const SizedBox(width: 12),
                        const Text('Large (32px) - Headers and details'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Implementation Notes
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Implementation Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Avatars automatically show based on organizationId field'),
                    const SizedBox(height: 4),
                    const Text('✅ Personal items: Green avatar with user profile image'),
                    const SizedBox(height: 4),
                    const Text('✅ Organizational items: Blue avatar with organization logo'),
                    const SizedBox(height: 4),
                    const Text('✅ Tooltips show user name or organization name'),
                    const SizedBox(height: 4),
                    const Text('✅ Integrated with ProfileProvider and OrganizationProvider'),
                    const SizedBox(height: 4),
                    const Text('✅ Three sizes: Compact, Default, and Large'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
