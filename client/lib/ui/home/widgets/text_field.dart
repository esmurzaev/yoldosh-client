import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class _TextFieldSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  _TextFieldSelectionGestureDetectorBuilder({
    @required _TextFieldState state,
  })  : _state = state,
        super(delegate: state);
  final _TextFieldState _state;
  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editableText.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {}
  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditable.selectWordsInRange(
            from: details.globalPosition - details.offsetFromOrigin,
            to: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
      }
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    editableText.hideToolbar();
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditable.selectPosition(cause: SelectionChangedCause.tap);
          break;
      }
    }
    _state._requestKeyboard();
    // Future.delayed(Duration(milliseconds: 300), () => _state._requestKeyboard());
    // _state.widget.onTap();
    // _state.widget.focusNode.requestFocus();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditable.selectWord(cause: SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
      }
    }
  }
}

class TextField extends StatefulWidget {
  const TextField({
    // Key key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.onTap,
  }); // : super(key: key);
  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final GestureTapCallback onTap;
  @override
  _TextFieldState createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController get _effectiveController => widget.controller;
  FocusNode get _effectiveFocusNode => widget.focusNode;
  bool _isHovering = false;
  bool _showSelectionHandles = false;
  _TextFieldSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;
  @override
  bool forcePressEnabled;
  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();
  @override
  bool get selectionEnabled => true;
  int get _currentLength => _effectiveController.value.text.runes.length;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder = _TextFieldSelectionGestureDetectorBuilder(state: this);
  }

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  EditableTextState get _editableText => editableTextKey.currentState;
  void _requestKeyboard() {
    _editableText?.requestKeyboard();
    // widget.focusNode.requestFocus();
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause cause) {
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) return false;
    if (cause == SelectionChangedCause.keyboard) return false;
    if (cause == SelectionChangedCause.longPress) return true;
    if (_effectiveController.text.isNotEmpty) return true;
    return false;
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (cause == SelectionChangedCause.longPress) {
          _editableText?.bringIntoView(selection.base);
        }
        return;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
    }
    widget.onTap();
  }

  void _handleSelectionHandleTapped() {
    if (_effectiveController.selection.isCollapsed) {
      _editableText.toggleToolbar();
    }
  }

  void _handleHover(bool hovering) {
    if (hovering != _isHovering) {
      setState(() {
        return _isHovering = hovering;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasMaterial(context));
    // assert(debugCheckHasDirectionality(context));
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = themeData.textTheme.subtitle1;
    final TextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;
    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset cursorOffset;
    Radius cursorRadius;
    switch (themeData.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        forcePressEnabled = true;
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        forcePressEnabled = false;
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        break;
    }
    Widget child = EditableText(
      key: editableTextKey,
      toolbarOptions: const ToolbarOptions(copy: true, cut: false, selectAll: true, paste: true),
      showSelectionHandles: _showSelectionHandles,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,
      style: style,
      autocorrect: false,
      autofocus: false,
      cursorWidth: 1,
      // enableSuggestions: false,
      selectionColor: themeData.textSelectionHandleColor,
      selectionControls: textSelectionControls,
      onSelectionChanged: _handleSelectionChanged,
      onSelectionHandleTapped: _handleSelectionHandleTapped,
      // inputFormatters: const <TextInputFormatter>[],
      rendererIgnoresPointer: true,
      cursorRadius: cursorRadius,
      cursorColor: themeData.cursorColor,
      cursorOpacityAnimates: cursorOpacityAnimates,
      cursorOffset: cursorOffset,
      paintCursorAboveText: paintCursorAboveText,
      backgroundCursorColor: CupertinoColors.inactiveGray,
      keyboardAppearance: themeData.primaryColorBrightness,
      enableInteractiveSelection: true,
      // scrollPhysics: const NeverScrollableScrollPhysics(),
    );

    child = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[focusNode, controller]),
      builder: (BuildContext context, Widget child) {
        return InputDecorator(
          decoration: widget.decoration,
          baseStyle: style,
          textAlign: TextAlign.start,
          isHovering: _isHovering,
          isFocused: focusNode.hasFocus,
          isEmpty: controller.value.text.isEmpty,
          child: child,
        );
      },
      child: child,
    );

    return IgnorePointer(
      ignoring: false, // false
      child: MouseRegion(
        onEnter: (PointerEnterEvent event) => _handleHover(true),
        onExit: (PointerExitEvent event) => _handleHover(false),
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget child) {
            return Semantics(
              maxValueLength: 100,
              currentValueLength: _currentLength,
              onTap: () {
                if (!_effectiveController.selection.isValid)
                  _effectiveController.selection = TextSelection.collapsed(offset: _effectiveController.text.length);
                _requestKeyboard();
              },
              child: child,
            );
          },
          child: _selectionGestureDetectorBuilder.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: child,
          ),
        ),
      ),
    );
  }
}
