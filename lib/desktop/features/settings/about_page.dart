import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                
                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade700,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App Name
                const Text(
                  'Obscurify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Version
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tagline
                const Text(
                  'Your music. Your way. Everywhere.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Description
                const Text(
                  'The Spotify experience you love, powered by your own Plex music library.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Features Section
                _buildSection(
                  'What You Get',
                  [
                    _buildFeature(Icons.library_music, 'Your Library, Beautiful', 
                      'Browse your collection by artists, albums, or tracks with stunning visuals.'),
                    _buildFeature(Icons.search, 'Search That Just Works', 
                      'Find any track, album, or artist instantly.'),
                    _buildFeature(Icons.play_circle_outline, 'Seamless Playback', 
                      'High-quality streaming with support for FLAC, MP3, AAC, and more.'),
                    _buildFeature(Icons.playlist_play, 'Playlists & Collections', 
                      'Create and manage playlists for every mood.'),
                    _buildFeature(Icons.dark_mode, 'Dark Mode Always', 
                      'Easy on your eyes, day or night.'),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Tech Section
                _buildSection(
                  'Built With',
                  [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '• Flutter - Cross-platform framework\n'
                        '• Plex Media Server API\n'
                        '• SQLite for local caching\n'
                        '• Media Kit for audio playback',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // License Section
                _buildSection(
                  'License',
                  [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Apache License 2.0\n\n'
                        'Obscurify is open source and free to use. '
                        'Contributions are welcome!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLinkButton(
                      'GitHub',
                      Icons.code,
                      'https://github.com/j-convey/Obscurify',
                    ),
                    const SizedBox(width: 16),
                    _buildLinkButton(
                      'Sponsor',
                      Icons.favorite,
                      'https://github.com/sponsors/j-convey',
                      color: Colors.pink,
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Footer
                const Text(
                  'Made with ❤️ for music collectors everywhere.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, IconData icon, String url, {Color? color}) {
    return ElevatedButton.icon(
      onPressed: () => _launchUrl(url),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
