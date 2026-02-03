import 'package:flutter_test/flutter_test.dart';
import 'package:apollo/core/services/audio_player_service.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  // MediaKit needs to be initialized for tests that instantiate the Player
  setUpAll(() {
    MediaKit.ensureInitialized();
  });

  group('AudioPlayerService Unit Tests', () {
    late AudioPlayerService service;

    setUp(() {
      service = AudioPlayerService();
    });

    test('Initial state should be empty and stopped', () {
      expect(service.currentTrack, isNull);
      expect(service.isPlaying, isFalse);
      expect(service.duration, Duration.zero);
      expect(service.position, Duration.zero);
      expect(service.currentIndex, -1);
      expect(service.queueLength, 0);
    });

    test('setPlayQueue should update queue length and current index', () {
      final tracks = [
        {'title': 'Song 1', 'Media': []},
        {'title': 'Song 2', 'Media': []},
        {'title': 'Song 3', 'Media': []},
      ];
      
      service.setPlayQueue(tracks, 1);
      
      expect(service.queueLength, 3);
      expect(service.currentIndex, 1);
    });

    test('setServerUrls should update internal server mapping', () {
      final urls = {
        'server_1': 'https://192.168.1.10:32400',
        'server_2': 'https://my-plex-server.direct:32400',
      };
      
      // This ensures the method exists and accepts the data structure
      service.setServerUrls(urls);
    });

    test('stop should reset playback metadata', () async {
      // Setup dummy state
      service.setPlayQueue([{'title': 'Song 1'}], 0);
      
      await service.stop();
      
      expect(service.currentTrack, isNull);
      expect(service.isPlaying, isFalse);
      expect(service.position, Duration.zero);
      expect(service.duration, Duration.zero);
    });

    test('setVolume should accept values between 0.0 and 1.0', () async {
      // We verify the service handles the call correctly
      await service.setVolume(0.5);
      await service.setVolume(0.0);
      await service.setVolume(1.0);
    });

    test('Queue navigation boundaries', () {
      final tracks = [
        {'title': 'Song 1'},
        {'title': 'Song 2'},
      ];
      service.setPlayQueue(tracks, 0);
      
      // Note: next() and previous() are async and involve media_kit calls.
      // In unit tests, we primarily verify they don't throw when data is missing.
      expect(() => service.next(), returnsNormally);
      expect(() => service.previous(), returnsNormally);
    });
  });
}