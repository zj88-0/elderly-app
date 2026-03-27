// lib/data/data_service.dart
//
// Firebase-backed DataService — PATCHED v2
//
// FIXES in this version (on top of previous):
//   1. Messages: sendMessage now immediately inserts the message into _messages
//      so the UI updates without waiting for the Firestore snapshot round-trip.
//      The snapshot listener deduplicates by id to prevent double-insertion.
//   2. Messages: fromJson handling for Timestamp is now in MessageModel itself
//      (see message_model.dart), but subscribeToConversation also passes the
//      doc.id so the 'id' field is always present.
//   3. Caregiver home page: getCheckInWindowHours() exposes the configured
//      interval per elderly so the home page cards use the right window.
//   4. hasActivityInWindow is now readable for caregiver status cards via
//      getActivityStatusForElderly().
//   5. Manual check-in always uses a 24hr window (never uses configured
//      interval) — enforced via hasManualCheckedInToday which checks same day.

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/checkin_model.dart';
import '../models/message_model.dart';
import '../models/wellbeing_model.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

const _uuid = Uuid();

// Generates a random 6-character uppercase invite code e.g. "X4K9TZ"
String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O,0,I,1 — ambiguous
  final rng = math.Random.secure();
  return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
}

// ── Firestore collection paths ─────────────────────────────────────────────
const _colUsers = 'users';
const _colGroups = 'groups';
const _colSos = 'sos';
const _colSummary = 'checkin_summary';
const _colWellbeing = 'wellbeing';
const _colInviteCodes = 'invite_codes';
// messages: /messages/{groupId}/msgs/{msgId}
// checkins: /checkins/{elderlyId}/events/{eventId}

class DataService extends ChangeNotifier {
  // ── Firebase instances ───────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── In-memory caches (avoid repeated Firestore reads) ───────────────────
  final Map<String, UserModel> _userCache = {};
  final List<GroupModel> _groups = [];
  final List<SosModel> _sosList = [];
  final List<MessageModel> _messages = [];
  final List<WellbeingEntry> _wellbeingEntries = [];

  // ── Local-only (SharedPreferences) ──────────────────────────────────────
  final List<CheckInModel> _checkIns = [];
  final Map<String, ActivityCheckModel> _activityChecks = {};
  final Map<String, String?> _nicknames = {};

  // ── Active real-time listeners (cancel on logout) ────────────────────────
  StreamSubscription? _groupsSub;
  StreamSubscription? _sosSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _checkInsSub;
  // Caregiver: real-time listener for a single elderly's check-in events
  StreamSubscription? _elderlyCheckInsSub;
  // Caregiver: real-time listeners for all group unread message counters
  final List<StreamSubscription> _unreadSubs = [];
  String? _activeConvGroupId;
  String? _activeElderlyCheckInsId;

  // Tracks known IDs to prevent notifying on initial app load
  final Set<String> _knownSosIds = {};
  final Set<String> _knownMessageIds = {};

  // ── Per-user unread message counters ─────────────────────────────────────
  final Map<String, int> _unreadCounts = {};

  // ── Pagination cursor for messages ───────────────────────────────────────
  DocumentSnapshot? _lastMessageDoc;
  static const int _msgPageSize = 30;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  List<GroupModel> get groups => List.unmodifiable(_groups);
  List<SosModel> get sosList => List.unmodifiable(_sosList);
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoggedIn => _currentUser != null;
  List<UserModel> get users => _userCache.values.toList();
  List<CheckInModel> get checkIns => List.unmodifiable(_checkIns);
  Map<String, String?> get nicknames => Map.unmodifiable(_nicknames);

  // ════════════════════════════════════════════════════════════════════════
  // INIT
  // ════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await _loadLocal();

    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      await _restoreSession(fbUser.uid);
    }

    notifyListeners();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();

    _checkIns.clear();
    _activityChecks.clear();
    _nicknames.clear();
    _wellbeingEntries.clear();

    final acRaw = prefs.getString('activityChecks');
    if (acRaw != null) {
      final map = jsonDecode(acRaw) as Map<String, dynamic>;
      map.forEach((k, v) => _activityChecks[k] =
          ActivityCheckModel.fromJson(v as Map<String, dynamic>));
    }

    final nickRaw = prefs.getString('nicknames');
    if (nickRaw != null) {
      final map = jsonDecode(nickRaw) as Map<String, dynamic>;
      map.forEach((k, v) => _nicknames[k] = v as String?);
    }

    final wbRaw = prefs.getString('wellbeingEntries');
    if (wbRaw != null) {
      final list = jsonDecode(wbRaw) as List;
      _wellbeingEntries.addAll(
          list.map((e) => WellbeingEntry.fromJson(e as Map<String, dynamic>)));
    }
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final acMap = <String, dynamic>{};
    _activityChecks.forEach((k, v) => acMap[k] = v.toJson());
    await prefs.setString('activityChecks', jsonEncode(acMap));
    await prefs.setString('nicknames', jsonEncode(_nicknames));
    await prefs.setString('wellbeingEntries',
        jsonEncode(_wellbeingEntries.map((w) => w.toJson()).toList()));
    if (_currentUser != null) {
      await prefs.setString('currentUserId', _currentUser!.id);
    }
  }

  Future<void> _restoreSession(String uid) async {
    final user = await _fetchUser(uid);
    if (user != null) {
      _currentUser = user;
      await _subscribeToGroups();
      await _subscribeToSos();
      if (user.role == UserRole.elderly) {
        _subscribeToMyCheckIns();
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // USER CACHE HELPERS
  // ════════════════════════════════════════════════════════════════════════

  Future<UserModel?> _fetchUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    try {
      final doc = await _db.collection(_colUsers).doc(uid).get();
      if (!doc.exists) return null;
      final user = UserModel.fromJson({'id': doc.id, ...doc.data()!});
      _userCache[uid] = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveUser(UserModel user) async {
    _userCache[user.id] = user;
    final data = user.toFirestore();
    await _db
        .collection(_colUsers)
        .doc(user.id)
        .set(data, SetOptions(merge: true));
  }

  UserModel? getUserById(String id) => _userCache[id];

  // ════════════════════════════════════════════════════════════════════════
  // NICKNAMES  (local only)
  // ════════════════════════════════════════════════════════════════════════

  String? getNickname(String userId) => _nicknames[userId];

  Future<void> setNickname(String userId, String? nickname) async {
    if (nickname == null || nickname.trim().isEmpty) {
      _nicknames.remove(userId);
    } else {
      _nicknames[userId] = nickname.trim();
    }
    await _persistLocal();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  // AUTH  (Firebase Authentication)
  // ════════════════════════════════════════════════════════════════════════

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phoneNumber,
  }) async {
    late UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already registered.');
      }
      throw Exception(e.message ?? 'Registration failed.');
    }

    final uid = cred.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email.trim().toLowerCase(),
      password: '',
      role: role,
      phoneNumber: phoneNumber,
    );

    await _saveUser(user);
    await _auth.signOut();
    return user;
  }

  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final uid = cred.user!.uid;

    final user = await _fetchUser(uid);
    if (user == null) throw Exception('User profile not found.');

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', uid);

    await _subscribeToGroups();
    await _subscribeToSos();
    if (user.role == UserRole.elderly) {
      _subscribeToMyCheckIns();
    }
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    _cancelSubscriptions();
    await _auth.signOut();
    _currentUser = null;
    _groups.clear();
    _sosList.clear();
    _messages.clear();
    _wellbeingEntries.clear();
    _userCache.clear();
    _knownSosIds.clear();
    _knownMessageIds.clear();
    _unreadCounts.clear();
    for (final sub in _unreadSubs) { sub.cancel(); }
    _unreadSubs.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    notifyListeners();
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateCurrentUser({
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');

    if (name != null) user.name = name;
    if (email != null) user.email = email.toLowerCase();
    if (phoneNumber != null) user.phoneNumber = phoneNumber;

    if (password != null && password.isNotEmpty) {
      await _auth.currentUser!.updatePassword(password);
    }

    if (email != null && email.toLowerCase() != _auth.currentUser!.email) {
      await _auth.currentUser!.verifyBeforeUpdateEmail(email);
    }

    _currentUser = user;
    await _saveUser(user);
    notifyListeners();
  }

  List<UserModel> searchUsersByEmail(String query) {
    return _userCache.values
        .where((u) =>
    u.email.toLowerCase().contains(query.toLowerCase()) &&
        u.id != _currentUser?.id)
        .toList();
  }

  Future<String> regenerateInviteCode(String groupId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');
    final group = getGroupById(groupId);
    if (group == null) throw Exception('Group not found.');
    if (group.elderlyId != user.id) {
      throw Exception('Only the elderly owner can regenerate the invite code.');
    }
    if (group.inviteCode != null && group.inviteCode!.isNotEmpty) {
      await _db.collection(_colInviteCodes).doc(group.inviteCode).delete();
    }
    final newCode = _generateInviteCode();
    group.inviteCode = newCode;
    final batch = _db.batch();
    batch.update(
        _db.collection(_colGroups).doc(groupId), {'inviteCode': newCode});
    batch.set(_db.collection(_colInviteCodes).doc(newCode), {
      'groupId': groupId,
      'elderlyId': user.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    notifyListeners();
    return newCode;
  }

  // ════════════════════════════════════════════════════════════════════════
  // GROUPS  (Firestore real-time)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _subscribeToGroups() async {
    final user = _currentUser;
    if (user == null) return;
    _groupsSub?.cancel();

    Query<Map<String, dynamic>> query;
    if (user.role == UserRole.elderly) {
      query = _db.collection(_colGroups).where('elderlyId', isEqualTo: user.id);
    } else {
      query = _db
          .collection(_colGroups)
          .where('caregiverIds', arrayContains: user.id);
    }

    _groupsSub = query.snapshots().listen((snap) async {
      _groups.clear();
      for (final doc in snap.docs) {
        final g = GroupModel.fromJson({'id': doc.id, ...doc.data()});
        _groups.add(g);
        for (final uid in g.allMemberIds) {
          if (!_userCache.containsKey(uid)) {
            await _fetchUser(uid);
          }
        }
      }
      await _subscribeToSos();
      await _subscribeToUnreadCounts();
      await _saveBackgroundServiceData();
      notifyListeners();
    });
  }

  /// Persists the user's group and name data to SharedPreferences so the
  /// background service isolate (which cannot access DataService) can set up
  /// its own Firestore listeners for messages and SOS when the app is closed.
  Future<void> _saveBackgroundServiceData() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      final groups = _groups.map((g) => {
        'id': g.id,
        'elderlyId': g.elderlyId,
        'allMemberIds': g.allMemberIds,
      }).toList();
      final userNames = <String, String>{};
      for (final e in _userCache.entries) {
        userNames[e.key] = e.value.name;
      }
      userNames[user.id] = user.name;
      for (final e in _nicknames.entries) {
        if (e.value != null) userNames[e.key] = e.value!;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserId', user.id);
      await prefs.setString(
          'currentUserRole',
          user.role == UserRole.elderly ? 'elderly' : 'caregiver');
      await prefs.setString('bgGroups', jsonEncode(groups));
      await prefs.setString('bgUserNames', jsonEncode(userNames));
      FlutterBackgroundService().invoke('updateListeners');
    } catch (_) {}
  }

  Future<GroupModel> createGroup(String name) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.elderly) {
      throw Exception('Only elderly users can create groups.');
    }
    if (user.groupId != null && user.groupId!.isNotEmpty) {
      throw Exception('You already belong to a group.');
    }
    final groupId = _uuid.v4();

    String inviteCode = _generateInviteCode();
    final codeCheck =
    await _db.collection(_colInviteCodes).doc(inviteCode).get();
    if (codeCheck.exists) inviteCode = _generateInviteCode();

    final group = GroupModel(
        id: groupId, name: name, elderlyId: user.id, inviteCode: inviteCode);

    final batch = _db.batch();
    batch.set(_db.collection(_colGroups).doc(groupId), group.toJson());
    batch.set(_db.collection(_colInviteCodes).doc(inviteCode), {
      'groupId': groupId,
      'elderlyId': user.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    user.groupId = groupId;
    _currentUser = user;
    await _saveUser(user);
    notifyListeners();
    return group;
  }

  GroupModel? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GroupModel> getCaregiverGroups() {
    final user = _currentUser;
    if (user == null) return [];
    return _groups
        .where(
            (g) => g.caregiverIds.contains(user.id) || g.elderlyId == user.id)
        .toList();
  }

  GroupModel? getElderlyGroup() {
    final user = _currentUser;
    if (user?.groupId == null || user!.groupId!.isEmpty) return null;
    return getGroupById(user.groupId!);
  }

  List<GroupInvite> getPendingInvitesForCurrentUser() {
    final user = _currentUser;
    if (user == null) return [];
    ;
    return _groups
        .expand((g) => g.pendingInvites)
        .where((inv) => inv.toUserId == user.id)
        .toList();
  }

  Future<void> sendInvite({
    required String toUserId,
    required String groupId,
    required bool fromElderly,
  }) async {
    final groupIdx = _groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) throw Exception('Group not found.');
    final alreadyInvited =
    _groups[groupIdx].pendingInvites.any((i) => i.toUserId == toUserId);
    if (alreadyInvited) throw Exception('Invite already sent.');

    final invite = GroupInvite(
      fromUserId: _currentUser!.id,
      toUserId: toUserId,
      groupId: groupId,
      fromElderly: fromElderly,
    );
    _groups[groupIdx].pendingInvites.add(invite);

    await _db.collection(_colGroups).doc(groupId).update({
      'pendingInvites':
      _groups[groupIdx].pendingInvites.map((i) => i.toJson()).toList(),
    });
    notifyListeners();
  }

  Future<void> requestToJoinGroup(String elderlyUserId) async {
    final caregiver = _currentUser;
    if (caregiver == null || caregiver.role != UserRole.caregiver) {
      throw Exception('Only caregivers can send join requests.');
    }
    final elderly = await _fetchUser(elderlyUserId);
    if (elderly == null ||
        elderly.groupId == null ||
        elderly.groupId!.isEmpty) {
      throw Exception('Elderly user does not have a group yet.');
    }
    await sendInvite(
      toUserId: elderlyUserId,
      groupId: elderly.groupId!,
      fromElderly: false,
    );
  }

  Future<void> _updateGroupDoc(GroupModel group) async {
    await _db
        .collection(_colGroups)
        .doc(group.id)
        .set(group.toJson(), SetOptions(merge: true));
  }

  Future<void> acceptInvite(GroupInvite invite) async {
    final groupIdx = _groups.indexWhere((g) => g.id == invite.groupId);
    if (groupIdx == -1) throw Exception('Group not found.');
    final group = _groups[groupIdx];
    group.pendingInvites.removeWhere(
            (i) => i.toUserId == invite.toUserId && i.groupId == invite.groupId);

    if (invite.fromElderly) {
      if (!group.caregiverIds.contains(invite.toUserId)) {
        group.caregiverIds.add(invite.toUserId);
      }
      final u = await _fetchUser(invite.toUserId);
      if (u != null && !u.groupIds.contains(group.id)) {
        u.groupIds.add(group.id);
        await _saveUser(u);
        if (_currentUser?.id == u.id) _currentUser = u;
      }
    } else {
      if (!group.caregiverIds.contains(invite.fromUserId)) {
        group.caregiverIds.add(invite.fromUserId);
      }
      final u = await _fetchUser(invite.fromUserId);
      if (u != null && !u.groupIds.contains(group.id)) {
        u.groupIds.add(group.id);
        await _saveUser(u);
      }
    }
    await _updateGroupDoc(group);
    notifyListeners();
  }

  Future<void> declineInvite(GroupInvite invite) async {
    final groupIdx = _groups.indexWhere((g) => g.id == invite.groupId);
    if (groupIdx == -1) return;
    _groups[groupIdx].pendingInvites.removeWhere(
            (i) => i.toUserId == invite.toUserId && i.groupId == invite.groupId);
    await _updateGroupDoc(_groups[groupIdx]);
    notifyListeners();
  }

  Future<void> adminAcceptInvite(GroupInvite invite) async =>
      acceptInvite(invite);
  Future<void> adminDeclineInvite(GroupInvite invite) async =>
      declineInvite(invite);

  Future<void> setGroupAdmin(
      {required String groupId, required String? caregiverId}) async {
    final groupIdx = _groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) throw Exception('Group not found.');
    final group = _groups[groupIdx];
    if (_currentUser?.id != group.elderlyId) {
      throw Exception('Only the elderly owner can set the group admin.');
    }
    group.adminCaregiverId = caregiverId;
    await _updateGroupDoc(group);
    notifyListeners();
  }

  bool isAdminOfGroup(String groupId) {
    final user = _currentUser;
    if (user == null) return false;
    final group = getGroupById(groupId);
    if (group == null) return false;
    return group.adminCaregiverId == user.id;
  }

  Future<void> removeCaregiverFromGroup(
      {required String groupId, required String caregiverId}) async {
    final groupIdx = _groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) throw Exception('Group not found.');
    final group = _groups[groupIdx];
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');
    if (user.id != group.elderlyId && group.adminCaregiverId != user.id) {
      throw Exception('Only the elderly or admin can remove members.');
    }
    group.caregiverIds.remove(caregiverId);
    if (group.adminCaregiverId == caregiverId) group.adminCaregiverId = null;
    final u = await _fetchUser(caregiverId);
    if (u != null) {
      u.groupIds.remove(groupId);
      await _saveUser(u);
    }
    await _updateGroupDoc(group);
    notifyListeners();
  }

  Future<void> updateGroupName(
      {required String groupId, required String name}) async {
    final groupIdx = _groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) throw Exception('Group not found.');
    final group = _groups[groupIdx];
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');
    if (user.id != group.elderlyId && group.adminCaregiverId != user.id) {
      throw Exception('Only the elderly or admin can rename the group.');
    }
    group.name = name.trim();
    await _updateGroupDoc(group);
    notifyListeners();
  }

  Future<GroupModel> joinGroupByInviteCode(String code) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');
    if (user.role != UserRole.caregiver) {
      throw Exception('Only caregivers can join groups with an invite code.');
    }

    final upperCode = code.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (upperCode.length != 6) {
      throw Exception(
          'Invite code must be 6 characters. You entered ${upperCode.length} characters.');
    }

    final codeDoc = await _db.collection(_colInviteCodes).doc(upperCode).get();
    if (!codeDoc.exists) {
      throw Exception(
          'Invalid invite code ($upperCode). Please check and try again.');
    }

    final groupId = codeDoc.data()?['groupId'] as String?;
    if (groupId == null) {
      throw Exception('Invalid invite code data. Please ask for a new code.');
    }

    final groupDoc = await _db.collection(_colGroups).doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Group no longer exists. Please ask for a new code.');
    }

    final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data()!});

    if (group.caregiverIds.contains(user.id)) {
      throw Exception('You are already a member of this group.');
    }

    group.caregiverIds.add(user.id);
    if (!user.groupIds.contains(group.id)) {
      user.groupIds.add(group.id);
    }
    _currentUser = user;

    await _db.collection(_colGroups).doc(group.id).update({
      'caregiverIds': group.caregiverIds,
    });
    await _saveUser(user);
    notifyListeners();
    return group;
  }

  Future<void> quitGroup(String groupId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');
    if (user.role != UserRole.caregiver) {
      throw Exception('Only caregivers can quit a group.');
    }
    final groupIdx = _groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) throw Exception('Group not found.');
    final group = _groups[groupIdx];
    group.caregiverIds.remove(user.id);
    if (group.adminCaregiverId == user.id) group.adminCaregiverId = null;
    user.groupIds.remove(groupId);
    _currentUser = user;
    await _saveUser(user);
    await _updateGroupDoc(group);
    notifyListeners();
  }

  Future<void> elderlyQuitGroup() async {
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in.');
    if (user.role != UserRole.elderly) {
      throw Exception('Only elderly users can disband their group.');
    }
    if (user.groupId == null) throw Exception('You are not in a group.');
    final groupId = user.groupId!;
    final groupIdx = _groups.indexWhere((g) => g.id == groupId);
    if (groupIdx != -1) {
      final group = _groups[groupIdx];
      for (final cid in group.caregiverIds) {
        final u = await _fetchUser(cid);
        if (u != null) {
          u.groupIds.remove(groupId);
          await _saveUser(u);
        }
      }
      await _db.collection(_colGroups).doc(groupId).delete();
      _groups.removeAt(groupIdx);
    }
    user.groupId = null;
    _currentUser = user;
    await _saveUser(user);

    await _deleteGroupMessages(groupId);
    await _deleteSosForElderly(user.id);
    _sosList.removeWhere((s) => s.elderlyId == user.id);
    _checkIns.removeWhere((c) => c.elderlyId == user.id);
    _checkInsSub?.cancel();
    _checkInsSub = null;
    await _persistLocal();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  // CHECK-INS  (Firestore real-time for elderly; summary for caregivers)
  // ════════════════════════════════════════════════════════════════════════

  Future<CheckInModel> createCheckIn({
    required String elderlyId,
    required CheckInType type,
    Map<String, dynamic>? meta,
    DateTime? timestamp,
    String? id,
  }) async {
    final effectiveId = id ?? _uuid.v4();

    if (_checkIns.any((c) => c.id == effectiveId)) {
      debugPrint('Check-in $effectiveId already exists, skipping.');
      return _checkIns.firstWhere((c) => c.id == effectiveId);
    }

    final checkIn = CheckInModel(
        id: effectiveId,
        elderlyId: elderlyId,
        type: type,
        meta: meta,
        timestamp: timestamp);

    _checkIns.insert(0, checkIn);
    if (_checkIns.length > 200) _checkIns.removeLast();

    _updateActivitySignal(elderlyId, type, timestamp);

    // Write to Firestore check-in events collection
    await _db
        .collection('checkins')
        .doc(elderlyId)
        .collection('events')
        .doc(effectiveId)
        .set(checkIn.toJson());

    await _persistLocal();
    await _updateCheckInSummary(elderlyId);

    notifyListeners();
    return checkIn;
  }

  Future<void> handleAppResume() async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.elderly) return;

    final pending = await BackgroundServiceHelper.consumePendingCheckIns();
    for (final item in pending) {
      final type = CheckInType.values.firstWhere(
            (e) => e.name == item['type'],
        orElse: () => CheckInType.manual,
      );

      await createCheckIn(
        elderlyId: item['elderlyId'],
        type: type,
        meta: item['meta'],
        timestamp: DateTime.parse(item['timestamp']),
        id: item['id'],
      );
    }

    // _refreshAllUnreadCounts was removed and replaced by _subscribeToUnreadCounts
  }

  Future<void> _updateCheckInSummary(String elderlyId) async {
    final ac = getOrCreateActivityCheck(elderlyId);
    final latestUnlock = getLatestPhoneUnlockCheckIn(elderlyId);
    final latestManual = getLatestManualCheckIn(elderlyId);
    final latestSteps = getLatestStepsCheckIn(elderlyId);
    final latestPickup = getLatestPhonePickupCheckIn(elderlyId);
    final todayCount = getTodayCheckIns(elderlyId).length;

    await _db.collection(_colSummary).doc(elderlyId).set({
      'elderlyId': elderlyId,
      'lastActivity': ac.nextCheckDue,
      'elderlyNotified': ac.elderlyNotified,
      'caregiverNotified': ac.caregiverNotified,
      'checkInIntervalHours': ac.checkInIntervalHours,
      'autoCheckInEnabled': ac.autoCheckInEnabled,
      'trackPhoneUnlock': ac.trackPhoneUnlock,
      'trackStepsActive': ac.trackStepsActive,
      'trackPhonePickup': ac.trackPhonePickup,
      'sleepStartHour': ac.sleepStartHour,
      'sleepEndHour': ac.sleepEndHour,
      'lastPhoneUnlock': latestUnlock?.timestamp.toIso8601String(),
      'lastManual': latestManual?.timestamp.toIso8601String(),
      'lastSteps': latestSteps?.timestamp.toIso8601String(),
      'lastPickup': latestPickup?.timestamp.toIso8601String(),
      'todayCount': todayCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCheckInSummary(String elderlyId) async {
    try {
      final doc = await _db.collection(_colSummary).doc(elderlyId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to real-time check-in summary updates for a given elderly user.
  void subscribeToElderlyCheckIns(String elderlyId) {
    if (_activeElderlyCheckInsId == elderlyId) return; // already subscribed

    _elderlyCheckInsSub?.cancel();
    _activeElderlyCheckInsId = elderlyId;

    _elderlyCheckInsSub = _db
        .collection('checkins')
        .doc(elderlyId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      // Merge into the shared _checkIns list (only for this elderly)
      _checkIns.removeWhere((c) => c.elderlyId == elderlyId);
      for (final doc in snap.docs) {
        try {
          _checkIns.add(CheckInModel.fromJson(doc.data()));
        } catch (_) {}
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Elderly check-in subscription error: $e');
    });
  }

  void unsubscribeFromElderlyCheckIns() {
    _elderlyCheckInsSub?.cancel();
    _elderlyCheckInsSub = null;
    _activeElderlyCheckInsId = null;
  }

  CheckInModel? getLatestCheckIn(String elderlyId) {
    final list = _checkIns.where((c) => c.elderlyId == elderlyId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.isEmpty ? null : list.first;
  }

  CheckInModel? getLatestManualCheckIn(String elderlyId) {
    final list = _checkIns
        .where((c) => c.elderlyId == elderlyId && c.type == CheckInType.manual)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.isEmpty ? null : list.first;
  }

  CheckInModel? getLatestPhoneUnlockCheckIn(String elderlyId) {
    final list = _checkIns
        .where((c) =>
    c.elderlyId == elderlyId && c.type == CheckInType.phoneUnlock)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.isEmpty ? null : list.first;
  }

  CheckInModel? getLatestStepsCheckIn(String elderlyId) {
    final list = _checkIns
        .where((c) =>
    c.elderlyId == elderlyId && c.type == CheckInType.stepsActive)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.isEmpty ? null : list.first;
  }

  CheckInModel? getLatestPhonePickupCheckIn(String elderlyId) {
    final list = _checkIns
        .where((c) =>
    c.elderlyId == elderlyId && c.type == CheckInType.phonePickup)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.isEmpty ? null : list.first;
  }

  List<CheckInModel> getTodayCheckIns(String elderlyId) {
    final today = DateTime.now();
    return _checkIns
        .where((c) =>
    c.elderlyId == elderlyId &&
        c.timestamp.year == today.year &&
        c.timestamp.month == today.month &&
        c.timestamp.day == today.day)
        .toList();
  }

  bool hasManualCheckedInToday(String elderlyId) {
    final today = DateTime.now();
    return _checkIns.any((c) =>
    c.elderlyId == elderlyId &&
        c.type == CheckInType.manual &&
        c.timestamp.year == today.year &&
        c.timestamp.month == today.month &&
        c.timestamp.day == today.day);
  }

  bool hasCheckedInToday(String elderlyId) =>
      getTodayCheckIns(elderlyId).isNotEmpty;

  // ── FIX: Helpers for caregiver home page to use configured interval ──────

  /// Returns the configured check-in alert interval for an elderly user.
  /// Falls back to 10h if not configured.
  int getCheckInWindowHours(String elderlyId) {
    return _activityChecks[elderlyId]?.checkInIntervalHours ?? 10;
  }

  /// Returns whether each check-in type is considered "active" for a given
  /// elderly user, using the CONFIGURED interval (not a hardcoded window).
  /// Manual check-in always uses a 24hr (same-day) window regardless.
  ({bool phoneUnlock, bool steps, bool pickup, bool manual})
  getActivityStatusForElderly(String elderlyId) {
    final ac = _activityChecks[elderlyId];
    final intervalHours = ac?.checkInIntervalHours ?? 10;
    final cutoff = DateTime.now().subtract(Duration(hours: intervalHours));

    final latestUnlock = getLatestPhoneUnlockCheckIn(elderlyId);
    final latestSteps = getLatestStepsCheckIn(elderlyId);
    final latestPickup = getLatestPhonePickupCheckIn(elderlyId);

    return (
    phoneUnlock:
    latestUnlock != null && latestUnlock.timestamp.isAfter(cutoff),
    steps: latestSteps != null && latestSteps.timestamp.isAfter(cutoff),
    pickup: latestPickup != null && latestPickup.timestamp.isAfter(cutoff),
    manual: hasManualCheckedInToday(elderlyId), // always 24hr/same-day
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTIVITY CHECKS  (local + Firestore summary for caregiver settings)
  // ════════════════════════════════════════════════════════════════════════

  ActivityCheckModel getOrCreateActivityCheck(String elderlyId) {
    if (!_activityChecks.containsKey(elderlyId)) {
      _activityChecks[elderlyId] = ActivityCheckModel(elderlyId: elderlyId);
    }
    return _activityChecks[elderlyId]!;
  }

  void _updateActivitySignal(String elderlyId, CheckInType type,
      [DateTime? timestamp]) {
    final ac = getOrCreateActivityCheck(elderlyId);
    final time = timestamp ?? DateTime.now();
    switch (type) {
      case CheckInType.phoneUnlock:
        ac.lastPhoneUnlock = time;
        break;
      case CheckInType.stepsActive:
        ac.lastStepsActive = time;
        break;
      case CheckInType.phonePickup:
        ac.lastPhonePickup = time;
        break;
      default:
        break;
    }
    ac.elderlyNotified = false;
    ac.caregiverNotified = false;
    ac.nextCheckDue = time.add(Duration(hours: ac.checkInIntervalHours));
    _activityChecks[elderlyId] = ac;
  }

  Future<bool> runActivityCheck(String elderlyId) async {
    final ac = getOrCreateActivityCheck(elderlyId);
    if (ac.isInSleepWindow()) return false;
    if (ac.hasActivityInWindow()) return false;
    final nextDue = ac.nextCheckDue;
    if (nextDue != null && DateTime.now().isBefore(nextDue)) return false;
    if (!ac.caregiverNotified) {
      ac.caregiverNotified = true;
      _activityChecks[elderlyId] = ac;
      await _persistLocal();
      await _updateCheckInSummary(elderlyId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> markElderlyNotified(String elderlyId) async {
    final ac = getOrCreateActivityCheck(elderlyId);
    ac.elderlyNotified = true;
    _activityChecks[elderlyId] = ac;
    await _persistLocal();
    await _updateCheckInSummary(elderlyId);
    notifyListeners();
  }

  /// Set sleep window — also writes to Firestore so the elderly device
  /// picks it up on the next syncOwnActivityCheck call.
  Future<void> setSleepWindow({
    required String elderlyId,
    required int? startHour,
    required int? endHour,
  }) async {
    if (_currentUser == null) throw Exception('Not logged in.');
    final ac = getOrCreateActivityCheck(elderlyId);
    ac.sleepStartHour = startHour;
    ac.sleepEndHour = endHour;
    _activityChecks[elderlyId] = ac;
    await _persistLocal();

    await _db.collection(_colSummary).doc(elderlyId).set({
      'sleepStartHour': startHour,
      'sleepEndHour': endHour,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  Future<void> setCheckInInterval(String elderlyId, int hours) async {
    if (_currentUser == null) throw Exception('Not logged in.');
    final ac = getOrCreateActivityCheck(elderlyId);
    ac.checkInIntervalHours = hours;
    final now = DateTime.now();
    if (ac.nextCheckDue == null || ac.nextCheckDue!.isBefore(now)) {
      ac.nextCheckDue = now.add(Duration(hours: hours));
    }
    _activityChecks[elderlyId] = ac;
    await _persistLocal();
    await _updateCheckInSummary(elderlyId);
    notifyListeners();
  }

  Future<void> setAutoCheckInEnabled(String elderlyId, bool enabled) async {
    if (_currentUser == null) throw Exception('Not logged in.');
    final ac = getOrCreateActivityCheck(elderlyId);
    ac.autoCheckInEnabled = enabled;
    _activityChecks[elderlyId] = ac;
    await _persistLocal();
    await _updateCheckInSummary(elderlyId);
    notifyListeners();
  }

  /// Called by caregiver admin to save all auto check-in preferences.
  /// Manual check-in is NOT configurable and always stays at 24hr.
  Future<void> setCheckInTypeSettings({
    required String elderlyId,
    required bool enabled,
    required int intervalHours,
    required bool trackPhoneUnlock,
    required bool trackStepsActive,
    required bool trackPhonePickup,
    // Manual check-in is intentionally NOT a parameter — always 24 hr.
  }) async {
    if (_currentUser == null) throw Exception('Not logged in.');
    final ac = getOrCreateActivityCheck(elderlyId);
    ac.autoCheckInEnabled = enabled;
    ac.checkInIntervalHours = intervalHours;
    ac.trackPhoneUnlock = trackPhoneUnlock;
    ac.trackStepsActive = trackStepsActive;
    ac.trackPhonePickup = trackPhonePickup;
    // Reset alert flags so the new interval starts fresh
    ac.elderlyNotified = false;
    ac.caregiverNotified = false;
    final now = DateTime.now();
    if (ac.nextCheckDue == null || ac.nextCheckDue!.isBefore(now)) {
      ac.nextCheckDue = now.add(Duration(hours: intervalHours));
    }
    _activityChecks[elderlyId] = ac;
    await _persistLocal();

    // Single Firestore write with all fields so elderly device syncs them all
    await _db.collection(_colSummary).doc(elderlyId).set({
      'checkInIntervalHours': intervalHours,
      'autoCheckInEnabled': enabled,
      'trackPhoneUnlock': trackPhoneUnlock,
      'trackStepsActive': trackStepsActive,
      'trackPhonePickup': trackPhonePickup,
      'elderlyNotified': false,
      'caregiverNotified': false,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// Sync caregiver's local activity check state from Firestore summaries.
  Future<void> syncElderlySummaries() async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.caregiver) return;

    final elderlyIds = _groups.map((g) => g.elderlyId).toList();
    if (elderlyIds.isEmpty) return;

    try {
      final snap = await _db
          .collection(_colSummary)
          .where(FieldPath.documentId, whereIn: elderlyIds.take(30).toList())
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final elderlyId = doc.id;
        final ac = getOrCreateActivityCheck(elderlyId);

        if (data['lastActivity'] != null) {
          final ts = data['lastActivity'];
          if (ts is Timestamp) ac.nextCheckDue = ts.toDate();
        }
        ac.elderlyNotified = data['elderlyNotified'] as bool? ?? false;
        ac.caregiverNotified = data['caregiverNotified'] as bool? ?? false;
        ac.checkInIntervalHours = data['checkInIntervalHours'] as int? ?? 10;
        ac.autoCheckInEnabled = data['autoCheckInEnabled'] as bool? ?? true;
        ac.trackPhoneUnlock = data['trackPhoneUnlock'] as bool? ?? true;
        ac.trackStepsActive = data['trackStepsActive'] as bool? ?? true;
        ac.trackPhonePickup = data['trackPhonePickup'] as bool? ?? true;
        ac.sleepStartHour = data['sleepStartHour'] as int?;
        ac.sleepEndHour = data['sleepEndHour'] as int?;

        _activityChecks[elderlyId] = ac;

        // Also update check-in timestamps from summary for the home page cards
        final unlockStr = data['lastPhoneUnlock'] as String?;
        final stepsStr = data['lastSteps'] as String?;
        final pickupStr = data['lastPickup'] as String?;
        final manualStr = data['lastManual'] as String?;
        _mergeTimestampFromSummary(
            elderlyId, CheckInType.phoneUnlock, unlockStr);
        _mergeTimestampFromSummary(
            elderlyId, CheckInType.stepsActive, stepsStr);
        _mergeTimestampFromSummary(
            elderlyId, CheckInType.phonePickup, pickupStr);
        _mergeTimestampFromSummary(elderlyId, CheckInType.manual, manualStr);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Sync summaries failed: $e');
    }
  }

  /// Inserts a synthetic check-in entry from summary data so caregiver home
  /// page cards show correct last-seen timestamps.
  void _mergeTimestampFromSummary(
      String elderlyId, CheckInType type, String? isoStr) {
    if (isoStr == null) return;
    try {
      final ts = DateTime.parse(isoStr);
      final existing = _checkIns
          .where((c) => c.elderlyId == elderlyId && c.type == type)
          .toList();
      if (existing.isEmpty || existing.first.timestamp.isBefore(ts)) {
        final syntheticId = 'summary_${elderlyId}_${type.name}';
        _checkIns.removeWhere((c) => c.id == syntheticId);
        _checkIns.insert(
            0,
            CheckInModel(
              id: syntheticId,
              elderlyId: elderlyId,
              type: type,
              timestamp: ts,
            ));
      }
    } catch (_) {}
  }

  /// Sync elderly device's own settings from Firestore (called on app resume).
  Future<void> syncOwnActivityCheck(String elderlyId) async {
    try {
      final doc = await _db.collection(_colSummary).doc(elderlyId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final ac = getOrCreateActivityCheck(elderlyId);

      bool changed = false;
      final newInterval = data['checkInIntervalHours'] as int? ?? 10;
      final newEnabled = data['autoCheckInEnabled'] as bool? ?? true;
      final newTrackUnlock = data['trackPhoneUnlock'] as bool? ?? true;
      final newTrackSteps = data['trackStepsActive'] as bool? ?? true;
      final newTrackPickup = data['trackPhonePickup'] as bool? ?? true;
      final newSleepStart = data['sleepStartHour'] as int?;
      final newSleepEnd = data['sleepEndHour'] as int?;

      if (ac.checkInIntervalHours != newInterval) {
        ac.checkInIntervalHours = newInterval;
        changed = true;
      }
      if (ac.autoCheckInEnabled != newEnabled) {
        ac.autoCheckInEnabled = newEnabled;
        changed = true;
      }
      if (ac.trackPhoneUnlock != newTrackUnlock) {
        ac.trackPhoneUnlock = newTrackUnlock;
        changed = true;
      }
      if (ac.trackStepsActive != newTrackSteps) {
        ac.trackStepsActive = newTrackSteps;
        changed = true;
      }
      if (ac.trackPhonePickup != newTrackPickup) {
        ac.trackPhonePickup = newTrackPickup;
        changed = true;
      }
      if (ac.sleepStartHour != newSleepStart) {
        ac.sleepStartHour = newSleepStart;
        changed = true;
      }
      if (ac.sleepEndHour != newSleepEnd) {
        ac.sleepEndHour = newSleepEnd;
        changed = true;
      }

      if (changed) {
        _activityChecks[elderlyId] = ac;
        await _persistLocal();
        notifyListeners();
      }
    } catch (_) {}
  }

  ActivityCheckModel? getActivityCheck(String elderlyId) =>
      _activityChecks[elderlyId];

  // ════════════════════════════════════════════════════════════════════════
  // SOS  (Firestore real-time)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _subscribeToSos() async {
    final user = _currentUser;
    if (user == null) return;
    _sosSub?.cancel();

    Query<Map<String, dynamic>> query;
    if (user.role == UserRole.caregiver) {
      final elderlyIds = _groups.map((g) => g.elderlyId).toList();
      if (elderlyIds.isEmpty) return;
      query = _db
          .collection(_colSos)
          .where('elderlyId', whereIn: elderlyIds.take(30).toList());
    } else {
      query = _db.collection(_colSos).where('elderlyId', isEqualTo: user.id);
    }

    _sosSub = query.snapshots().listen((snap) async {
      final userNow = _currentUser;
      final isCaregiver = userNow?.role == UserRole.caregiver;
      final isInitialLoad = _sosList.isEmpty && _knownSosIds.isEmpty;

      _sosList.clear();
      for (final doc in snap.docs) {
        final sos = SosModel.fromJson({'id': doc.id, ...doc.data()});
        _sosList.add(sos);

        // Only fire notification in DataService when the app is in the foreground.
        // The background service (separate isolate) handles it when app is closed.
        final lifecycleState = WidgetsBinding.instance.lifecycleState;
        if (isCaregiver &&
            sos.status == SosStatus.active &&
            !isInitialLoad &&
            !_knownSosIds.contains(sos.id) &&
            lifecycleState == AppLifecycleState.resumed) {
          final elderlyName = _nicknames[sos.elderlyId] ??
              (await _fetchUser(sos.elderlyId))?.name ??
              'Elderly member';

          NotificationService.showSosNotification(
            elderlyName: elderlyName,
            description: sos.description,
          );
        }
        _knownSosIds.add(sos.id);
      }
      _sosList.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
      notifyListeners();
    }, onError: (e) {
      debugPrint('SOS subscription error: $e');
    });
  }

  Future<void> refreshAllUnreadCounts() async {
    final me = _currentUser?.id;
    if (me == null) return;
    _unreadCounts.clear();
    for (final group in _groups) {
      try {
        final doc = await _db
            .collection('messages')
            .doc(group.id)
            .collection('unread')
            .doc(me)
            .get();
        final count = (doc.data()?['count'] as int?) ?? 0;
        final otherId =
        group.allMemberIds.firstWhere((id) => id != me, orElse: () => '');
        if (otherId.isNotEmpty && count > 0) {
          _unreadCounts[otherId] = (_unreadCounts[otherId] ?? 0) + count;
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Real-time unread-count listener for every group the current user belongs to.
  ///
  /// When the unread counter for ME increases AND the most recent message in
  /// that conversation was sent BY SOMEONE ELSE (not me), we fire a local
  /// push notification.  This prevents the sender from notifying themselves.
  Future<void> _subscribeToUnreadCounts() async {
    final me = _currentUser?.id;
    if (me == null) return;

    // Cancel any existing per-group unread listeners first
    for (final sub in _unreadSubs) {
      sub.cancel();
    }
    _unreadSubs.clear();
    _unreadCounts.clear();
    // Clear seeding tokens so a restarted subscription seeds fresh baselines.
    _knownMessageIds.removeWhere((id) => id.startsWith('unread_seeded_'));

    for (final group in _groups) {
      final groupId = group.id;

      // Resolve the "other" user in this conversation from the current user's POV
      final otherId =
      group.allMemberIds.firstWhere((id) => id != me, orElse: () => '');
      if (otherId.isEmpty) continue;

      final sub = _db
          .collection('messages')
          .doc(groupId)
          .collection('unread')
          .doc(me)
          .snapshots()
          .listen((snap) async {
        
        final newCount = snap.exists ? ((snap.data()?['count'] as int?) ?? 0) : 0;

        // First snapshot is the baseline seed — load the count for the badge
        // but do NOT fire a notification (messages already existed before now).
        if (!_knownMessageIds.contains('unread_seeded_$groupId')) {
          _knownMessageIds.add('unread_seeded_$groupId');
          _unreadCounts[otherId] = newCount;
          notifyListeners();
          return;
        }

        final prevCount = _unreadCounts[otherId] ?? 0;
        _unreadCounts[otherId] = newCount;
        notifyListeners();

        // Only notify if the count went UP — meaning a NEW message arrived
        // directed at ME. Skip if count went down (conversation was read).
        if (newCount <= prevCount) return;

        // Only fire from DataService when the app is in the foreground.
        // Background service handles notification when app is closed/backgrounded.
        final isResumed = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        if (!isResumed) return;

        // If actively viewing this exact conversation, just mark read — no popup.
        if (groupId == _activeConvGroupId) {
          markConversationRead(otherUserId: otherId, groupId: groupId);
          return;
        }

        // Fetch the latest message in the conversation to verify the sender
        // is NOT me (guard against the sender's own device triggering a noti).
        try {
          final msgSnap = await _db
              .collection('messages')
              .doc(groupId)
              .collection('msgs')
              .orderBy('sentAt', descending: true)
              .limit(1)
              .get();

          if (msgSnap.docs.isEmpty) return;

          final latestData = {'id': msgSnap.docs.first.id, ...msgSnap.docs.first.data()};
          final latestMsg = MessageModel.fromJson(latestData);

          // CRITICAL: do NOT notify if the current user sent this message
          if (latestMsg.senderId == me) return;

          final sender = _userCache[otherId] ??
              await _fetchUser(otherId);
          final senderName = _nicknames[otherId] ??
              sender?.name ??
              'Someone';

          await NotificationService.showMessageNotification(
            senderName: senderName,
            message: latestMsg.text,
          );
        } catch (e) {
          debugPrint('Message notification error: $e');
        }
      }, onError: (e) {
        debugPrint('Unread count subscription error: $e');
      });

      _unreadSubs.add(sub);
    }
  }

  Future<SosModel> triggerSos(
      {required String elderlyId, required String description}) async {
    final sos = SosModel(
        id: _uuid.v4(), elderlyId: elderlyId, description: description);
    await _db.collection(_colSos).doc(sos.id).set(sos.toJson());
    notifyListeners();
    return sos;
  }

  SosModel? getActiveSos(String elderlyId) {
    try {
      return _sosList.firstWhere(
              (s) => s.elderlyId == elderlyId && s.status == SosStatus.active);
    } catch (_) {
      return null;
    }
  }

  List<SosModel> getSosHistoryForElderly(String elderlyId) {
    return _sosList.where((s) => s.elderlyId == elderlyId).toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
  }

  List<SosModel> getCaregiverSosAlerts() {
    final user = _currentUser;
    if (user == null) return [];
    final elderlyIds = _groups.map((g) => g.elderlyId).toSet();
    return _sosList.where((s) => elderlyIds.contains(s.elderlyId)).toList();
  }

  Future<void> resolveSos(String sosId) async {
    final idx = _sosList.indexWhere((s) => s.id == sosId);
    if (idx == -1) return;
    _sosList[idx].status = SosStatus.resolved;
    _sosList[idx].resolvedAt = DateTime.now();
    await _db.collection(_colSos).doc(sosId).update({
      'status': 'resolved',
      'resolvedAt': _sosList[idx].resolvedAt!.toIso8601String(),
    });
    notifyListeners();
  }

  Future<void> _deleteSosForElderly(String elderlyId) async {
    final snap = await _db
        .collection(_colSos)
        .where('elderlyId', isEqualTo: elderlyId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════════════
  // MESSAGES  (Firestore real-time)
  //
  // FIX v2: sendMessage now inserts the message into _messages immediately
  // (optimistic local update) so the UI doesn't wait for the Firestore
  // round-trip. The snapshot listener checks for existing ids to avoid
  // duplicates.
  //
  // FIX v1: removed .where('participants', arrayContains: me) filter.
  // ════════════════════════════════════════════════════════════════════════

  void subscribeToConversation({
    required String otherUserId,
    required String groupId,
  }) {
    final me = _currentUser?.id;
    if (me == null) return;

    if (_activeConvGroupId != groupId) {
      _messagesSub?.cancel();
      _messages.clear();
      _lastMessageDoc = null;
      _activeConvGroupId = groupId;
    }

    _messagesSub = _db
        .collection('messages')
        .doc(groupId)
        .collection('msgs')
        .orderBy('sentAt', descending: true)
        .limit(_msgPageSize)
        .snapshots()
        .listen((snap) {
      // FIX: Rebuild _messages from snapshot but preserve any optimistic
      // locally-added messages that haven't arrived from Firestore yet.
      final incomingIds = snap.docs.map((d) => d.id).toSet();

      // Remove messages that are now in the snapshot (we'll re-add from source of truth)
      _messages.removeWhere((m) => incomingIds.contains(m.id));

      for (final doc in snap.docs) {
        try {
          // Always pass doc.id explicitly — Firestore data may not include 'id'
          final data = {'id': doc.id, ...doc.data()};
          final m = MessageModel.fromJson(data);
          final involves = (m.senderId == me || m.receiverId == me);
          if (involves && !m.deletedForSender && !m.deletedForEveryone) {
            _messages.add(m);
          }
        } catch (e) {
          debugPrint('Message parse error: $e');
        }
        if (snap.docs.isNotEmpty) _lastMessageDoc = snap.docs.last;
      }
      _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      notifyListeners();
    }, onError: (e) {
      debugPrint('Message subscription error: $e');
    });
  }

  void unsubscribeFromConversation() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _activeConvGroupId = null;
    _messages.clear();
    _lastMessageDoc = null;
    notifyListeners();
  }

  Future<void> loadMoreMessages(String groupId) async {
    final me = _currentUser?.id;
    if (me == null || _lastMessageDoc == null) return;
    final snap = await _db
        .collection('messages')
        .doc(groupId)
        .collection('msgs')
        .orderBy('sentAt', descending: true)
        .startAfterDocument(_lastMessageDoc!)
        .limit(_msgPageSize)
        .get();

    if (snap.docs.isNotEmpty) _lastMessageDoc = snap.docs.last;
    final older = <MessageModel>[];
    for (final doc in snap.docs) {
      try {
        final data = {'id': doc.id, ...doc.data()};
        final m = MessageModel.fromJson(data);
        final involves = (m.senderId == me || m.receiverId == me);
        if (involves && !m.deletedForSender && !m.deletedForEveryone)
          older.add(m);
      } catch (_) {}
    }
    older.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _messages.insertAll(0, older);
    notifyListeners();
  }

  Future<MessageModel> sendMessage({
    required String receiverId,
    required String groupId,
    required String text,
  }) async {
    final sender = _currentUser;
    if (sender == null) throw Exception('Not logged in.');
    final msgId = _uuid.v4();
    // Use DateTime.now() for the local optimistic message
    final message = MessageModel(
      id: msgId,
      senderId: sender.id,
      receiverId: receiverId,
      groupId: groupId,
      text: text,
      sentAt: DateTime.now(),
    );

    // FIX: Optimistic local insert so the UI updates immediately without
    // waiting for the Firestore snapshot round-trip.
    _messages.add(message);
    _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    notifyListeners();

    // Write to Firestore — sentAt uses serverTimestamp for authoritative ordering
    await _db
        .collection('messages')
        .doc(groupId)
        .collection('msgs')
        .doc(msgId)
        .set({
      ...message.toJson(),
      'participants': [sender.id, receiverId],
      'sentAt': FieldValue.serverTimestamp(), // authoritative server time
    });

    // Update unread counter for receiver
    await _db
        .collection('messages')
        .doc(groupId)
        .collection('unread')
        .doc(receiverId)
        .set({'count': FieldValue.increment(1)}, SetOptions(merge: true));

    return message;
  }

  List<MessageModel> getConversation({
    required String otherUserId,
    required String groupId,
  }) {
    final me = _currentUser?.id;
    if (me == null) return [];
    return _messages
        .where((m) =>
    m.groupId == groupId &&
        ((m.senderId == me && m.receiverId == otherUserId) ||
            (m.senderId == otherUserId && m.receiverId == me)))
        .toList();
  }

  Future<int> getUnreadCountAsync(String fromUserId) async {
    final me = _currentUser?.id;
    if (me == null) return 0;
    final sharedGroup = _groups.firstWhere(
          (g) => g.allMemberIds.contains(me) && g.allMemberIds.contains(fromUserId),
      orElse: () => GroupModel(id: '', name: '', elderlyId: ''),
    );
    if (sharedGroup.id.isEmpty) return 0;
    try {
      final doc = await _db
          .collection('messages')
          .doc(sharedGroup.id)
          .collection('unread')
          .doc(me)
          .get();
      return (doc.data()?['count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  int getUnreadCount(String fromUserId) => _unreadCounts[fromUserId] ?? 0;

  int getTotalUnreadCount() {
    return _unreadCounts.values.fold(0, (sum, c) => sum + c);
  }

  List<String> getSendersWithUnread() {
    return _unreadCounts.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
  }

  Future<void> markConversationRead({
    required String otherUserId,
    required String groupId,
  }) async {
    final me = _currentUser?.id;
    if (me == null) return;
    for (final m in _messages) {
      if (m.groupId == groupId &&
          m.senderId == otherUserId &&
          m.receiverId == me &&
          !m.isRead) {
        m.isRead = true;
      }
    }
    _unreadCounts.remove(otherUserId);
    await _db
        .collection('messages')
        .doc(groupId)
        .collection('unread')
        .doc(me)
        .set({'count': 0}, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> deleteMessageForMe(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final groupId = _messages[idx].groupId;
    _messages[idx].deletedForSender = true;
    _messages.removeAt(idx); // remove from local list immediately
    await _db
        .collection('messages')
        .doc(groupId)
        .collection('msgs')
        .doc(messageId)
        .update({'deletedForSender': true});
    notifyListeners();
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    final me = _currentUser?.id;
    if (me == null) return;
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    if (_messages[idx].senderId != me) return;
    final groupId = _messages[idx].groupId;
    _messages.removeAt(idx);
    await _db
        .collection('messages')
        .doc(groupId)
        .collection('msgs')
        .doc(messageId)
        .delete();
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async =>
      deleteMessageForEveryone(messageId);

  Future<void> deleteAllMessages({
    required String otherUserId,
    required String groupId,
  }) async {
    final me = _currentUser?.id;
    if (me == null) return;
    final snap =
    await _db.collection('messages').doc(groupId).collection('msgs').get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(me)) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();

    _messages.removeWhere((m) =>
    m.groupId == groupId &&
        ((m.senderId == me && m.receiverId == otherUserId) ||
            (m.senderId == otherUserId && m.receiverId == me)));
    notifyListeners();
  }

  Future<void> _deleteGroupMessages(String groupId) async {
    final snap =
    await _db.collection('messages').doc(groupId).collection('msgs').get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════════════
  // WELLBEING
  // ════════════════════════════════════════════════════════════════════════

  Future<WellbeingEntry> saveWellbeingEntry({
    required String elderlyId,
    required List<WellbeingAnswer> answers,
  }) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    _wellbeingEntries.removeWhere((e) =>
    e.elderlyId == elderlyId &&
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);

    final entry = WellbeingEntry(
        id: _uuid.v4(), elderlyId: elderlyId, date: today, answers: answers);
    _wellbeingEntries.add(entry);
    await _persistLocal();

    await _db
        .collection(_colWellbeing)
        .doc(elderlyId)
        .collection('entries')
        .doc(dateKey)
        .set(entry.toJson());

    notifyListeners();
    return entry;
  }

  WellbeingEntry? getTodayWellbeing(String elderlyId) {
    final today = DateTime.now();
    try {
      return _wellbeingEntries.firstWhere((e) =>
      e.elderlyId == elderlyId &&
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day);
    } catch (_) {
      return null;
    }
  }

  Future<List<WellbeingEntry>> getWellbeingHistoryRemote(String elderlyId,
      {int days = 7}) async {
    final snap = await _db
        .collection(_colWellbeing)
        .doc(elderlyId)
        .collection('entries')
        .orderBy('date', descending: true)
        .limit(days)
        .get();
    return snap.docs
        .map((doc) => WellbeingEntry.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  List<WellbeingEntry> getWellbeingHistory(String elderlyId, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _wellbeingEntries
        .where((e) => e.elderlyId == elderlyId && e.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════

  void _cancelSubscriptions() {
    _groupsSub?.cancel();
    _sosSub?.cancel();
    _messagesSub?.cancel();
    _checkInsSub?.cancel();
    _elderlyCheckInsSub?.cancel();
    for (final sub in _unreadSubs) {
      sub.cancel();
    }
    _unreadSubs.clear();
    _groupsSub = null;
    _sosSub = null;
    _messagesSub = null;
    _checkInsSub = null;
    _elderlyCheckInsSub = null;
    _activeConvGroupId = null;
    _activeElderlyCheckInsId = null;
    _unreadCounts.clear();
    _knownMessageIds.removeWhere((id) => id.startsWith('unread_seeded_'));
  }

  void _subscribeToMyCheckIns() {
    final user = _currentUser;
    if (user == null || user.role != UserRole.elderly) return;

    _checkInsSub?.cancel();
    _checkInsSub = _db
        .collection('checkins')
        .doc(user.id)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
      _checkIns.clear();
      for (var doc in snap.docs) {
        try {
          _checkIns.add(CheckInModel.fromJson(doc.data()));
        } catch (_) {}
      }
      notifyListeners();
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // DEV / TESTING HELPERS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> clearTrackingDataForCurrentUser() async {
    final user = _currentUser;
    if (user == null) return;
    _checkIns.removeWhere((c) => c.elderlyId == user.id);
    _wellbeingEntries.removeWhere((w) => w.elderlyId == user.id);
    _sosList.removeWhere((s) => s.elderlyId == user.id);
    _activityChecks.remove(user.id);

    await _db.collection(_colSummary).doc(user.id).delete();
    await _deleteSosForElderly(user.id);

    final snap = await _db
        .collection('checkins')
        .doc(user.id)
        .collection('events')
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }

    await _persistLocal();
    notifyListeners();
  }
}