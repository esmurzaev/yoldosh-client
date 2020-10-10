import 'package:flutter/material.dart';

import '../../common/configs.dart';
import '../../model/app.dart';

class InfoScreen extends StatelessWidget {
  @override
  build(BuildContext context) {
    // final height = (MediaQuery.of(context).size.height/2) - 40;
    return Material(
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 74),
          SizedBox(
            height: 64,
            child: Center(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(Configs.appTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          Text(AppModel.localization.version + ' ' + Configs.appVersion,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16)), // fontWeight: FontWeight.w300)),
          // const SizedBox(height: 48),
          const Divider(height: 100, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 8, bottom: 16),
            child: Text(
              AppModel.localization.description,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16), // fontWeight: FontWeight.w300),
              // softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
