import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wheelimal/providers.dart';

class ColorWheelPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorWheelPickerDialog({super.key, required this.initialColor});

  @override
  State<ColorWheelPickerDialog> createState() => _ColorWheelPickerDialogState();
}

class _ColorWheelPickerDialogState extends State<ColorWheelPickerDialog> {
  late HSVColor _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a theme color'),
      content: SizedBox(
        width: 250,
        height: 250,
        child: GestureDetector(
          onPanUpdate: _handleColorSelection,
          onTapDown: _handleColorSelection,
          child: CustomPaint(
            painter: _ColorWheelPainter(_selectedColor),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Select'),
          onPressed: () {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.setSeedColor(_selectedColor.toColor());
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  // Handle color selection from wheel
  void _handleColorSelection(dynamic details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    final double centerX = box.size.width / 2;
    final double centerY = box.size.height / 2;
    final double radius = box.size.width / 2;

    final double dx = localPosition.dx - centerX;
    final double dy = localPosition.dy - centerY;
    final double distance = math.sqrt(dx * dx + dy * dy);

    // Only process points inside the color wheel
    if (distance <= radius) {
      final double angle = math.atan2(dy, dx);
      final double hue = (angle * 180 / math.pi + 360) % 360;

      setState(() {
        _selectedColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0);
      });
    }
  }
}

// Custom painter for color wheel
class _ColorWheelPainter extends CustomPainter {
  final HSVColor selectedColor;

  _ColorWheelPainter(this.selectedColor);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Create gradient for color wheel
    final gradient = SweepGradient(
      colors: List.generate(36, (index) {
        return HSVColor.fromAHSV(1.0, index * 10.0, 1.0, 1.0).toColor();
      }),
    );

    // Draw color wheel
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = gradient
              .createShader(Rect.fromCircle(center: center, radius: radius)));

    // Draw selection indicator
    final double hue = selectedColor.hue;
    final double angle = hue * math.pi / 180;
    final double indicatorRadius = radius * 0.85;
    final Offset indicatorPosition = Offset(
      center.dx + indicatorRadius * math.cos(angle),
      center.dy + indicatorRadius * math.sin(angle),
    );

    // Draw outer white ring
    canvas.drawCircle(
        indicatorPosition,
        12,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // Draw inner color circle
    canvas.drawCircle(
        indicatorPosition,
        10,
        Paint()
          ..color = selectedColor.toColor()
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
