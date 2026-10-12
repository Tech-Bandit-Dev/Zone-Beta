import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'auth_screen.dart' show describeAuthError, ErrorBanner;

/// 6-box OTP entry. On success the auth state flips and the app root swaps to
/// the map automatically. In mock mode [devCode] is shown as a hint.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email, this.devCode});
  final String email;
  final String? devCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild on focus changes so the focused box can highlight.
    for (final n in _nodes) {
      n.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _error = 'Enter all 6 digits');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(email: widget.email, code: _code);
      // Root listens to authProvider and swaps to the map; pop this stack.
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _error = describeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < 5) {
      _nodes[i + 1].requestFocus();
    }
    setState(() {});
  }

  /// TextField's onChanged only fires when the value actually changes, so
  /// pressing Backspace on a box that's already empty fires nothing — the
  /// focus just gets stuck. Catching the raw key event lets us handle that
  /// case explicitly: clear the previous box and move focus back to it.
  KeyEventResult _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _controllers[i - 1].clear();
      _nodes[i - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Select any existing digit when a box is focused, so typing overwrites
  /// it instead of trying (and failing, at maxLength 1) to insert alongside it.
  void _selectAll(int i) {
    _controllers[i].selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controllers[i].text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: zc.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.mark_email_read_outlined,
                    color: zc.primary, size: 28),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Check your inbox',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: zc.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: 'Enter the 6-digit code sent to ',
                children: [
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(
                        color: zc.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              style: TextStyle(color: zc.textMuted, fontSize: 15, height: 1.4),
            ),
            if (widget.devCode != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ZoneColors.sell.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Dev code · ${widget.devCode}',
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: List.generate(6, (i) {
                final filled = _controllers[i].text.isNotEmpty;
                final focused = _nodes[i].hasFocus;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 60,
                      decoration: BoxDecoration(
                        color: filled
                            ? zc.primary.withValues(alpha: 0.08)
                            : zc.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: focused
                              ? zc.primary
                              : (filled
                                  ? zc.primary.withValues(alpha: 0.4)
                                  : Colors.transparent),
                          width: focused ? 1.8 : 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Focus(
                        onKeyEvent: (node, event) => _onKey(i, event),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _nodes[i],
                          autofocus: i == 0,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: zc.textPrimary,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _selectAll(i),
                          onChanged: (v) => _onChanged(i, v),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ErrorBanner(message: _error!),
                    ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
