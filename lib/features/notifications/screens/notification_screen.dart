import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

import '../../../providers/notification_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';

// ── Riverpod Provider ─────────────────────────────────────────────────────────
final notificationProvider =
    ChangeNotifierProvider<NotificationProvider>((ref) {
  final p = NotificationProvider();
  p.loadNotifications();
  return p;
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  static const Color _primaryTeal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(notificationProvider);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context, ref, provider),
      body: provider.notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding:
                  EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              itemCount: provider.notifications.length,
              itemBuilder: (ctx, index) {
                final notif = provider.notifications[index];
                return _NotifCard(
                  notif: notif,
                  onTap: () async {
                    await ref.read(notificationProvider).markRead(notif.id);
                  },
                  onDismiss: () async {
                    await ref
                        .read(notificationProvider)
                        .deleteNotification(notif.id);
                    if (context.mounted) {
                      NyutjiNotif.showInfo(context, 'Notifikasi dihapus');
                    }
                  },
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    NotificationProvider provider,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20),
        color: const Color(0xFF111111),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Notifikasi',
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111111),
        ),
      ),
      actions: [
        if (provider.notifications.isNotEmpty)
          TextButton(
            onPressed: () async {
              await ref.read(notificationProvider).markAllRead();
              if (context.mounted) {
                NyutjiNotif.showSuccess(
                    context, 'Semua notif ditandai sudah dibaca');
              }
            },
            child: Text(
              'Baca semua',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryTeal,
              ),
            ),
          ),
        if (provider.notifications.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18),
            color: Colors.red[400],
            tooltip: 'Hapus semua notifikasi',
            onPressed: () async {
              await ref.read(notificationProvider).clearAll();
              if (context.mounted) {
                NyutjiNotif.showInfo(context, 'Semua notifikasi dihapus');
              }
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _primaryTeal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bellOff,
              size: 38,
              color: _primaryTeal,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ada Notifikasi',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua notifikasi pesanan, chat, dan\npanggilan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final LocalNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifCard({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });


  IconData _iconForType(String type) {
    switch (type) {
      case 'chat':
        return LucideIcons.messageCircle;
      case 'call':
        return LucideIcons.phoneCall;
      case 'order_status':
        return LucideIcons.packageCheck;
      default:
        return LucideIcons.bell;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'chat':
        return const Color(0xFF0D9488);
      case 'call':
        return const Color(0xFF7C3AED);
      case 'order_status':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF0D9488);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM y', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(notif.type);
    final isUnread = !notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(LucideIcons.trash2, color: Colors.red[400], size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? typeColor.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? typeColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(notif.type),
                  size: 22,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notif.createdAt),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
