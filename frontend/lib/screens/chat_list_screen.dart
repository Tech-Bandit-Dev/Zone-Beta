import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';
import 'chat_screen.dart';

/// Chat tab. Lists every conversation the signed-in user has open — signals
/// they've accepted or posted — so they don't have to dig back through the
/// map to keep talking. Tapping a row opens the existing per-signal
/// [ChatScreen]. Rendered inside MapScreen's nav (via [onBack]), same
/// pattern as ActivityScreen/ProfileScreen.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: conversations.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 40, color: ZoneColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No chats yet',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ZoneColors.textPrimary),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Accept a signal on the map to start a conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ZoneColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) {
                final s = conversations[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: s.type.tint,
                    child: Icon(s.type.icon, color: s.type.color),
                  ),
                  title: Text(
                    s.type.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    s.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: ZoneColors.textMuted),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(signal: s)),
                  ),
                );
              },
            ),
    );
  }
}
