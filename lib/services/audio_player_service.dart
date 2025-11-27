import 'dart:async';
import 'package:flutter/foundation.dart';

/// An abstract class that defines the contract for an audio playback service.
abstract class AudioPlayerService {
  /// Tracks whether the LLM is currently speaking.
  ValueNotifier<bool> get isLLMSpeaking;

  /// Plays a stream of incoming audio chunks.
  Future<void> playIncomingAudio(Stream<Uint8List> audioStream);

  /// Stops any ongoing playback.
  Future<void> stopPlayback();

  /// Clears any buffered audio and stops immediate playback.
  Future<void> clearPlaybackQueue();
}
