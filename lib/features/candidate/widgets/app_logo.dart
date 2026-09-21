import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const AppLogo({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size, size), painter: AshWheelPainter(wheelColor: finalColor)),
        SizedBox(width: AppSpacing.sm),
        Text("Hylo", style: GoogleFonts.lobster(color: finalColor, fontSize: size)),
      ],
    );
  }
}
