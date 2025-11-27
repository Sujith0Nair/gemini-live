import 'dart:async';
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:gemini_live_app/widgets/visualizer.dart';
import 'package:gemini_live_app/services/audio_service.dart';
import 'package:gemini_live_app/infrastructure/audio_service_impl.dart';
import 'package:gemini_live_app/services/llm_service.dart';
import 'package:gemini_live_app/infrastructure/gemini_llm_service_impl.dart';

/// The screen where the live conversation with the AI takes place.
///
/// This screen handles the initialization of audio and LLM services,
/// manages the conversation state, and displays the visualizer.
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  bool _isInitializing = false;
  bool _isConnectionActive = false;
  bool _isLLMSpeaking = false;
  bool _isLive = false;

  final AudioService _audioService = AudioServiceImpl();
  final LLMService _llmService = GeminiLLMServiceImpl();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initializes the audio and LLM services.
  ///
  /// This method checks for microphone permission, initializes the services,
  /// and starts the audio streaming.
  Future<void> _initializeServices() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    if (!await Permission.microphone.isGranted) {
      _showError('Microphone permission is required for live conversation.');
      setState(() => _isInitializing = false);
      return;
    }

    _llmService.connectionStatus.addListener(_onLLMConnectionChanged);
    _audioService.isLLMSpeaking.addListener(_onLLMSpeakingChanged);

    try {
      await _audioService.initialize();
      await _llmService.connect();
      _audioService.playIncomingAudio(_llmService.onAudioReceived);
      await _audioService.startRecording();
      _llmService.sendAudioStream(_audioService.outgoingAudioStream);

      setState(() {
        _isInitializing = false;
        _isLive = true;
      });
    } catch (e) {
      _showError('Failed to initialize: $e');
      setState(() {
        _isInitializing = false;
        _isLive = false;
      });
    }
  }

  /// Called when the LLM speaking status changes.
  void _onLLMSpeakingChanged() {
    if (mounted) {
      setState(() {
        _isLLMSpeaking = _audioService.isLLMSpeaking.value;
      });
    }
  }

  /// Called when the LLM connection status changes.
  void _onLLMConnectionChanged() {
    final newStatus = _llmService.connectionStatus.value;
    if (mounted) {
      setState(() {
        _isConnectionActive = newStatus;
        if (!newStatus && _isLive) {
          _endConversation();
        }
      });
    }
  }

  /// Ends the conversation and disposes of the services.
  void _endConversation() async {
    if (!_isLive && !_isInitializing) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLive = false);
    await _audioService.stopRecording();
    await _audioService.stopPlayback();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _audioService.isLLMSpeaking.removeListener(_onLLMSpeakingChanged);
    _llmService.connectionStatus.removeListener(_onLLMConnectionChanged);
    _llmService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gemini Live',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Visualizer(isTalking: _isLLMSpeaking),
                    const SizedBox(height: 40),
                    _buildStatusText(),
                  ],
                ),
              ),
              _buildEndCallButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the status text widget.
  Widget _buildStatusText() {
    String text;
    if (_isInitializing) {
      text = 'Connecting...';
    } else if (!_isConnectionActive) {
      text = 'Disconnected. Check API key or permissions.';
    } else if (_isLive) {
      text = _isLLMSpeaking
          ? 'LLM is speaking...'
          : 'Live Conversation...';
    } else {
      text = 'Conversation Ended.';
    }
    return Text(text, style: TextStyle(fontSize: 16, color: Colors.grey[400]));
  }

  /// Builds the end call button.
  Widget _buildEndCallButton() {
    final bool isEnabled = !_isInitializing && _isConnectionActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: FloatingActionButton(
        onPressed: isEnabled ? _endConversation : null,
        backgroundColor: isEnabled ? Colors.red.shade700 : Colors.grey.shade800,
        child: Icon(
          Icons.call_end,
          color: isEnabled ? Colors.white : Colors.grey.shade600,
          size: 36,
        ),
      ),
    );
  }

  /// Shows an error dialog.
  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (!_isConnectionActive && !_isInitializing) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
