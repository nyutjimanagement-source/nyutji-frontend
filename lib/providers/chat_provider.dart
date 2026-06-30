import 'package:flutter/foundation.dart';
import 'dart:async';
import '../data/services/api_service.dart';
import '../data/services/cache_service.dart';
import '../data/models/chat_message_model.dart';

class ChatProvider extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Throttle: simpan timestamp fetch terakhir per key
  final Map<String, DateTime> _lastFetchTime = {};

  final ApiService _api = ApiService();

  // ── Public Methods ─────────────────────────────────────────────────────────

  /// Cache key unik per kombinasi orderNumber + channel
  String _cacheKey(String orderNumber, String channel) =>
      'chat_${orderNumber}_$channel';

  /// Ambil pesan — cache-first + throttle 15s (sesuai arsitektur offline-first)
  Future<void> fetchMessages(
    String orderNumber,
    String channel, {
    bool force = false,
  }) async {
    final key = _cacheKey(orderNumber, channel);

    // 1. Tampilkan dari cache secara instan
    final cached = CacheService.get(key);
    if (cached != null && cached is List && _messages.isEmpty) {
      try {
        _messages = cached
            .map((item) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _safeNotify();
      } catch (e) {
        debugPrint('[ChatProvider] Error parsing cache: $e');
      }
    }

    // 2. Throttle check
    final now = DateTime.now();
    final lastFetch = _lastFetchTime[key];
    if (!force &&
        lastFetch != null &&
        now.difference(lastFetch).inSeconds < 15) {
      debugPrint('[ChatProvider] Throttled — kurang dari 15 detik ($key)');
      return;
    }

    // 3. Fetch dari API secara async
    _isLoading = _messages.isEmpty;
    _errorMessage = null;
    _safeNotify();

    try {
      final rawList = await _api.getChatMessages(orderNumber, channel);
      _lastFetchTime[key] = DateTime.now();

      final parsed = rawList
          .map((item) =>
              ChatMessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      _messages = parsed;
      _errorMessage = null;

      // 4. Simpan ke cache
      await CacheService.set(key, rawList);
    } catch (e) {
      debugPrint('[ChatProvider] Gagal fetch pesan dari API: $e');
      // Jika ada data cache, tetap tampilkan tanpa error dialog
      if (_messages.isEmpty) {
        _errorMessage = 'Gagal memuat pesan. Periksa koneksi internet.';
      }
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Kirim pesan baru — langsung POST ke API, optimistic update UI
  Future<bool> sendMessage(
    String orderNumber,
    String channel,
    String message,
    String senderId,
    String senderName,
    String senderRole,
  ) async {
    if (message.trim().isEmpty) return false;

    _isSending = true;
    _safeNotify();

    // Optimistic update: tambahkan pesan sementara ke list lokal
    final tempMsg = ChatMessageModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      orderNumber: orderNumber,
      channel: channel,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      message: message.trim(),
      createdAt: DateTime.now(),
    );
    _messages.add(tempMsg);
    _safeNotify();

    try {
      final result =
          await _api.sendChatMessage(orderNumber, channel, message.trim());

      if (result['status'] == 'success' && result['data'] != null) {
        // Ganti optimistic message dengan data real dari server
        _messages.removeWhere((m) => m.id == tempMsg.id);
        final realMsg = ChatMessageModel.fromJson(
            Map<String, dynamic>.from(result['data'] as Map));
        _messages.add(realMsg);

        // Update cache
        final key = _cacheKey(orderNumber, channel);
        final rawList = _messages.map((m) => m.toJson()).toList();
        await CacheService.set(key, rawList);

        // Reset throttle agar fetch berikutnya selalu dapat data fresh
        _lastFetchTime.remove(key);
      }

      _isSending = false;
      _safeNotify();
      return true;
    } catch (e) {
      debugPrint('[ChatProvider] Gagal kirim pesan: $e');
      // Rollback optimistic update
      _messages.removeWhere((m) => m.id == tempMsg.id);
      _isSending = false;
      _safeNotify();
      return false;
    }
  }

  /// Reset state saat berpindah order/channel
  void reset() {
    _messages = [];
    _isLoading = false;
    _isSending = false;
    _errorMessage = null;
    _safeNotify();
  }
}
