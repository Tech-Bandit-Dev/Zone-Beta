import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

/// Chat tab. Lists every conversation the signed-in user has open — signals
/// they've accepted or posted — so they don't have to dig back through the
/// map to keep talking. Tapping a row opens the existing per-signal
/// [ChatScreen]. Rendered inside MapScreen's nav, same pattern as
/// ActivityScreen/ProfileScreen.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final zc = context.zc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        automaticallyImplyLeading: false,
      ),
      body: conversations.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No chats yet',
              message: 'Accept a signal on the map to start a conversation.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = conversations[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + i * 60),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, (1 - v) * 12),
                      child: child,
                    ),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: s.type.tint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(s.type.icon, color: s.type.color),
                      ),
                      title: Text(
                        s.type.label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: zc.textPrimary),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          s.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: zc.textMuted),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: zc.textMuted),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(signal: s)),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
