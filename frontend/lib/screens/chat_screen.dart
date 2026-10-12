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
    final zc = context.zc;
    final type = widget.signal.type;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: type.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(type.icon, size: 20, color: type.color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Aarav',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: zc.textPrimary)),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 15, color: zc.primary),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: ZoneColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('${type.label} · nearby',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: zc.textMuted)),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: zc.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                // Group consecutive messages from the same side.
                final nextSame = i + 1 < _messages.length &&
                    _messages[i + 1].mine == m.mine;
                return _Bubble(
                  key: ObjectKey(m),
                  msg: m,
                  tail: !nextSame,
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: zc.surface,
              border: Border(top: BorderSide(color: zc.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Message',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                BorderSide(color: zc.primary, width: 1.4),
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedScale(
                      scale: _input.text.trim().isEmpty ? 0.85 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: AnimatedOpacity(
                        opacity: _input.text.trim().isEmpty ? 0.5 : 1,
                        duration: const Duration(milliseconds: 160),
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: zc.primary,
                            foregroundColor: Colors.white,
                            fixedSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded),
                          onPressed: _send,
                        ),
                      ),
                    ),
                  ],
                ),
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
  const _Bubble({super.key, required this.msg, required this.tail});
  final _Msg msg;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    const r = Radius.circular(20);
    const small = Radius.circular(6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(msg.mine ? (1 - v) * 24 : -(1 - v) * 24, 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(top: 2, bottom: tail ? 10 : 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: msg.mine ? zc.primary : zc.surfaceAlt,
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: msg.mine || !tail ? r : small,
              bottomRight: msg.mine && tail ? small : r,
            ),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: msg.mine ? Colors.white : zc.textPrimary,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
