import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NyutjiNotif {
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
    final overlay = Overlay.of(context);
    
    // Gunakan GlobalKey untuk mengakses state widget agar bisa memicu animasi keluar
    final GlobalKey<_BeautyPopupWidgetState> popupKey = GlobalKey();

    final overlayEntry = OverlayEntry(
      builder: (context) => _BeautyPopupWidget(
        key: popupKey,
        message: message,
        icon: icon,
        color: color,
      ),
    );

    overlay.insert(overlayEntry);

    // Tunggu 3 detik, lalu panggil animasi keluar sebelum remove
    Future.delayed(const Duration(seconds: 3), () async {
      if (popupKey.currentState != null && popupKey.currentState!.mounted) {
        await popupKey.currentState!.dismiss();
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      }
    });
  }
}

class _BeautyPopupWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _BeautyPopupWidget({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  State<_BeautyPopupWidget> createState() => _BeautyPopupWidgetState();
}

class _BeautyPopupWidgetState extends State<_BeautyPopupWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
        
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _controller.forward();
  }

  // Fungsi publik untuk dipanggil oleh NyutjiNotif saat akan ditutup
  Future<void> dismiss() async {
    if (mounted) {
      await _controller.reverse();
    }
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
          padding: const EdgeInsets.only(top: 24),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color.withValues(alpha: 0.95),
                            widget.color.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.icon, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
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
      ),
    );
  }
}
