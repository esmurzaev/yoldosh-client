package uz.meteor.georouter;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


import java.lang.String;
import java.lang.Integer;
import java.lang.Double;
import java.lang.Math;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;


import com.graphhopper.util.PointList;
import com.graphhopper.util.EdgeIteratorState;
import com.graphhopper.storage.BaseGraph;
import com.graphhopper.storage.GraphExtension;
import com.graphhopper.storage.DAType;
import com.graphhopper.storage.GHDirectory;
import com.graphhopper.storage.index.LocationIndexTree;
import com.graphhopper.storage.index.QueryResult;
import com.graphhopper.storage.index.QueryResult.Position;
import com.graphhopper.routing.Path;
import com.graphhopper.routing.QueryGraph;
import com.graphhopper.routing.AStarBidirection;
import com.graphhopper.routing.AlternativeRoute;
import com.graphhopper.routing.util.FlagEncoder;
import com.graphhopper.routing.util.EncodingManager;
import com.graphhopper.routing.util.DefaultFlagEncoderFactory;
import com.graphhopper.routing.util.EdgeFilter;
import com.graphhopper.routing.util.TraversalMode;
import com.graphhopper.routing.weighting.FastestWeighting;
import com.graphhopper.routing.profiles.DefaultEncodedValueFactory;
import com.graphhopper.util.shapes.GHPoint3D;


public class GeorouterPlugin implements MethodCallHandler {
  private static String graphFolder;
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "georouter");
    channel.setMethodCallHandler(new GeorouterPlugin());
    graphFolder = registrar.context().getApplicationInfo().dataDir + "/app_flutter/tashkent_region-gh/";
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getClientRoute")) {
      result.success(getClientRoute((double[]) call.arguments));
    } else if (call.method.equals("getDriverRoute")) {
      result.success(getDriverRoute((double[]) call.arguments));
    } else {
      // result.notImplemented();
      result.success(null);
    }
  }

  private static final String flagEncoders = "car|speed_factor=5.0|speed_bits=5|turn_costs=false|version=2";
  private static final String encodedValues = "roundabout|version=283388307|bits=1|index=0|shift=0|store_both_directions=false,"
  + "road_class|version=888755028|bits=5|index=0|shift=1|store_both_directions=false,"
  + "road_class_link|version=146075245|bits=1|index=0|shift=6|store_both_directions=false,"
  + "max_speed|version=1224181345|bits=5|index=0|shift=7|store_both_directions=true";

  public Map<String, Object> getClientRoute(final double[] req) {
    GHDirectory dir = new GHDirectory(graphFolder, DAType.MMAP_RO);
    BaseGraph graph = new BaseGraph(dir, new GraphExtension.NoOpExtension());
    graph.loadExisting();
    LocationIndexTree index = new LocationIndexTree(graph, dir);
    index.loadExisting();
    QueryResult fromQR = index.findClosest(req[0], req[1], EdgeFilter.ALL_EDGES);
    QueryResult toQR = index.findClosest(req[2], req[3], EdgeFilter.ALL_EDGES);
    index.close();
    if (!fromQR.isValid() || !toQR.isValid()) {
      graph.close();
      return null;
    }
    // Control out of road, for start point
    // TODO testing: 15 -> 50
    if (fromQR.getQueryDistance() > 50) {
      graph.close();
      return new HashMap<>(); // pointA out of road to 15m
    }
    QueryGraph queryGraph = new QueryGraph(graph);
    queryGraph.lookup(fromQR, toQR);
    queryGraph.enforceHeading(fromQR.getClosestNode(), bearing(req[0], req[1], req[2], req[3]), false);
    queryGraph.enforceHeading(toQR.getClosestNode(), bearing(req[2], req[3], req[0], req[1]), true);
    EncodingManager encodingManager = EncodingManager.start()
      .addAll(new DefaultEncodedValueFactory(), encodedValues)
      .addAll(new DefaultFlagEncoderFactory(), flagEncoders)
      .build();
    FlagEncoder encoder = encodingManager.getEncoder("car");
    AlternativeRoute algo = new AlternativeRoute(queryGraph, new FastestWeighting(encoder), TraversalMode.NODE_BASED);
    algo.setMaxPaths(8);
    // algo.setMaxVisitedNodes(10000000);
    // algo.setMaxExplorationFactor(2);
    // algo.setMaxWeightFactor(2);
    // algo.setMaxShareFactor(2);
    // algo.setMinPlateauFactor(0.1);
    List<Path> paths = algo.calcPaths(fromQR.getClosestNode(), toQR.getClosestNode());
    int pathsLen = paths.size();
    if (pathsLen == 0) {
      graph.close();
      return null;
    }
    // System.out.println("Alt route: " + String.valueOf(pathsLen));
    // System.out.println("Visited nodes: " + String.valueOf(algo.getVisitedNodes()));
    // Extract start node
    Path path = paths.get(0);
    List<EdgeIteratorState> edges = path.calcEdges();
    EdgeIteratorState edge;
    PointList pointList;
    double lat = req[0];
    double lon = req[1];
    double distXA;
    double distXB;
    int length;
    int idx = 0;
    int nodeA;
    List<Integer> nodeBs = new ArrayList<>();

    // control start point turn
    for (int i = 0, len = edges.size(); i < len; i++) {
      edge = edges.get(i);
      pointList = edge.fetchWayGeometry(3);
      length = pointList.size()-1;
      distXA = distance(pointList.getLat(0), pointList.getLon(0), lat, lon);
      distXB = distance(pointList.getLat(length), pointList.getLon(length), lat, lon);
      if (edge.getDistance() > (distXA + distXB - 50)) {
        idx = i;
      // } else if (distXB > 3000) {
        // break;
      }
    }
    edge = edges.get(idx);
    if (idx == 0) {
      int adjNode = edge.getAdjNode();
      edge = fromQR.getClosestEdge();
      nodeA = edge.getBaseNode();
      if (nodeA == adjNode) {
        nodeA = edge.getAdjNode();
      }
    } else {
      nodeA = edge.getBaseNode();
    }

    //Extract end node(s)
    GHPoint3D point = toQR.getSnappedPoint();
    lat = point.getLat();
    lon = point.getLon();
    idx = 0;
    if (pathsLen == 1) {
      for (int j = edges.size()-1; j > 0; j--) {
          edge = edges.get(j);
          pointList = edge.fetchWayGeometry(1);
          distXB = distance(pointList.getLat(0), pointList.getLon(0), lat, lon);
          if (distXB < 1200) {
            idx = j;
          } else if (distXB > 3000) {
            break;
          }
        }
        if (idx == 0) {
          idx = edges.size()-1;
        }
        edge = edges.get(idx);
        nodeBs.add(edge.getBaseNode());
    } else {
      List<List<EdgeIteratorState>> edgesList = new ArrayList<List<EdgeIteratorState>>();
      for (int i = 0; i < pathsLen; i++) {
        path = paths.get(i);
        edges = path.calcEdges();
        edgesList.add(edges);
      }
      for (int i = 0; i < pathsLen || i == 3;) {
        edges = edgesList.get(i);
        length = edges.size();
        for ( int j = length-1; j > 0; j--) {
          edge = edges.get(j);
          pointList = edge.fetchWayGeometry(1);
          distXB = distance(pointList.getLat(0), pointList.getLon(0), lat, lon);
          if (distXB < 1200) {
            idx = j;
          } else if (distXB > 3000) {
            break;
          }
        }
        if (idx == 0) {
          idx = length-1;
        }
        edge = edges.get(idx);
        nodeBs.add(edge.getBaseNode());
        // pointList = edge.fetchWayGeometry(1);
        // System.out.println("NodesB point: " + String.valueOf(pointList.getLat(0)) + " " + String.valueOf(pointList.getLon(0)));
        i++;
        if (i == pathsLen) {
          break;
        }
        idx = length - idx;
        for (int j = i; j < pathsLen;) {
          edges = edgesList.get(j);
          if (edge.getEdge() == edges.get(edges.size() - idx).getEdge()) {
            if (pathsLen - i == 1) {
              pathsLen = 0;
              break;
            }
            edgesList.remove(j);
            pathsLen--;
          } else {
            j++;
          }
        }
      }
    }
    // System.out.println("NodesB: " + String.valueOf(nodeBs));
    // Exit config
    graph.close();
    Map<String, Object> out = new HashMap<>();
    path = paths.get(0);
    out.put("distance", path.getDistance());
    out.put("nodeA", nodeA);
    out.put("nodeBs", nodeBs);
    return out;
  }

  //###############################################################################################

  public Map<String, Object> getDriverRoute(final double[] req) {
    GHDirectory dir = new GHDirectory(graphFolder, DAType.MMAP_RO);
    BaseGraph graph = new BaseGraph(dir, new GraphExtension.NoOpExtension());
    graph.loadExisting();
    LocationIndexTree index = new LocationIndexTree(graph, dir);
    index.loadExisting();
    QueryResult fromQR = index.findClosest(req[0], req[1], EdgeFilter.ALL_EDGES);
    QueryResult toQR = index.findClosest(req[2], req[3], EdgeFilter.ALL_EDGES);
    index.close();
    if (!fromQR.isValid() || !toQR.isValid()) {
      graph.close();
      return null;
    }
    QueryGraph queryGraph = new QueryGraph(graph);
    queryGraph.lookup(fromQR, toQR);
    queryGraph.enforceHeading(fromQR.getClosestNode(), bearing(req[0], req[1], req[2], req[3]), false);
    queryGraph.enforceHeading(toQR.getClosestNode(), bearing(req[2], req[3], req[0], req[1]), true);
    EncodingManager encodingManager = EncodingManager.start()
      .addAll(new DefaultEncodedValueFactory(), encodedValues)
      .addAll(new DefaultFlagEncoderFactory(), flagEncoders)
      .build();
    FlagEncoder encoder = encodingManager.getEncoder("car");
    AStarBidirection algo = new AStarBidirection(queryGraph, new FastestWeighting(encoder), TraversalMode.NODE_BASED);
    Path path = algo.calcPath(fromQR.getClosestNode(), toQR.getClosestNode());
    if (!path.isFound()) {
      graph.close();
      return null;
    }

    // Process
    List<Integer> nodes = new ArrayList<Integer>();
    List<Integer> nodesIndexes = new ArrayList<Integer>();
    List<Double> points = new ArrayList<Double>();
    List<EdgeIteratorState> edges = path.calcEdges();
    GHPoint3D point = fromQR.getSnappedPoint();
    double lat = point.getLat();
    double lon = point.getLon();
    int idx = 0;
    if (fromQR.getQueryDistance() > 5) {
      points.add(req[0]);
      points.add(req[1]);
      idx++;
    }
    points.add(lat);
    points.add(lon);
    if (fromQR.getSnappedPosition() == Position.TOWER) {
      nodesIndexes.add(idx);
      idx++;
    }
    if (toQR.getSnappedPosition() != Position.TOWER) {
      edges.remove(edges.size() - 1);
    }

    for (EdgeIteratorState edge : edges) {
      nodes.add(edge.getAdjNode());
      PointList pointList = edge.fetchWayGeometry(2);
      int length = pointList.size();
      int i = 0;
      for (; i < length; i++) {
        points.add(pointList.getLat(i));
        points.add(pointList.getLon(i));
      }
      idx += i-1;
      nodesIndexes.add(idx);
      idx++;
    }

    // Exit config
    graph.close();
    Map<String, Object> out = new HashMap<>();
    out.put("distance", path.getDistance());
    out.put("nodes", nodes);
    out.put("nodesIndexes", nodesIndexes);
    out.put("points", points);
    return out;
  }

  List<Double> getSnapPosition(final double[] req) {
    GHDirectory dir = new GHDirectory(graphFolder, DAType.MMAP_RO);
    BaseGraph graph = new BaseGraph(dir, new GraphExtension.NoOpExtension());
    graph.loadExisting();
    LocationIndexTree index = new LocationIndexTree(graph, dir);
    index.loadExisting();
    QueryResult toQR = index.findClosest(req[0], req[1], EdgeFilter.ALL_EDGES);
    index.close();
    graph.close();
    if (!toQR.isValid()) {
      return null;
    }
    GHPoint3D point = toQR.getSnappedPoint();
    List<Double> points = new ArrayList<Double>();
    points.add(point.getLat());
    points.add(point.getLon());
    return points;
  }

  // returns distance in meters
  private static double distance(double lat1, double lon1, double lat2, double lon2) {
   double a = (lat1-lat2)*distPerLat(lat1);
   double b = (lon1-lon2)*distPerLon(lat1);
   return Math.sqrt(a*a+b*b);
  }

  private static double distPerLat(double lat) {
    return -0.000000487305676*Math.pow(lat, 4)
      -0.0033668574*Math.pow(lat, 3)
      +0.4601181791*lat*lat
      -1.4558127346*lat+110579.25662316;
  }

  private static double distPerLon(double lat) {
    return 0.0003121092*Math.pow(lat, 4)
      +0.0101182384*Math.pow(lat, 3)
      -17.2385140059*lat*lat
      +5.5485277537*lat+111301.967182595;
  }

  // calculate azimuth
  private static double bearing(double lat1, double lon1, double lat2, double lon2) {
    double longitude1 = lon1;
    double longitude2 = lon2;
    double latitude1 = Math.toRadians(lat1);
    double latitude2 = Math.toRadians(lat2);
    double longDiff= Math.toRadians(longitude2-longitude1);
    double y= Math.sin(longDiff)*Math.cos(latitude2);
    double x=Math.cos(latitude1)*Math.sin(latitude2)-Math.sin(latitude1)*Math.cos(latitude2)*Math.cos(longDiff);
    return (Math.toDegrees(Math.atan2(y, x))+360)%360;
  }
}
