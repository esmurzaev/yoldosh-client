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
package com.graphhopper.util;

import com.graphhopper.storage.Graph;
import com.graphhopper.storage.NodeAccess;
import com.graphhopper.util.EdgeIterator;
import com.graphhopper.util.EdgeIteratorState;
import com.graphhopper.util.Helper;

/**
 * A helper class to avoid cluttering the Graph interface with all the common
 * methods. Most of the methods are useful for unit tests or debugging only.
 *
 * @author Peter Karich
 */
public class GHUtility {

    public static double getDistance(int from, int to, NodeAccess nodeAccess) {
        double fromLat = nodeAccess.getLat(from);
        double fromLon = nodeAccess.getLon(from);
        double toLat = nodeAccess.getLat(to);
        double toLon = nodeAccess.getLon(to);
        return Helper.DIST_PLANE.calcDist(fromLat, fromLon, toLat, toLon);
    }
    /**
     * @return the <b>first</b> edge containing the specified nodes base and adj.
     *         Returns null if not found.
     */
    public static EdgeIteratorState getEdge(Graph graph, int base, int adj) {
        EdgeIterator iter = graph.createEdgeExplorer().setBaseNode(base);
        while (iter.next()) {
            if (iter.getAdjNode() == adj)
                return iter;
        }
        return null;
    }

    /**
     * Creates unique positive number for specified edgeId taking into account the
     * direction defined by nodeA, nodeB and reverse.
     */
    public static int createEdgeKey(int nodeA, int nodeB, int edgeId, boolean reverse) {
        edgeId = edgeId << 1;
        if (reverse)
            return (nodeA >= nodeB) ? edgeId : edgeId + 1;
        return (nodeA > nodeB) ? edgeId + 1 : edgeId;
    }

    /**
     * Returns if the specified edgeKeys (created by createEdgeKey) are identical
     * regardless of the direction.
     */
    public static boolean isSameEdgeKeys(int edgeKey1, int edgeKey2) {
        return edgeKey1 / 2 == edgeKey2 / 2;
    }

    /**
     * Returns the edgeKey of the opposite direction
     */
    public static int reverseEdgeKey(int edgeKey) {
        return edgeKey % 2 == 0 ? edgeKey + 1 : edgeKey - 1;
    }

    /**
     * @return edge ID for edgeKey
     */
    public static int getEdgeFromEdgeKey(int edgeKey) {
        return edgeKey / 2;
    }

    /**
     * Returns the edge key for a given edge id and adjacent node. This is needed in
     * a few places where the base node is not known.
     */
    public static int getEdgeKey(Graph graph, int edgeId, int node, boolean reverse) {
        EdgeIteratorState edgeIteratorState = graph.getEdgeIteratorState(edgeId, node);
        return createEdgeKey(edgeIteratorState.getBaseNode(), edgeIteratorState.getAdjNode(), edgeId,
                reverse);
    }
}
