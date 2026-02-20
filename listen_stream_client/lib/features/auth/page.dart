import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../data/remote/api_service.dart';
import '../../shared/platform/platform_util.dart';

/// Phone + SMS OTP login page (C.4).
class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});
  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final _phoneController = TextEditingController();
  final _otpControllers   = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes    = List.generate(6, (_) => FocusNode());

  bool _sending     = false;
  bool _submitting  = false;
  int  _countdown   = 0;
  Timer? _timer;
  String? _phoneError;
  String? _otpError;
  String? _toast;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      setState(() => _phoneError = '请输入11位手机号');
      return;
    }
    setState(() { _sending = true; _phoneError = null; });
    try {
      await ref.read(apiServiceProvider).sendSmsCode(phone);
      _startCountdown();
    } on Object catch (e) {
      final msg = _extractError(e);
      if (msg.contains('RATE_LIMITED')) {
        final retryAfter = _parseRetryAfter(e);
        setState(() => _phoneError = '请 $retryAfter 秒后再试');
      } else {
        setState(() => _toast = '网络错误，请稍后重试');
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) { t.cancel(); setState(() => _countdown = 0); }
      else { setState(() => _countdown--); }
    });
  }

  Future<void> _submit() async {
    if (_otp.length != 6 || _submitting) return;
    setState(() { _submitting = true; _otpError = null; });
    try {
      await ref.read(authNotifierProvider.notifier)
          .loginWithSms(_phoneController.text.trim(), _otp);
    } on Object catch (e) {
      final msg = _extractError(e);
      if (msg.contains('INVALID_CODE')) {
        setState(() => _otpError = '验证码错误');
      } else {
        setState(() => _toast = '登录失败，请稍后重试');
      }
      _clearOtp();
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    _otpFocusNodes[0].requestFocus();
  }

  String _extractError(Object e) => e.toString();
  int _parseRetryAfter(Object e) {
    final s = e.toString();
    final m = RegExp(r'"retryAfter":(\d+)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 60;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformUtil.isDesktop;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: isDesktop
            ? const BoxConstraints(maxWidth: 400)
            : const BoxConstraints.expand(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            Text('Listen Stream', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 48),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '手机号',
                errorText: _phoneError,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _countdown > 0 || _sending ? null : _sendCode,
              child: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_countdown > 0 ? '重新获取(${_countdown}s)' : '获取验证码'),
            ),
            const SizedBox(height: 28),
            _OtpRow(
              controllers: _otpControllers,
              focusNodes: _otpFocusNodes,
              hasError: _otpError != null,
              onComplete: _submit,
            ),
            if (_otpError != null) ...[
              const SizedBox(height: 6),
              Text(_otpError!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            if (_submitting) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );

    return Scaffold(
      body: isDesktop ? Center(child: body) : body,
    );
  }
}

/// Six-cell OTP input widget.
class _OtpRow extends StatelessWidget {
  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.onComplete,
  });
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 48,
            height: 56,
            child: TextField(
              controller: controllers[i],
              focusNode: focusNodes[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: hasError ? Theme.of(context).colorScheme.error : Colors.grey,
                  ),
                ),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) focusNodes[i + 1].requestFocus();
                if (i == 5 && v.isNotEmpty) onComplete();
              },
            ),
          ),
        );
      }),
    );
  }
}
