import 'package:flutter/material.dart' hide AnimatedContainer;

/*
class BoxConstraintsTween extends Tween<BoxConstraints> {
  BoxConstraintsTween({ BoxConstraints begin, BoxConstraints end }) : super(begin: begin, end: end);
  @override
  BoxConstraints lerp(double t) => BoxConstraints.lerp(begin, end, t);
}
*/

class AnimatedContainer extends StatefulWidget {
  AnimatedContainer({
    this.child,
    @required double height,
    @required this.opacity,
  }) : constraints = BoxConstraints.tightFor(width: null, height: height);
  final Widget child;
  final BoxConstraints constraints;
  final double opacity;

  @override
  _AnimatedContainerState createState() => _AnimatedContainerState();
}

class _AnimatedContainerState extends State<AnimatedContainer> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _heightAnimation;
  Animation<double> _opacityAnimation;
  BoxConstraintsTween _constraints;
  Tween<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _controller.addListener(() => setState(() {}));
    _heightAnimation = CurvedAnimation(parent: _controller, curve: const Cubic(0.0, 0.0, 0.2, 1.0));
    // _heightAnimation = Tween<double>(begin: 0, end: 1.0).animate(_controller);
    _constructTweens();
    _opacityAnimation = _heightAnimation.drive(_opacity);
  }

  @override
  void didUpdateWidget(AnimatedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_constructTweens()) {
      forEachTween((Tween<dynamic> tween, dynamic targetValue, TweenConstructor<dynamic> constructor) {
        _updateTween(tween, targetValue);
        return tween;
      });
      _controller
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldAnimateTween(Tween<dynamic> tween, dynamic targetValue) {
    return targetValue != (tween.end ?? tween.begin);
  }

  void _updateTween(Tween<dynamic> tween, dynamic targetValue) {
    if (tween == null) return;
    tween
      ..begin = tween.evaluate(_heightAnimation)
      ..end = targetValue;
  }

  bool _constructTweens() {
    bool shouldStartAnimation = false;
    forEachTween((Tween<dynamic> tween, dynamic targetValue, TweenConstructor<dynamic> constructor) {
      if (targetValue != null) {
        tween ??= constructor(targetValue);
        if (_shouldAnimateTween(tween, targetValue)) shouldStartAnimation = true;
      } else {
        tween = null;
      }
      return tween;
    });
    return shouldStartAnimation;
  }

  @protected
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _constraints = visitor(_constraints, widget.constraints, (dynamic value) => BoxConstraintsTween(begin: value));
    _opacity = visitor(_opacity, widget.opacity, (dynamic value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      /*
      decoration: BoxDecoration(
        boxShadow: [
          const BoxShadow(
            offset: const Offset(0, 2),
            color: const Color(0x40000000),
            blurRadius: 4,
          ),
        ],
        gradient: LinearGradient(
          // begin: Alignment.topCenter,
          // end: Alignment.bottomCenter,
          // stops: [0.1, 1.0],
          // colors: [const Color(0xFF154360), const Color(0xFF107054)], // Blue to Green 1
          // colors: [const Color(0xFF075E54), const Color(0xFF075E54)], // Whatsapp
          // colors: [const Color(0xFF269067), const Color(0xFF269067)], // Custom green
          // colors: [const Color(0xFF43A047), const Color(0xFF43A047)], // Green
          colors: [const Color(0xFF7CB342), const Color(0xFF7CB342)], // Light Green
          // colors: [const Color(0xFF00897B), const Color(0xFF00897B)], // Teal
          // colors: [const Color(0xFF480048), const Color(0xFFC04848)], // Influenza
        ),
      ),
      */
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
      constraints: _constraints.evaluate(_heightAnimation),
    );
  }
}
