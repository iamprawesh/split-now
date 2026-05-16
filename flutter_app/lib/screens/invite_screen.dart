import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' as share;
import '../providers/group_provider.dart';
import '../main.dart';

class InviteScreen extends ConsumerStatefulWidget {
  final String groupId;
  const InviteScreen({super.key, required this.groupId});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupProvider.notifier).generateInvite(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final invite = groupState.invite;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Invite'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Share invite code',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 6),
              Text('Ask friends to scan this QR or share the link.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: groupState.isLoading
                    ? SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: _PulseLoader(),
                        ),
                      )
                    : invite != null
                        ? QrImageView(
                            data: invite.qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          )
                        : const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: Text('Failed to load',
                                style: TextStyle(color: textSecondary))),
                          ),
              ),
              const SizedBox(height: 28),
              if (invite != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          invite.link,
                          style: const TextStyle(
                              fontSize: 13, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          share.Share.share(invite.link);
                        },
                        child: const Icon(Icons.copy,
                            size: 18, color: accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      share.Share.share(invite.link);
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share invite link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseLoader extends StatefulWidget {
  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Opacity(
        opacity: _pulse.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: borderLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded,
                    size: 64, color: accent),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Generating invite...',
                style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}
