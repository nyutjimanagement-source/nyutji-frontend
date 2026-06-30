import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Model notifikasi in-app yang disimpan lokal di Hive
class LocalNotification {
  final String id;
  final String type; // 'chat', 'order_status', 'call', 'info'
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime createdAt;
  bool isRead;

  LocalNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory LocalNotification.fromMap(Map map) {
    return LocalNotification(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'info',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      data: map['data'] != null
          ? Map<String, String>.from(
              (map['data'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
          : {},
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class NotificationProvider extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  static const _boxName = 'nyutji_notifications';
  static const _maxNotifications = 50; // Batas max notif yang disimpan

  List<LocalNotification> _notifications = [];
  List<LocalNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Public Methods ─────────────────────────────────────────────────────────

  /// Muat semua notifikasi dari Hive
  Future<void> loadNotifications() async {
    try {
      final box = Hive.box(_boxName);
      final rawList = box.get('all_notifications', defaultValue: []);
      if (rawList is List) {
        _notifications = rawList
            .map((item) => LocalNotification.fromMap(item as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Terbaru dulu
        _safeNotify();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error load notif: $e');
    }
  }

  /// Tambahkan notifikasi baru
  Future<void> addNotification({
    required String type,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      final notif = LocalNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: title,
        body: body,
        data: data,
        createdAt: DateTime.now(),
        isRead: false,
      );

      _notifications.insert(0, notif);

      // Batasi max 50 notif
      if (_notifications.length > _maxNotifications) {
        _notifications = _notifications.take(_maxNotifications).toList();
      }

      await _saveToHive();
      _safeNotify();
    } catch (e) {
      debugPrint('[NotificationProvider] Error add notif: $e');
    }
  }

  /// Tandai satu notif sebagai sudah dibaca
  Future<void> markRead(String notifId) async {
    try {
      final idx = _notifications.indexWhere((n) => n.id == notifId);
      if (idx != -1) {
        _notifications[idx].isRead = true;
        await _saveToHive();
        _safeNotify();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error mark read: $e');
    }
  }

  /// Tandai semua notif sudah dibaca
  Future<void> markAllRead() async {
    try {
      for (final n in _notifications) {
        n.isRead = true;
      }
      await _saveToHive();
      _safeNotify();
    } catch (e) {
      debugPrint('[NotificationProvider] Error mark all read: $e');
    }
  }

  /// Hapus satu notif
  Future<void> deleteNotification(String notifId) async {
    try {
      _notifications.removeWhere((n) => n.id == notifId);
      await _saveToHive();
      _safeNotify();
    } catch (e) {
      debugPrint('[NotificationProvider] Error delete notif: $e');
    }
  }

  /// Hapus semua notif
  Future<void> clearAll() async {
    try {
      _notifications.clear();
      await _saveToHive();
      _safeNotify();
    } catch (e) {
      debugPrint('[NotificationProvider] Error clear all notif: $e');
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _saveToHive() async {
    try {
      final box = Hive.box(_boxName);
      await box.put(
        'all_notifications',
        _notifications.map((n) => n.toMap()).toList(),
      );
    } catch (e) {
      debugPrint('[NotificationProvider] Error save to Hive: $e');
    }
  }
}
