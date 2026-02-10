import 'package:flutter/material.dart';

enum SortOption {
  title,
  artist,
  album,
  recentlyAdded,
}

class SortBottomSheet extends StatelessWidget {
  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF282828),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Sort options
            _buildSortOption(
              context,
              label: 'Title',
              option: SortOption.title,
            ),
            _buildSortOption(
              context,
              label: 'Artist',
              option: SortOption.artist,
            ),
            _buildSortOption(
              context,
              label: 'Album',
              option: SortOption.album,
            ),
            _buildSortOption(
              context,
              label: 'Recently added',
              option: SortOption.recentlyAdded,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String label,
    required SortOption option,
  }) {
    final isSelected = currentSort == option;

    return InkWell(
      onTap: () {
        onSortChanged(option);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF1DB954),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
