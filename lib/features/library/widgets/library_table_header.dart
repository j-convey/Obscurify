import 'package:flutter/material.dart';

class LibraryTableHeader extends StatelessWidget {
  final String sortColumn;
  final bool sortAscending;
  final Function(String) onSort;

  const LibraryTableHeader({
    super.key,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          // # column
          const SizedBox(
            width: 40,
            child: Text(
              '#',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Title column (sortable)
          Expanded(
            flex: 3,
            child: _buildSortableHeader('Title', 'title'),
          ),
          // Album column (sortable)
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Album', 'album'),
          ),
          // Date added column (sortable)
          Expanded(
            flex: 1,
            child: _buildSortableHeader('Date added', 'addedAt'),
          ),
          // Duration column (sortable)
          SizedBox(
            width: 110,
            child: InkWell(
              onTap: () => onSort('duration'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (sortColumn == 'duration')
                    Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: Colors.grey,
                    ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String label, String column) {
    return InkWell(
      onTap: () => onSort(column),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (sortColumn == column)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}
