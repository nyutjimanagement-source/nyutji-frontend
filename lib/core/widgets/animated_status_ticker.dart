import 'dart:async';
import 'package:flutter/material.dart';

/// Widget ticker status yang menampilkan satu teks dalam satu waktu.
/// Fase 1: teks lama fade out. Fase 2: teks baru naik dari bawah & fade in.
/// Jeda 5 detik antar status.
class AnimatedStatusTicker extends StatefulWidget {
  final List<String> statuses;
  final TextStyle style;

  const AnimatedStatusTicker({
    super.key,
    required this.statuses,
    required this.style,
  });

  @override
  State<AnimatedStatusTicker> createState() => _AnimatedStatusTickerState();
}

class _AnimatedStatusTickerState extends State<AnimatedStatusTicker>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _nextIndex = 0;
  Timer? _pauseTimer;
  late AnimationController _controller;
  late Animation<double> _fadeOut;
  late Animation<double> _fadeIn;
  late Animation<double> _slideIn;
  bool _showingNew = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fase 1 (0.0 → 0.45): teks lama fade out
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Fase 2 (0.5 → 1.0): teks baru naik dari bawah & fade in
    _slideIn = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addListener(() {
      if (!_showingNew && _controller.value >= 0.5) {
        setState(() => _showingNew = true);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
          _showingNew = false;
        });
        _controller.reset();
        _schedulePause();
      }
    });

    _schedulePause();
  }

  void _schedulePause() {
    _pauseTimer?.cancel();
    if (widget.statuses.length <= 1) return;
    _pauseTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _nextIndex = (_currentIndex + 1) % widget.statuses.length;
      _showingNew = false;
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedStatusTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statuses.length != oldWidget.statuses.length) {
      _currentIndex = 0;
      _nextIndex = 0;
      _showingNew = false;
      _controller.reset();
      _schedulePause();
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statuses.isEmpty) return const SizedBox.shrink();

    if (widget.statuses.length == 1) {
      return Text(
        widget.statuses[0],
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_showingNew) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Text(
              widget.statuses[_currentIndex % widget.statuses.length],
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return Transform.translate(
          offset: Offset(0, _slideIn.value),
          child: Opacity(
            opacity: _fadeIn.value,
            child: Text(
              widget.statuses[_nextIndex % widget.statuses.length],
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
