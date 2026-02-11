import 'package:flutter/foundation.dart';

/// Utility for determining audio quality tier from track metadata.
///
/// Tiers:
/// - **Max**: Lossless with hi-res audio (bit depth > 16 or sample rate > 44100 Hz)
/// - **High**: Lossless at CD quality (16-bit, 44.1 kHz) or below
/// - **Low**: Lossy codecs (MP3, AAC, OGG, etc.)
class AudioQualityUtils {
  AudioQualityUtils._();

  /// Known lossless audio codecs.
  static const _losslessCodecs = {
    'flac',
    'alac',
    'wav',
    'aiff',
    'aif',
    'pcm',
    'dsd',
    'dff',
    'dsf',
    'ape',
    'wv',        // WavPack
    'wavpack',
  };

  /// Determines the quality tier for a track.
  ///
  /// Accepts a track map (from [Track.toJson]) and inspects codec,
  /// sample rate, and bit depth to classify the audio.
  static AudioQualityTier getTier(Map<String, dynamic>? track) {
    debugPrint('AUDIO_QUALITY: ─────────────────────────────────');
    if (track == null) {
      debugPrint('AUDIO_QUALITY: Track is null, returning LOW');
      return AudioQualityTier.low;
    }

    final codec = _resolveCodec(track);
    final sampleRate = track['sampleRate'] as int?;
    final bitDepth = track['bitDepth'] as int?;

    debugPrint('AUDIO_QUALITY: codec: $codec');
    debugPrint('AUDIO_QUALITY: sampleRate: $sampleRate');
    debugPrint('AUDIO_QUALITY: bitDepth: $bitDepth');

    // If the codec is lossy, it's always Low
    if (codec != null && !_losslessCodecs.contains(codec.toLowerCase())) {
      debugPrint('AUDIO_QUALITY: Codec "$codec" is LOSSY -> LOW');
      return AudioQualityTier.low;
    }

    debugPrint('AUDIO_QUALITY: Codec "$codec" is LOSSLESS (or unknown)');

    // Lossless codec (or unknown codec) — check resolution
    final isHiRes = (bitDepth != null && bitDepth > 16) ||
        (sampleRate != null && sampleRate > 44100);

    debugPrint('AUDIO_QUALITY: isHiRes: $isHiRes (bitDepth > 16: ${bitDepth != null && bitDepth > 16}, sampleRate > 44100: ${sampleRate != null && sampleRate > 44100})');

    if (isHiRes) {
      debugPrint('AUDIO_QUALITY: Hi-res audio -> MAX');
      return AudioQualityTier.max;
    }

    // Lossless at CD quality or below
    if (codec != null && _losslessCodecs.contains(codec.toLowerCase())) {
      debugPrint('AUDIO_QUALITY: Lossless at CD quality or below -> HIGH');
      return AudioQualityTier.high;
    }

    // No codec info at all — can't determine
    debugPrint('AUDIO_QUALITY: No codec info, returning LOW');
    return AudioQualityTier.low;
  }

  /// Resolves the audio codec from a track map, checking multiple fields.
  static String? _resolveCodec(Map<String, dynamic> track) {
    // Direct field
    final codec = track['audioCodec'] as String?;
    if (codec != null && codec.isNotEmpty) return codec;

    // From container
    final container = track['container'] as String?;
    if (container != null && container.isNotEmpty) return container;

    return null;
  }
}

/// Audio quality tier classification.
enum AudioQualityTier {
  /// Hi-res lossless (up to 24-bit / 192 kHz)
  max,

  /// CD quality lossless (16-bit / 44.1 kHz)
  high,

  /// Lossy or low quality
  low;

  /// Display label for the tier.
  String get label {
    switch (this) {
      case AudioQualityTier.max:
        return 'MAX';
      case AudioQualityTier.high:
        return 'HIGH';
      case AudioQualityTier.low:
        return 'LOW';
    }
  }
}
