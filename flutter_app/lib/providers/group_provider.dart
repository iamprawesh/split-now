import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class GroupState {
  final bool isLoading;
  final bool isCreating;
  final bool isJoining;
  final bool isLeaving;
  final bool isTogglingMember;
  final List<Group> groups;
  final Group? selectedGroup;
  final String? error;
  final GroupInvite? invite;

  GroupState({
    this.isLoading = false,
    this.isCreating = false,
    this.isJoining = false,
    this.isLeaving = false,
    this.isTogglingMember = false,
    this.groups = const [],
    this.selectedGroup,
    this.error,
    this.invite,
  });

  GroupState copyWith({
    bool? isLoading,
    bool? isCreating,
    bool? isJoining,
    bool? isLeaving,
    bool? isTogglingMember,
    List<Group>? groups,
    Group? selectedGroup,
    String? error,
    GroupInvite? invite,
  }) {
    return GroupState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isJoining: isJoining ?? this.isJoining,
      isLeaving: isLeaving ?? this.isLeaving,
      isTogglingMember: isTogglingMember ?? this.isTogglingMember,
      groups: groups ?? this.groups,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      error: error,
      invite: invite ?? this.invite,
    );
  }
}

class GroupNotifier extends StateNotifier<GroupState> {
  final ApiService _api;
  final Ref _ref;

  GroupNotifier(this._api, this._ref) : super(GroupState());

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get('/groups');
      final groups =
          (response.data as List).map((g) => Group.fromJson(g)).toList();
      state = state.copyWith(isLoading: false, groups: groups);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createGroup(String name, String description) async {
    state = state.copyWith(isCreating: true);

    final user = _ref.read(authProvider).user;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticGroup = Group(
      id: tempId,
      name: name,
      description: description,
      members: user != null
          ? [
              GroupMember(
                userId: user.id,
                name: user.name,
                email: user.email,
                avatar: user.avatar,
                role: 'admin',
                joinedAt: DateTime.now(),
              ),
            ]
          : [],
      createdBy: user?.id ?? '',
    );
    state = state.copyWith(
      groups: [optimisticGroup, ...state.groups],
      isCreating: false,
    );

    try {
      await _api.post('/groups', data: {
        'name': name,
        'description': description,
      });
      await loadGroups();
    } catch (e) {
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != tempId).toList(),
        error: e.toString(),
      );
    }
  }

  Future<void> updateGroup(String id, String name, String description) async {
    state = state.copyWith(isCreating: true);

    final tempGroup = state.selectedGroup;
    if (tempGroup != null) {
      state = state.copyWith(
        selectedGroup: Group(
          id: tempGroup.id,
          name: name,
          description: description,
          members: tempGroup.members,
          createdBy: tempGroup.createdBy,
        ),
      );
    }

    try {
      await _api.put('/groups/$id', data: {
        'name': name,
        'description': description,
      });
      state = state.copyWith(isCreating: false);
      await loadGroups();
      if (state.selectedGroup?.id == id) {
        await loadGroup(id);
      }
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        selectedGroup: tempGroup,
        error: e.toString(),
      );
    }
  }

  Future<void> loadGroup(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get('/groups/$id');
      state = state.copyWith(
        isLoading: false,
        selectedGroup: Group.fromJson(response.data),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addMembers(String groupId, List<String> userIds) async {
    state = state.copyWith(isTogglingMember: true);
    try {
      final response = await _api.post('/groups/$groupId/members', data: {
        'userIds': userIds,
      });
      state = state.copyWith(
        isTogglingMember: false,
        selectedGroup: Group.fromJson(response.data),
      );
      await loadGroups();
    } catch (e) {
      state = state.copyWith(isTogglingMember: false, error: e.toString());
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    state = state.copyWith(isTogglingMember: true);
    try {
      final response =
          await _api.delete('/groups/$groupId/members/$userId');
      state = state.copyWith(
        isTogglingMember: false,
        selectedGroup: Group.fromJson(response.data),
      );
      await loadGroups();
    } catch (e) {
      state = state.copyWith(isTogglingMember: false, error: e.toString());
    }
  }

  Future<void> generateInvite(String groupId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.post('/groups/$groupId/invite');
      state = state.copyWith(
        isLoading: false,
        invite: GroupInvite.fromJson(response.data),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Group?> joinByCode(String code) async {
    state = state.copyWith(isJoining: true);
    try {
      final response = await _api.post('/groups/join/$code');
      final group = Group.fromJson(response.data);
      state = state.copyWith(isJoining: false);
      await loadGroups();
      return group;
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
      return null;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    state = state.copyWith(isLeaving: true);
    try {
      await _api.post('/groups/$groupId/leave');
      state = state.copyWith(isLeaving: false);
      await loadGroups();
    } catch (e) {
      state = state.copyWith(isLeaving: false, error: e.toString());
    }
  }
}

final groupProvider =
    StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  return GroupNotifier(ref.watch(apiServiceProvider), ref);
});
