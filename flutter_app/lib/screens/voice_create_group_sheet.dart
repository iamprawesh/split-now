import 'package:flutter/material.dart';
import '../main.dart';
import '../services/voice_service.dart';
import '../utils/voice_parser.dart';
import 'create_group_screen.dart';

class VoiceCreateGroupSheet extends StatefulWidget {
  const VoiceCreateGroupSheet({super.key});

  @override
  State<VoiceCreateGroupSheet> createState() => _VoiceCreateGroupSheetState();
}

class _VoiceCreateGroupSheetState extends State<VoiceCreateGroupSheet>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _manualController = TextEditingController();
  String _transcription = '';
  bool _isListening = false;
  bool _isDone = false;
  bool _isInitializing = true;
  bool _showManualFallback = false;
  String? _error;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _manualController.addListener(() => setState(() {}));
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      final available = await _voiceService.initialize();
      if (!mounted) return;
      setState(() => _isInitializing = false);
      if (!available) {
        final err = _voiceService.lastError;
        setState(() {
          _error = err ?? 'Speech recognition not available on this device.';
          _showManualFallback = true;
        });
        return;
      }
      await _startListening();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = '$e';
        _showManualFallback = true;
      });
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _error = null;
    });
    try {
      await _voiceService.startListening((text) {
        if (mounted) setState(() => _transcription = text);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _error = '$e';
          _showManualFallback = true;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isDone = true;
      });
    }
  }

  void _confirm() {
    final text = _transcription.isNotEmpty ? _transcription : _manualController.text.trim();
    if (text.isEmpty) return;

    final parsed = parseGroupCommand(text);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          initialName: parsed.name.isNotEmpty ? parsed.name : text,
          initialDescription: parsed.description,
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _transcription = '';
      _isDone = false;
      _isInitializing = true;
      _showManualFallback = false;
      _error = null;
    });
    _initVoice();
  }

  @override
  void dispose() {
    _voiceService.cancelListening();
    _manualController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isDone ? 'Review' : 'Voice Input',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_showManualFallback) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Type the group name instead:',
                  style: const TextStyle(fontSize: 13, color: textSecondary),
                ),
              ),
              TextField(
                controller: _manualController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Trip to Goa',
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _manualController.text.trim().isNotEmpty
                      ? _confirm
                      : null,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry Voice'),
                  ),
                ),
            ] else if (!_isDone) ...[
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? accent.withValues(alpha: 0.12)
                          : borderLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening
                          ? Icons.mic
                          : _isInitializing
                              ? Icons.hourglass_bottom
                              : Icons.mic_off,
                      color: _isListening || _isInitializing
                          ? accent
                          : textSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isListening
                    ? 'Listening...'
                    : _isInitializing
                        ? 'Initializing...'
                        : 'Ready',
                style: const TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 20),
              if (_transcription.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderLight),
                  ),
                  child: Text(
                    _transcription,
                    style: const TextStyle(
                      fontSize: 15, color: textPrimary, height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (_isListening)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _stopListening,
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('Stop'),
                  ),
                ),
            ],
            if (_isDone) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderLight),
                ),
                child: Text(
                  _transcription.isNotEmpty
                      ? _transcription
                      : '(No speech detected)',
                  style: const TextStyle(
                    fontSize: 15, color: textPrimary, height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Retry'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _transcription.isNotEmpty ? _confirm : null,
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        label: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
