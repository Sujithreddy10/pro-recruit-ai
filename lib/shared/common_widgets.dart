import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pro_recruit_ai/shared/app_design_system.dart';

// --- SHARED APP DATA ---
class AppData {
  static String name = "";
  static String detectedRole = "Senior Flutter Developer";
  static List<String> missingSkills = [
    "Unit Testing (Mocktail/BlocTest)",
    "CI/CD Pipelines (GitHub Actions)",
    "SOLID Architecture"
  ];
  static Map<String, String> rtrData = {
    "Total Experience": "7.5 Years",
    "Relevant Experience": "5.2 Years",
    "Current CTC": "16 LPA",
    "Expected CTC": "22 LPA",
    "Current Location": "Hyderabad",
    "Preferred Location": "Bangalore / Remote",
    "PF & Form 16": "Verified ✓",
    "AI Pipeline": "2 Active Rounds",
  };
}

// --- SHARED LOGO PAINTER ---
class AshWheelPainter extends CustomPainter {
  final Color wheelColor;
  AshWheelPainter({this.wheelColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = wheelColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);
    for (int i = 0; i < 8; i++) {
      double angle = (i * 2 * math.pi) / 8;
      canvas.drawLine(
          center,
          Offset(center.dx + radius * math.cos(angle),
              center.dy + radius * math.sin(angle)),
          paint);
    }
    canvas.drawCircle(center, size.width * 0.12,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(center, size.width * 0.12, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- SHARED ANIMATED BACKGROUND ---
class AnimatedBackgroundWrapper extends StatefulWidget {
  final Widget child;
  const AnimatedBackgroundWrapper({super.key, required this.child});
  @override
  State<AnimatedBackgroundWrapper> createState() =>
      _AnimatedBackgroundWrapperState();
}

class _AnimatedBackgroundWrapperState extends State<AnimatedBackgroundWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = ThemeController.instance.isDarkMode ? Colors.white : Colors.black;
    return Stack(children: [
      Container(
        color: ThemeController.instance.isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFBAE6FD),
      ),
      AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Positioned(
                top: -_controller.value * 200,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height + 200,
                child: Opacity(
                    opacity: 0.12,
                    child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                mainAxisSpacing: 30,
                                crossAxisSpacing: 30),
                        itemCount: 150,
                        itemBuilder: (context, index) {
                          List<IconData> icons = [
                            Icons.code,
                            Icons.analytics,
                            Icons.biotech,
                            Icons.terminal,
                            Icons.settings,
                            Icons.business_center,
                            Icons.sports_cricket,
                            Icons.memory
                          ];
                          return Transform.rotate(
                              angle: -0.2,
                              child: Icon(icons[index % icons.length],
                                  size: 22, color: iconColor));
                        })));
          }),
      Center(
          child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                  size: const Size(350, 350),
                  painter: AshWheelPainter(wheelColor: Colors.blueGrey)))),
      widget.child,
    ]);
  }
}