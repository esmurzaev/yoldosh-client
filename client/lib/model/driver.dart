part of service;

class DriverService {
  DriverService._();

  static int _nodeSeq;
  static List<int> _nodes;
  static List<int> _nodesIndexes;
  static List<double> _wayPointsDistance;
  static List<LatLon> _wayPoints;
  static List<LatLon> _clientsPosit;
  static int _clientsNum;
  static int _nodesLength;
  static List<int> _nodeSeqPacket = [0x14, 0];

  static int _accuracyErrCount;
  static int _wayPointsIdx;
  static int _wayPointsIdxNext;
  static double curLat, curLon, distXA, distXB;
  static num bearingXA, bearingXB;

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
    Socket.connect(Configs.serviceHost, Configs.driverPort, timeout: Duration(seconds: 30)).then((socket) {
      socket.setOption(SocketOption.tcpNoDelay, true);
      socket.listen(_socketDataHandler, onDone: Service.socketDoneHandler);
      Service.socket = socket;
      socket.add(Service.getAuthPacket);
      _sendRoutePacket();
    }).catchError((_) => Service.socketErrorHandler());
  }

  static void _sendRoutePacket() {
    final out = <int>[];
    out.add(0x11);
    out.add(_nodes.length);
    out.add(AppModel.getDescr);
    out.add(AppModel.carBrand);
    out.add(AppModel.carColor);
    _nodes.forEach((f) => out.addAll(TypeConvert.int16ToBytes(f)));
    Service.socket.add(out);
    Service.socket.flush();
  }

  static void _sendNodeSeqPacket() {
    _nodeSeqPacket[1] = _nodeSeq;
    _nodeSeq++;
    Service.socket.add(_nodeSeqPacket);
    Service.socket.flush();
  }

  static void _socketDataHandler(List<int> input) {
    switch (input[0]) {
      case 0x21:
        if (input[1] == 0x01) {
          if (!Service.serviceStatus) {
            Service.serviceStatus = true;
            _locationControl();
            Service.notifyProcessScreen(Status.clientSearch);
          }
        }
        break;
      case 0x22:
        if (input[1] == 0x01) {
          _clientsNum = input[2];
          if ((_clientsNum * 10) + 3 > input.length || _clientsNum == 0) {
            return;
          }
          _clientsFoundProcess(input.sublist(3));
        } else if (input[1] == 0x02) {
          Service.notifyProcessScreen(Status.clientCanceled);
          Future.delayed(const Duration(seconds: 30), () {
            if (Service.serviceStatus) {
              Service.notifyProcessScreen(Status.clientSearch);
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

  static _clientsFoundProcess(List<int> buf) {
    double lat, lon;
    Service.clientsDestPlaceIdx = [];
    Service.distanceToClients = [];
    _clientsPosit = [];
    for (int i = 0, pos = 0; i < _clientsNum; i++) {
      lat = TypeConvert.bytesToDouble(buf.sublist(pos, pos + 4));
      lon = TypeConvert.bytesToDouble(buf.sublist(pos + 4, pos + 8));
      _clientsPosit.add(LatLon(lat: lat, lon: lon));
      Service.clientsDestPlaceIdx.add(buf[pos + 9] | buf[pos + 8] << 8);
      Service.distanceToClients.add(Geotools.distance(curLat, curLon, lat, lon).toInt());
      pos += 10;
    }
    Service.distanceToClientsUpdate();
    Service.processOK = true;
    Service.notifyProcessScreen(Status.clientFound);
    Service.distanceToRidersTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      for (int i = 0; i < _clientsNum; i++) {
        final posit = _clientsPosit[i];
        Service.distanceToClients[i] = Geotools.distance(curLat, curLon, posit.lat, posit.lon).toInt();
      }
      Service.distanceToClientsUpdate();
      Service.setState();
    });
    // TODO 120 -> 60
    Future.delayed(const Duration(seconds: 60), () {
      Service.distanceToRidersTimer?.cancel();
      if (Service.serviceStatus) {
        Service.processOK = false;
        Service.processStr2 = '';
        Service.notifyProcessScreen(Status.clientSearch);
        // Service.notifications?.cancelAll();
      }
    });
  }

  static Future<bool> _loadRoute() async {
    final latFrom = Service.currentPos.latitude;
    final lonFrom = Service.currentPos.longitude;
    final latTo = AppModel.selectedPlace.lat;
    final lonTo = AppModel.selectedPlace.lon;
    final res = await Service.georouter.getDriverRoute(Float64List.fromList([latFrom, lonFrom, latTo, lonTo]));
    if (res == null) {
      Service.notifyProcessScreen(Status.routeErr);
      return false;
    }
    if (res.nodes == null) {
      Service.notifyProcessScreen(Status.noRoad);
      return false;
    }
    _nodes = res.nodes;
    _nodesIndexes = res.nodesIndexes;
    final pointList = res.pointList;
    _wayPoints = [];
    int length = pointList.length;
    for (int i = 1; i < length; i += 2) {
      _wayPoints.add(LatLon(lat: pointList[i - 1], lon: pointList[i]));
    }
    Service.routeDistance = res.distance;
    _nodesLength = _nodes.length;
    if (_nodesLength > 255) {
      _nodes.removeRange(255, _nodesLength); // Road length limit ~40km
      _nodesLength = 255;
    }
    _wayPointsDistance = [];
    length = _wayPoints.length;
    for (int i = 1, j = 0; i < length; i++) {
      _wayPointsDistance
          .add(Geotools.distance(_wayPoints[j].lat, _wayPoints[j].lon, _wayPoints[i].lat, _wayPoints[i].lon));
      j = i;
    }
    _nodeSeq = 0;
    return true;
  }

  static void _locationControl() async {
    _accuracyErrCount = 0;
    _wayPointsIdx = 0;
    _wayPointsIdxNext = 1;

    Service.positionStream = getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
      timeInterval: 1000,
      forceAndroidLocationManager: true,
    ).listen((pos) {
      // TODO for testing: 10 -> 30
      if (pos.accuracy > 30) {
        _accuracyErrCount++;
        if (_accuracyErrCount >= 10) {
          Service.notifyProcessScreen(Status.driverLocationWeak);
        }
        return;
      } else if (_accuracyErrCount > 0) {
        if (_accuracyErrCount >= 10) {
          Service.notifyProcessScreen(Status.clientSearch);
        }
        _accuracyErrCount = 0;
      }
      // TODO
      Service.processDebugStr = '\n\ngps accuracy: ' + pos.accuracy.toInt().toString();
      Service.setState();

      curLat = pos.latitude;
      curLon = pos.longitude;

      // distXA = Geotools.distance(_wayPoints[_wayPointsIdx].lat, _wayPoints[_wayPointsIdx].lon, curLat, curLon);
      distXB = Geotools.distance(_wayPoints[_wayPointsIdxNext].lat, _wayPoints[_wayPointsIdxNext].lon, curLat, curLon);

      /*
      if (distXA + 30 < _wayPointsDistance[_wayPointsIdx]) {
      return;
      }
      */

      if (distXB <= 30) {
        if (_nodesIndexes[_nodeSeq] == _wayPointsIdx) {
          if (_nodesLength <= _nodeSeq) {
            Service.processOK = true;
            Service.processCancel();
            Service.notifyProcessScreen(Status.clientSearchEnd);
            return;
          }
          // TODO
          //Service.processDebugStr = '\n\nNode send: ' + _nodes[_nodeSeq].toString();
          //Service.setState();
          _sendNodeSeqPacket();
        }
        _wayPointsIdx++;
        _wayPointsIdxNext = _wayPointsIdx + 1;
      } else {
        /*
        bearingXA = Geotools.bearingBetweenTwoGeoPoints(LatLon(lat: curLat, lon: curLon),
            LatLon(lat: _wayPoints[_wayPointsIdx].lat, lon: _wayPoints[_wayPointsIdx].lon));
        bearingXB = Geotools.bearingBetweenTwoGeoPoints(LatLon(lat: curLat, lon: curLon),
            LatLon(lat: _wayPoints[_wayPointsIdxNext].lat, lon: _wayPoints[_wayPointsIdxNext].lon));

        num res = (bearingXA - bearingXB).abs();
        print(res);
        if ((res < 160 || res > 200) && _wayPointsDistance[_wayPointsIdx] < (distXA + distXB - 30)) {
        */
        distXA = Geotools.distance(_wayPoints[_wayPointsIdx].lat, _wayPoints[_wayPointsIdx].lon, curLat, curLon);

        // Out of road control
        if (_wayPointsDistance[_wayPointsIdx] < (distXA + distXB - 60)) {
          bool outOfRoad = true;
          final length = _wayPoints.length - 1;
          for (int i = _wayPointsIdx + 1; i < length; i++) {
            distXA = Geotools.distance(_wayPoints[i].lat, _wayPoints[i].lon, curLat, curLon);
            distXB = Geotools.distance(_wayPoints[i + 1].lat, _wayPoints[i + 1].lon, curLat, curLon);
            /*
            bearingXA = Geotools.bearingBetweenTwoGeoPoints(
                LatLon(lat: curLat, lon: curLon), LatLon(lat: _wayPoints[i].lat, lon: _wayPoints[i].lon));
            bearingXB = Geotools.bearingBetweenTwoGeoPoints(
                LatLon(lat: curLat, lon: curLon), LatLon(lat: _wayPoints[i + 1].lat, lon: _wayPoints[i + 1].lon));
            res = (bearingXA - bearingXB).abs();
            if ((res >= 160 && res <= 200) || (_wayPointsDistance[i] >= (distXA + distXB - 30))) {
            */
            if (_wayPointsDistance[i] >= (distXA + distXB - 60)) {
              _wayPointsIdx = i;
              _wayPointsIdxNext = i + 1;
              outOfRoad = false;
              for (int j = _nodeSeq; j < _nodesLength; j++) {
                if (_nodesIndexes[j] >= i) {
                  _nodeSeq = j;
                  break;
                }
              }
              // TODO
              //Service.processDebugStr = '\n\nRoute corrected!';
              //Service.setState();
              break;
            }
          }

          if (outOfRoad) {
            Service.positionStream?.cancel();
            Service.currentPos = pos;
            _loadRoute().then((value) {
              if (value && Service.serviceStatus) {
                Service.serviceStatus = false;
                _sendRoutePacket();
                // TODO
                //Service.processDebugStr = '\n\nRoute reloaded!';
                //Service.setState();
              } else {
                Service.processCancel();
              }
            });
            return;
          }
        }
      }
    });
  }
}
