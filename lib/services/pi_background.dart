import 'package:flutter/material.dart';
import 'dart:math' as math;

class PiBackground extends StatelessWidget {
  final Widget child;

  const PiBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Pi symbols in the background
        Positioned.fill(
          child: Container(
            color: Colors.white, // Base background color
            child: const _PiSymbolLayer(),
          ),
        ),
        // The actual content
        SafeArea(child: child),
      ],
    );
  }
}

class _PiSymbolLayer extends StatelessWidget {
  const _PiSymbolLayer();

  @override
  Widget build(BuildContext context) {
    final List<Color> piColors = [
      const Color(0xFF8E2157).withOpacity(0.05),
      const Color(0xFF5C0632).withOpacity(0.03),
      const Color(0xFF8E2157).withOpacity(0.08),
      const Color(0xFF5C0632).withOpacity(0.06),
      Colors.grey.withOpacity(0.04),
    ];

    final random = math.Random(42); // Seeded for consistency

    return LayoutBuilder(
      builder: (context, constraints) {
        final List<Widget> symbols = [];

        // Add around 25-30 symbols at random positions
        for (int i = 0; i < 30; i++) {
          final size = 40.0 + random.nextDouble() * 120.0;
          final color = piColors[random.nextInt(piColors.length)];
          final rotation = random.nextDouble() * math.pi / 4 - math.pi / 8;
          final left = random.nextDouble() * constraints.maxWidth;
          final top = random.nextDouble() * constraints.maxHeight;

          symbols.add(
            Positioned(
              left: left - (size / 2),
              top: top - (size / 2),
              child: Transform.rotate(
                angle: rotation,
                child: Text(
                  'π',
                  style: TextStyle(
                    fontSize: size,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: symbols);
      },
    );
  }
}
