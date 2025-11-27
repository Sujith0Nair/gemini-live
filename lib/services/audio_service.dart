import 'dart:async';
import 'package:gemini_live_app/services/audio_player_service.dart';
import 'package:gemini_live_app/services/audio_recorder_service.dart';

/// An abstract class that defines the contract for an audio service.
///
/// This service handles the recording and playback of audio by combining
/// the [AudioRecorderService] and [AudioPlayerService] interfaces.
abstract class AudioService implements AudioRecorderService, AudioPlayerService {
  /// Initializes the audio recorder and player.
  Future<bool> initialize();

  /// Disposes of all audio resources.
  void dispose();
}