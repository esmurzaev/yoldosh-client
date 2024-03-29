/*
 *  Licensed to GraphHopper GmbH under one or more contributor
 *  license agreements. See the NOTICE file distributed with this work for
 *  additional information regarding copyright ownership.
 *
 *  GraphHopper GmbH licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except in
 *  compliance with the License. You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package com.graphhopper.routing;

import com.carrotsearch.hppc.IntArrayList;
import com.carrotsearch.hppc.IntIndexedContainer;
import com.graphhopper.coll.GHIntArrayList;
import com.graphhopper.routing.profiles.BooleanEncodedValue;
import com.graphhopper.routing.util.FlagEncoder;
import com.graphhopper.routing.weighting.Weighting;
import com.graphhopper.storage.Graph;
import com.graphhopper.storage.NodeAccess;
import com.graphhopper.storage.SPTEntry;
import com.graphhopper.util.*;

import java.util.*;

/**
 * Stores the nodes for the found path of an algorithm. It additionally needs the edgeIds to make
 * edge determination faster and less complex as there could be several edges (u,v) especially for
 * graphs with shortcuts.
 * <p>
 *
 * @author Peter Karich
 * @author Ottavio Campana
 * @author jan soe
 */
public class Path {
    protected Graph graph;
    protected double distance;
    // we go upwards (via SPTEntry.parent) from the goal node to the origin node
    protected boolean reverseOrder = true;
    protected long time;
    /**
     * Shortest path tree entry
     */
    protected SPTEntry sptEntry;
    protected int endNode = -1;
    protected Weighting weighting;
    private FlagEncoder encoder;
    private boolean found;
    private int fromNode = -1;
    private GHIntArrayList edgeIds;
    private double weight;
    private NodeAccess nodeAccess;

    public Path(Graph graph, Weighting weighting) {
        this.weight = Double.MAX_VALUE;
        this.graph = graph;
        this.nodeAccess = graph.getNodeAccess();
        this.weighting = weighting;
        this.encoder = weighting.getFlagEncoder();
        this.edgeIds = new GHIntArrayList();
    }

    /**
     * Populates an unextracted path instances from the specified path p.
     */
    Path(Path p) {
        this(p.graph, p.weighting);
        weight = p.weight;
        edgeIds = new GHIntArrayList(p.edgeIds);
        sptEntry = p.sptEntry;
    }

    public Path setSPTEntry(SPTEntry sptEntry) {
        this.sptEntry = sptEntry;
        return this;
    }

    protected void addEdge(int edge) {
        edgeIds.add(edge);
    }

    protected Path setEndNode(int end) {
        endNode = end;
        return this;
    }

    /**
     * @return the first node of this Path.
     */
    private int getFromNode() {
        if (fromNode < 0)
            throw new IllegalStateException("Call extract() before retrieving fromNode");

        return fromNode;
    }

    /**
     * We need to remember fromNode explicitly as its not saved in one edgeId of edgeIds.
     */
    protected Path setFromNode(int from) {
        fromNode = from;
        return this;
    }

    public int getEdgeCount() {
        return edgeIds.size();
    }

    public boolean isFound() {
        return found;
    }

    public Path setFound(boolean found) {
        this.found = found;
        return this;
    }

    void reverseOrder() {
        if (!reverseOrder)
            throw new IllegalStateException("Switching order multiple times is not supported");

        reverseOrder = false;
        edgeIds.reverse();
    }

    public Path setDistance(double distance) {
        this.distance = distance;
        return this;
    }

    /**
     * @return distance in meter
     */
    public double getDistance() {
        return distance;
    }

    /**
     * This weight will be updated during the algorithm. The initial value is maximum double.
     */
    public double getWeight() {
        return weight;
    }

    public Path setWeight(double w) {
        this.weight = w;
        return this;
    }

    /**
     * Extracts the Path from the shortest-path-tree determined by sptEntry.
     */
    public Path extract() {
        if (isFound())
            throw new IllegalStateException("Extract can only be called once");

        SPTEntry currEdge = sptEntry;
        setEndNode(currEdge.adjNode);
        boolean nextEdgeValid = EdgeIterator.Edge.isValid(currEdge.edge);
        int nextEdge;
        while (nextEdgeValid) {
            // the reverse search needs the next edge
            nextEdgeValid = EdgeIterator.Edge.isValid(currEdge.parent.edge);
            nextEdge = nextEdgeValid ? currEdge.parent.edge : EdgeIterator.NO_EDGE;
            processEdge(currEdge.edge, currEdge.adjNode, nextEdge);
            currEdge = currEdge.parent;
        }

        setFromNode(currEdge.adjNode);
        reverseOrder();
        return setFound(true);
    }

    /**
     * Yields the final edge of the path
     */
    public EdgeIteratorState getFinalEdge() {
        return graph.getEdgeIteratorState(edgeIds.get(edgeIds.size() - 1), endNode);
    }

    /**
     * Calculates the distance and time of the specified edgeId. Also it adds the edgeId to the path list.
     *
     * @param prevEdgeId the edge that comes before edgeId: --prevEdgeId-x-edgeId-->adjNode
     */
    protected void processEdge(int edgeId, int adjNode, int prevEdgeId) {
        EdgeIteratorState iter = graph.getEdgeIteratorState(edgeId, adjNode);
        distance += iter.getDistance();
        time += weighting.calcMillis(iter, false, prevEdgeId);
        addEdge(edgeId);
    }

    /**
     * Iterates over all edges in this path sorted from start to end and calls the visitor callback
     * for every edge.
     * <p>
     *
     * @param visitor callback to handle every edge. The edge is decoupled from the iterator and can
     *                be stored.
     */
    private void forEveryEdge(EdgeVisitor visitor) {
        int tmpNode = getFromNode();
        int len = edgeIds.size();
        int prevEdgeId = EdgeIterator.NO_EDGE;
        for (int i = 0; i < len; i++) {
            EdgeIteratorState edgeBase = graph.getEdgeIteratorState(edgeIds.get(i), tmpNode);
            if (edgeBase == null)
                throw new IllegalStateException("Edge " + edgeIds.get(i) + " was empty when requested with node " + tmpNode
                        + ", array index:" + i + ", edges:" + edgeIds.size());

            tmpNode = edgeBase.getBaseNode();
            // more efficient swap, currently not implemented for virtual edges: visitor.next(edgeBase.detach(true), i);
            edgeBase = graph.getEdgeIteratorState(edgeBase.getEdge(), tmpNode);
            visitor.next(edgeBase, i, prevEdgeId);

            prevEdgeId = edgeBase.getEdge();
        }
        visitor.finish();
    }

    /**
     * Returns the list of all edges.
     */
    public List<EdgeIteratorState> calcEdges() {
        final List<EdgeIteratorState> edges = new ArrayList<>(edgeIds.size());
        if (edgeIds.isEmpty())
            return edges;

        forEveryEdge(new EdgeVisitor() {
            @Override
            public void next(EdgeIteratorState eb, int index, int prevEdgeId) {
                edges.add(eb);
            }

            @Override
            public void finish() {

            }
        });
        return edges;
    }

    /**
     * @return the uncached node indices of the tower nodes in this path.
     */
    public IntIndexedContainer calcNodes() {
        final IntArrayList nodes = new IntArrayList(edgeIds.size() + 1);
        if (edgeIds.isEmpty()) {
            if (isFound()) {
                nodes.add(endNode);
            }
            return nodes;
        }

        int tmpNode = getFromNode();
        nodes.add(tmpNode);
        forEveryEdge(new EdgeVisitor() {
            @Override
            public void next(EdgeIteratorState eb, int index, int prevEdgeId) {
                nodes.add(eb.getAdjNode());
            }

            @Override
            public void finish() {

            }
        });
        return nodes;
    }

    /**
     * This method calculated a list of points for this path
     * <p>
     *
     * @return this path its geometry
     */
    public PointList calcPoints() {
        final PointList points = new PointList(edgeIds.size() + 1, nodeAccess.is3D());
        if (edgeIds.isEmpty()) {
            if (isFound()) {
                points.add(graph.getNodeAccess(), endNode);
            }
            return points;
        }

        int tmpNode = getFromNode();
        points.add(nodeAccess, tmpNode);
        forEveryEdge(new EdgeVisitor() {
            @Override
            public void next(EdgeIteratorState eb, int index, int prevEdgeId) {
                PointList pl = eb.fetchWayGeometry(2);
                for (int j = 0; j < pl.getSize(); j++) {
                    points.add(pl, j);
                }
            }

            @Override
            public void finish() {

            }
        });
        return points;
    }

    /**
     * The callback used in forEveryEdge.
     */
    public interface EdgeVisitor {
        void next(EdgeIteratorState edge, int index, int prevEdgeId);

        void finish();
    }
}
