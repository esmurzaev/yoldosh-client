import 'dart:math' as math;

/// The PI constant.
// const double PI = math.pi;

/// Converts degree to radian
// double degToRadian(final double deg) => deg * (PI / 180.0);

/// Radian to degree
// double radianToDeg(final double rad) => rad * (180.0 / PI);

class LatLon {
  const LatLon({this.lat, this.lon});
  final double lat;
  final double lon;
}

/// The main geodesy class
class Geotools {
  Geotools._();
  /*
  /// check if a given geo point is in the bouding box
  static bool isGeoPointInBoudingBox(LatLon l, LatLon topLeft, LatLon bottomRight) {
    return topLeft.lat <= l.lat && l.lat <= bottomRight.lat && topLeft.lon <= l.lon && l.lon <= bottomRight.lon ? true : false;
  }
  */

  /// check if a given geo point is in the a polygon
  /// using even-odd rule algorithm
  static bool isGeoPointInPolygon(LatLon l, List<LatLon> polygon) {
    bool isInPolygon = false;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((((polygon[i].lat <= l.lat) && (l.lat < polygon[j].lat)) ||
              ((polygon[j].lat <= l.lat) && (l.lat < polygon[i].lat))) &&
          (l.lon <
              (polygon[j].lon - polygon[i].lon) * (l.lat - polygon[i].lat) / (polygon[j].lat - polygon[i].lat) +
                  polygon[i].lon)) isInPolygon = !isInPolygon;
    }
    return isInPolygon;
  }

  /*
  /// calculate the bearing from point l1 to point l2
  static num bearingBetweenTwoGeoPoints(LatLon l1, LatLon l2) {
    num l1LatRadians = degToRadian(l1.lat);
    num l2LatRadians = degToRadian(l2.lat);
    num lngRadiansDiff = degToRadian(l2.lon - l1.lon);
    num y = math.sin(lngRadiansDiff) * math.cos(l2LatRadians);
    num x = math.cos(l1LatRadians) * math.sin(l2LatRadians) -
        math.sin(l1LatRadians) * math.cos(l2LatRadians) * math.cos(lngRadiansDiff);
    num radians = math.atan2(y, x);

    return (radianToDeg(radians as double) + 360) % 360;
  }

  /// calculate the final bearing from point l1 to point l2
  static num finalBearingBetweenTwoGeoPoints(LatLon l1, LatLon l2) {
    return (bearingBetweenTwoGeoPoints(l2, l1) + 180) % 360;
  }
  */

  // returns routeDistance in meters
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    final double a = (lat1 - lat2) * _distPerLat(lat1);
    final double b = (lon1 - lon2) * _distPerLon(lat1);
    return math.sqrt(a * a + b * b);
  }

  static double _distPerLat(double lat) {
    return -0.000000487305676 * math.pow(lat, 4) -
        0.0033668574 * math.pow(lat, 3) +
        0.4601181791 * lat * lat -
        1.4558127346 * lat +
        110579.25662316;
  }

  static double _distPerLon(double lat) {
    return 0.0003121092 * math.pow(lat, 4) +
        0.0101182384 * math.pow(lat, 3) -
        17.2385140059 * lat * lat +
        5.5485277537 * lat +
        111301.967182595;
  }
}
