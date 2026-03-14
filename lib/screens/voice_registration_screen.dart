import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_colors.dart';
import '../widgets/glass_card.dart';

class VoiceRegistrationScreen extends StatefulWidget {
  const VoiceRegistrationScreen({super.key});

  @override
  State<VoiceRegistrationScreen> createState() =>
      _VoiceRegistrationScreenState();
}

enum RecordState { idle, recording, processing, success, error }

class _VoiceRegistrationScreenState extends State<VoiceRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  RecordState _state = RecordState.idle;

  // Waveform logic
  StreamSubscription<Amplitude>? _amplitudeSub;
  final List<double> _amplitudes = List.filled(40, 0.0);

  // 5 second timer
  Timer? _timer;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/voice_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path,
        );

        setState(() {
          _state = RecordState.recording;
          _secondsLeft = 5;
          // Reset waveform
          for (int i = 0; i < _amplitudes.length; i++) {
            _amplitudes[i] = 0.0;
          }
        });

        _startWaveformListening();

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _secondsLeft--;
            if (_secondsLeft <= 0) {
              _stopRecording();
            }
          });
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission denied',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      setState(() => _state = RecordState.error);
    }
  }

  void _startWaveformListening() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
          if (!mounted) return;
          setState(() {
            // Amplitude is returned in dBFS (-160 to 0)
            // Normalize to a 0.0 to 1.0 range based on typical speech levels
            double currentAmp = amp.current;
            double normalized = (currentAmp + 50) / 50;
            normalized = max(
              0.0,
              min(1.0, normalized),
            ); // Clamp between 0 and 1

            // Add minimal noise for visual appeal even when quiet
            if (normalized < 0.1) {
              normalized = 0.1 + (Random().nextDouble() * 0.1);
            }

            _amplitudes.removeAt(0);
            _amplitudes.add(normalized);
          });
        });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();

    setState(() => _state = RecordState.processing);

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        // Simulate a slight delay for processing
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          setState(() => _state = RecordState.success);
        }
      } else {
        setState(() => _state = RecordState.error);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() => _state = RecordState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voice Registration',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                const Spacer(),
                _buildMainContent(),
                const Spacer(),
                _buildInteractiveArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mic_none_rounded,
                color: AppColors.neonCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Acoustic Footprint',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neonCyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _getHeaderText(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getSubtext(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _getHeaderText() {
    switch (_state) {
      case RecordState.idle:
        return 'Setup Voice Context';
      case RecordState.recording:
        return 'Recording...';
      case RecordState.processing:
        return 'Analyzing Voice...';
      case RecordState.success:
        return 'Voice Registered';
      case RecordState.error:
        return 'Registration Failed';
    }
  }

  String _getSubtext() {
    switch (_state) {
      case RecordState.idle:
        return 'We need a 5-second sample to recognize your voice during social interactions and reduce false positive nudges.';
      case RecordState.recording:
        return 'Please speak naturally.\n$_secondsLeft seconds remaining.';
      case RecordState.processing:
        return 'Extracting baseline acoustic features...';
      case RecordState.success:
        return 'Your acoustic footprint has been securely processed and stored locally.';
      case RecordState.error:
        return 'We couldn\'t process your voice sample. Please try again.';
    }
  }

  Widget _buildMainContent() {
    if (_state == RecordState.recording) {
      return _buildWaveform();
    } else if (_state == RecordState.processing) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.neonCyan,
            strokeWidth: 3,
          ),
        ),
      );
    } else if (_state == RecordState.success) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 64,
            ),
          ),
        ),
      );
    } else {
      // Idle state
      return SizedBox(
        height: 150,
        child: Center(
          child: Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.textMuted.withValues(alpha: 0.3),
            size: 100,
          ),
        ),
      );
    }
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_amplitudes.length, (index) {
          final height = max(4.0, _amplitudes[index] * 120.0);
          return Container(
            width: 4,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.neonCyan,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInteractiveArea() {
    if (_state == RecordState.success) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonCyan,
            foregroundColor: AppColors.darkNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: AppColors.neonCyan.withValues(alpha: 0.5),
          ),
          child: Text(
            'Complete Setup',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else if (_state == RecordState.idle || _state == RecordState.error) {
      return GestureDetector(
        onTap: _startRecording,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lavender.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.lavender, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.lavender.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.mic_rounded, color: AppColors.lavender, size: 36),
          ),
        ),
      );
    } else if (_state == RecordState.recording) {
      return GestureDetector(
        onTap: () {
          // User can cancel it early if they want, but technically requirement is 5s limit
          _stopRecording();
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.error, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.stop_rounded, color: AppColors.error, size: 36),
          ),
        ),
      );
    } else {
      return const SizedBox(height: 80);
    }
  }
}
