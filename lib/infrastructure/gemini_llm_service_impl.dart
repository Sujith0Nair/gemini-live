import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:gemini_live_app/services/llm_service.dart';

/// A concrete implementation of the [LLMService] interface that uses the
/// Gemini Live API via `firebase_ai`.
class GeminiLLMServiceImpl implements LLMService {
  late LiveGenerativeModel _liveGenerativeModel;
  LiveSession? _liveSession;
  StreamSubscription? _audioStreamSubscription;
  StreamSubscription? _responseSubscription;

  @override
  final connectionStatus = ValueNotifier<bool>(false);

  final _incomingAudioStreamController =
      StreamController<Uint8List>.broadcast();
  @override
  Stream<Uint8List> get onAudioReceived =>
      _incomingAudioStreamController.stream;

  /// Connects to the Gemini Live API and initializes a live session.
  @override
  Future<void> connect() async {
    try {
      final String jsonContent = await rootBundle.loadString(
        'assets/config.json',
      );
      final Map<String, dynamic> config = json.decode(jsonContent);
      final String modelName = config['model_name'];
      final String systemInstructionText = await rootBundle.loadString(
        'assets/system_instructions.txt',
      );

      final ai = FirebaseAI.googleAI();

      _liveGenerativeModel = ai.liveGenerativeModel(
        model: modelName,
        liveGenerationConfig: LiveGenerationConfig(
          responseModalities: [ResponseModalities.audio],
        ),
        systemInstruction: Content('model', [TextPart(systemInstructionText)]),
      );

      try {
        _liveSession = await _liveGenerativeModel.connect();
      } catch (e) {
        connectionStatus.value = false;
        rethrow;
      }

      _listenForResponses();

      connectionStatus.value = true;
    } catch (e) {
      connectionStatus.value = false;
      rethrow;
    }
  }

  /// Sends the user's audio stream to the Gemini Live API.
  @override
  void sendAudioStream(Stream<Uint8List> audioStream) {
    if (_liveSession == null || !connectionStatus.value) {
      return;
    }
    _audioStreamSubscription?.cancel();

    _audioStreamSubscription = audioStream
        .map((data) {
          return InlineDataPart('audio/pcm', data);
        })
        .listen(
          (chunk) async {
            try {
              await _liveSession!.sendAudioRealtime(chunk);
            } catch (e) {
              connectionStatus.value = false;
              _audioStreamSubscription?.cancel();
            }
          },
          onDone: () {},
          onError: (e) {
            connectionStatus.value = false;
            _audioStreamSubscription?.cancel();
          },
          cancelOnError: true,
        );
  }

  /// Listens for incoming audio responses from the Gemini Live API.
  void _listenForResponses() {
    if (_liveSession == null) return;
    _responseSubscription?.cancel();
    _responseSubscription = _liveSession!.receive().listen(
      (message) {
        if (message.message is LiveServerContent &&
            (message.message as LiveServerContent).modelTurn?.parts != null) {
          final serverContent = message.message as LiveServerContent;
          for (final part in serverContent.modelTurn!.parts) {
            if (part is InlineDataPart) {
              final audioBytes = part.bytes;
              _incomingAudioStreamController.add(audioBytes);
            }
          }
        }
      },
      onDone: () {
        connectionStatus.value = false;
      },
      onError: (e) {
        connectionStatus.value = false;
      },
      cancelOnError: true,
    );
  }

  /// Disposes of the resources used by the service.
  @override
  void dispose() {
    _liveSession?.close();
    _audioStreamSubscription?.cancel();
    _responseSubscription?.cancel();
    connectionStatus.dispose();
    _incomingAudioStreamController.close();
  }
}
