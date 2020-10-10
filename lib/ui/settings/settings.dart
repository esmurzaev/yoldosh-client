import 'package:flutter/material.dart';

import '../../common/configs.dart';
import '../../common/route.dart';
import '../../common/themes.dart';
import '../../model/app.dart';
import 'expansion_tile.dart';

Widget buildSettings(BuildContext context) {
  final _theme = Theme.of(context);
  return Drawer(
    elevation: 6,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 48), // 38
        /*
        SizedBox(
          height: 64,
          child: Center(
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 40), // 38
        const Divider(height: 0),
        const SizedBox(height: 24), // 38
        Text(Configs.appTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        // const SizedBox(height: 4),
        Text(AppModel.localization.version + ' ' + Configs.appVersion,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        Divider(height: 48),
        */
        AnimatedCrossFade(
          // layoutBuilder: customlayoutBuilder,
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 250),
          crossFadeState: AppModel.driverMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: ListTile(
            key: ValueKey(1),
            dense: true,
            leading: Icon(Icons.account_circle, color: _theme.hintColor),
            contentPadding: const EdgeInsets.only(left: 24, right: 8),
            title: Text(AppModel.carDescrString, style: TextStyle(fontSize: 16)),
            onTap: () => Navigator.pushNamed(context, Router.car),
          ),
          secondChild: ListTile(
            key: ValueKey(2),
            dense: true,
            leading: Icon(Icons.account_circle, color: _theme.hintColor),
            contentPadding: const EdgeInsets.only(left: 24, right: 8),
            title: Text(AppModel.userName, style: TextStyle(fontSize: 16)),
            onTap: () => _showNameEditDialog(context),
          ),
        ),
        ListTile(
          dense: true,
          leading: Icon(Icons.directions_car, color: _theme.hintColor),
          contentPadding: const EdgeInsets.only(left: 24, right: 8),
          title: Text(AppModel.localization.driverMode, style: TextStyle(fontSize: 16)),
          trailing: Switch(
            activeColor: CustomTheme.blue,
            value: AppModel.driverMode,
            onChanged: (value) {
              if (!AppModel.setDriverMode(value)) {
                Navigator.pushNamed(context, Router.car);
              }
            },
          ),
        ),
        // const Divider(),
        ListTile(
            dense: true,
            leading: Icon(Icons.brightness_medium, color: _theme.hintColor),
            contentPadding: const EdgeInsets.only(left: 24, right: 8),
            title: Text(AppModel.themeMode ? AppModel.localization.lightTheme : AppModel.localization.darkTheme,
                style: TextStyle(fontSize: 16)),
            onTap: () {
              AppModel.setTheme();
              // Provider.of<ThemeProvider>(context, listen: false).setTheme();
            }),
        CustomExpansionTile(
          leading: Icon(Icons.language, color: _theme.hintColor),
          title: Text(AppModel.localization.language, style: TextStyle(fontSize: 16)),
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 80, right: 22),
              title: const Text('O\'zbekcha', style: TextStyle(fontSize: 16)),
              onTap: () => AppModel.setLanguage('uz'),
              trailing:
                  Icon(Icons.done, color: AppModel.languageCode == 'uz' ? CustomTheme.blue : _theme.disabledColor),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 80, right: 22),
              title: const Text('Русский', style: TextStyle(fontSize: 16)),
              onTap: () => AppModel.setLanguage('ru'),
              trailing:
                  Icon(Icons.done, color: AppModel.languageCode == 'ru' ? CustomTheme.blue : _theme.disabledColor),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 80, right: 22),
              title: const Text('English', style: TextStyle(fontSize: 16)),
              onTap: () => AppModel.setLanguage('en'),
              trailing:
                  Icon(Icons.done, color: AppModel.languageCode == 'en' ? CustomTheme.blue : _theme.disabledColor),
            ),
            /*
            ListTile(
              contentPadding: const EdgeInsets.only(left: 80, right: 22),
              title: const Text('Ўзбекча'),
              onTap: () => AppModel.setLanguage('oz'),
              trailing: Icon(Icons.done, color: AppModel.languageCode == 'oz' ? CustomTheme.blue : _theme.disabledColor),
            ),
            */
            SizedBox(height: 12),
          ],
        ),
        ListTile(
          dense: true,
          leading: Icon(Icons.info_outline, color: _theme.hintColor),
          contentPadding: const EdgeInsets.only(left: 24, right: 8),
          title: Text(AppModel.localization.info, style: TextStyle(fontSize: 16)),
          onTap: () => Navigator.pushNamed(context, Router.info),
        ),
      ],
    ),
  );
}

void _showNameEditDialog(BuildContext context) {
  // Timer _timer;
  // bool _nameIsShort = false;
  String _userName = '';
  // await
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      // return StatefulBuilder(
      // builder: (BuildContext context, StateSetter _setState) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /*
            CustomAnimatedContainer(
              // duration: const Duration(milliseconds: 200),
              height: _nameIsShort ? 40 : 0,
              opacity: _nameIsShort ? 1 : 0,
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Align(alignment: Alignment.center, child: Text(AppModel.localization.nameIsShort)),
              ),
            ),
            */
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, left: 24, right: 24),
              child: TextField(
                autocorrect: false,
                autofocus: true,
                maxLength: 22,
                enableInteractiveSelection: false,
                cursorColor: Theme.of(context).cursorColor,
                cursorWidth: 1,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.text,
                onChanged: (value) => _userName = value,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 8),
                  hintText: AppModel.localization.enterName,
                  focusedBorder:
                      UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor, width: 2)),
                  enabledBorder:
                      UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor, width: 2)),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FlatButton(
                  padding: const EdgeInsets.all(8),
                  child: Text(AppModel.localization.cancelButtonLabel, style: const TextStyle(color: CustomTheme.blue)),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(AppModel.localization.okButtonLabel, style: const TextStyle(color: CustomTheme.blue)),
                  onPressed: () {
                    if (_userName.length >= 3) {
                      AppModel.setUserName(_userName);
                      Navigator.pop(context);
                      // } else {
                      // _setState(() => _nameIsShort = true);
                      // _timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
                      // timer.cancel();
                      // _setState(() => _nameIsShort = false);
                      // });
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      );
    },
  );
  // },
  // );
  // _timer?.cancel();
}
/*
  Widget customlayoutBuilder(Widget topChild, Key topChildKey, Widget bottomChild, Key bottomChildKey) {
    return Stack(
      // overflow: Overflow.visible,
      alignment: const Alignment(0.0, 0.0),
      children: <Widget>[
        SizedBox(
          key: bottomChildKey,
          child: bottomChild,
        ),
        SizedBox(
          key: topChildKey,
          child: topChild,
        )
        // bottomChild,
        // topChild,
        /*
        Positioned(
          key: bottomChildKey,
          left: 0.0,
          top: 0.0,
          right: 0.0,
          child: bottomChild,
        ),
        Positioned(
          key: topChildKey,
          child: topChild,
        ),
        */
      ],
    );
  }
  */
