import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class IncomingCallOverlay extends StatefulWidget {
  final String callerName;
  final String roomId;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    super.key,
    required this.callerName,
    required this.roomId,
    required this.onDismiss,
  });

  static OverlayEntry? _currentOverlayEntry;

  static void show(BuildContext context, String callerName, String roomId) {
    dismiss();
    _currentOverlayEntry = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: IncomingCallOverlay(
          callerName: callerName,
          roomId: roomId,
          onDismiss: () => dismiss(),
        ),
      ),
    );
    Overlay.of(context).insert(_currentOverlayEntry!);
  }

  static void dismiss() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDeclined = false;
  Timer? _autoDismissTimer;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startRingtone();
    _startAutoDismiss();
    _startCountdown();
  }

  void _startRingtone() async {
    try {
      // Haptic feedback saat ringtone mulai
      HapticFeedback.heavyImpact();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        UrlSource(
            'https://assets.mixkit.co/active_storage/sfx/911/911-84.wav'),
      );
    } catch (e) {
      debugPrint("Gagal memutar ringtone: $e");
    }
  }

  void _stopRingtone() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint("Gagal menghentikan ringtone: $e");
    }
  }

  void _startAutoDismiss() {
    // Auto-dismiss setelah 30 detik jika tidak direspons
    _autoDismissTimer = Timer(const Duration(seconds: 30), () {
      if (!_isDeclined && mounted) {
        _declineCall();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, 30);
      });
      if (_remainingSeconds <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    _stopRingtone();
    super.dispose();
  }

  void _declineCall() {
    if (_isDeclined) return;
    setState(() => _isDeclined = true);
    HapticFeedback.mediumImpact();
    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    _stopRingtone();
    widget.onDismiss();
  }

  void _acceptCall() async {
    HapticFeedback.heavyImpact();
    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    _stopRingtone();
    widget.onDismiss();

    // Buka room audio/video Jitsi Meet menggunakan browser eksternal
    final url = Uri.parse(
        'https://meet.jit.si/${widget.roomId}#config.startWithAudioMuted=false&config.startWithVideoMuted=true');
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Jitsi room launched successfully");
    } else {
      debugPrint("Failed to launch Jitsi room");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: Colors.black.withValues(alpha: 0.80),
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ripple Pulse Animation
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        Container(
                          width: 130 + (_pulseController.value * 50),
                          height: 130 + (_pulseController.value * 50),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D9488).withValues(
                                alpha: (1.0 - _pulseController.value) * 0.3),
                          ),
                        ),
                        // Inner pulse ring
                        Container(
                          width: 120 + (_pulseController.value * 20),
                          height: 120 + (_pulseController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D9488).withValues(
                                alpha: (1.0 - _pulseController.value) * 0.25),
                          ),
                        ),
                        // Center circle
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF0D9488),
                                Color(0xFF0A7B71),
                              ],
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.phoneCall,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Panggilan Masuk label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'PANGGILAN MASUK',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4DD0C8),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Caller Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.callerName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Panggilan Suara Nyutji",
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),

                // Countdown Timer
                Text(
                  'Berakhir dalam $_remainingSeconds detik',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _remainingSeconds <= 10
                        ? Colors.orange[300]
                        : Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 60),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Button
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _declineCall,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(22),
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 12,
                            shadowColor:
                                const Color(0xFFDC2626).withValues(alpha: 0.5),
                          ),
                          child: const Icon(LucideIcons.phoneOff, size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Tolak",
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Accept Button
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _acceptCall,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(22),
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            elevation: 12,
                            shadowColor: const Color(0xFF0D9488)
                                .withValues(alpha: 0.5),
                          ),
                          child: const Icon(LucideIcons.phone, size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Terima",
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
