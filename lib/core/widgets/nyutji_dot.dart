import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NyutjiDotType { static, blinking, badge, text }

class NyutjiDot extends StatefulWidget {
  final NyutjiDotType type;
  final Color color;
  final double size;
  final int? count;
  final String? text;
  final Color textColor;
  final Color? borderColor;

  /// 1. Constructor untuk Dot Statis Pasif (contoh: indikator belum isi Bank/Alamat/PIN)
  const NyutjiDot.static({
    super.key,
    this.color = const Color(0xFFC3312E), // Merah Nyutji
    this.size = 8.0,
  }) : type = NyutjiDotType.static,
       count = null,
       text = null,
       textColor = Colors.white,
       borderColor = null;

  /// 2. Constructor untuk Dot Berkedip (contoh: status sistem atau peta online)
  const NyutjiDot.blinking({
    super.key,
    this.color = Colors.greenAccent, // Hijau status sistem
    this.size = 8.0,
  }) : type = NyutjiDotType.blinking,
       count = null,
       text = null,
       textColor = Colors.white,
       borderColor = null;

  /// 3. Constructor untuk Lencana Angka (contoh: Lonceng Notifikasi / Ikon Keranjang)
  const NyutjiDot.badge({
    super.key,
    required this.count,
    this.color = const Color(0xFFC3312E),
    this.textColor = Colors.white,
    this.borderColor,
  }) : type = NyutjiDotType.badge,
       size = 18.0,
       text = null;

  /// 4. Constructor untuk Lencana Teks (contoh: label "PROMO")
  const NyutjiDot.text({
    super.key,
    required this.text,
    this.color = const Color(0xFFC3312E),
    this.textColor = Colors.white,
  }) : type = NyutjiDotType.text,
       size = 18.0,
       count = null,
       borderColor = null;

  @override
  State<NyutjiDot> createState() => _NyutjiDotState();
}

class _NyutjiDotState extends State<NyutjiDot> with SingleTickerProviderStateMixin {
  AnimationController? _blinkController;
  Animation<double>? _blinkAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.type == NyutjiDotType.blinking) {
      _blinkController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController!);
    }
  }

  @override
  void dispose() {
    _blinkController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == NyutjiDotType.blinking && _blinkAnimation != null) {
      return FadeTransition(
        opacity: _blinkAnimation!,
        child: _buildDotContainer(),
      );
    }

    if (widget.type == NyutjiDotType.badge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(10),
          border: widget.borderColor != null 
              ? Border.all(color: widget.borderColor!, width: 1.5) 
              : null,
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          '${widget.count}',
          style: GoogleFonts.montserrat(
            color: widget.textColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.type == NyutjiDotType.text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          widget.text ?? '',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: widget.textColor,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return _buildDotContainer();
  }

  Widget _buildDotContainer() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: widget.type == NyutjiDotType.blinking ? 1 : 0,
          )
        ],
      ),
    );
  }
}
