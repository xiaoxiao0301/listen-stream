import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_notifier.dart';
import '../auth/token_store.dart';

final wsClientProvider = Provider<WsClient>((ref) => WsClient(ref));

/// WebSocket client with auto-reconnect and offline-event pull (C.5).
class WsClient {
  WsClient(this._ref) {
    // Listen to app lifecycle for background/foreground transitions.
    WidgetsBinding.instance.addObserver(_LifecycleObserver(
      onResume: _onAppResume,
      onPause:  _onAppPause,
    ));
  }

  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _backgroundTimer;

  int _retryCount = 0;
  DateTime? _lastSyncTime;
  bool _userDisconnected = false;

  static const _maxRetryDelay = Duration(seconds: 30);

  /// Connect (called after successful login).
  Future<void> connect() async {
    _userDisconnected = false;
    await _doConnect();
  }

  /// Disconnect (called on logout or explicit teardown).
  void disconnect() {
    _userDisconnected = true;
    _cancel();
  }

  Future<void> _doConnect() async {
    _cancel();
    final tokenStore = _ref.read(tokenStoreProvider);
    final at = await tokenStore.getAccessToken();
    if (at == null) return;

    final host = const String.fromEnvironment('WS_HOST', defaultValue: 'localhost:8003');
    final uri = Uri.parse('ws://$host/ws?token=$at');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _retryCount = 0;
      _lastSyncTime ??= DateTime.now();

      _sub = _channel!.stream.listen(
        _handleMessage,
        onDone:  _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    _lastSyncTime = DateTime.now();
    final Map<String, dynamic> msg;
    try { msg = jsonDecode(raw) as Map<String, dynamic>; }
    catch (_) { return; }

    final event = msg['event'] as String? ?? '';
    final payload = msg['data'] as Map<String, dynamic>? ?? {};

    switch (event) {
      // These invalidate sync state — simple approach: reload via /user/sync.
      case 'favorite.added':
      case 'favorite.removed':
      case 'playlist.created':
      case 'playlist.updated':
      case 'playlist.deleted':
      case 'progress.updated':
        // Feature providers can subscribe to a stream; here we store and
        // let them refresh. Full binding done in each feature's provider.
        _eventController.add(WsEvent(event: event, payload: payload));

      case 'device.kicked':
        _ref.read(authNotifierProvider.notifier).logout(
              message: '您已在另一台设备上登录',
            );

      case 'config.jwt_rotated':
        _ref.read(authNotifierProvider.notifier).logout(
              message: '凭证已更新，请重新登录',
            );
    }
  }

  // ── Public event stream (feature providers subscribe here) ─────────────────
  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get events => _eventController.stream;

  // ── Reconnect logic ─────────────────────────────────────────────────────────
  void _scheduleReconnect() {
    if (_userDisconnected) return;
    final delay = _calcDelay();
    _retryCount++;
    _reconnectTimer = Timer(delay, () async {
      await _doConnect();
      await _fetchMissedEvents();
    });
  }

  Duration _calcDelay() {
    final seconds = 1 << _retryCount; // 1, 2, 4, 8, 16, 32 → capped at 30
    return Duration(seconds: seconds.clamp(1, 30));
  }

  Future<void> _fetchMissedEvents() async {
    if (_lastSyncTime == null) return;
    try {
      // Fire-and-forget sync; feature providers react to WS events.
      _eventController.add(WsEvent(event: '_sync', payload: {
        'since': _lastSyncTime!.toIso8601String(),
      }));
    } catch (_) {}
  }

  // ── App lifecycle ───────────────────────────────────────────────────────────
  void _onAppPause() {
    // Disconnect after 30 s in background to save battery.
    _backgroundTimer = Timer(const Duration(seconds: 30), () {
      if (!_userDisconnected) _cancel();
    });
  }

  void _onAppResume() {
    _backgroundTimer?.cancel();
    if (!_userDisconnected && _channel == null) {
      _retryCount = 0; // Immediate reconnect on foreground.
      _doConnect().then((_) => _fetchMissedEvents());
    }
  }

  void _cancel() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

/// Typed WebSocket event.
class WsEvent {
  const WsEvent({required this.event, required this.payload});
  final String event;
  final Map<String, dynamic> payload;
}

/// Minimal app-lifecycle observer for WsClient.
class _LifecycleObserver extends WidgetsBindingObserver {
  const _LifecycleObserver({required this.onResume, required this.onPause});
  final VoidCallback onResume;
  final VoidCallback onPause;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
    if (state == AppLifecycleState.paused)  onPause();
  }
}
