import 'dart:async';

import 'package:flutter/material.dart' hide AnimatedContainer, TextField;
import 'package:flutter/rendering.dart';

import '../../common/configs.dart';
import '../../common/route.dart';
import '../../common/themes.dart';
import '../../model/app.dart';
import '../../ui/settings/settings.dart';
import 'widgets/favorite_delete_dialog.dart';
import 'widgets/text_field.dart';

// import 'widgets/animated_container.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Animation<double> _opacityAnimation;
  AnimationController _opacityController;
  bool _search = false;
  ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      AppModel.searchPlace(_textController.text);
      setState(() {});
    });
    _opacityController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacityAnimation = Tween<double>(begin: 0, end: 0.7).animate(_opacityController);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _opacityController.dispose();
    super.dispose();
  }
  /*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
  }
  */

  Future<bool> _onWillPop() {
    if (_search) {
      _searchCancel();
      return Future<bool>.value(false);
    }
    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // backgroundColor: const Color(0xFF2C2E30), // 292A30
        // extendBody: true,
        // resizeToAvoidBottomInset: false,
        // resizeToAvoidBottomPadding: false,
        // drawerEdgeDragWidth: 40,
        drawerEnableOpenDragGesture: false,
        key: _scaffoldKey,
        primary: false,
        drawer: buildSettings(context),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            _buildAppBar(),
            _buildSearchField(),
            _buildBodyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      // child: AnimatedContainer(
      // height: _search ? 0 : 100, // 135
      // opacity: _search ? 0 : 1,
      child: SafeArea(
        child: SizedBox(
          height: 42,
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter, // const Alignment(0, 0),
            // mainAxisSize: MainAxisSize.min,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 10.0),
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 42,
                    ),
                    // padding: const EdgeInsets.only(top: 24, left: 24),
                    icon: const Icon(Icons.menu, color: CustomTheme.green, size: 26), // utf: 0x2630
                    onPressed: () => _scaffoldKey.currentState.openDrawer(),
                  ),
                ),
              ),
              Text(Configs.appTitle, style: _theme.textTheme.headline6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SliverPersistentHeader(
      // floating: true,
      pinned: true,
      delegate: _SliverHeaderDelegate(
        child: Container(
          height: 52,
          margin: const EdgeInsets.only(top: 0, bottom: 24, left: 16, right: 16), // bottom: 24
          decoration: BoxDecoration(
            // color: _theme.inputDecorationTheme.fillColor,
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(CustomTheme.buttonRound)),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 1),
                color: Theme.of(context).disabledColor, // const Color(0x30000000),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: const Alignment(0, 0),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 24, right: 48), // top: 0, bottom: 0),
                    hintText: AppModel.localization.searchFieldLabel,
                  ),
                  onTap: _onTapSearchField,
                ),
              ),
              if (_textController.text?.isNotEmpty)
                Align(
                  alignment: const Alignment(1.0, 0.0),
                  child: MaterialButton(
                    elevation: 0,
                    minWidth: 56,
                    height: 56,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                    child: Icon(Icons.clear, color: _theme.hintColor),
                    onPressed: _onTapSearchClear,
                  ),
                ),
              /*
                SizedBox(
                  width: 56,
                  child: GestureDetector(
                    onTap: _onTapSearchClear,
                    child: Center(
                      child: Icon(Icons.clear),
                    ),
                  ),
                ),
                */
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyList() {
    return SliverToBoxAdapter(
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // const SizedBox(height: 16),
              for (Place place in AppModel.bodyList)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 40, right: 8),
                  title: Text(
                    AppModel.isCyrillic ? place.nameRu : place.nameUz,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: Text(
                    AppModel.localization.districts[place.districtCode],
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(color: _theme.hintColor, fontSize: 13),
                  ),
                  onTap: () => _onTapBodyList(place),
                  onLongPress: () => _onLongTapBodyList(place),
                ),
              const SizedBox(height: 24),
            ],
          ),
          FadeTransition(
            opacity: _opacityAnimation,
            child: GestureDetector(
              onTap: _searchCancel,
              onVerticalDragUpdate: (_) => _searchCancel(),
              onHorizontalDragUpdate: (_) => _searchCancel(),
              child: Container(
                height: _search && _textController.text.length < 2 ? 800 : 0,
                color: _theme.scaffoldBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTapBodyList(Place place) async {
    AppModel.selectedPlace = place;
    if (!_search) {
      if (await Navigator.pushNamed(context, Router.process) != null) {
        setState(() {});
        if (_scrollController.offset > 0)
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.linear);
      }
    } else {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
        await Future.delayed(Duration(milliseconds: 200), () {});
      }
      if (await Navigator.pushNamed(context, Router.process) != null) {
        _searchCancel();
      }
    }
  }

  void _onLongTapBodyList(Place place) async {
    if (!_search) {
      AppModel.selectedPlace = place;
      final name = AppModel.isCyrillic ? AppModel.selectedPlace.nameRu : AppModel.selectedPlace.nameUz;
      if (await showFavoriteDeleteDialog(context, name) != null) {
        AppModel.favoritePlaceDelete();
        setState(() {});
      }
    }
  }

  void _onTapSearchClear() {
    _textController.clear();
    if (_scrollController.offset > 0) _scrollController.jumpTo(0);
  }

  void _onTapSearchField() {
    if (!_search) {
      if (_scrollController.offset > 0) {
        Future.delayed(Duration(milliseconds: 200), () {
          _scrollController.animateTo(0, duration: Duration(milliseconds: 150), curve: Curves.linear);
        });
      }
      _opacityController.forward();
      setState(() => _search = true);
    }
  }

  void _searchCancel() {
    if (_focusNode.hasFocus) _focusNode.unfocus();
    if (_textController.text.length > 0) _textController.clear();
    if (_scrollController.offset > 0)
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.linear);
    setState(() => _search = false);
    _opacityController.reverse();
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverHeaderDelegate({
    this.child,
  });
  final Widget child;
  @override
  double get minExtent => 112; // 120
  @override
  double get maxExtent => 112; // 120
  @override
  Widget build(_, __, ___) {
    return Align(
      child: child,
      alignment: const Alignment(0.0, 1.0),
    );
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
