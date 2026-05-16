class GroupMember {
  final String userId;
  final String name;
  final String email;
  final String avatar;
  final String role;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.avatar,
    required this.role,
    this.joinedAt,
    this.leftAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    return GroupMember(
      userId: user['_id'] ?? user['id'] ?? json['user'] ?? '',
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      avatar: user['avatar'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final List<GroupMember> members;
  final String createdBy;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.createdBy,
  });

  int get activeMemberCount => members.where((m) => m.leftAt == null).length;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromJson(m))
              .toList() ??
          [],
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['_id'] ?? ''
          : json['createdBy'] ?? '',
    );
  }
}

class GroupInvite {
  final String code;
  final String link;
  final String qrData;

  GroupInvite({
    required this.code,
    required this.link,
    required this.qrData,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      code: json['code'] ?? '',
      link: json['link'] ?? '',
      qrData: json['qrData'] ?? '',
    );
  }
}
