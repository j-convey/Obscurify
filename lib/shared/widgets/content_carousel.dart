import 'package:flutter/material.dart';

/// A single item to display in the [ContentCarousel].
///
/// This is a generic data class so any entity (track, album, artist)
/// can be mapped into a uniform shape for the carousel.
class CarouselItem {
  /// Unique identifier (e.g. ratingKey)
  final String id;

  /// Primary display text (track title, album title, artist name)
  final String title;

  /// Secondary display text (artist name, year, genre, etc.)
  final String? subtitle;

  /// Fully-qualified image URL (already includes token)
  final String? imageUrl;

  /// The type of content this item represents
  final CarouselItemType type;

  /// Optional raw data payload for navigation callbacks
  final Map<String, dynamic>? data;

  const CarouselItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.type = CarouselItemType.album,
    this.data,
  });
}

/// The kind of media a [CarouselItem] represents.
enum CarouselItemType { track, album, artist }

/// A reusable horizontal carousel widget that displays a titled section
/// with a horizontally-scrollable list of cards.
///
/// Usage:
/// ```dart
/// ContentCarousel(
///   title: 'Recently Played',
///   items: items,
///   onItemTap: (item) => _handleTap(item),
/// )
/// ```
class ContentCarousel extends StatelessWidget {
  /// Section header text displayed above the carousel.
  final String title;

  /// The items to render as cards.
  final List<CarouselItem> items;

  /// Called when a card is tapped.
  final void Function(CarouselItem item)? onItemTap;

  /// Height of each card (defaults to 220).
  final double cardHeight;

  /// Width of each card (defaults to 160).
  final double cardWidth;

  /// Whether to show a "Show all" button when there are many items.
  final VoidCallback? onShowAll;

  /// Whether to use circular clipping for the image (e.g. for artists).
  final bool circularImage;

  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
    this.cardHeight = 240,
    this.cardWidth = 160,
    this.onShowAll,
    this.circularImage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Debug: Log carousel items order
    if (title == 'New Releases') {
      debugPrint('CAROUSEL: Building "$title" with ${items.length} items');
      for (int i = 0; i < items.length && i < 5; i++) {
        final item = items[i];
        debugPrint('CAROUSEL: [$i] "${item.title}" - ${item.subtitle}');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              if (onShowAll != null)
                TextButton(
                  onPressed: onShowAll,
                  child: Text(
                    'Show all',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Horizontal scrolling list
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < items.length - 1 ? 16 : 0,
                ),
                child: _CarouselCard(
                  item: item,
                  width: cardWidth,
                  circularImage: circularImage ||
                      item.type == CarouselItemType.artist,
                  onTap: onItemTap != null ? () => onItemTap!(item) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private card widget
// ---------------------------------------------------------------------------

class _CarouselCard extends StatefulWidget {
  final CarouselItem item;
  final double width;
  final bool circularImage;
  final VoidCallback? onTap;

  const _CarouselCard({
    required this.item,
    required this.width,
    this.circularImage = false,
    this.onTap,
  });

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard> {
  bool _isHovered = false;

  IconData get _fallbackIcon {
    switch (widget.item.type) {
      case CarouselItemType.artist:
        return Icons.person;
      case CarouselItemType.album:
        return Icons.album;
      case CarouselItemType.track:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = widget.width - 24; // padding: 12 * 2

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF282828)
                : const Color(0xFF181818),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image / artwork
              Stack(
                children: [
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      shape: widget.circularImage
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: widget.circularImage
                          ? null
                          : BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: widget.circularImage
                          ? BorderRadius.circular(imageSize / 2)
                          : BorderRadius.circular(4),
                      child: widget.item.imageUrl != null &&
                              widget.item.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.item.imageUrl!,
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize,
                              errorBuilder: (_, error, ___) {
                                debugPrint('CAROUSEL_IMAGE_ERROR: "${widget.item.title}" url=${widget.item.imageUrl} error=$error');
                                return Icon(
                                  _fallbackIcon,
                                  color: Colors.grey,
                                  size: 48,
                                );
                              },
                            )
                          : Icon(
                              _fallbackIcon,
                              color: Colors.grey,
                              size: 48,
                            ),
                    ),
                  ),

                  // Play button overlay on hover
                  if (_isHovered)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                widget.item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Subtitle
              if (widget.item.subtitle != null)
                Text(
                  widget.item.subtitle!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}