import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:flutter/material.dart' hide Localizations;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/car.dart';
import '../common/localization.dart';
import '../common/themes.dart';
import '../common/utils/search.dart';
import '../model/service.dart';

class Place {
  Place({this.nameUz, this.nameEn, this.nameRu, this.lat, this.lon, this.districtCode, this.index, this.count});
  final String nameUz;
  final String nameEn;
  final String nameRu;
  final double lat;
  final double lon;
  final int districtCode;
  final int index;
  int count;
}

class AppModel {
  AppModel._();

  static ThemeData theme;
  static Localizations localization;
  static bool themeMode;
  static bool driverMode;
  static bool isCyrillic;
  static int carDescr = 0;
  static int carBrand;
  static int carColor;
  static String userName;
  static String carDescrString = '';
  static String seat;
  static String tariff;
  static String languageCode;
  static String _favoritesPath;
  static Place selectedPlace;
  static List<Place> bodyList;
  static List<Place> places;
  static List<String> _placesNameUz;
  static List<String> _placesNameRu;
  static final List<Place> _favorites = [];
  static final ListToCsvConverter _toCsv = ListToCsvConverter(fieldDelimiter: '\t', eol: '\n');
  static SharedPreferences _prefs;
  static void Function() setState;

  static int get getDescr {
    return int.parse(seat) | (int.parse(tariff) ~/ 100).toInt() << 4;
  }

  static Future<void> load() async {
    final fromCsv = CsvToListConverter(fieldDelimiter: '\t', eol: '\n');
    _prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 30));

    // Load _prefs
    String appDocDirPath = _prefs.getString('appDocDirPath') ?? await _firstRunDataLoad();
    _favoritesPath = '$appDocDirPath/favorite-places.csv';
    languageCode = _prefs.getString('languageCode');
    localization = Localizations.load(languageCode);
    isCyrillic = languageCode == 'ru' ? true : false;
    userName = _prefs.getString('userName') ?? localization.enterName;
    tariff = _prefs.getString('tariff') ?? '300';
    themeMode = _prefs.getBool('darkTheme') ?? false;
    theme = themeMode ? CustomTheme.darkTheme : CustomTheme.lightTheme;
    driverMode = _prefs.getBool('driverMode') ?? false;
    if (driverMode) {
      carDescr = _prefs.getInt('carDescr') ?? 0;
      carBrand = carDescr & 0xFF;
      carColor = (carDescr >> 8) & 0xFF;
      _carDescrToString();
      seat = '4';
    } else {
      seat = '1';
    }
    String str = File('$appDocDirPath/tashkent_region-places.csv').readAsStringSync();
    List<List<dynamic>> list = fromCsv.convert(str);
    final len = list.length;
    places = List<Place>(len);
    _placesNameUz = List<String>(len);
    _placesNameRu = List<String>(len);
    for (int i = 0; i < len; i++) {
      final row = list[i];
      places[i] = Place(
        nameUz: row[0],
        nameEn: row[1],
        nameRu: row[2],
        lat: row[3],
        lon: row[4],
        districtCode: row[5],
        index: row[6],
        count: 0,
      );
      _placesNameUz[i] = row[0].replaceAll('\'', '').toLowerCase();
      _placesNameRu[i] = row[2].replaceAll('\'', '').toLowerCase();
    }

    if (File(_favoritesPath).existsSync()) {
      str = File(_favoritesPath).readAsStringSync();
      list = fromCsv.convert(str);
      list.forEach((row) => _favorites.add(Place(
          nameUz: row[0],
          nameEn: row[1],
          nameRu: row[2],
          lat: row[3],
          lon: row[4],
          districtCode: row[5],
          index: row[6],
          count: row[7])));
      bodyList = _favorites;
    } else {
      bodyList = [];
    }
  }

  static Future<String> _firstRunDataLoad() async {
    final appDocDirPath =
        await getApplicationDocumentsDirectory().then((value) => value.path).timeout(const Duration(seconds: 15));
    _prefs.setString('appDocDirPath', appDocDirPath);

    final langCode = ui.window.locale.languageCode.substring(0, 2).toLowerCase() ?? 'ru'; // First run language detect
    _prefs.setString('languageCode', langCode).timeout(const Duration(seconds: 30));

    ByteData data = await rootBundle.load('assets/db/favorite-places.csv').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/favorite-places.csv').writeAsBytesSync(data.buffer.asUint8List());

    data = await rootBundle.load('assets/db/tashkent_region-places.csv').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/tashkent_region-places.csv').writeAsBytesSync(data.buffer.asUint8List());

    Directory('$appDocDirPath/tashkent_region-gh/').createSync();
    data = await rootBundle.load('assets/db/tashkent_region-gh/edges').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/tashkent_region-gh/edges').writeAsBytesSync(data.buffer.asUint8List());
    data = await rootBundle.load('assets/db/tashkent_region-gh/geometry').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/tashkent_region-gh/geometry').writeAsBytesSync(data.buffer.asUint8List());
    data = await rootBundle.load('assets/db/tashkent_region-gh/location_index').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/tashkent_region-gh/location_index').writeAsBytesSync(data.buffer.asUint8List());
    data = await rootBundle.load('assets/db/tashkent_region-gh/nodes').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/tashkent_region-gh/nodes').writeAsBytesSync(data.buffer.asUint8List());
    data = await rootBundle.load('assets/db/tashkent_region-gh/properties').timeout(const Duration(seconds: 30));
    File('$appDocDirPath/tashkent_region-gh/properties').writeAsBytesSync(data.buffer.asUint8List());

    return appDocDirPath;
  }

  static void setLanguage(String value) {
    if (value == languageCode) {
      return;
    }
    languageCode = value;
    _prefs.setString('languageCode', value).timeout(const Duration(seconds: 30));
    localization = Localizations.load(value);
    userName = _prefs.getString('userName') ?? localization.enterName;
    if (driverMode) _carDescrToString();
    isCyrillic = languageCode == 'ru' ? true : false;
    setState();
  }

  static void setTheme() {
    themeMode ^= true;
    theme = themeMode ? CustomTheme.darkTheme : CustomTheme.lightTheme;
    _prefs.setBool('darkTheme', themeMode).timeout(const Duration(seconds: 30));
    setState();
  }

  static void setSeat(String value) {
    if (value == seat) return;
    seat = value;
    Service.descrChange();
  }

  static void setTariff(String value) {
    if (value == tariff) return;
    tariff = value;
    _prefs.setString('tariff', value).timeout(const Duration(seconds: 30));
    Service.descrChange();
  }

  static void setUserName(String value) {
    if (value == userName) {
      return;
    }
    userName = value;
    _prefs.setString('userName', value).timeout(const Duration(seconds: 30));
    setState();
  }

  static bool setDriverMode(bool value) {
    if (carDescr == 0 && value) {
      carDescr = _prefs.getInt('carDescr') ?? 0;
      if (carDescr == 0) {
        carBrand = 0;
        carColor = 0;
        return false;
      }
      carBrand = (carDescr & 0x000000FF);
      carColor = (carDescr & 0x0000FF00) >> 8;
      _carDescrToString();
    }
    driverMode = value;
    _prefs.setBool('driverMode', value).timeout(const Duration(seconds: 30));
    seat = value ? '4' : '1';
    setState();
    return true;
  }

  static void setCarDescription() {
    final int value = carBrand | carColor << 8;
    if (value == carDescr || carBrand == 0 || carColor == 0) {
      return;
    }
    carDescrString = '';
    carDescr = value;
    _prefs.setInt('carDescr', value).timeout(const Duration(seconds: 30));
    if (!driverMode) {
      setDriverMode(true);
    }
    _carDescrToString();
    setState();
  }

  static void setCarBrand(String value) {
    carBrand = carBrands.indexOf(value) + 1;
    setState();
  }

  static void setCarColor(String value) {
    carColor = localization.colors.indexOf(value) + 1;
    setState();
  }

  static void _carDescrToString() {
    // if (carBrand > 0) {
    carDescrString = carBrands[carBrand - 1];
    // }
    // if (carColor > 0) {
    carDescrString += '  (' + localization.colors[carColor - 1] + ')';
    // }
  }

  static void favoritesSave() {
    if (_favorites.length == 0 && File(_favoritesPath).existsSync()) {
      File(_favoritesPath).delete();
    } else {
      Place place;
      final len = _favorites.length;
      final list = List<List<dynamic>>(len);
      for (int i = 0; i < len; i++) {
        place = _favorites[i];
        list[i] = [
          place.nameUz,
          place.nameEn,
          place.nameRu,
          place.lat,
          place.lon,
          place.districtCode,
          place.index,
          place.count
        ];
      }
      final csv = _toCsv.convert(list);
      File(_favoritesPath).writeAsString(csv);
    }
  }

  static void favoritePlaceDelete() {
    _favorites.remove(selectedPlace);
    favoritesSave();
  }

  static void favoritesSort() async {
    final index = selectedPlace.index;
    final length = _favorites.length;
    Place place;
    selectedPlace.count++;

    for (int i = 0; i < length; i++) {
      place = _favorites[i];
      if (place.index == index) {
        for (int j = 0; j < i; j++) {
          if (_favorites[j].count <= place.count) {
            _favorites.removeAt(i);
            _favorites.insert(j, place);
            break;
          }
        }
        favoritesSave();
        return;
      }
    }

    if (length >= 30) {
      _favorites.removeLast();
    }

    for (int i = 0; i < length; i++) {
      place = _favorites[i];
      if (place.count <= 1) {
        _favorites.insert(i, selectedPlace);
        favoritesSave();
        return;
      }
    }

    _favorites.add(selectedPlace);
    favoritesSave();
    return;
  }

  static void searchPlace(String text) {
    if (text?.length != null && text.length > 1) {
      text = text.replaceAll('\'', '').toLowerCase();
      bodyList = [];
      final res = BitapMatch.matchAll(text.runes.first > 0x7F ? _placesNameRu : _placesNameUz, text);
      if (res.length > 0) res.forEach((i) => bodyList.add(places[i]));
    } else if (bodyList != _favorites) {
      bodyList = _favorites;
    }
  }
}
