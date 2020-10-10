part of service;

class ClientService {
  ClientService._();

  static int _nodeA, _nodeAOld;
  static List<int> _nodeBs;
  static int accuracyErrCount = 0;
  static int speedCount = 0;

  static void processStart() {
    _loadRoute().then((value) {
      if (value && Service.processStatus) {
        Service.notifyProcessScreen(Status.connToServer);
        connect();
      } else {
        Service.processStatus = false;
      }
    });
  }

  static void connect() {
    // TODO testing => second: 30 -> 5
    Socket.connect(Configs.serviceHost, Configs.clientPort, timeout: Duration(seconds: 30)).then((socket) {
      socket.setOption(SocketOption.tcpNoDelay, true);
      socket.listen(_socketDataHandler, onDone: Service.socketDoneHandler);
      Service.socket = socket;
      socket.add(Service.getAuthPacket);
      _sendRouteReqPacket();
    }).catchError((_) => Service.socketErrorHandler());
  }

  static void _sendRouteReqPacket() {
    final out = <int>[];
    out.add(0x11);
    out.add(_nodeBs.length);
    out.add(AppModel.getDescr);
    out.addAll(TypeConvert.positionToBytes(Service.currentPos.latitude, Service.currentPos.longitude));
    out.addAll(TypeConvert.int16ToBytes(AppModel.selectedPlace.index));
    out.addAll(TypeConvert.int16ToBytes(_nodeA));
    _nodeBs.forEach((f) => out.addAll(TypeConvert.int16ToBytes(f)));
    Service.socket.add(out);
    Service.socket.flush();
  }

  static void _socketDataHandler(List<int> input) {
    switch (input[0]) {
      case 0x21:
        if (input[1] == 0x01) {
          if (!Service.serviceStatus) {
            Service.serviceStatus = true;
            _locationControl();
            Service.notifyProcessScreen(Status.carWait);
          }
        }
        break;
      case 0x22:
        if (input[1] == 0x01) {
          if (input[2] > 10 || (input[3] == 0 && input[3] > 40) || (input[4] == 0 && input[4] > 15)) {
            return;
          }
          Service.price = (input[2] * 100 * Service.routeDistance).toInt();
          Service.foundedCarName = carBrands[input[3] - 1];
          Service.foundedCarName += '  (' + AppModel.localization.colors[input[4] - 1] + ')';
          Service.processOK = true;
          Service.processCancel();
          Service.notifyProcessScreen(Status.carFound);
        } else if (input[1] == 0x02) {
          Service.processOK = false;
          Service.notifyProcessScreen(Status.driverCanceled);
          Future.delayed(const Duration(seconds: 30), () {
            if (Service.serviceStatus) {
              Service.notifyProcessScreen(Status.carWait);
            }
          });
        }
        break;
      case 0x40:
        Service.processCancel();
        if (input[1] == 0x01) {
          Service.notifyProcessScreen(Status.isOldApp);
        } else if (input[1] == 0x02) {
          Service.notifyProcessScreen(Status.timeStampErr);
        }
        break;
    }
  }

  static Future<bool> _loadRoute() async {
    final latFrom = Service.currentPos.latitude; // 41.3443; // 41.3455;
    final lonFrom = Service.currentPos.longitude; // 69.3668; // 69.3637;
    final latTo = AppModel.selectedPlace.lat;
    final lonTo = AppModel.selectedPlace.lon;
    // final start = DateTime.now();
    final res = await Service.georouter.getClientRoute(Float64List.fromList([latFrom, lonFrom, latTo, lonTo]));
    // print(DateTime.now().difference(start).inMilliseconds);
    if (res == null) {
      Service.notifyProcessScreen(Status.routeErr);
      return false;
    } else if (res.nodeA == null) {
      Service.notifyProcessScreen(Status.noRoad);
      return false;
    }
    _nodeA = res.nodeA;
    _nodeBs = res.nodeBs;
    Service.routeDistance = res.distance;
    Service.price =
        ((Service.routeDistance * int.parse(AppModel.seat))).toInt() * int.parse(AppModel.tariff) + Configs.seatPrice;
    /*
    Directory downl = await DownloadsPathProvider.downloadsDirectory;
    List<String> route = res['routes'].cast<String>();
    int pathCount = 0;
    route.forEach((r) {
      pathCount++;
      File(downl.path + '/route_' + pathCount.toString() + '.gpx').writeAsStringSync(r, flush: true);
    });
    pathCount = 0;
    */
    return true;
  }

  static void _locationControl() async {
    accuracyErrCount = 0;
    speedCount = 0;
    Service.startPos = Service.currentPos;
    Service.locationTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (DateTime.now().difference(Service.currentPos.timestamp).inSeconds > 59) {
        if (!await isLocationServiceEnabled().timeout(Duration(seconds: 15))) {
          Service.processCancel();
          Service.notifyProcessScreen(Status.noLocation);
        }
      }
    });
    // TODO testing => distanceFilter: 2 -> 0
    Service.positionStream = getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeInterval: 3000,
      forceAndroidLocationManager: true,
    ).listen((pos) {
      // TODO
      Service.processDebugStr = '\n\ngps accuracy: ' + pos.accuracy.toInt().toString();
      Service.setState();
      Service.currentPos = pos;
      // TODO for testing: 10 -> 30
      if (pos.accuracy > 30) {
        accuracyErrCount++;
        // TODO
        Service.processDebugStr += '\naccuracy errors: ' + accuracyErrCount.toString();
        Service.setState();
        if (accuracyErrCount == 10) {
          Service.notifyProcessScreen(Status.clientLocationWeak);
        } else if (accuracyErrCount >= 180) {
          Service.processCancel();
        }
        return;
      }
      if (accuracyErrCount >= 10) {
        Service.notifyProcessScreen(Status.carWait);
      }
      accuracyErrCount = 0;
      // speed control
      if (pos.speed > 5) {
        speedCount++;
        if (speedCount > 5) {
          Service.processCancel();
          Service.closeProcessScreen();
          return;
        }
      } else {
        speedCount = 0;
      }
      if (Geotools.distance(Service.startPos.latitude, Service.startPos.longitude, pos.latitude, pos.longitude) > 20) {
        Service.startPos = pos;
        _nodeAOld = _nodeA;
        _loadRoute().then((value) {
          if (value && Service.serviceStatus) {
            if (_nodeAOld != _nodeA) {
              _sendRouteReqPacket();
            }
          } else {
            Service.processCancel();
          }
        });
      }
    });
  }
}
