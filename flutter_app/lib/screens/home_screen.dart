import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/loading_widgets.dart';
import '../main.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_detail_screen.dart';
import 'settings_screen.dart';
import 'voice_create_group_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupProvider.notifier).loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final groupState = ref.watch(groupProvider);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, size: 22),
              onPressed: () => _joinGroup(context),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (value == 'signout') {
                await ref.read(authProvider.notifier).signOut();
              }
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: accent.withValues(alpha: 0.1),
              backgroundImage:
                  authState.user?.avatar.isNotEmpty == true
                      ? NetworkImage(authState.user!.avatar)
                      : null,
              child: authState.user?.avatar.isNotEmpty != true
                  ? Text(
                      authState.user?.name.isNotEmpty == true
                          ? authState.user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    )
                  : null,
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: textSecondary),
                    SizedBox(width: 10),
                    Text('Settings',
                        style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: textSecondary),
                    SizedBox(width: 10),
                    Text('Sign Out',
                        style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: groupState.isLoading
          ? _skeletonList()
          : groupState.groups.isEmpty
              ? _emptyState()
              : _groupList(groupState),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              heroTag: 'voice',
              backgroundColor: Colors.white,
              onPressed: () => _voiceCreateGroup(context),
              child: const Icon(Icons.mic, size: 22, color: accent),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 52,
            height: 52,
            child: FloatingActionButton(
              heroTag: 'create',
              onPressed: () => _createGroup(context),
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonGroupCard(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.groups_outlined,
                  size: 36, color: accent),
            ),
            const SizedBox(height: 20),
            const Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group or join one\nwith an invite code.',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupList(GroupState groupState) {
    return PullToRefresh(
      onRefresh: () => ref.read(groupProvider.notifier).loadGroups(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: groupState.groups.length,
        itemBuilder: (context, index) {
          final group = groupState.groups[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDetailScreen(groupId: group.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            group.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${group.activeMemberCount} ${group.activeMemberCount == 1 ? 'member' : 'members'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _createGroup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }

  void _voiceCreateGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VoiceCreateGroupSheet(),
    );
  }

  void _joinGroup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
    );
  }
}
