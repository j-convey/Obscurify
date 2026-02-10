import 'package:flutter/material.dart';

class AuthenticationInfoCard extends StatelessWidget {
  const AuthenticationInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Authentication Works',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Click "Sign In with Plex"\n'
              '2. Your browser will open to Plex login page\n'
              '3. Sign in with your Plex credentials\n'
              '4. Once authenticated, return to this app\n'
              '5. Your credentials will be securely stored',
            ),
          ],
        ),
      ),
    );
  }
}
