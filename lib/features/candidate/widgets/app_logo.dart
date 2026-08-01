import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

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
        CustomPaint(
          size: Size(size, size),
          painter: AshWheelPainter(wheelColor: finalColor),
        ),
        SizedBox(width: AppSpacing.xs),
        Text("Hylo", style: AppTypography.headlineLarge.copyWith(color: finalColor, fontSize: size)),
      ],
    );
  }
}
