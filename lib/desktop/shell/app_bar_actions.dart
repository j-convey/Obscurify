import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class AppBarActions extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAccountTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSupportTap;
  final VoidCallback? onPrivateSessionTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final String? profileImagePath;
  final String? plexProfilePictureUrl;

  const AppBarActions({
    super.key,
    this.onNotificationsTap,
    this.onAccountTap,
    this.onProfileTap,
    this.onSupportTap,
    this.onPrivateSessionTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.profileImagePath,
    this.plexProfilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: Colors.white,
          onPressed: onNotificationsTap,
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
        
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 24),
          color: Colors.white,
          onPressed: onSettingsTap,
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
        
        // Profile dropdown
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          icon: _buildProfileAvatar(),
          color: Colors.grey[900],
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'account',
              child: Row(
                children: [
                  const Text('Account', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: Text('Profile', style: TextStyle(color: Colors.white)),
            ),
            PopupMenuItem<String>(
              value: 'support',
              child: Row(
                children: [
                  const Text('Support', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'private_session',
              child: Text('Private session', style: TextStyle(color: Colors.white)),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Text('Settings', style: TextStyle(color: Colors.white)),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Log out', style: TextStyle(color: Colors.white)),
            ),
          ],
          onSelected: (String value) {
            switch (value) {
              case 'account':
                onAccountTap?.call();
                break;
              case 'profile':
                onProfileTap?.call();
                break;
              case 'support':
                _launchSupportUrl();
                break;
              case 'private_session':
                onPrivateSessionTap?.call();
                break;
              case 'settings':
                onSettingsTap?.call();
                break;
              case 'logout':
                onLogoutTap?.call();
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    // Prefer local file, then Plex URL, then default icon
    ImageProvider? imageProvider;
    if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      imageProvider = FileImage(File(profileImagePath!));
    } else if (plexProfilePictureUrl != null && plexProfilePictureUrl!.isNotEmpty) {
      imageProvider = NetworkImage(plexProfilePictureUrl!);
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[800],
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person, color: Colors.white, size: 18)
          : null,
    );
  }

  Future<void> _launchSupportUrl() async {
    final url = Uri.parse('https://github.com/sponsors/j-convey');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
