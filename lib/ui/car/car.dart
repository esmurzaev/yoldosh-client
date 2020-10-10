import 'package:flutter/material.dart';

import '../../common/car.dart';
import '../../model/app.dart';

class CarDescriptionScreen extends StatelessWidget {
  Future<bool> _onWillPop() {
    AppModel.setCarDescription();
    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        child: Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: Text(AppModel.localization.selectCarDescr,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 70, right: 8),
                  leading: Icon(Icons.directions_car, color: _theme.hintColor),
                  title:
                      Text(AppModel.carBrand > 0 ? carBrands[AppModel.carBrand - 1] : AppModel.localization.carBrand),
                  onTap: () => _showCarBrands(context),
                ),
                /*
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 8),
                  leading: Icon(Icons.toc, color: _theme.hintColor),
                  title: Text(AppModel.carModel > 0 ? carModels[AppModel.carBrand - 1][AppModel.carModel - 1] : AppModel.localization.carModel),
                  onTap: () {
                    if (AppModel.carBrand > 0 && carModels[AppModel.carBrand - 1].length > 0) {
                      _showCarModels(context);
                    }
                  },
                ),
                */
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 70, right: 8),
                  leading: Icon(Icons.color_lens, color: _theme.hintColor),
                  title: Text(AppModel.carColor > 0
                      ? AppModel.localization.colors[AppModel.carColor - 1]
                      : AppModel.localization.carColor),
                  onTap: () => _showCarColors(context),
                ),
                // const SizedBox(height: 40),
              ],
            ),
            Align(
              alignment: const Alignment(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: FloatingActionButton(
                  child: Icon(Icons.done, size: 32, color: _theme.hintColor),
                  onPressed: () {
                    AppModel.setCarDescription();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCarBrands(BuildContext context) {
    showDialog(
      context: context,
      // builder: (BuildContext context) =>
      child: Center(
        child: SizedBox(
          // padding: const EdgeInsets.only(left: 72, right: 72),
          width: 220,
          child: SingleChildScrollView(
            // primary: false,
            physics: BouncingScrollPhysics(),
            child: Card(
              margin: const EdgeInsets.only(top: 40, bottom: 16, left: 0, right: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: carBrands.map((value) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 40, right: 8),
                    title: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      AppModel.setCarBrand(value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCarColors(BuildContext context) {
    showDialog(
      context: context,
      // builder: (BuildContext context) =>
      child: Center(
        child: SizedBox(
          // padding: const EdgeInsets.only(left: 72, right: 72),
          width: 220,
          child: SingleChildScrollView(
            // primary: false,
            physics: BouncingScrollPhysics(),
            child: Card(
              margin: const EdgeInsets.only(top: 40, bottom: 16, left: 0, right: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AppModel.localization.colors.map((String value) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 40, right: 8),
                    title: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      AppModel.setCarColor(value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*
  void _showCarModels(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      child: Center(
        child: SingleChildScrollView(
          // primary: false,
          // physics: BouncingScrollPhysics(),
          child: Card(
            margin: const EdgeInsets.only(top: 16, bottom: 16, left: 56, right: 56),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: carModels[AppModel.carBrand - 1].map((String value) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 24, right: 8),
                    title: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      AppModel.setCarModel(value);
                      Navigator.pop(context);
                    },
                  );
                }).toList()),
          ),
        ),
      ),
    );
  }
  
  Future<void> _showCarOptionDialog() async {
    showDialog(
      context: context,
      child: AlertDialog(
        title: Text(
          AppModel.localization.carOptionsDialog,
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(AppModel.localization.cancelButtonLabel, style: const TextStyle(color: CustomThemeScheme.blue)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(super.context);
            },
          ),
          FlatButton(
            child: Text('OK', style: const TextStyle(color: CustomThemeScheme.blue)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
  */
}
