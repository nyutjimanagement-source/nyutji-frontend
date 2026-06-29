import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class IncomingCallOverlay extends StatefulWidget {
  final String callerName;
  final String roomId;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    Key? key,
    required this.callerName,
    required this.roomId,
    required this.onDismiss,
  }) : super(key: key);

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

class _IncomingCallOverlayState extends State<IncomingCallOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDeclined = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startRingtone();
  }

  void _startRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/911/911-84.wav'));
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

  @override
  void dispose() {
    _pulseController.dispose();
    _stopRingtone();
    super.dispose();
  }

  void _declineCall() {
    if (_isDeclined) return;
    setState(() => _isDeclined = true);
    _stopRingtone();
    widget.onDismiss();
  }

  void _acceptCall() async {
    _stopRingtone();
    widget.onDismiss();
    
    // Buka room audio/video Jitsi Meet menggunakan browser eksternal
    final url = Uri.parse('https://meet.jit.si/${widget.roomId}#config.startWithAudioMuted=false&config.startWithVideoMuted=true');
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Jitsi room launched successfully");
    } else {
      debugPrint("Failed to launch Jitsi room");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.75),
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
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
                      Container(
                        width: 120 + (_pulseController.value * 40),
                        height: 120 + (_pulseController.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D9488).withOpacity((1.0 - _pulseController.value) * 0.4),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0D9488),
                        ),
                        child: const Icon(
                          LucideIcons.phoneCall,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              // Caller Name
              Text(
                widget.callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Panggilan Suara In-App Nyutji",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 64),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _declineCall,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 8,
                        ),
                        child: const Icon(LucideIcons.phoneOff, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Tolak",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  // Accept
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _acceptCall,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          elevation: 8,
                        ),
                        child: const Icon(LucideIcons.phone, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Terima",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
