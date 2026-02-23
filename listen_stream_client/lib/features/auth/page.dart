import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/remote/api_service.dart';
import '../../shared/platform/platform_util.dart';
import '../../shared/theme.dart';

/// Premium Phone + SMS OTP login page with modern glassmorphism design
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

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  String get _e164Phone => '+86${_phoneController.text.trim()}';

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      setState(() => _phoneError = '请输入11位手机号');
      return;
    }
    setState(() { _sending = true; _phoneError = null; });
    try {
      await ref.read(apiServiceProvider).sendSmsCode(_e164Phone);
      if (!mounted) return;
      _startCountdown();
    } on Object catch (e) {
      if (!mounted) return;
      final msg = _extractError(e);
      if (msg.contains('RATE_LIMITED')) {
        final retryAfter = _parseRetryAfter(e);
        setState(() => _phoneError = '请 $retryAfter 秒后再试');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('网络错误，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
          .loginWithSms(_e164Phone, _otp);
      // Navigation happens here — widget may already be disposed, so return early.
    } on Object catch (e) {
      if (!mounted) return;
      final msg = _extractError(e);
      if (msg.contains('INVALID_CODE')) {
        setState(() => _otpError = '验证码错误');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录失败，请稍后重试')));
      }
      _clearOtp();
    } finally {
      if (mounted) setState(() => _submitting = false);
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
    final themeMode = ref.watch(themeProvider);
    final isGlass = themeMode == AppThemeMode.glass;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeMode == AppThemeMode.light
                    ? [const Color(0xFFF5F7FA), const Color(0xFFE8EBF0)]
                    : themeMode == AppThemeMode.warm
                        ? [const Color(0xFF1A1410), const Color(0xFF2A1F18)]
                        : [AppTheme.darkBase, AppTheme.darkSecondary],
              ),
            ),
          ),
          
          // Theme switcher button (top-right)
          Positioned(
            top: 40,
            right: 40,
            child: _ThemeSwitcher(),
          ),
          
          // Login card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 440 : double.infinity,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isGlass
                        ? Colors.white.withOpacity(0.08)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: isGlass
                        ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: isGlass ? ImageFilter.blur(sigmaX: 25, sigmaY: 25) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // App Logo & Title
                            Icon(
                              Icons.music_note_rounded,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Listen Stream',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '登录以开始你的音乐之旅',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            
                            // Phone number input
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(fontSize: 16, letterSpacing: 0.5),
                                decoration: InputDecoration(
                                  labelText: '手机号',
                                  prefixIcon: const Icon(Icons.phone_android_rounded),
                                  errorText: _phoneError,
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Get code button
                            ElevatedButton(
                              onPressed: _countdown > 0 || _sending ? null : _sendCode,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _sending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _countdown > 0 ? '重新获取 (${_countdown}s)' : '获取验证码',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 32),
                            
                            // OTP input section
                            Text(
                              '验证码',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _OtpRow(
                              controllers: _otpControllers,
                              focusNodes: _otpFocusNodes,
                              hasError: _otpError != null,
                              onComplete: _submit,
                            ),
                            if (_otpError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _otpError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            
                            // Loading indicator
                            if (_submitting)
                              Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme switcher widget
class _ThemeSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PopupMenuButton<AppThemeMode>(
        icon: Icon(
          Icons.palette_outlined,
          color: Theme.of(context).primaryColor,
        ),
        tooltip: '主题设置',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          _buildThemeItem(context, AppThemeMode.light, '明亮', Icons.wb_sunny_rounded, currentTheme),
          _buildThemeItem(context, AppThemeMode.dark, '深色', Icons.nightlight_round, currentTheme),
          _buildThemeItem(context, AppThemeMode.glass, '玻璃', Icons.blur_on_rounded, currentTheme),
          _buildThemeItem(context, AppThemeMode.warm, '温暖', Icons.local_fire_department_rounded, currentTheme),
        ],
        onSelected: (mode) {
          ref.read(themeProvider.notifier).setTheme(mode);
        },
      ),
    );
  }
  
  PopupMenuItem<AppThemeMode> _buildThemeItem(
    BuildContext context,
    AppThemeMode mode,
    String label,
    IconData icon,
    AppThemeMode current,
  ) {
    final isSelected = mode == current;
    return PopupMenuItem<AppThemeMode>(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : null,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check_rounded,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// Six-cell OTP input widget with modern design
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
    children: List.generate(6, (i) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            decoration: BoxDecoration(
              color: focusNodes[i].hasFocus
                  ? Theme.of(context).primaryColor.withOpacity(0.08)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? Theme.of(context).colorScheme.error
                    : focusNodes[i].hasFocus
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: focusNodes[i].hasFocus ? 2 : 1.5,
              ),
              boxShadow: focusNodes[i].hasFocus
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: controllers[i],
              focusNode: focusNodes[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) {
                  focusNodes[i + 1].requestFocus();
                }
                if (i == 5 && v.isNotEmpty) {
                  onComplete();
                }
              },
              onTap: () {
                if (controllers[i].text.isNotEmpty) {
                  controllers[i].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controllers[i].text.length,
                  );
                }
              },
            ),
          ),
        ),
      );
    }),
  );
  }

}
