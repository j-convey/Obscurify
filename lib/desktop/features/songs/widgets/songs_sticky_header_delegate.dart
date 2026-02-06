import 'package:flutter/material.dart';
import 'songs_sticky_header_content.dart';

/// Delegate that controls the sticky header behavior for the songs list.
/// Keeps the column headers visible while scrolling.
class SongsStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final String sortColumn;
  final bool sortAscending;
  final Function(String) onSort;
  final double topPadding;

  SongsStickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    this.topPadding = 0.0,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Column(
        children: [
          if (topPadding > 0) SizedBox(height: topPadding),
          Expanded(
            child: SongsStickyHeaderContent(
              sortColumn: sortColumn,
              sortAscending: sortAscending,
              onSort: onSort,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(SongsStickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        sortColumn != oldDelegate.sortColumn ||
        sortAscending != oldDelegate.sortAscending ||
        topPadding != oldDelegate.topPadding;
  }
}
