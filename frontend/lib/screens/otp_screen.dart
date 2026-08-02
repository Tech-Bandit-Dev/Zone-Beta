import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'auth_screen.dart' show describeAuthError;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Verify')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ZoneColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent to ${widget.email}',
                style:
                    const TextStyle(color: ZoneColors.textMuted, fontSize: 15),
              ),
              if (widget.devCode != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Dev mode code: ${widget.devCode}',
                  style: const TextStyle(
                      color: ZoneColors.accent, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    child: Focus(
                      onKeyEvent: (node, event) => _onKey(i, event),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        autofocus: i == 0,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(counterText: ''),
                        onTap: () => _selectAll(i),
                        onChanged: (v) => _onChanged(i, v),
                      ),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
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
      ),
    );
  }
}
