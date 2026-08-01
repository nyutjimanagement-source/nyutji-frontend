import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:hive/hive.dart';

class NyutjiCoachMark {
  /// Menampilkan tutorial sekali saja berdasarkan [tutorialKey].
  /// Menyimpan status "telah dilihat" di Hive box 'nyutji_cache'.
  static void showTutorial({
    required BuildContext context,
    required String tutorialKey,
    required List<TargetFocus> targets,
    Color shadowColor = const Color(0xFF1E5655), // Default primaryTeal
  }) {
    final box = Hive.box('nyutji_cache');
    final hasSeen = box.get('tutorial_$tutorialKey', defaultValue: false);
    
    if (hasSeen) return;

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: shadowColor,
      textSkip: "LEWATI",
      paddingFocus: 8,
      opacityShadow: 0.82,
      alignSkip: Alignment.topRight,
      onFinish: () {
        box.put('tutorial_$tutorialKey', true);
      },
      onSkip: () {
        box.put('tutorial_$tutorialKey', true);
        return true;
      },
    );

    tutorial.show(context: context);
  }

  /// Template kartu tutorial estetik standar Nyutji.
  static Widget buildTutorialCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onNext,
    required VoidCallback onSkip,
    bool isLast = false,
    Color primaryColor = const Color(0xFF1E5655), // Default primaryTeal
    Color textColor = const Color(0xFF111827), // darkText
  }) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  step,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              height: 1.5,
              color: const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  "LEWATI",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast ? "SELESAI" : "LANJUT",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isLast ? LucideIcons.check : LucideIcons.chevronRight,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
