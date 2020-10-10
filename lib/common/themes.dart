import 'package:flutter/material.dart';

class CustomTheme {
  const CustomTheme._();

  static const double bottomSheetRound = 16;
  static const double buttonRound = 28;
  static const double dialogRound = 8;
  static const double cardRound = 8;

  static const Color yellow = Color(0xFFFFDB3B); // 0xFF7CB352 0xFF176E54 0xFFFFC107 0xFFFAAB1A 0xFF389E3C
  static const Color green = Color(0xFF22B573); // 0xFF54B060 0xFF5CB368 0xFF5CB362 0xFF4CAF50 0xFF7CB352 0xFF8BC34A
  static const Color blue = Color(0xFF03A9F4);
  static const Color red = Color(0xFFE53935);

  static const Color accentColorLight = Color(0xFF9E9E9E);
  static const Color cardColorLight = Color(0xFFFFFFFF); // 0xFFFFFFFF
  static const Color canvasColorLight = Color(0xFFFFFFFF); // 0xFFFAFAFA
  static const Color dividerColorLight = Color(0x2F000000);
  static const Color disabledColorLight = Color(0x61000000);
  static const Color hintColorLight = Color(0x8A000000);
  static const Color fillColorLight = Color(0xFFE3E4E6);
  static const Color textColorLight = Color(0xDD000000); // 0xDD000000 0xF8000000

  static const Color accentColorDark = Color(0xFF757880);
  // 202125 2A2B30 292A30 2B2D30 24262B 22242B 22252B 262A2F 2B2E32 2D2E30
  static const Color cardColorDark = Color(0xFF2A2D34);
  // static const Color canvasColorDark = Color(0xFF2B2D30);
  static const Color dividerColorDark = Color(0x2FFFFFFF);
  static const Color disabledColorDark = Color(0x52F0F8FF);
  static const Color hintColorDark = Color(0x80FFFFFF);
  static const Color fillColorDark = Color(0xFF373A43); // 3D4045 3A3C45 3E4048
  static const Color textColorDark = Color(0xEFFFFFFF); // 0xEFFFFFFF

  static const String fontFamily = 'Rubik'; // Jost FuturaNew Cantarell Manrope Rubik Roboto

  static final ThemeData lightTheme = ThemeData(
    platform: TargetPlatform.android,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    /*
    appBarTheme: const AppBarTheme(
      brightness: Brightness.dark,
      // color: colorGreen,
      iconTheme: const IconThemeData(color: colorGreen),
      textTheme: const TextTheme(
        headline6: const TextStyle(
          fontSize: 20,
          color: colorGreen, // cardColorLight
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          // shadows: [Shadow(color: Color(0x7F000000), offset: Offset(1, 1), blurRadius: 3)],
          height: 0.99,
        ),
      ),
    ),
    */
    // splashColor: cardColorLight,
    cursorColor: disabledColorLight,
    // textSelectionColor: base.disabledColor,
    textSelectionHandleColor: blue,
    primaryColor: canvasColorLight,
    dividerColor: dividerColorLight,
    disabledColor: fillColorLight,
    accentColor: accentColorLight,
    // indicatorColor: textColorDark,
    // splashColor: Colors.white24,
    // splashFactory: InkRipple.splashFactory,
    canvasColor: canvasColorLight,
    cardColor: cardColorLight,
    scaffoldBackgroundColor: canvasColorLight,
    backgroundColor: canvasColorLight,
    dialogBackgroundColor: cardColorLight,
    hintColor: hintColorLight,
    textTheme: _lightTextTheme,
    primaryTextTheme: _lightTextTheme,
    accentTextTheme: _lightTextTheme,
    // iconTheme: const IconThemeData(color: const Color(0xFFFFFFFF), size: 26),
    cardTheme: const CardTheme(
      color: cardColorLight,
      elevation: 4,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRound))),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: cardColorLight,
      elevation: 0,
      highlightElevation: 4,
      shape: const OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        borderSide: const BorderSide(color: hintColorLight, width: 3),
      ),
    ),
    dialogTheme: const DialogTheme(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(dialogRound))),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: textColorLight,
        fontFamily: fontFamily,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: const TextStyle(
        color: hintColorLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      fillColor: cardColorLight, // fillColorLight,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(buttonRound)),
        borderSide: BorderSide.none, // (color: dividerColorLight, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(buttonRound)),
        borderSide: BorderSide.none, // (color: dividerColorLight, width: 2),
      ),
    ),
  );

  static const _lightTextTheme = TextTheme(
    headline6: const TextStyle(color: green, fontSize: 20, fontWeight: FontWeight.w700), // letterSpacing: -1),
    headline5: const TextStyle(color: textColorLight), // letterSpacing: -0.6),
    subtitle1:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColorLight), // letterSpacing: -0.6),
    bodyText1:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColorLight), // letterSpacing: -0.6),
    bodyText2:
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: textColorLight), // letterSpacing: -0.6),
    button: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // letterSpacing: -0.6),
  );
  // shadows: [Shadow(color: Color(0xAF000000), offset: Offset(0, 1), blurRadius: 6)],
  // height: 2.9,

//-----------------------------------------------------------------------------------------------

  static final ThemeData darkTheme = ThemeData(
    platform: TargetPlatform.android,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    /*
    appBarTheme: const AppBarTheme(
      brightness: Brightness.dark,
      // color: colorGreen,
      iconTheme: const IconThemeData(color: colorGreen),
      textTheme: const TextTheme(
        headline6: const TextStyle(
          fontSize: 20,
          color: colorGreen, // cardColorLight
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          // shadows: [Shadow(color: Color(0xAF000000), offset: Offset(0, 1), blurRadius: 6)],
          height: 0.99,
        ),
      ),
    ),
    */
    // splashColor: cardColorDark,
    cursorColor: disabledColorDark,
    // textSelectionColor: base.disabledColor,
    textSelectionHandleColor: blue,
    primaryColor: cardColorDark,
    dividerColor: dividerColorDark,
    disabledColor: fillColorDark,
    hintColor: hintColorDark,
    // indicatorColor: const Color(0xFFFAFAFA),
    accentColor: accentColorDark,
    cardColor: cardColorDark,
    canvasColor: cardColorDark,
    scaffoldBackgroundColor: cardColorDark,
    backgroundColor: cardColorDark,
    dialogBackgroundColor: cardColorDark,
    textTheme: _darkTextTheme,
    primaryTextTheme: _darkTextTheme,
    accentTextTheme: _darkTextTheme,
    // iconTheme: const IconThemeData(color: const Color(0xFFFFFFFF), size: 26),
    cardTheme: const CardTheme(
      color: cardColorDark,
      elevation: 4,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRound))),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: cardColorDark,
      elevation: 0,
      highlightElevation: 4,
      shape: const OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        borderSide: const BorderSide(color: hintColorDark, width: 3),
      ),
    ),
    dialogTheme: const DialogTheme(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(dialogRound))),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: textColorDark,
        fontFamily: fontFamily,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: const TextStyle(
        color: hintColorDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      fillColor: fillColorDark,
      enabledBorder: const OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(buttonRound)),
        borderSide: BorderSide.none, // (color: dividerColorDark, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(buttonRound)),
        borderSide: BorderSide.none, // (color: dividerColorDark, width: 2),
      ),
    ),
  );

  static const _darkTextTheme = TextTheme(
    headline6: const TextStyle(color: green, fontSize: 20, fontWeight: FontWeight.w700), // letterSpacing: -1),
    headline5: const TextStyle(color: textColorDark), // letterSpacing: -1),
    subtitle1:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColorDark), // letterSpacing: -0.6),
    bodyText1:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColorDark), // letterSpacing: -0.6),
    bodyText2:
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: textColorDark), // letterSpacing: -0.6),
    button: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // letterSpacing: -0.6),
  );
}
