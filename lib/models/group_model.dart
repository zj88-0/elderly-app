// lib/models/group_model.dart

class GroupInvite {
  final String fromUserId;
  final String toUserId;
  final String groupId;
  final bool fromElderly;

  GroupInvite({
    required this.fromUserId,
    required this.toUserId,
    required this.groupId,
    required this.fromElderly,
  });

  Map<String, dynamic> toJson() => {
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'groupId': groupId,
    'fromElderly': fromElderly,
  };

  factory GroupInvite.fromJson(Map<String, dynamic> json) => GroupInvite(
    fromUserId: json['fromUserId'],
    toUserId: json['toUserId'],
    groupId: json['groupId'],
    fromElderly: json['fromElderly'],
  );
}

class GroupModel {
  final String id;
  String name;
  String elderlyId;
  List<String> caregiverIds;
  List<GroupInvite> pendingInvites;
  DateTime createdAt;
  String? adminCaregiverId;
  // 6-character uppercase invite code — generated when group is created
  String? inviteCode;

  GroupModel({
    required this.id,
    required this.name,
    required this.elderlyId,
    List<String>? caregiverIds,
    List<GroupInvite>? pendingInvites,
    DateTime? createdAt,
    this.adminCaregiverId,
    this.inviteCode,
  })  : caregiverIds = caregiverIds ?? [],
        pendingInvites = pendingInvites ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'elderlyId': elderlyId,
    'caregiverIds': caregiverIds,
    'pendingInvites': pendingInvites.map((i) => i.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'adminCaregiverId': adminCaregiverId,
    'inviteCode': inviteCode,
  };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
    id: json['id'],
    name: json['name'],
    elderlyId: json['elderlyId'],
    caregiverIds: List<String>.from(json['caregiverIds'] ?? []),
    pendingInvites: (json['pendingInvites'] as List<dynamic>? ?? [])
        .map((i) => GroupInvite.fromJson(i))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    adminCaregiverId: json['adminCaregiverId'] as String?,
    inviteCode: json['inviteCode'] as String?,
  );

  List<String> get allMemberIds => [elderlyId, ...caregiverIds];
}