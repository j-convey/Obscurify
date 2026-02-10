import 'package:flutter/material.dart';

class PlexAuthCard extends StatelessWidget {
  final bool isAuthenticated;
  final String? username;
  final bool isLoading;
  final bool isSyncing;
  final bool canSync;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onSync;

  const PlexAuthCard({
    super.key,
    required this.isAuthenticated,
    required this.username,
    required this.isLoading,
    required this.isSyncing,
    required this.canSync,
    required this.onSignIn,
    required this.onSignOut,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.check_circle : Icons.cloud_off,
                  color: isAuthenticated ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAuthenticated ? 'Connected' : 'Not Connected',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (isAuthenticated && username != null)
                        Text(
                          'Logged in as $username',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Plex Server',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isAuthenticated
                  ? 'Your Plex account is connected. You can access your media libraries and content.'
                  : 'Connect to your Plex account to access your media libraries.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (isAuthenticated) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (isSyncing || !canSync) ? null : onSync,
                      icon: isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: Text(isSyncing ? 'Syncing...' : 'Sync Library'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        disabledForegroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else
              ElevatedButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Sign In with Plex'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
