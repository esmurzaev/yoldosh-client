import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../common/configs.dart';
import '../../common/themes.dart';
import '../../model/app.dart';
import '../../model/service.dart';
import 'indicator.dart';

const Duration _bottomSheetEnterDuration = Duration(milliseconds: 250);
const Duration _bottomSheetExitDuration = Duration(milliseconds: 200);
const Curve _modalBottomSheetCurve = Cubic(0.0, 0.0, 0.2, 1.0);
const double _minFlingVelocity = 700.0;
const double _closeProgressThreshold = 0.5;

class ProcessScreen<T> extends StatefulWidget {
  const ProcessScreen({
    // Key key,
    // this.route,
    this.animationController,
    this.animation,
  }); // : super(key: key);
  // final ProcessPage<T> route;
  final AnimationController animationController;
  final Animation<double> animation;
  @override
  _ProcessScreenState<T> createState() => _ProcessScreenState<T>();
}

class _ProcessScreenState<T> extends State<ProcessScreen<T>> with SingleTickerProviderStateMixin {
  bool _process = false;
  double _screenHeight = 0;
  double _screenHeightHalf = 0;
  ThemeData _theme;
  MediaQueryData mediaQuery;
  ParametricCurve<double> animationCurve = _modalBottomSheetCurve;
  final GlobalKey _childKey = GlobalKey(debugLabel: 'ProcessScreen child');

  @override
  void initState() {
    super.initState();
    Service.closeProcessScreen = () => Navigator.pop(context);
    Service.setState = () => setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onWillPop() {
    if (_process) {
      _processCancel();
      return Future<bool>.value(false);
    }
    return Future<bool>.value(true);
  }

  double get _childHeight {
    final RenderBox renderBox = _childKey.currentContext.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway => widget.animationController.status == AnimationStatus.reverse;

  void _handleDragStart(_) {
    animationCurve = Curves.linear;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dismissUnderway || _process) return;
    widget.animationController.value -= details.primaryDelta / (_childHeight ?? details.primaryDelta);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dismissUnderway || _process) return;
    bool isClosing = false;
    if (details.velocity.pixelsPerSecond.dy > _minFlingVelocity) {
      final double flingVelocity = -details.velocity.pixelsPerSecond.dy / _childHeight;
      if (widget.animationController.value > 0.0) {
        widget.animationController.fling(velocity: flingVelocity);
      }
      if (flingVelocity < 0.0) {
        isClosing = true;
      }
    } else if (widget.animationController.value < _closeProgressThreshold) {
      if (widget.animationController.value > 0.0) widget.animationController.fling(velocity: -1.0);
      isClosing = true;
    } else {
      widget.animationController.forward();
    }
    animationCurve = _BottomSheetSuspendedCurve(
      widget.animation.value, // widget.route.animation.value,
      curve: _modalBottomSheetCurve,
    );

    if (isClosing) {
      _onClosing();
    }
  }

  bool extentChanged(DraggableScrollableNotification notification) {
    if (notification.extent == notification.minExtent) {
      _onClosing();
    }
    return false;
  }

  void _onClosing() {
    // if (widget.route.isCurrent) {
    Navigator.pop(context);
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    if (mediaQuery == null) mediaQuery = MediaQuery.of(context);
    _screenHeight = mediaQuery.size.height - mediaQuery.padding.top - 32;
    _screenHeightHalf = (_screenHeight / 2) - 30;
  }

  @override
  Widget build(BuildContext context) {
    // final MediaQueryData mediaQuery = MediaQuery.of(context);
    // _theme = Theme.of(context);
    // if (_screenHeight == 0) _screenHeight = mediaQuery.size.height - 16;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnimatedBuilder(
        animation: widget.animation, // widget.route.animation,
        builder: (BuildContext context, Widget child) {
          final double animationValue =
              animationCurve.transform(mediaQuery.accessibleNavigation ? 1.0 : widget.animation.value);
          return ClipRect(
            child: CustomSingleChildLayout(
              delegate: _ModalBottomSheetLayout(animationValue, true),
              child: GestureDetector(
                onVerticalDragStart: _handleDragStart,
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                excludeFromSemantics: true,
                child: _buildProcess(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcess() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          key: _childKey,
          // color: color,
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(CustomTheme.bottomSheetRound))),
          child: NotificationListener<DraggableScrollableNotification>(
            onNotification: extentChanged,
            child: AnimatedSize(
              alignment: const Alignment(0.0, 1.0),
              vsync: this,
              duration: const Duration(milliseconds: 250),
              curve: const Cubic(0.0, 0.0, 0.2, 1.0), // Curves.linear,
              child: SizedBox(
                height: _process ? _screenHeight : _screenHeightHalf,
                child: Stack(
                  alignment: const Alignment(0.0, 0.0),
                  children: <Widget>[
                    if (_process)
                      Align(
                        alignment: const Alignment(0.0, -1.0),
                        child: SizedBox(
                          height: _screenHeightHalf - 10,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Text(
                                Service.processStr + Service.processStr2 + Service.processDebugStr,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.fade,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_process)
                      Service.progress
                          ? CustomProgressIndicator(
                              color: Service.serviceStatus ? CustomTheme.yellow : _theme.hintColor)
                          : PulseIndicator(color: Service.processOK ? CustomTheme.green : CustomTheme.red),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: _screenHeightHalf / 2 - 18, // 162,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 12),
                              child: Text(
                                AppModel.isCyrillic ? AppModel.selectedPlace.nameRu : AppModel.selectedPlace.nameUz,
                                // "\n" +
                                // mediaQuery.size.width.toString() +
                                // " x " +
                                // _screenHeight.toString() +
                                // " " +
                                // _screenHeightHalf.toString(),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.fade,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        // Divider(indent: 50, endIndent: 50, height: 8),
                        _buildDescrOptions(),
                        // Divider(indent: 50, endIndent: 50, height: 8),
                        SizedBox(height: 8.0),
                        SizedBox(
                          height: _screenHeightHalf / 2 - 38, // 138, // 108
                          // width: 300,
                          child: AnimatedCrossFade(
                            layoutBuilder: customlayoutBuilder,
                            duration: const Duration(milliseconds: 200),
                            crossFadeState: _process ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            firstChild: AnimatedContainer(
                              key: ValueKey(1),
                              duration: const Duration(milliseconds: 200),
                              width: _process ? 52 : 200, // 168
                              height: 52,
                              margin: const EdgeInsets.only(left: 10, right: 10),
                              // /*
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(CustomTheme.buttonRound),
                                boxShadow: [
                                  const BoxShadow(
                                    offset: const Offset(0, 0),
                                    color: const Color(0x7FFFDB3B), //const Color(0x40000000),
                                    blurRadius: 6,
                                  ),
                                  /*
                                  const BoxShadow(
                                    offset: const Offset(0, 0),
                                    color: CustomTheme.yellow,
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                  */
                                ],
                              ),
                              // */
                              child: RaisedButton(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(CustomTheme.buttonRound))),
                                elevation: 0,
                                highlightElevation: 0,
                                color: CustomTheme.yellow,
                                colorBrightness: Brightness.dark,
                                // animationDuration: const Duration(milliseconds: 100),
                                child: _process
                                    ? null
                                    : Text(AppModel.localization.start,
                                        style: const TextStyle(
                                            color: const Color(0xE0000000), fontWeight: FontWeight.w600)),
                                onPressed: _processStart,
                              ),
                            ),
                            secondChild: FloatingActionButton(
                              key: ValueKey(2),
                              heroTag: null,
                              shape: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(28)),
                                borderSide: BorderSide(
                                  color:
                                      Service.processOK && !AppModel.driverMode ? CustomTheme.green : _theme.hintColor,
                                  width: 3,
                                ),
                              ),
                              child: Service.processOK && !AppModel.driverMode
                                  ? const Icon(
                                      Icons.done,
                                      size: 32,
                                      color: CustomTheme.green,
                                    )
                                  : Icon(Icons.clear, size: 32, color: _theme.hintColor),
                              onPressed: _processCancel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget customlayoutBuilder(Widget topChild, _, Widget bottomChild, __) {
    return Stack(
      // overflow: Overflow.visible,
      alignment: const Alignment(0.0, 0.0),
      children: <Widget>[
        bottomChild,
        topChild,
      ],
    );
  }

  Widget _buildDescrOptions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text('  ' + AppModel.localization.seat + '  '), // style: TextStyle(fontSize: 18)),
        // Icon(Icons.supervisor_account),
        // SizedBox(width: 16),
        DropdownButton(
          underline: const SizedBox(),
          value: AppModel.seat,
          onChanged: (seat) {
            AppModel.setSeat(seat);
            setState(() {});
          },
          items: const <String>['1', '2', '3', '4'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
        Text('          ' + AppModel.localization.tariff + '  '), // style: TextStyle(fontSize: 18)),
        // SizedBox(width: 40),
        // Icon(Icons.monetization_on),
        // SizedBox(width: 16),
        DropdownButton(
          underline: const SizedBox(),
          value: AppModel.tariff,
          onChanged: (tariff) {
            AppModel.setTariff(tariff);
            setState(() {});
          },
          items: Configs.tariffs.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ],
    );
  }

  Future<bool> _showProcessCancelDialog() async {
    return await showDialog(
      context: context,
      child: AlertDialog(
        title: Text(AppModel.localization.cancelTrip, textAlign: TextAlign.center),
        actions: <Widget>[
          FlatButton(
            child: Text(AppModel.localization.no, style: const TextStyle(color: CustomTheme.blue)),
            onPressed: () => Navigator.pop(context),
          ),
          FlatButton(
            child: Text(AppModel.localization.yes, style: const TextStyle(color: CustomTheme.blue)),
            onPressed: () => Navigator.pop(context, true),
          )
        ],
      ),
    );
  }

  void _processStart() {
    // Service.processStr = '';
    // Future.delayed(const Duration(milliseconds: 300), () => Service.processStart());
    setState(() => _process = true);
    Service.processStart();
  }

  void _processCancel() async {
    if (Service.processStatus &&
        (!Service.processOK || AppModel.driverMode) &&
        await _showProcessCancelDialog() == null) {
      return;
    }
    _process = false;
    Service.processCancel();
    Navigator.pop(context, true);
  }
}

class ProcessScreenRoute<T> extends PopupRoute<T> {
  /*
  ProcessPage({
    RouteSettings settings,
  }) : super(settings: settings);
  */
  @override
  Duration get transitionDuration => _bottomSheetEnterDuration;
  @override
  Duration get reverseTransitionDuration => _bottomSheetExitDuration;
  @override
  bool get barrierDismissible => true;
  @override
  final String barrierLabel = 'ProcessPage';
  @override
  Color get barrierColor => Colors.black45;
  AnimationController _animationController;
  @override
  AnimationController createAnimationController() {
    // assert(_animationController == null);
    _animationController = AnimationController(
      duration: _bottomSheetEnterDuration,
      reverseDuration: _bottomSheetExitDuration,
      vsync: navigator.overlay,
    );
    return _animationController;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, _) {
    return ProcessScreen<T>(
      // route: this,
      animation: animation,
      animationController: _animationController,
    );
  }
}

class _ModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetLayout(this.progress, this.isScrollControlled);
  final double progress;
  final bool isScrollControlled;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: isScrollControlled ? constraints.maxHeight : constraints.maxHeight * 9.0 / 16.0,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_ModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _BottomSheetSuspendedCurve extends ParametricCurve<double> {
  const _BottomSheetSuspendedCurve(
    this.startingPoint, {
    this.curve = Curves.easeOutCubic,
  })  : assert(startingPoint != null),
        assert(curve != null);
  final double startingPoint;
  final Curve curve;
  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(startingPoint >= 0.0 && startingPoint <= 1.0);
    if (t < startingPoint) {
      return t;
    }
    if (t == 1.0) {
      return t;
    }
    final double curveProgress = (t - startingPoint) / (1 - startingPoint);
    final double transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed);
  }
  /*
  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
  */
}
