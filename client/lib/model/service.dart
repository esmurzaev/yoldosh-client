library service;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity/connectivity.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:georouter/georouter.dart';

import '../common/car.dart';
import '../common/configs.dart';
import '../common/polygon.dart';
import '../common/utils/geotools.dart';
import '../common/utils/type_convert.dart';
import 'app.dart';

part 'client.dart';
part 'driver.dart';

enum Status {
  noConn,
  noLocation,
  locationDet,
  outOfArea,
  noRoad,
  routeErr,
  connToServer,
  noService,
  connError,
  carWait,
  driverCanceled,
  carFound,
  clientSearch,
  clientFound,
  clientCanceled,
  clientSearchEnd,
  clientLocationWeak,
  driverLocationWeak,
  isOldApp,
  timeStampErr,
}

class Service {
  Service._();

  static final List<LatLon> _polygon = polygon.map((element) => LatLon(lon: element[0], lat: element[1])).toList();
  static final _encrypter =
      Encrypter(AES(Key(Uint8List.fromList(Configs.masterKey)), mode: AESMode.cbc, padding: null));
  static final _nonce = TypeConvert.int32ToBytes(Random().nextInt(0xFFFFFFFF));
  static void Function() setState;
  static void Function() closeProcessScreen;
  static String processStr = '';
  static String processStr2 = '';
  static String processDebugStr = '';
  static String foundedCarName;
  static bool progress = true;
  static bool processStatus = false;
  static bool processOK = false;
  static bool serviceStatus = false;
  static double routeDistance;
  static int price;
  static int _socketErrCount = 0;
  static List<int> distanceToClients;
  static List<int> clientsDestPlaceIdx;
  static Socket socket;
  static Timer locationTimer;
  static Timer distanceToRidersTimer;
  static final _connectivity = Connectivity();
  static final _netChecker = DataConnectionChecker();
  static final notifications = FlutterLocalNotificationsPlugin()
    ..initialize(
        InitializationSettings(AndroidInitializationSettings('@mipmap/ic_launcher'), IOSInitializationSettings()));
  static final georouter = Georouter();
  static StreamSubscription<ConnectivityResult> _connChangedSubscription;
  static StreamSubscription<Position> positionStream;
  static Position currentPos;
  static Position startPos;
  static final vibrationPattern = Int64List.fromList([1800, 400, 1800, 600]);

  static List<int> get getAuthPacket {
    final timeStamp = TypeConvert.int32ToBytes((DateTime.now().millisecondsSinceEpoch ~/ 1000).toInt());
    final input = <int>[];
    final out = <int>[];
    input.addAll(Configs.masterCode);
    input.addAll(timeStamp);
    input.addAll(_nonce);
    out.add(0x01);
    out.addAll(_encrypter.encryptBytes(input, iv: IV.fromLength(16)).bytes);
    return out;
  }

  static _showNotification(String title, String body) {
    final android = AndroidNotificationDetails('yoldosh_id', 'yoldosh_channel', 'yoldosh_description',
        importance: Importance.High,
        priority: Priority.High,
        ticker: 'yoldosh_ticker',
        timeoutAfter: 180000,
        icon: 'notification_icon',
        // vibrationPattern: AppModel.driverMode ? null : vibrationPattern,
        vibrationPattern: vibrationPattern,
        sound: RawResourceAndroidNotificationSound('open_your_eyes_and_see'));
    final iOS = IOSNotificationDetails(sound: 'slow_spring_board.aiff');
    final platformChannelSpecifics = NotificationDetails(android, iOS);
    notifications.show(0, title, body, platformChannelSpecifics).timeout(Duration(seconds: 30));
  }

  static void descrChange() {
    if (!serviceStatus || processOK) return;
    _sendDescrPacket();
    if (AppModel.driverMode) return;
    price = ((routeDistance * int.parse(AppModel.seat))).toInt() * int.parse(AppModel.tariff) + Configs.seatPrice;
    notifyProcessScreen(Status.carWait);
  }

  static void _sendDescrPacket() {
    List<int> buf = [];
    buf.add(0x12);
    buf.add(AppModel.getDescr);
    socket.add(buf);
    socket.flush();
  }

  static void socketDoneHandler() {
    if (!processStatus) {
      return;
    }
    if (!processOK) {
      notifyProcessScreen(Status.connError);
    }
    processCancel();
    /*
    Timer.periodic(const Duration(minutes: 30), (timer) {
      timer.cancel();
      if (!processStatus) closeProcessScreen();
    });
    */
  }

  static void socketErrorHandler() async {
    if (processOK) {
      processCancel();
      return;
    } else if (processStatus) {
      _socketErrCount++;
      if (_socketErrCount >= 3) {
        processCancel();
        notifyProcessScreen(Status.noService);
        return;
      }
      if (await _connectivity.checkConnectivity() != ConnectivityResult.none &&
          await _netChecker.hasConnection &&
          processStatus) {
        AppModel.driverMode ? DriverService.connect() : ClientService.connect();
      } else if (processStatus) {
        processCancel();
        notifyProcessScreen(Status.noConn);
      }
    }
  }

  static void _processInit() async {
    int speedCount = 0;
    bool locationStatus = false;
    if (await _connectivity.checkConnectivity() == ConnectivityResult.none) {
      notifyProcessScreen(Status.noConn);
      _connChangedSubscription = _connectivity.onConnectivityChanged.listen((onData) {
        if (processStatus && onData != ConnectivityResult.none) {
          _connChangedSubscription?.cancel();
          _processInit();
        }
      });
      return;
    }
    if (await isLocationServiceEnabled().timeout(Duration(seconds: 10))) {
      locationStatus = true;
      notifyProcessScreen(Status.locationDet);
    } else {
      notifyProcessScreen(Status.noLocation);
    }
    positionStream = getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeInterval: 1000,
      forceAndroidLocationManager: true,
      timeLimit: const Duration(minutes: 10),
    ).listen((pos) {
      Service.processDebugStr = '\n\ngps accuracy: ' + pos.accuracy.toInt().toString();
      setState();
      // TODO testing => accuracy: 15 -> 50
      if (pos.accuracy > 50) {
        if (!locationStatus) {
          locationStatus = true;
          notifyProcessScreen(Status.locationDet);
        }
        return;
      }
      // speed control
      if (pos.speed > 5 && !AppModel.driverMode) {
        speedCount++;
        if (speedCount > 5) {
          processStatus = false;
          positionStream?.cancel();
          closeProcessScreen();
        }
        return;
      }
      positionStream?.cancel();
      if (!Geotools.isGeoPointInPolygon(LatLon(lat: pos.latitude, lon: pos.longitude), _polygon)) {
        notifyProcessScreen(Status.outOfArea);
        processStatus = false;
        return;
      }
      currentPos = pos;
      AppModel.driverMode ? DriverService.processStart() : ClientService.processStart();
    });
  }

  static void processStart() {
    processStatus = true;
    serviceStatus = false;
    processOK = false;
    processStr = '';
    processStr2 = '';
    AppModel.favoritesSort();
    _processInit();
  }

  static void processCancel() {
    if (!processStatus) {
      if (processOK) {
        processOK = false;
        notifications?.cancelAll();
      }
      return;
    }
    locationTimer?.cancel();
    processStatus = false;
    serviceStatus = false;
    _socketErrCount = 0;
    socket?.destroy();
    // socket?.close();
    _connChangedSubscription?.cancel();
    positionStream?.cancel();
    distanceToRidersTimer?.cancel();
  }

  static void distanceToClientsUpdate() {
    distanceToClients.sort();
    processStr = AppModel.localization.clientFound +
        '\n\n' +
        distanceToClients
            .map((f) => f.toString() + ' M')
            .toString()
            .replaceFirst('(', '')
            .replaceFirst(')', '')
            .replaceAll(',', ' /');
    // setState();
  }

  static void notifyProcessScreen(Status status) {
    switch (status) {
      // Notifyes for client mode
      case Status.noConn:
        processStr = AppModel.localization.noConn;
        progress = false;
        break;
      case Status.noLocation:
        processStr = AppModel.localization.noLocation;
        progress = false;
        break;
      case Status.locationDet:
        processStr = AppModel.localization.locationDet;
        progress = true;
        break;
      case Status.outOfArea:
        processStr = AppModel.localization.outOfArea;
        progress = false;
        break;
      case Status.noRoad:
        processStr = AppModel.localization.noRoad;
        progress = false;
        break;
      case Status.routeErr:
        processStr = AppModel.localization.routeErr;
        progress = false;
        break;
      case Status.connToServer:
        processStr = AppModel.localization.connToServer;
        progress = true;
        break;
      case Status.noService:
        processStr = AppModel.localization.noService;
        progress = false;
        break;
      case Status.connError:
        processStr = AppModel.localization.connError;
        progress = false;
        break;
      case Status.carWait:
        processStr = AppModel.localization.carWait +
            '\n\n' +
            price.toString() +
            AppModel.localization.sum +
            ' / ' +
            routeDistance.toString() +
            AppModel.localization.km;
        progress = true;
        break;
      case Status.driverCanceled:
        processStr = AppModel.localization.driverCanceled;
        break;
      case Status.carFound:
        processStr = AppModel.localization.carFound +
            '\n\n' +
            foundedCarName +
            '\n\n' +
            price.toString() +
            AppModel.localization.sum +
            ' / ' +
            routeDistance.toString() +
            AppModel.localization.km;
        progress = false;
        _showNotification(AppModel.localization.carFound, Service.foundedCarName);
        break;

      // Notifyes for driver mode
      case Status.clientSearch:
        processStr = AppModel.localization.clientSearch;
        progress = true;
        break;
      case Status.clientFound:
        processStr2 = '\n' +
            clientsDestPlaceIdx
                .map((f) => '\n' + (AppModel.isCyrillic ? AppModel.places[f].nameRu : AppModel.places[f].nameUz))
                .toString()
                .replaceFirst('(', '')
                .replaceFirst(')', '')
                .replaceAll(',', '');
        _showNotification(AppModel.localization.clientFound, processStr2.trimLeft());
        progress = false;
        break;
      case Status.clientCanceled:
        processStr = AppModel.localization.clientCanceled;
        break;
      case Status.clientSearchEnd:
        processStr = AppModel.localization.clientSearchEnd;
        progress = false;
        break;
      case Status.clientLocationWeak:
        processStr = AppModel.localization.clientLocationWeak;
        progress = false;
        break;
      case Status.driverLocationWeak:
        processStr = AppModel.localization.driverLocationWeak;
        progress = false;
        break;

      // For app error
      case Status.isOldApp:
        processStr = AppModel.localization.isOldApp;
        progress = false;
        break;
      case Status.timeStampErr:
        processStr = AppModel.localization.timeStampErr;
        progress = false;
        break;
    }
    setState();
  }
}
