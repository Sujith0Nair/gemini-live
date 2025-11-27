import 'dart:async';
import 'package:flutter/foundation.dart';

/// An abstract class that defines the contract for a live, bidirectional
/// conversational AI service.
abstract class LLMService {
  /// Notifier that broadcasts the current connection status of the service.
  /// `true` if connected, `false` otherwise.
  ValueNotifier<bool> get connectionStatus;

  /// A stream that emits audio data received from the AI model.
  Stream<Uint8List> get onAudioReceived;

  /// Initiates a connection to the AI service.
  Future<void> connect();

  /// Sends a continuous stream of audio data to the AI model.
  /// The AI model will send back audio responses via `onAudioReceived`.
  void sendAudioStream(Stream<Uint8List> audioStream);

  /// Closes the connection and releases all resources.
  void dispose();
}
