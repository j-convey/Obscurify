import 'package:flutter/foundation.dart';

/// Singleton [ChangeNotifier] that fires whenever the music library
/// has been modified (sync completed, data cleared, etc.).
///
/// UI pages that display library data should listen to this and
/// reload when notified:
///
/// ```dart
/// LibraryChangeNotifier().addListener(_reload);
/// ```
class LibraryChangeNotifier extends ChangeNotifier {
  LibraryChangeNotifier._();
  static final LibraryChangeNotifier _instance = LibraryChangeNotifier._();
  factory LibraryChangeNotifier() => _instance;

  /// Call after any operation that changes library data
  /// (sync, sign-out / clear, etc.).
  void notifyLibraryChanged() {
    notifyListeners();
  }
}
