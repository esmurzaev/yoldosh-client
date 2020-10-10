import 'dart:async';

import 'package:flutter/material.dart';

import '../../../common/themes.dart';
import '../../../model/app.dart';

Future<bool> showFavoriteDeleteDialog(BuildContext cont, String name) async {
  return await showModalBottomSheet(
    context: cont,
    backgroundColor: const Color(0),
    builder: (BuildContext context) {
      return Card(
        shape:
            const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(CustomTheme.bottomSheetRound))),
        margin: const EdgeInsets.only(top: 0, bottom: 12, left: 12, right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 8, right: 8),
              child: Text(
                AppModel.localization.deleteFromFavorite,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(
              height: 112,
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 24, left: 8, right: 8),
                child: Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 168,
              height: 54,
              child: OutlineButton(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(CustomTheme.buttonRound))),
                // elevation: 4,
                highlightElevation: 8,
                // color: const Color(0xFFE53935), // _theme.cardColor,
                borderSide: BorderSide(color: CustomTheme.red, width: 3),
                highlightedBorderColor: CustomTheme.red, //_theme.disabledColor,
                child: Text(AppModel.localization.delete, style: const TextStyle(color: CustomTheme.red)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
