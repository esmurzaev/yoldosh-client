import 'package:flutter/material.dart';

const double _kCustomProgressIndicatorHeight = 12;
const int _kIndeterminateLinearDuration = 8000;

class _CustomProgressIndicatorPainter extends CustomPainter {
  const _CustomProgressIndicatorPainter({
    this.color,
    this.animationValue,
  });

  final Color color;
  final double animationValue;

  static const Curve lineHead = Interval(0.0, 0.5, curve: Cubic(0.7, 0.8, 0.9, 1.0));
  static const Curve lineTail = Interval(0.5, 1, curve: Cubic(0.7, 0.8, 0.9, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _kCustomProgressIndicatorHeight;

    /*
    final Gradient gradient = LinearGradient(
      colors: <Color>[
        Colors.green.withOpacity(1.0),
        Colors.green.withOpacity(0.3),
        Colors.yellow.withOpacity(0.2),
        Colors.red.withOpacity(0.1),
        Colors.red.withOpacity(0.0),
      ],
      stops: [
        0.0,
        0.5,
        0.7,
        0.9,
        1.0,
      ],
    );
    Rect rect = new Rect.fromCircle(
      center: new Offset(165.0, 55.0),
      radius: 180.0,
    );
    paint.shader = gradient.createShader(rect);
    */

    final double x = size.width * lineTail.transform(animationValue);
    final double width = size.width * lineHead.transform(animationValue);
    final ceneter = size.height / 2;

    canvas.drawLine(Offset(x, ceneter), Offset(width, ceneter), paint);
  }

  @override
  bool shouldRepaint(_CustomProgressIndicatorPainter oldPainter) {
    return oldPainter.color != color || oldPainter.animationValue != animationValue;
  }
}

class CustomProgressIndicator extends StatefulWidget {
  const CustomProgressIndicator({
    // Key key,
    this.color,
  }); // : super(key: key);

  final Color color;
  @override
  _CustomProgressIndicatorState createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateLinearDuration),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void didUpdateWidget(CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 80, left: 48, right: 48),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            child: Container(
              color: Theme.of(context).dividerColor,
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: _kCustomProgressIndicatorHeight,
              ),
              child: CustomPaint(
                painter: _CustomProgressIndicatorPainter(
                  color: widget.color,
                  animationValue: _controller.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

//-------------------------------------------------------------------------------------

class PulseIndicator extends StatefulWidget {
  const PulseIndicator({
    // Key key,
    this.color,
  }); // : super(key: key);

  final Color color;
  @override
  _PulseIndicatorState createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator> with SingleTickerProviderStateMixin {
  Animation<double> _opacityAnimation;
  AnimationController _opacityController;

  @override
  void initState() {
    super.initState();
    _opacityController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _opacityController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _opacityController.forward();
        }
      });
    _opacityAnimation =
        Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(parent: _opacityController, curve: Curves.easeInOut));
    _opacityController.forward();
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        // color: widget.color,
        // height: _kCustomProgressIndicatorHeight,
        margin: const EdgeInsets.only(bottom: 80, left: 48, right: 48),
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: _kCustomProgressIndicatorHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: widget.color,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 0),
              color: widget.color,
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}
