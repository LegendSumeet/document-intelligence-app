import 'package:flutter/material.dart';

/// The 20px sidebar icon used by the home-screen drawer trigger.
class SidebarIcon extends StatelessWidget {
  const SidebarIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _SidebarIconPainter(
          IconTheme.of(context).color ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _SidebarIconPainter extends CustomPainter {
  const _SidebarIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 20;
    canvas
      ..save()
      ..scale(scale);

    final shape = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(5.83301, 6.00098)
      ..cubicTo(6.20028, 6.00098, 6.49805, 6.29875, 6.49805, 6.66602)
      ..lineTo(6.49805, 13.333)
      ..cubicTo(6.49787, 13.7001, 6.20017, 13.998, 5.83301, 13.998)
      ..cubicTo(5.46596, 13.9979, 5.16814, 13.7, 5.16797, 13.333)
      ..lineTo(5.16797, 6.66602)
      ..cubicTo(5.16797, 6.29883, 5.46585, 6.00111, 5.83301, 6.00098)
      ..close()
      ..moveTo(14.5, 2.87695)
      ..cubicTo(16.5241, 2.87695, 18.165, 4.51787, 18.165, 6.54199)
      ..lineTo(18.165, 13.459)
      ..cubicTo(18.1649, 15.483, 16.524, 17.124, 14.5, 17.124)
      ..lineTo(5.5, 17.124)
      ..cubicTo(3.47598, 17.124, 1.83514, 15.483, 1.83496, 13.459)
      ..lineTo(1.83496, 6.54199)
      ..cubicTo(1.83496, 4.51787, 3.47588, 2.87695, 5.5, 2.87695)
      ..close()
      ..moveTo(5.5, 4.20703)
      ..cubicTo(4.21042, 4.20703, 3.16504, 5.25241, 3.16504, 6.54199)
      ..lineTo(3.16504, 13.459)
      ..cubicTo(3.16521, 14.7484, 4.21052, 15.7939, 5.5, 15.7939)
      ..lineTo(14.5, 15.7939)
      ..cubicTo(15.7895, 15.7939, 16.8348, 14.7484, 16.835, 13.459)
      ..lineTo(16.835, 6.54199)
      ..cubicTo(16.835, 5.25241, 15.7896, 4.20703, 14.5, 4.20703)
      ..close();

    canvas.drawPath(shape, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SidebarIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
