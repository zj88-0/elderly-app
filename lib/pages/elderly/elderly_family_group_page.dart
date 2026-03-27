// lib/pages/elderly/elderly_family_group_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/language_button.dart';
import '../chat/chat_page.dart';

class ElderlyFamilyGroupPage extends StatefulWidget {
  const ElderlyFamilyGroupPage({super.key});

  @override
  State<ElderlyFamilyGroupPage> createState() =>
      _ElderlyFamilyGroupPageState();
}

class _ElderlyFamilyGroupPageState extends State<ElderlyFamilyGroupPage> {
  final _groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalizations.of(context);
    if (_groupNameCtrl.text.trim().isEmpty) return;
    try {
      await context.read<DataService>().createGroup(_groupNameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.groupCreated, style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e', style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.sosRed,
        ));
      }
    }
  }

  // Deprecated: Search replaced by invitation codes
  // Future<void> _searchCaregivers(String query) async { ... }
  // Future<void> _sendInvite(UserModel caregiver) async { ... }

  Future<void> _acceptInvite(invite) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<DataService>().acceptInvite(invite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.inviteAccepted, style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e', style: const TextStyle(fontSize: 17))));
      }
    }
  }

  Future<void> _declineInvite(invite) async {
    final l10n = AppLocalizations.of(context);
    await context.read<DataService>().declineInvite(invite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.inviteDeclined, style: const TextStyle(fontSize: 17)),
      ));
    }
  }

  Future<void> _setAdmin(String groupId, String? caregiverId) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<DataService>().setGroupAdmin(groupId: groupId, caregiverId: caregiverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(caregiverId == null ? l10n.adminRemoved : l10n.adminSet,
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

  void _showSetAdminDialog(BuildContext context, DataService ds, String groupId,
      List<UserModel> caregivers, String? currentAdminId) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.setAdmin, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.divider,
                child: Icon(Icons.person_off_rounded, color: AppTheme.textSecondary),
              ),
              title: Text(l10n.noAdmin, style: const TextStyle(fontSize: 17)),
              trailing: currentAdminId == null
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                await _setAdmin(groupId, null);
              },
            ),
            const Divider(),
            ...caregivers.map((cg) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.primary),
              ),
              title: Text(ds.getNickname(cg.id) ?? cg.name, style: const TextStyle(fontSize: 17)),
              subtitle: Text(cg.email,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              trailing: cg.id == currentAdminId
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.accent)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                await _setAdmin(groupId, cg.id);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, DataService ds, UserModel member) {
    final l10n = AppLocalizations.of(context);
    final current = ds.getNickname(member.id);
    final ctrl = TextEditingController(text: current ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              await ds.setNickname(member.id, name.isEmpty ? null : name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save, style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }

  void _showRenameGroupDialog(BuildContext context, DataService ds, String groupId, String currentName) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.renameGroup, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                await ds.updateGroupName(groupId: groupId, name: name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.groupRenamed, style: const TextStyle(fontSize: 17)),
                    backgroundColor: AppTheme.success,
                  ));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$e', style: const TextStyle(fontSize: 17)),
                    backgroundColor: AppTheme.sosRed,
                  ));
                }
              }
            },
            child: Text(l10n.rename, style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(BuildContext context, DataService ds, String groupId, UserModel member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.kickMember, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        content: Text('${l10n.kickMemberConfirm}\n\n${ds.getNickname(member.id) ?? member.name} (${member.email})',
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.kick, style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ds.removeCaregiverFromGroup(groupId: groupId, caregiverId: member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.memberRemoved, style: const TextStyle(fontSize: 17)),
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

  Future<void> _quitGroup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.disbandGroup, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        content: Text(l10n.disbandGroupConfirm, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.disband, style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<DataService>().elderlyQuitGroup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.groupDisbanded, style: const TextStyle(fontSize: 17)),
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
    final group = ds.getElderlyGroup();
    final pendingInvites = ds.getPendingInvitesForCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myFamilyGroupPage),
        actions: const [LanguageButton()],
      ),
      floatingActionButton: const SosButton(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Pending requests ──────────────────────────────────────────
          if (pendingInvites.isNotEmpty) ...[
            _SectionHeader(icon: Icons.mail_rounded, title: l10n.pendingRequests, color: AppTheme.warning),
            ...pendingInvites.map((inv) {
              final sender = ds.getUserById(inv.fromUserId);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.warningLight,
                        radius: 24,
                        child: Icon(Icons.person_rounded, color: AppTheme.warning, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sender?.name ?? 'Unknown',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            if (sender?.email != null)
                              Text(sender!.email,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            Text(inv.fromElderly ? l10n.youInvited : l10n.caregiverWantsToJoin,
                                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      if (!inv.fromElderly) ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 32),
                          onPressed: () => _acceptInvite(inv),
                          tooltip: l10n.accept,
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: AppTheme.sosRed, size: 32),
                          onPressed: () => _declineInvite(inv),
                          tooltip: l10n.decline,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // ── Create group ──────────────────────────────────────────────
          if (group == null) ...[
            _SectionHeader(icon: Icons.group_add_rounded, title: l10n.createYourGroup, color: AppTheme.primary),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.createGroupDesc, style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _groupNameCtrl,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: l10n.groupName,
                        prefixIcon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 26),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createGroup,
                      icon: const Icon(Icons.add_rounded, size: 26),
                      label: Text(l10n.createGroup),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Manage group ──────────────────────────────────────────────
          if (group != null) ...[
            // Group name row with rename and set admin — wrapped to prevent overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SectionHeader(icon: Icons.group_rounded, title: group.name, color: AppTheme.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.drive_file_rename_outline_rounded, color: AppTheme.primary, size: 22),
                      tooltip: l10n.renameGroup,
                      onPressed: () => _showRenameGroupDialog(context, ds, group.id, group.name),
                    ),
                  ],
                ),
                if (group.caregiverIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton.icon(
                      onPressed: () {
                        final caregivers = group.caregiverIds
                            .map((id) => ds.getUserById(id))
                            .whereType<UserModel>()
                            .toList();
                        _showSetAdminDialog(context, ds, group.id, caregivers, group.adminCaregiverId);
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppTheme.accent),
                      label: Text(l10n.setAdmin,
                          style: const TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Invite Code ─────────────────────────────────────
                    if (group.inviteCode != null)
                      Card(
                        color: const Color(0xFF6A1B9A).withOpacity(0.06),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.vpn_key_rounded,
                                      color: Color(0xFF6A1B9A), size: 22),
                                  const SizedBox(width: 8),
                                  Text(l10n.yourInviteCode,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6A1B9A))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(l10n.shareCode,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                      height: 1.4)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6A1B9A)
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF6A1B9A)
                                                .withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        group.inviteCode!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 8,
                                          color: Color(0xFF6A1B9A),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        color: Color(0xFF6A1B9A), size: 26),
                                    tooltip: l10n.copyCode,
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(
                                          text: group.inviteCode!));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(l10n.codeCopied,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          backgroundColor: const Color(0xFF6A1B9A),
                                        ));
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: () async {
                                  try {
                                    final newCode = await ds
                                        .regenerateInviteCode(group.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(l10n.codeRegenerated,
                                            style: const TextStyle(
                                                fontSize: 16)),
                                        backgroundColor: AppTheme.success,
                                      ));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('$e',
                                            style: const TextStyle(
                                                fontSize: 16)),
                                        backgroundColor: AppTheme.sosRed,
                                      ));
                                    }
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded,
                                    color: AppTheme.textSecondary, size: 18),
                                label: Text(l10n.regenerateCode,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                      ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            _SectionHeader(icon: Icons.people_rounded, title: l10n.allMembers, color: AppTheme.textSecondary),
            ...group.allMemberIds.map((uid) {
              final member = ds.getUserById(uid);
              if (member == null) return const SizedBox.shrink();
              final isMe = member.id == ds.currentUser?.id;
              final isElderly = member.role == UserRole.elderly;
              final isAdmin = group.adminCaregiverId == member.id;
              final unread = isMe ? 0 : ds.getUnreadCount(member.id);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isMe
                      ? null
                      : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ChatPage(otherUser: member, groupId: group.id))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isElderly
                              ? AppTheme.accent.withOpacity(0.2)
                              : AppTheme.primaryLight.withOpacity(0.2),
                          child: Icon(
                            isElderly ? Icons.elderly_rounded : Icons.volunteer_activism_rounded,
                            color: isElderly ? AppTheme.accent : AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                        isMe ? member.name : (ds.getNickname(member.id) ?? member.name),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(l10n.you,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                  if (!isMe && !isElderly)
                                    GestureDetector(
                                      onTap: () => _showEditNicknameDialog(context, ds, member),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.edit_rounded, size: 16, color: AppTheme.textSecondary),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                isElderly ? l10n.elderly : l10n.caregiver,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isElderly ? AppTheme.accent : AppTheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (member.phoneNumber != null && member.phoneNumber!.isNotEmpty)
                                Text(member.phoneNumber!,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        // Right-side: Admin badge (top) + kick button + message button
                        // All stacked vertically to prevent overflow with long Tamil text
                        if (!isMe)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Admin badge at top of button column
                              if (isAdmin)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(l10n.adminLabel,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.accent,
                                          fontWeight: FontWeight.w700)),
                                ),
                              // Remove member button (non-elderly only)
                              if (!isElderly)
                                IconButton(
                                  icon: const Icon(Icons.person_remove_rounded,
                                      color: AppTheme.sosRed, size: 22),
                                  tooltip: l10n.kickMember,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  onPressed: () => _kickMember(context, ds, group.id, member),
                                ),
                              // Message button with unread badge
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        ChatPage(otherUser: member, groupId: group.id))),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.message_rounded,
                                          color: AppTheme.primary, size: 24),
                                    ),
                                    if (unread > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                              color: AppTheme.sosRed, shape: BoxShape.circle),
                                          child: Text('$unread',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _quitGroup(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sosRed,
                side: const BorderSide(color: AppTheme.sosRed, width: 2),
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 24),
              label: Text(l10n.disbandLeaveGroup, style: const TextStyle(fontSize: 17)),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}