Multi-Provider Architecture Plan for Obscurify
Current State Analysis
Your app currently has:

✅ Provider-agnostic domain models (Track, Album, Artist, Playlist)
✅ Local database layer for caching
❌ Tight coupling to Plex in services (AudioPlayerService, HomeDataService)
❌ Plex-specific authentication and API clients


Recommended Architecture: Provider Abstraction Layer
Phase 1: Define Provider Contracts (Interfaces)
Create abstract interfaces that all providers must implement:

```
lib/core/providers/
├── contracts/
│   ├── music_provider.dart              # Main provider interface
│   ├── authentication_provider.dart     # Auth operations
│   ├── library_provider.dart            # Library/catalog operations
│   ├── playback_provider.dart          # Streaming URLs, quality
│   ├── search_provider.dart            # Search operations
│   ├── playlist_provider.dart          # Playlist CRUD
│   ├── rating_provider.dart            # Rating/favorites
│   └── provider_capabilities.dart      # Feature flags per provider
```
Key Interface Example:
```
/// Base contract all music providers must implement
abstract class MusicProvider {
  String get providerId;              // 'plex', 'navidrome', 'jellyfin'
  String get providerName;            // Display name
  ProviderCapabilities get capabilities;
  
  // Lifecycle
  Future<void> initialize(ProviderConfig config);
  Future<void> dispose();
  
  // Sub-providers (composition pattern)
  AuthenticationProvider get auth;
  LibraryProvider get library;
  PlaybackProvider get playback;
  SearchProvider get search;
  PlaylistProvider get playlists;
  RatingProvider? get rating;  // Optional
}

abstract class LibraryProvider {
  Future<List<Track>> getTracks({String? libraryId});
  Future<List<Album>> getAlbums({String? libraryId});
  Future<List<Artist>> getArtists({String? libraryId});
  Future<Album> getAlbum(String albumId);
  Future<Artist> getArtist(String artistId);
  // ... more operations
}

abstract class PlaybackProvider {
  Future<StreamingUrl> getStreamUrl(Track track, {AudioQuality quality});
  Future<Duration?> getTrackDuration(String trackId);
}
```
Phase 2: Provider Implementations
Create provider-specific implementations:
```
lib/core/providers/
├── plex/
│   ├── plex_provider.dart              # Implements MusicProvider
│   ├── plex_auth_provider.dart
│   ├── plex_library_provider.dart
│   ├── plex_playback_provider.dart
│   ├── plex_adapter.dart               # Converts Plex JSON → Domain models
│   └── plex_config.dart
├── navidrome/
│   ├── navidrome_provider.dart
│   ├── navidrome_auth_provider.dart    # Subsonic API auth
│   ├── navidrome_library_provider.dart
│   ├── navidrome_adapter.dart
│   └── navidrome_config.dart
├── jellyfin/
│   ├── jellyfin_provider.dart
│   ├── jellyfin_auth_provider.dart
│   ├── jellyfin_library_provider.dart
│   ├── jellyfin_adapter.dart
│   └── jellyfin_config.dart
└── provider_factory.dart              # Factory pattern
```

Adapter Pattern (normalize provider responses):

```
/// Converts provider-specific responses to domain models
class PlexAdapter {
  static Track toTrack(Map<String, dynamic> plexJson, String serverId) {
    return Track.fromPlexJson(plexJson, serverId);
  }
  
  static Album toAlbum(Map<String, dynamic> plexJson, String serverId) {
    return Album.fromPlexJson(plexJson, serverId);
  }
}

class NavidromeAdapter {
  static Track toTrack(Map<String, dynamic> subsonicJson, String serverId) {
    // Convert Subsonic/Navidrome format → Track
    return Track(
      ratingKey: subsonicJson['id'],
      title: subsonicJson['title'],
      artistName: subsonicJson['artist'],
      albumName: subsonicJson['album'],
      duration: (subsonicJson['duration'] ?? 0) * 1000, // sec → ms
      serverId: serverId,
      // ... map all fields
    );
  }
}
```


Phase 3: Provider Management & Configuration
```
lib/core/providers/
├── provider_manager.dart          # Singleton managing active provider
├── provider_registry.dart         # Registry of all available providers
└── models/
    ├── provider_config.dart       # Configuration data structure
    └── provider_type.dart         # Enum for provider types
```

Provider Manager (Singleton):
```
class ProviderManager extends ChangeNotifier {
  static final instance = ProviderManager._();
  ProviderManager._();
  
  MusicProvider? _activeProvider;
  ProviderConfig? _activeConfig;
  
  MusicProvider? get current => _activeProvider;
  ProviderType? get currentType => _activeConfig?.type;
  
  Future<void> switchProvider(ProviderConfig config) async {
    await _activeProvider?.dispose();
    
    _activeProvider = ProviderFactory.create(config.type);
    await _activeProvider!.initialize(config);
    _activeConfig = config;
    
    notifyListeners();
  }
  
  Future<void> initialize() async {
    final config = await _loadSavedConfig();
    if (config != null) {
      await switchProvider(config);
    }
  }
}
```

Provider Factory:
```
enum ProviderType { plex, navidrome, jellyfin }

class ProviderFactory {
  static MusicProvider create(ProviderType type) {
    switch (type) {
      case ProviderType.plex:
        return PlexProvider();
      case ProviderType.navidrome:
        return NavidromeProvider();
      case ProviderType.jellyfin:
        return JellyfinProvider();
    }
  }
}
```

Phase 4: Refactor Existing Services
Update services to depend on provider interfaces instead of Plex specifics:

Before:
```
class AudioPlayerService {
  final PlexApiClient _plexApiClient = PlexApiClient();
  // ...
}
```
After:

```
class AudioPlayerService {
  final ProviderManager _providerManager = ProviderManager.instance;
  
  Future<void> play(Track track) async {
    final provider = _providerManager.current;
    if (provider == null) throw Exception('No provider configured');
    
    final streamUrl = await provider.playback.getStreamUrl(
      track,
      quality: AudioQuality.high,
    );
    
    await _player.open(Media(streamUrl.url));
  }
}
```
Services to refactor:

✏️ audio_player_service.dart
✏️ home_data_service.dart
✏️ playlist_service.dart
✏️ authentication_check_service.dart

Phase 5: Provider Selection UI
```
lib/core/features/provider_setup/
├── provider_selection_page.dart    # Choose provider type
├── plex_setup_page.dart           # Plex-specific setup
├── navidrome_setup_page.dart      # Navidrome setup
└── jellyfin_setup_page.dart       # Jellyfin setup
```

Provider Configuration Storage:

```
class ProviderConfig {
  final ProviderType type;
  final String serverUrl;
  final Map<String, dynamic> credentials; // Flexible for different auth types
  final Map<String, dynamic> settings;    // Provider-specific settings
}
```

Implementation Strategy
Recommended Phased Approach:
Phase	Tasks	Effort	Priority
1	Create provider contracts/interfaces	2-3 days	High
2	Refactor existing Plex code into provider pattern	5-7 days	High
3	Build provider management infrastructure	3-4 days	High
4	Update services to use provider interfaces	5-7 days	High
5	Implement Navidrome provider	7-10 days	Medium
6	Implement Jellyfin provider	7-10 days	Medium
7	Provider selection UI	3-5 days	Medium
8	Multi-provider support (switch without restart)	3-5 days	Low


Key Design Principles
Dependency Inversion: Services depend on abstractions (interfaces), not concrete implementations
Single Responsibility: Each provider handles only its data source
Open/Closed: Easy to add new providers without modifying existing code
Liskov Substitution: All providers are interchangeable through the MusicProvider interface
Strategy Pattern: Runtime provider selection
Adapter Pattern: Normalize provider-specific formats to domain models
Benefits of This Approach
✅ Maintainable: Clear separation of concerns
✅ Testable: Mock providers for testing
✅ Extensible: Add providers without touching core logic
✅ Type-safe: Compile-time guarantees via interfaces
✅ Database-agnostic: Your local DB layer remains unchanged
✅ Industry-standard: Uses proven patterns (Repository, Strategy, Factory, Adapter)



Provider Capability Matrix
Different providers have different features. Handle this with capability flags:

```
class ProviderCapabilities {
  final bool supportsRatings;
  final bool supportsPlaylists;
  final bool supportsLyrics;
  final bool supportsTranscoding;
  final List<AudioFormat> supportedFormats;
  
  const ProviderCapabilities({...});
}

// Usage in UI:
if (provider.capabilities.supportsRatings) {
  // Show rating UI
}
```
















