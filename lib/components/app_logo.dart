import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
            size: Size(size, size), 
            painter: AshWheelPainter(wheelColor: Colors.black)), // Adjust color as needed
        const SizedBox(height: 8),
        Text("Hylo", style: GoogleFonts.lobster(fontSize: size / 1.5)),
      ],
    );
  }
}