import 'package:flutter/material.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';

class ServerLibrarySelector extends StatelessWidget {
  final List<PlexServer> servers;
  final Map<String, List<Map<String, dynamic>>> serverLibraries;
  final Map<String, Set<String>> selectedLibraries;
  final bool isLoading;
  final VoidCallback onSave;
  final Function(String serverKey, String libraryKey, bool isSelected) onSelectionChanged;

  const ServerLibrarySelector({
    super.key,
    required this.servers,
    required this.serverLibraries,
    required this.selectedLibraries,
    required this.isLoading,
    required this.onSave,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (servers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'No servers found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure you have a Plex Media Server set up and it\'s accessible.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Libraries',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which music libraries you want to use in Obscurify',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ...servers.map((server) {
          final serverId = server.machineIdentifier;
          final serverName = server.name;
          final libraries = serverLibraries[serverId] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: const Icon(Icons.dns),
              title: Text(serverName),
              subtitle: Text(
                '${libraries.length} music ${libraries.length == 1 ? 'library' : 'libraries'}',
              ),
              children: [
                if (libraries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No music libraries found on this server',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...libraries.map((library) {
                    final libraryKey = library['key'] as String;
                    final libraryTitle = library['title'] as String;
                    final isSelected = selectedLibraries[serverId]?.contains(libraryKey) ?? false;

                    return CheckboxListTile(
                      title: Text(libraryTitle),
                      subtitle: Text('Library ID: $libraryKey'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        onSelectionChanged(
                          serverId,
                          libraryKey,
                          value ?? false,
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
