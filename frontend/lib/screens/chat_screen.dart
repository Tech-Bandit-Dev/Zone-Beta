import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';

/// Mock coordination chat opened after accepting a signal. Messages live in
/// local state only. Wire to the realtime gateway / a messages service later.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.signal});
  final Signal signal;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  late final List<_Msg> _messages = [
    _Msg(text: widget.signal.message, mine: false),
    _Msg(text: 'Hey! I can join. Where exactly are you?', mine: true),
    _Msg(text: 'Gate 2, near the taxi stand. Grey jacket.', mine: false),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: t, mine: true));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.signal.type.color.withOpacity(0.15),
              child: Icon(widget.signal.type.icon,
                  size: 18, color: widget.signal.type.color),
            ),
            const SizedBox(width: 10),
            const Text('Aarav'),
            const SizedBox(width: 6),
            const Icon(Icons.verified, size: 16, color: ZoneColors.primary),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ZoneColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool mine;
  _Msg({required this.text, required this.mine});
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.mine ? ZoneColors.primary : ZoneColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: msg.mine
              ? null
              : Border.all(color: ZoneColors.border),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.mine ? Colors.white : ZoneColors.textPrimary,
            fontSize: 15,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
