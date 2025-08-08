import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/profile_provider.dart';

/// Widget that displays an avatar indicating whether an item is personal or organizational
class AttributionAvatarWidget extends StatelessWidget {
  final String? organizationId;
  final String? userId;
  final double size;
  final bool showTooltip;

  const AttributionAvatarWidget({
    Key? key,
    this.organizationId,
    this.userId,
    this.size = 24.0,
    this.showTooltip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    // Determine if this is organizational or personal
    final bool isOrganizational = organizationId != null && organizationId!.isNotEmpty;
    
    if (isOrganizational) {
      return _buildOrganizationAvatar(context);
    } else {
      return _buildPersonalAvatar(context, currentUserId);
    }
  }

  Widget _buildOrganizationAvatar(BuildContext context) {
    return Consumer<OrganizationProvider>(
      builder: (context, orgProvider, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getOrganizationInfo(orgProvider),
          builder: (context, snapshot) {
            final orgData = snapshot.data;
            final orgName = orgData?['name'] ?? 'Organization';
            final orgLogo = orgData?['logo_url'];
            
            Widget avatar = CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: orgLogo != null ? NetworkImage(orgLogo) : null,
              child: orgLogo == null
                  ? Icon(
                      Icons.business,
                      size: size * 0.6,
                      color: Colors.blue.shade700,
                    )
                  : null,
            );

            if (showTooltip) {
              return Tooltip(
                message: 'Organization: $orgName',
                child: avatar,
              );
            }
            
            return avatar;
          },
        );
      },
    );
  }

  Widget _buildPersonalAvatar(BuildContext context, String? currentUserId) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;
        final userName = profile != null 
            ? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim()
            : 'Personal';
        final userImageUrl = profile?.avatarUrl;
        
        Widget avatar = CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.green.shade100,
          backgroundImage: userImageUrl != null && userImageUrl.isNotEmpty 
              ? NetworkImage(userImageUrl) 
              : null,
          child: userImageUrl == null || userImageUrl.isEmpty
              ? Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: Colors.green.shade700,
                )
              : null,
        );

        if (showTooltip) {
          return Tooltip(
            message: userName.isNotEmpty ? userName : 'Personal',
            child: avatar,
          );
        }
        
        return avatar;
      },
    );
  }

  Future<Map<String, dynamic>?> _getOrganizationInfo(OrganizationProvider orgProvider) async {
    if (organizationId == null) return null;
    
    try {
      // Use the new method from OrganizationProvider to get basic info
      final orgInfo = await orgProvider.getOrganizationBasicInfo(organizationId!);
      
      if (orgInfo != null) {
        return orgInfo;
      }
      
      // Fallback if organization not found
      return {
        'name': 'Organization',
        'logo_url': null,
      };
    } catch (e) {
      debugPrint('Error getting organization info for avatar: $e');
      return {
        'name': 'Organization',
        'logo_url': null,
      };
    }
  }
}

/// Compact version for use in lists
class CompactAttributionAvatar extends StatelessWidget {
  final String? organizationId;
  final String? userId;

  const CompactAttributionAvatar({
    Key? key,
    this.organizationId,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AttributionAvatarWidget(
      organizationId: organizationId,
      userId: userId,
      size: 20.0,
      showTooltip: true,
    );
  }
}

/// Large version for headers or detailed views
class LargeAttributionAvatar extends StatelessWidget {
  final String? organizationId;
  final String? userId;

  const LargeAttributionAvatar({
    Key? key,
    this.organizationId,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AttributionAvatarWidget(
      organizationId: organizationId,
      userId: userId,
      size: 32.0,
      showTooltip: true,
    );
  }
}
