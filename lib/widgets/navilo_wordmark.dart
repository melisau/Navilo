import 'package:flutter/material.dart';

/// Shared brand lockup. Dotless i lets the leaf be the only dot.
class NaviloWordmark extends StatelessWidget {
  final double fontSize;
  const NaviloWordmark({super.key, this.fontSize = 30});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Navilo',
      image: true,
      child: ExcludeSemantics(
          child: CustomPaint(
              size: Size(fontSize * 3.55, fontSize * 1.4),
              painter: _WordmarkPainter(fontSize))));
}

class _WordmarkPainter extends CustomPainter {
  final double fontSize;
  const _WordmarkPainter(this.fontSize);
  @override
  void paint(Canvas canvas, Size size) {
    final text = TextPainter(
        text: TextSpan(
            text: 'Navılo',
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'sans-serif',
                color: const Color(0xFF214D3B),
                letterSpacing: -0.5)),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, Offset(0, fontSize * .2));
    final box = text
        .getBoxesForSelection(
            const TextSelection(baseOffset: 3, extentOffset: 4))
        .single;
    final x = (box.left + box.right) / 2;
    final y = fontSize * .04;
    final w = fontSize * .36;
    final h = fontSize * .35;
    final leaf = Path()
      ..moveTo(x - w / 2, y + h)
      ..cubicTo(x - w * .6, y + h * .35, x + w * .15, y, x + w / 2, y)
      ..cubicTo(x + w * .6, y + h * .65, x - w * .15, y + h, x - w / 2, y + h)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF9DBB8D));
    final vein = Path()
      ..moveTo(x - w * .31, y + h * .83)
      ..quadraticBezierTo(x, y + h * .47, x + w * .30, y + h * .18);
    canvas.drawPath(
        vein,
        Paint()
          ..color = const Color(0xFFFBF8EF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fontSize * .026
          ..strokeCap = StrokeCap.round);
    text.dispose();
  }

  @override
  bool shouldRepaint(covariant _WordmarkPainter oldDelegate) =>
      oldDelegate.fontSize != fontSize;
}
