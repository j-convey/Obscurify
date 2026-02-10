# Obscurify

A modern, cross-platform music player built with Flutter that seamlessly integrates with Plex Media Server to provide a premium music streaming experience.

![Obscurify](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Plex](https://img.shields.io/badge/Plex-E5A00D?style=for-the-badge&logo=plex&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=white)

## 🌟 Features

### 🎵 Core Music Features
- **Seamless Plex Integration**: Connect directly to your Plex Media Server
- **High-Quality Audio Playback**: Support for FLAC, MP3, AAC, and other formats
- **Smart Caching**: Local database storage for offline browsing and faster loading
- **Queue Management**: Create and manage playback queues with drag-and-drop
- **Shuffle & Repeat**: Full playback controls with shuffle and repeat modes

### 🎨 Modern UI/UX
- **Dark Theme**: Beautiful, eye-friendly dark interface
- **Custom Window Controls**: Native desktop window management
- **Responsive Design**: Optimized for desktop screens with proper scaling
- **Album Art Display**: High-quality album artwork integration
- **Progress Visualization**: Real-time playback progress with seek controls
<img width="1920" height="1536" alt="image" src="https://github.com/user-attachments/assets/62b1ccfc-8894-4faa-b84a-fa7411357378" />

### 🔍 Discovery & Navigation
- **Library Browser**: Browse your entire music collection by artist, album, or track
  <img width="1920" height="1468" alt="image" src="https://github.com/user-attachments/assets/3bd08996-6b56-4916-b6e1-633c9840a0d5" />

- **Search Functionality**: Fast, real-time search across your music library
<img width="699" height="708" alt="image" src="https://github.com/user-attachments/assets/abdc19fc-cd8d-4150-8f0b-a256dd3c4e5b" />

- **Recently Played**: Quick access to recently played tracks
- **Playlists**: Create and manage custom playlists (coming soon)

### ⚙️ Advanced Features
- **Multi-Server Support**: Connect to multiple Plex servers simultaneously
- **Server Selection**: Choose between local and remote server connections
- **Authentication**: Secure Plex account authentication with PIN-based login
- **Settings Management**: Comprehensive settings for audio, display, and server preferences

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.10.8 or higher
- **Dart SDK**: Version 3.10.8 or higher
- **Plex Media Server**: A running Plex Media Server instance with music libraries
- **Platform Tools**: Windows, macOS, or Linux development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/j-convey/Obscurify.git
   cd Obscurify
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Windows
```bash
flutter build windows --release
```

#### macOS
```bash
flutter build macos --release
```

#### Linux
```bash
flutter build linux --release
```

## 🏗️ Architecture

### Project Structure

```
lib/
<<<<<<< HEAD
├── core/                    # Core application components
│   ├── constants/          # App-wide constants
│   ├── services/           # Business logic services
│   │   ├── audio_player_service.dart    # Audio playback management
│   │   ├── plex_auth_service.dart       # Plex authentication
│   │   ├── storage_service.dart         # Local data persistence
│   │   └── database_service.dart        # SQLite database operations
│   ├── theme/              # UI theming (future use)
│   ├── utils/              # Utility functions (future use)
│   └── widgets/            # Shared UI components
│       ├── apollo_app_bar.dart          # Custom app bar
│       ├── player_bar.dart              # Playback controls
│       └── app_bar/                     # App bar sub-components
├── features/               # Feature-based modules
│   ├── authentication/     # User authentication
│   ├── home/               # Home screen
│   ├── music/              # Music library browsing
│   ├── player/             # Audio player (future use)
│   ├── playlists/          # Playlist management
│   ├── settings/           # App settings
│   │   └── server/         # Server configuration
│   └── library/            # Library page and details
│       ├── library_page.dart
│       ├── utils/
│       └── widgets/
└── main.dart               # Application entry point
=======
├── main.dart                          # Platform router
├── core/                              # Headless shared logic
│   ├── constants/
│   ├── database/                      # DB service + repos + schema (cross-platform)
│   ├── models/                        # Track, Album, Artist, Playlist
│   ├── services/                      # AudioPlayer, Storage, Plex*, Playlist, AuthCheck
│   ├── theme/                         # Shared ThemeData definitions
│   └── utils/                         # string_utils, collection_utils (consolidated)
├── shared/                            # Shared UI components
│   └── widgets/                       # Headers, action buttons, cards, dialogs
├── desktop/                           # Desktop app
│   ├── main_desktop.dart              # WindowManager init
│   ├── shell/                         # AppBar, WindowControls, NavButtons, PlayerBar
│   └── features/                      # All current feature pages (moved as-is)
│       ├── album/
│       ├── artist/
│       ├── authentication/
│       ├── collection/
│       ├── home/
│       ├── music/
│       ├── playlists/
│       ├── profile/
│       ├── settings/
│       └── songs/
└── mobile/                            # Android app (built fresh)
    ├── main_mobile.dart
    ├── shell/
    └── features/
```

```
lib/mobile/
├── main_mobile.dart              # MaterialApp with mobile theme, no window_manager
├── shell/
│   ├── mobile_shell.dart         # Scaffold with BottomNavigationBar + mini player
│   └── mini_player.dart          # Collapsed player bar, tappable to expand
└── features/
    ├── home/
    ├── library/
    ├── albums/
    ├── artists/
    ├── playlists/
    ├── settings/
    └── profile/
>>>>>>> file-structure-refactor
```

### Key Technologies

- **Flutter**: Cross-platform UI framework
- **media_kit**: High-performance audio playback library
- **sqflite**: SQLite database for local caching
- **http**: REST API communication
- **shared_preferences**: Local key-value storage
- **window_manager**: Custom window controls
- **url_launcher**: External URL handling for authentication

### Data Flow

1. **Authentication**: User authenticates with Plex via PIN-based OAuth flow
2. **Server Discovery**: App discovers available Plex Media Servers
3. **Library Sync**: Music library metadata is cached locally in SQLite
4. **Playback**: Audio streams are played using media_kit with Plex transcoding
5. **Caching**: Frequently accessed data is stored locally for performance

## 🔧 Configuration

### Plex Media Server Setup

1. Ensure your Plex Media Server has music libraries configured
2. Enable remote access if connecting from outside your local network
3. Verify that your Plex account has access to the music libraries

### App Configuration

The app automatically handles most configuration, but you can customize:

- **Server Connections**: Choose between local and remote server URLs
- **Audio Quality**: Adjust playback quality settings (future feature)
- **Cache Size**: Configure local storage limits (future feature)

## 📱 Usage

### First Time Setup

1. **Launch Obscurify**: Open the application on your desktop
2. **Authenticate**: Click the settings icon and select "Server Settings"
3. **PIN Authentication**: Follow the on-screen instructions to authenticate with Plex
4. **Server Selection**: Choose your Plex Media Server from the available options
5. **Library Sync**: The app will automatically sync your music library

### Daily Usage

1. **Browse Music**: Use the home screen to access your library
2. **Search**: Use the search bar in the app bar to find specific tracks
3. **Play Music**: Click on any track to start playback
4. **Queue Management**: Add tracks to queue and control playback order
5. **Navigation**: Use back/forward buttons for navigation history

## 🔒 Security

- **Secure Authentication**: Uses Plex's official OAuth flow with PIN-based authentication
- **Token Management**: Securely stores authentication tokens using platform-specific secure storage
- **HTTPS Communication**: All network requests use HTTPS encryption
- **Local Data**: Sensitive data is stored securely on the local device

### Debug Mode

Run the app in debug mode to see detailed logs:
```bash
flutter run --debug
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.


---

**Obscurify** - Bringing your music collection to life with modern desktop audio streaming.
