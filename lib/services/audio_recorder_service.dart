import 'dart:async';
import 'dart:typed_data';

/// An abstract class that defines the contract for an audio recording service.
abstract class AudioRecorderService {
  /// A stream of recorded audio chunks from the microphone.
  Stream<Uint8List> get outgoingAudioStream;

  /// A property to check the recording status.
  bool get isRecording;

  /// Starts continuous audio recording.
  Future<void> startRecording();

  /// Stops the continuous audio recording.
  Future<void> stopRecording();
}
