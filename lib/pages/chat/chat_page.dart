// lib/pages/chat/chat_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';
import '../../widgets/sos_button.dart';

class ChatPage extends StatefulWidget {
  final UserModel otherUser;
  final String groupId;

  const ChatPage({
    super.key,
    required this.otherUser,
    required this.groupId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Open the real-time Firestore listener for this conversation
    context.read<DataService>().subscribeToConversation(
      otherUserId: widget.otherUser.id,
      groupId: widget.groupId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataService>().markConversationRead(
        otherUserId: widget.otherUser.id,
        groupId: widget.groupId,
      );
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    context.read<DataService>().unsubscribeFromConversation();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEditNameDialog(BuildContext context, String currentDisplay) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(
        text: currentDisplay == widget.otherUser.name ? '' : currentDisplay);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: '${l10n.newName} (${widget.otherUser.name})',
            hintText: widget.otherUser.name,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<DataService>().setNickname(widget.otherUser.id, null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              await context.read<DataService>().setNickname(
                widget.otherUser.id, name.isEmpty ? null : name,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save, style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteAllMessages,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        content: Text(l10n.deleteAllConfirm, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sosRed, minimumSize: const Size(0, 44)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<DataService>().deleteAllMessages(
                otherUserId: widget.otherUser.id,
                groupId: widget.groupId,
              );
            },
            child: Text(l10n.deleteAll,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show delete options on tap.
  /// Own message: "Delete for everyone" (removes from DB entirely) OR "Delete for me" (hides from my view)
  /// Other's message: "Delete for me" only (hides from my view, they still see it)
  void _showDeleteOptions(BuildContext context, DataService ds, MessageModel msg, bool isMe) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '"${msg.text.length > 40 ? msg.text.substring(0, 40) + "..." : msg.text}"',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            // Delete for me — available for ALL messages (own + received)
            ListTile(
              leading: const Icon(Icons.visibility_off_rounded, color: AppTheme.textSecondary),
              title: Text(l10n.deleteForMe,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: const Text('Only hidden from your view',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              onTap: () async {
                Navigator.pop(ctx);
                await ds.deleteMessageForMe(msg.id);
              },
            ),
            // Delete for everyone — only own messages
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.sosRed),
                title: Text(l10n.deleteForEveryone,
                    style: const TextStyle(
                        fontSize: 17, color: AppTheme.sosRed, fontWeight: FontWeight.w600)),
                subtitle: const Text('Removed for everyone permanently',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ds.deleteMessageForEveryone(msg.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
              title: Text(l10n.cancel, style: const TextStyle(fontSize: 17)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      final ds = context.read<DataService>();
      await ds.sendMessage(
        receiverId: widget.otherUser.id,
        groupId: widget.groupId,
        text: text,
      );
      // Note: local message notifications should only appear on the receiver's
      // device. Sending one here would notify the sender of their own message.
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final me = ds.currentUser!;
    final displayName = ds.getNickname(widget.otherUser.id) ?? widget.otherUser.name;
    final messages = ds.getConversation(
      otherUserId: widget.otherUser.id,
      groupId: widget.groupId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Icon(
                widget.otherUser.role == UserRole.elderly
                    ? Icons.elderly_rounded
                    : Icons.volunteer_activism_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _showEditNameDialog(context, displayName),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
                      ],
                    ),
                    Text(
                      widget.otherUser.role == UserRole.elderly ? l10n.elderly : l10n.caregiver,
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
              tooltip: l10n.deleteAllMessages,
              onPressed: () => _confirmDeleteAll(context),
            ),
          const LanguageButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: messages.isEmpty
                    ? _EmptyState(name: displayName)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          final isMe = msg.senderId == me.id;
                          final showDate = i == 0 ||
                              !_sameDay(messages[i - 1].sentAt, msg.sentAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.sentAt),
                              _MessageBubble(
                                message: msg,
                                isMe: isMe,
                                onTap: () => _showDeleteOptions(context, ds, msg, isMe),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [SosButton()
              ],
            ),
            const SizedBox(height: 10,),

            _InputBar(
              textCtrl: _textCtrl,
              focusNode: _focusNode,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyState extends StatelessWidget {
  final String name;
  const _EmptyState({required this.name});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    // For Chinese: the grammar does not work with appending a name.
    // Use a standalone greeting instead.
    final bool appendName = locale != 'zh';
    final parts = l10n.noMessages.split('\n');
    final line1 = parts.isNotEmpty ? parts[0] : '';
    final line2 = parts.length > 1 ? parts[1] : '';
    final line2Display = appendName ? '$line2 $name!' : '$line2';

    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxHeight < 120) {
        return Center(
          child: Text(line2Display,
              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: AppTheme.textSecondary.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(line1,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(line2Display,
                style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
          ],
        ),
      );
    });
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.textCtrl,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: textCtrl,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 17),
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.typeMessage,
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 48, height: 48,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final timeStr = locale == 'zh'
        ? DateFormat('HH:mm').format(message.sentAt)
        : DateFormat('h:mm a').format(message.sentAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(
            top: 4, bottom: 4,
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                    fontSize: 17,
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white.withOpacity(0.75) : AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday =
        date.year == now.year && date.month == now.month && date.day == now.day - 1;

    String label;
    if (isToday) {
      label = l10n.today;
    } else if (isYesterday) {
      label = l10n.yesterday;
    } else if (locale == 'zh') {
      label = '${date.year}年${date.month}月${date.day}日';
    } else {
      label = DateFormat('d MMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
