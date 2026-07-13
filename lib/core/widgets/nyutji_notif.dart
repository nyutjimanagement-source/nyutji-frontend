import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/scheduler.dart';

class NyutjiNotif {
  static OverlayEntry? _currentEntry;

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, LucideIcons.checkCircle, const Color(0xFF286B6A));
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, LucideIcons.alertCircle, const Color(0xFFC3312E));
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, LucideIcons.info, const Color(0xFF286B6A));
  }

  static void _show(BuildContext context, String message, IconData icon, Color color) {
    if (!context.mounted) return;

    void showAction() {
      if (!context.mounted) return;
      try {
        // Hapus notifikasi yang sedang aktif sebelumnya agar tidak bertumpuk
        if (_currentEntry != null) {
          try {
            if (_currentEntry!.mounted) {
              _currentEntry!.remove();
            }
          } catch (_) {}
          _currentEntry = null;
        }

        OverlayState? overlay;
        if (context is StatefulElement && context.state is OverlayState) {
          overlay = context.state as OverlayState;
        } else if (context is StatefulElement && context.state is NavigatorState) {
          overlay = (context.state as NavigatorState).overlay;
        } else {
          overlay = Overlay.maybeOf(context) ?? Navigator.maybeOf(context)?.overlay;
        }

        if (overlay == null) {
          debugPrint("NyutjiNotif Error: Tidak dapat menemukan OverlayState dari context yang diberikan.");
          return;
        }

        final overlayEntry = OverlayEntry(
          builder: (context) => _BeautyPopupWidget(
            message: message,
            icon: icon,
            color: color,
          ),
        );

        _currentEntry = overlayEntry;
        overlay.insert(overlayEntry);

        Future.delayed(const Duration(seconds: 3), () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
            if (_currentEntry == overlayEntry) {
              _currentEntry = null;
            }
          }
        });
      } catch (e) {
        debugPrint("Error showing NyutjiNotif: $e");
      }
    }

    // Jika sedang dalam fase build/layout, tunda sampai frame selesai.
    // Jika tidak (misal interaksi tap dari user), langsung tampilkan instan tanpa delay.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => showAction());
    } else {
      showAction();
    }
  }
}

class _BeautyPopupWidget extends ConsumerStatefulWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _BeautyPopupWidget({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override ConsumerState<_BeautyPopupWidget> createState() => _BeautyPopupWidgetState();
}

class _BeautyPopupWidgetState extends ConsumerState<_BeautyPopupWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(widget.icon, size: 18, color: widget.color),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
