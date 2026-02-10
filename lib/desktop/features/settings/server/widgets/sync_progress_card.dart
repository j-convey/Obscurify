import 'package:flutter/material.dart';

class SyncProgressCard extends StatelessWidget {
  final bool isSyncing;
  final double syncProgress;
  final int totalTracksSynced;
  final int estimatedTotalTracks;
  final String? currentSyncingLibrary;
  final Map<String, dynamic>? syncStatus;

  const SyncProgressCard({
    super.key,
    required this.isSyncing,
    required this.syncProgress,
    required this.totalTracksSynced,
    required this.estimatedTotalTracks,
    required this.currentSyncingLibrary,
    required this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (isSyncing && estimatedTotalTracks > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Syncing $currentSyncingLibrary',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: syncProgress,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(syncProgress * 100).toStringAsFixed(0)}% • $totalTracksSynced of $estimatedTotalTracks songs',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    if (syncStatus != null && !isSyncing) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${syncStatus!['trackCount']} songs synced • Last sync: ${syncStatus!['lastSync']}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
