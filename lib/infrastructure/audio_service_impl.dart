import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:gemini_live_app/services/audio_service.dart';
import 'package:audio_session/audio_session.dart';

/// An implementation of the [AudioService] interface.
///
/// This class handles the recording and playback of audio using the `record`
/// and `flutter_sound` packages.
class AudioServiceImpl implements AudioService {
  final _audioRecorder = AudioRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();

  bool _isRecording = false;
  StreamSubscription? _recordingSubscription;
  StreamSubscription? _playbackSubscription;
  Timer? _llmSpeechTimeout;

  @override
  final isLLMSpeaking = ValueNotifier<bool>(false);

  final _outgoingAudioStreamController =
      StreamController<Uint8List>.broadcast();
  @override
  Stream<Uint8List> get outgoingAudioStream =>
      _outgoingAudioStreamController.stream;

  /// Initializes the audio service.
  ///
  /// This method requests microphone permission and configures the audio session.
  @override
  Future<bool> initialize() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        return false;
      }

      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      await _audioPlayer.openPlayer();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Starts recording audio from the microphone.
  ///
  /// The recorded audio is added to the [outgoingAudioStream].
  @override
  Future<void> startRecording() async {
    if (_isRecording) {
      return;
    }
    _isRecording = true;

    try {
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          noiseSuppress: true,
          autoGain: true,
          iosConfig: IosRecordConfig(
            categoryOptions: [
              IosAudioCategoryOption.defaultToSpeaker,
              IosAudioCategoryOption.allowBluetooth,
              IosAudioCategoryOption.allowBluetoothA2DP,
            ],
          ),
        ),
      );

      await _audioRecorder.ios?.manageAudioSession(true);

      _recordingSubscription = stream.listen(
        (data) {
          _outgoingAudioStreamController.add(data);
        },
        onDone: () {
          _isRecording = false;
        },
        onError: (e) {
          _isRecording = false;
        },
      );
    } catch (e) {
      _isRecording = false;
    }
  }

  /// Stops recording audio.
  @override
  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }
    await _audioRecorder.stop();
    _recordingSubscription?.cancel();
    _recordingSubscription = null;
    _isRecording = false;
  }

  @override
  Future<void> clearPlaybackQueue() async {
    if (_audioPlayer.isPlaying) {
      await _audioPlayer.stopPlayer();
    }
    _llmSpeechTimeout?.cancel();
    if (isLLMSpeaking.value) {
      isLLMSpeaking.value = false;
    }
  }

  /// Plays the incoming audio stream.
  @override
  Future<void> playIncomingAudio(Stream<Uint8List> audioStream) async {
    if (!_audioPlayer.isOpen()) {
      return;
    }
    _playbackSubscription?.cancel();
    _playbackSubscription = audioStream.listen(
      (audioChunk) async {
        _playbackSubscription?.pause();

        try {
          if (!_audioPlayer.isPlaying) {
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer.startPlayerFromStream(
              codec: Codec.pcm16,
              numChannels: 1,
              sampleRate: 24000,
              interleaved: true,
              bufferSize: 8192,
            );
          }

          await _audioPlayer.feedUint8FromStream(audioChunk);

          if (!isLLMSpeaking.value) {
            isLLMSpeaking.value = true;
          }

          _llmSpeechTimeout?.cancel();
          _llmSpeechTimeout = Timer(const Duration(milliseconds: 1200), () {
            if (isLLMSpeaking.value) {
              isLLMSpeaking.value = false;
            }
          });
        } finally {
          _playbackSubscription?.resume();
        }
      },
      onDone: () {
        _llmSpeechTimeout?.cancel();
        _llmSpeechTimeout = Timer(const Duration(milliseconds: 1200), () {
          if (isLLMSpeaking.value) {
            isLLMSpeaking.value = false;
          }
        });
      },
      onError: (e) {
        if (_audioPlayer.isPlaying) {
          _audioPlayer.stopPlayer();
        }
        _llmSpeechTimeout?.cancel();
        if (isLLMSpeaking.value) {
          isLLMSpeaking.value = false;
        }
      },
      cancelOnError: true,
    );
  }

  /// Stops the audio playback.
  @override
  Future<void> stopPlayback() async {
    if (_audioPlayer.isPlaying) {
      await _audioPlayer.stopPlayer();
      _llmSpeechTimeout?.cancel();
      if (isLLMSpeaking.value) {
        isLLMSpeaking.value = false;
      }
    }
  }

  /// Disposes of the audio resources.
  @override
  void dispose() {
    _llmSpeechTimeout?.cancel();
    _recordingSubscription?.cancel();
    _playbackSubscription?.cancel();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    _audioPlayer.closePlayer();
    _outgoingAudioStreamController.close();
    isLLMSpeaking.dispose();
  }

  @override
  bool get isRecording => _isRecording;
}
