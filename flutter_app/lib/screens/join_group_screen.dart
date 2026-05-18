import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/group_provider.dart';
import '../widgets/loading_widgets.dart';
import '../main.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _scanMode = false;
  bool _joining = false;

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: groupState.isJoining,
      message: 'Joining group...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Join Group'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _scanMode ? _scanner(isDark) : _codeInput(groupState, isDark),
      ),
    );
  }

  Widget _codeInput(GroupState groupState, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.groups_outlined,
                size: 32, color: accent),
          ),
          const SizedBox(height: 20),
          Text('Enter invite code',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? textPrimaryDark : textPrimary)),
          const SizedBox(height: 6),
          Text('Paste the code shared with you.',
              style: TextStyle(fontSize: 13,
                  color: isDark ? textSecondaryDark : textSecondary)),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'e.g. aB3xK9mP2q',
            ),
            textCapitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 16),
          LoadingButton(
            isLoading: groupState.isJoining,
            label: 'Join Group',
            loadingLabel: 'Joining...',
            onPressed: _joinByCode,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: TextStyle(
                    fontSize: 13,
                    color: isDark ? textSecondaryDark : textSecondary)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: groupState.isJoining
                  ? null
                  : () {
                      _scannerController = MobileScannerController();
                      setState(() => _scanMode = true);
                    },
              icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
              label: const Text('Scan QR code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanner(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null && !_joining) {
                    _joining = true;
                    _scannerController?.stop();
                    _handleScan(barcode!.rawValue!);
                  }
                },
              ),
              Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: isDark ? cardBgDark : Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Point camera at QR code',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? textPrimaryDark : textPrimary)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    _scannerController?.dispose();
                    _scannerController = null;
                    setState(() => _scanMode = false);
                  },
                  child: const Text('Enter code manually'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleScan(String raw) {
    try {
      String code = raw;
      try {
        final json = jsonDecode(raw);
        if (json is Map && json['code'] != null) {
          code = json['code'].toString();
        }
      } catch (_) {}
      if (code == raw && raw.contains('grp_')) {
        code = raw.split('grp_').last.split('"').first;
      }
      _codeController.text = code;
      _joinByCode();
    } catch (_) {
      _joining = false;
      _scannerController?.start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code')),
      );
    }
  }

  void _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _joining = false;
      _scannerController?.start();
      return;
    }
    final group =
        await ref.read(groupProvider.notifier).joinByCode(code);
    if (!mounted) return;
    if (group != null) {
      Navigator.pop(context);
    } else {
      _joining = false;
      _scannerController?.start();
    }
  }
}
