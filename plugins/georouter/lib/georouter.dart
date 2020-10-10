import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class Georouter {
  static const MethodChannel _channel = const MethodChannel('georouter');

  Future<ClientRoute> getClientRoute(Float64List req) async {
    final Map<String, dynamic> result = await _channel.invokeMapMethod('getClientRoute', req);
    if (result == null) {
      return null;
    } else if (result.length == 0) {
      return ClientRoute();
    }
    return ClientRoute(
      nodeA: result['nodeA'],
      nodeBs: result['nodeBs'].cast<int>(),
      distance: (result['distance'] / 100).round() / 10, // 12345meter -> 12.345km -> 12.3km
    );
  }

  Future<DriverRoute> getDriverRoute(Float64List req) async {
    final Map<String, dynamic> result = await _channel.invokeMapMethod('getDriverRoute', req);
    if (result == null) {
      return null;
    } else if (result.length == 0) {
      return DriverRoute();
    }
    return DriverRoute(
      nodes: result['nodes'].cast<int>(),
      nodesIndexes: result['nodesIndexes'].cast<int>(),
      pointList: result['points'].cast<double>(),
      distance: (result['distance'] / 100).round() / 10, // 12345meter -> 12.345km -> 12.3km
    );
  }
}

class ClientRoute {
  const ClientRoute({this.nodeA, this.nodeBs, this.distance});
  // final bool found;
  final int nodeA;
  final List<int> nodeBs;
  final double distance;
}

class DriverRoute {
  const DriverRoute({this.nodes, this.nodesIndexes, this.pointList, this.distance});
  // final bool found;
  final List<int> nodes;
  final List<int> nodesIndexes;
  final List<double> pointList;
  final double distance;
}
