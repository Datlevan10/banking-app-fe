import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A dark, high-contrast scanning overlay: a dimmed scrim with a transparent
/// square cutout, bright corner accents, and an animated scan line.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({super.key, this.cutoutSize = 260});

  final double cutoutSize;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size = widget.cutoutSize;
        final Rect cutout = Rect.fromCenter(
          center: Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          ),
          width: size,
          height: size,
        );

        return Stack(
          children: <Widget>[
            // Dimmed scrim + corner accents.
            Positioned.fill(
              child: CustomPaint(
                painter: _OverlayPainter(cutout: cutout),
              ),
            ),
            // Animated scan line travelling within the cutout.
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double y = cutout.top +
                    _controller.value * (cutout.height - 2);
                return Positioned(
                  left: cutout.left + 12,
                  top: y,
                  width: cutout.width - 24,
                  child: child!,
                );
              },
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.accent.withValues(alpha: 0),
                      AppColors.accent,
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({required this.cutout});

  final Rect cutout;

  static const double _radius = 20;
  static const double _cornerLen = 32;
  static const double _cornerWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect hole = RRect.fromRectAndRadius(
      cutout,
      const Radius.circular(_radius),
    );

    // Dim everything except the cutout.
    final Path scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.7));

    // Bright L-shaped corner accents.
    final Paint corner = Paint()
      ..color = AppColors.textOnPrimary
      ..strokeWidth = _cornerWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double l = cutout.left;
    final double t = cutout.top;
    final double r = cutout.right;
    final double b = cutout.bottom;

    void drawCorner(Offset p, Offset h, Offset v) {
      canvas
        ..drawLine(p, h, corner)
        ..drawLine(p, v, corner);
    }

    drawCorner(Offset(l, t), Offset(l + _cornerLen, t), Offset(l, t + _cornerLen));
    drawCorner(Offset(r, t), Offset(r - _cornerLen, t), Offset(r, t + _cornerLen));
    drawCorner(Offset(l, b), Offset(l + _cornerLen, b), Offset(l, b - _cornerLen));
    drawCorner(Offset(r, b), Offset(r - _cornerLen, b), Offset(r, b - _cornerLen));
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) => oldDelegate.cutout != cutout;
}
