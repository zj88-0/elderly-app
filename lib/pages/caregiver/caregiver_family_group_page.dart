// lib/pages/caregiver/caregiver_family_group_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/data_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_button.dart';
import '../chat/chat_page.dart';

class CaregiverFamilyGroupPage extends StatefulWidget {
  const CaregiverFamilyGroupPage({super.key});

  @override
  State<CaregiverFamilyGroupPage> createState() =>
      _CaregiverFamilyGroupPageState();
}

class _CaregiverFamilyGroupPageState
    extends State<CaregiverFamilyGroupPage> {
  final _codeCtrl = TextEditingController();
  bool _joiningWithCode = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // Deprecated: Search replaced by invitation codes
  // Future<void> _searchElderly(String query) async { ... }
  // Future<void> _sendRequest(UserModel elderly) async { ... }

  // ── Join with invite code ──────────────────────────────────────────────
  Future<void> _joinWithCode() async {
    final l10n = AppLocalizations.of(context);
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _joiningWithCode = true);
    try {
      await context.read<DataService>().joinGroupByInviteCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.joinedWithCode,
              style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.success,
        ));
        _codeCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e', style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.sosRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _joiningWithCode = false);
    }
  }

  Future<void> _acceptInvite(invite) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<DataService>().acceptInvite(invite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.joinedGroup,
              style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e', style: const TextStyle(fontSize: 17)),
            backgroundColor: AppTheme.sosRed));
      }
    }
  }

  Future<void> _declineInvite(invite) async {
    final l10n = AppLocalizations.of(context);
    await context.read<DataService>().declineInvite(invite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.inviteDeclined,
            style: const TextStyle(fontSize: 17)),
      ));
    }
  }

  void _showEditNicknameDialog(
      BuildContext context, DataService ds, UserModel member) {
    final l10n = AppLocalizations.of(context);
    final current = ds.getNickname(member.id);
    final ctrl = TextEditingController(text: current ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editName,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: '${l10n.newName} (${member.name})',
            hintText: member.name,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ds.setNickname(member.id, null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
            Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              await ds.setNickname(
                  member.id, name.isEmpty ? null : name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save, style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }

  void _showRenameGroupDialog(BuildContext context, DataService ds,
      String groupId, String currentName) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.renameGroup,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: l10n.newGroupName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                await ds.updateGroupName(
                    groupId: groupId, name: name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.groupRenamed,
                        style: const TextStyle(fontSize: 17)),
                    backgroundColor: AppTheme.success,
                  ));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$e',
                        style: const TextStyle(fontSize: 17)),
                    backgroundColor: AppTheme.sosRed,
                  ));
                }
              }
            },
            child:
            Text(l10n.rename, style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(BuildContext context, DataService ds,
      String groupId, UserModel member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.kickMember,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800)),
        content: Text(
            '${l10n.kickMemberConfirm}\n\n${ds.getNickname(member.id) ?? member.name} (${member.email})',
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
            Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sosRed,
                minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.kick,
                style: const TextStyle(
                    fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ds.removeCaregiverFromGroup(
          groupId: groupId, caregiverId: member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.memberRemoved,
              style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e', style: const TextStyle(fontSize: 17)),
            backgroundColor: AppTheme.sosRed));
      }
    }
  }

  Future<void> _quitGroup(
      BuildContext context, String groupId, String groupName) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.leaveGroup,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800)),
        content: Text(
            '${l10n.leaveGroupConfirm}\n\n"$groupName"',
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
            Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sosRed,
                minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.leave,
                style: const TextStyle(
                    fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<DataService>().quitGroup(groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.youHaveLeftGroup,
              style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e', style: const TextStyle(fontSize: 17)),
            backgroundColor: AppTheme.sosRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final myGroups = ds.getCaregiverGroups();
    final pendingInvites = ds.getPendingInvitesForCurrentUser();
    final currentUserId = ds.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageGroups),
        actions: const [LanguageButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Pending invites ──────────────────────────────────────────
          if (pendingInvites.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.mail_rounded,
                title: l10n.groupInvitations,
                color: AppTheme.warning),
            ...pendingInvites.map((inv) {
              final sender = ds.getUserById(inv.fromUserId);
              final group = ds.getGroupById(inv.groupId);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.warningLight,
                            radius: 24,
                            child: Icon(Icons.elderly_rounded,
                                color: AppTheme.warning, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(sender?.name ?? 'Unknown',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                if (sender?.email != null)
                                  Text(sender!.email,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary)),
                                Text(
                                    '${l10n.myGroups}: ${group?.name ?? ""}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.textSecondary)),
                                Text(
                                    inv.fromElderly
                                        ? l10n.invitedToJoin
                                        : l10n.requestPending,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: inv.fromElderly
                                            ? AppTheme.warning
                                            : AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (inv.fromElderly) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _acceptInvite(inv),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    minimumSize: const Size(0, 50)),
                                icon: const Icon(Icons.check_rounded),
                                label: Text(l10n.accept,
                                    style: const TextStyle(fontSize: 17)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _declineInvite(inv),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.sosRed,
                                    side: const BorderSide(
                                        color: AppTheme.sosRed),
                                    minimumSize: const Size(0, 50)),
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.decline,
                                    style: const TextStyle(fontSize: 17)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // ── My groups ────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.group_rounded,
            title: '${l10n.myGroups} (${myGroups.length})',
            color: AppTheme.primary,
          ),
          if (myGroups.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.group_off_rounded,
                        size: 50, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(l10n.noGroupsJoined,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, height: 1.5)),
                  ],
                ),
              ),
            )
          else
            ...myGroups.map((group) {
              final elderly = ds.getUserById(group.elderlyId);
              final isAdmin = ds.isAdminOfGroup(group.id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.group_rounded,
                                color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group.name,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary),
                                    softWrap: true),
                                Text(
                                    '${l10n.elderly}: ${elderly?.name ?? "Unknown"}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.textSecondary),
                                    softWrap: true),
                                if (isAdmin) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .admin_panel_settings_rounded,
                                                size: 13,
                                                color: AppTheme.accent),
                                            const SizedBox(width: 3),
                                            Text(l10n.adminLabel,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.accent,
                                                    fontWeight:
                                                    FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            _showRenameGroupDialog(
                                                context,
                                                ds,
                                                group.id,
                                                group.name),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .drive_file_rename_outline_rounded,
                                                color: AppTheme.primary,
                                                size: 16),
                                            const SizedBox(width: 3),
                                            Text(l10n.renameGroup,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.primary,
                                                    fontWeight:
                                                    FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                          '${l10n.members} (${group.allMemberIds.length}):',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      ...group.allMemberIds.map((uid) {
                        final member = ds.getUserById(uid);
                        if (member == null) return const SizedBox.shrink();
                        final isMe = uid == currentUserId;
                        final isElderlyMember =
                            member.role == UserRole.elderly;
                        final isAdminMember =
                            group.adminCaregiverId == uid;
                        final displayName =
                            ds.getNickname(member.id) ?? member.name;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isElderlyMember
                                    ? AppTheme.accent.withOpacity(0.2)
                                    : AppTheme.primaryLight
                                    .withOpacity(0.2),
                                child: Icon(
                                  isElderlyMember
                                      ? Icons.elderly_rounded
                                      : Icons.volunteer_activism_rounded,
                                  size: 18,
                                  color: isElderlyMember
                                      ? AppTheme.accent
                                      : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isMe
                                                ? '$displayName (${l10n.you})'
                                                : displayName,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                FontWeight.w600),
                                          ),
                                        ),
                                        if (!isMe)
                                          GestureDetector(
                                            onTap: () =>
                                                _showEditNicknameDialog(
                                                    context, ds, member),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                  left: 4),
                                              child: Icon(
                                                  Icons.edit_rounded,
                                                  size: 14,
                                                  color: AppTheme
                                                      .textSecondary),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      isElderlyMember
                                          ? l10n.elderly
                                          : l10n.caregiver,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isElderlyMember
                                              ? AppTheme.accent
                                              : AppTheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMe)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    if (isAdminMember)
                                      Container(
                                        margin:
                                        const EdgeInsets.only(bottom: 2),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(6),
                                        ),
                                        child: Text(l10n.adminLabel,
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color: AppTheme.accent,
                                                fontWeight:
                                                FontWeight.w700)),
                                      ),
                                    if (isAdmin && !isElderlyMember)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.person_remove_rounded,
                                            color: AppTheme.sosRed,
                                            size: 20),
                                        tooltip: l10n.kickMember,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                        onPressed: () => _kickMember(
                                            context, ds, group.id, member),
                                      ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ChatPage(
                                                  otherUser: member,
                                                  groupId: group.id))),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryLight
                                              .withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.message_rounded,
                                            color: AppTheme.primary,
                                            size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }),

                      if (isAdmin && group.pendingInvites.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),
                        Text(
                            '${l10n.pendingRequests} (${group.pendingInvites.length})',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.warning)),
                        const SizedBox(height: 6),
                        ...group.pendingInvites.map((inv) {
                          final requester = ds.getUserById(inv.fromUserId);
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(requester?.name ?? 'Unknown',
                                        style: const TextStyle(
                                            fontSize: 14)),
                                    if (requester?.email != null)
                                      Text(requester!.email,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                              AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.success,
                                    size: 26),
                                onPressed: () =>
                                    ds.adminAcceptInvite(inv),
                                tooltip: l10n.accept,
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_rounded,
                                    color: AppTheme.sosRed, size: 26),
                                onPressed: () =>
                                    ds.adminDeclineInvite(inv),
                                tooltip: l10n.decline,
                              ),
                            ],
                          );
                        }),
                      ],

                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _quitGroup(context, group.id, group.name),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.sosRed,
                          side: const BorderSide(
                              color: AppTheme.sosRed, width: 2),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.exit_to_app_rounded,
                            size: 22),
                        label: Text(l10n.leaveGroup,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // ── Join with invite code ────────────────────────────────────
          _SectionHeader(
              icon: Icons.qr_code_rounded,
              title: l10n.joinWithCode,
              color: const Color(0xFF6A1B9A)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.joinWithCodeDesc,
                      style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeCtrl,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: l10n.inviteCode,
                      hintText: l10n.inviteCodeHint,
                      prefixIcon: const Icon(Icons.vpn_key_rounded,
                          color: Color(0xFF6A1B9A), size: 26),
                      counterText: '',
                    ),
                    onChanged: (v) =>
                    _codeCtrl.value = _codeCtrl.value.copyWith(
                      text: v.toUpperCase(),
                      selection: TextSelection.collapsed(
                          offset: v.length),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _joiningWithCode
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    onPressed: _joinWithCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 22),
                    label: Text(l10n.joinWithCode,
                        style: const TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),


          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }
}