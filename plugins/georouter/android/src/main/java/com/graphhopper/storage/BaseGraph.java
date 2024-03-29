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
package com.graphhopper.storage;

import com.graphhopper.coll.GHBitSet;
import com.graphhopper.coll.GHBitSetImpl;
import com.graphhopper.coll.SparseIntIntArray;
import com.graphhopper.routing.profiles.*;
import com.graphhopper.routing.util.AllEdgesIterator;
import com.graphhopper.routing.util.EdgeFilter;
import com.graphhopper.routing.util.EncodingManager;
import com.graphhopper.util.*;
import com.graphhopper.util.shapes.BBox;

import java.util.Locale;

import static com.graphhopper.util.EdgeIteratorState.REVERSE_STATE;
import static com.graphhopper.util.Helper.nf;

/**
 * The base graph handles nodes and edges file format. It can be used with different Directory
 * implementations like RAMDirectory for fast access or via MMapDirectory for virtual-memory and not
 * thread safe usage.
 * <p>
 * Note: A RAM DataAccess Object is thread-safe in itself but if used in this BaseGraph implementation
 * it is not write thread safe.
 * <p>
 * Life cycle: (1) object creation, (2) configuration via setters & getters, (3) create or
 * loadExisting, (4) usage, (5) flush, (6) close
 */
public class BaseGraph implements Graph {
    final DataAccess edges;
    final DataAccess nodes;
    final BBox bounds;
    final NodeAccess nodeAccess;
    final GraphExtension extStorage;
    final BitUtil bitUtil;
    final EdgeAccess edgeAccess;
    private final int bytesForFlags;
    // length | nodeA | nextNode | ... | nodeB
    // as we use integer index in 'egdes' area => 'geometry' area is limited to 4GB (we use pos&neg values!)
    private final DataAccess wayGeometry;
    private final Directory dir;
    /**
     * interval [0,n)
     */
    protected int edgeCount;
    // node memory layout:
    protected int N_EDGE_REF, N_LAT, N_LON, N_ELE, N_ADDITIONAL;
    // edge memory layout not found in EdgeAccess:
    int E_GEO, E_NAME, E_ADDITIONAL;
    /**
     * Specifies how many entries (integers) are used per edge.
     */
    int edgeEntryBytes;
    /**
     * Specifies how many entries (integers) are used per node
     */
    int nodeEntryBytes;
    private boolean initialized = false;
    /**
     * interval [0,n)
     */
    private int nodeCount;
    // remove markers are not yet persistent!
    private GHBitSet removedNodes;
    private int edgeEntryIndex, nodeEntryIndex;
    private long maxGeoRef;
    private boolean frozen = false;

    public BaseGraph(Directory dir, GraphExtension extendedStorage) {
        this.dir = dir;
        this.bytesForFlags = 4;
        this.bitUtil = BitUtil.get(dir.getByteOrder());
        this.wayGeometry = dir.find("geometry");
        this.nodes = dir.find("nodes", DAType.getPreferredInt(dir.getDefaultType()));
        this.edges = dir.find("edges", DAType.getPreferredInt(dir.getDefaultType()));
        this.edgeAccess = new EdgeAccess(edges) {
            @Override
            final EdgeIterable createSingleEdge(EdgeFilter filter) {
                return new EdgeIterable(BaseGraph.this, this, filter);
            }

            @Override
            final int getEdgeRef(int nodeId) {
                return nodes.getInt((long) nodeId * nodeEntryBytes + N_EDGE_REF);
            }

            @Override
            final void setEdgeRef(int nodeId, int edgeId) {
                nodes.setInt((long) nodeId * nodeEntryBytes + N_EDGE_REF, edgeId);
            }

            @Override
            final int getEntryBytes() {
                return edgeEntryBytes;
            }

            @Override
            final long toPointer(int edgeId) {
                assert isInBounds(edgeId) : "edgeId " + edgeId + " not in bounds [0," + edgeCount + ")";
                return (long) edgeId * edgeEntryBytes;
            }

            @Override
            final boolean isInBounds(int edgeId) {
                return edgeId < edgeCount && edgeId >= 0;
            }

            @Override
            public String toString() {
                return "base edge access";
            }
        };
        this.bounds = BBox.createInverse(false);
        this.nodeAccess = new GHNodeAccess(this, false);
        this.extStorage = extendedStorage;
        this.extStorage.init(this, dir);
    }

    private static boolean isTestingEnabled() {
        boolean enableIfAssert = false;
        assert (enableIfAssert = true) : true;
        return enableIfAssert;
    }

    @Override
    public Graph getBaseGraph() {
        return this;
    }

    void checkInit() {
        if (initialized)
            throw new IllegalStateException("You cannot configure this GraphStorage "
                    + "after calling create or loadExisting. Calling one of the methods twice is also not allowed.");
    }

    protected int loadNodesHeader() {
        nodeEntryBytes = nodes.getHeader(1 * 4);
        nodeCount = nodes.getHeader(2 * 4);
        bounds.minLon = Helper.intToDegree(nodes.getHeader(3 * 4));
        bounds.maxLon = Helper.intToDegree(nodes.getHeader(4 * 4));
        bounds.minLat = Helper.intToDegree(nodes.getHeader(5 * 4));
        bounds.maxLat = Helper.intToDegree(nodes.getHeader(6 * 4));

        if (bounds.hasElevation()) {
            bounds.minEle = Helper.intToEle(nodes.getHeader(7 * 4));
            bounds.maxEle = Helper.intToEle(nodes.getHeader(8 * 4));
        }

        frozen = nodes.getHeader(9 * 4) == 1;
        return 10;
    }

    protected int loadEdgesHeader() {
        edgeEntryBytes = edges.getHeader(0 * 4);
        edgeCount = edges.getHeader(1 * 4);
        return 5;
    }

    protected int loadWayGeometryHeader() {
        maxGeoRef = bitUtil.combineIntsToLong(wayGeometry.getHeader(0), wayGeometry.getHeader(4));
        return 1;
    }

    void initStorage() {
        edgeEntryIndex = 0;
        nodeEntryIndex = 0;
        edgeAccess.init(nextEdgeEntryIndex(4),
                nextEdgeEntryIndex(4),
                nextEdgeEntryIndex(4),
                nextEdgeEntryIndex(4),
                nextEdgeEntryIndex(4),
                nextEdgeEntryIndex(4));

        E_GEO = nextEdgeEntryIndex(4);
        E_NAME = nextEdgeEntryIndex(4);
        if (extStorage.isRequireEdgeField())
            E_ADDITIONAL = nextEdgeEntryIndex(4);
        else
            E_ADDITIONAL = -1;

        N_EDGE_REF = nextNodeEntryIndex(4);
        N_LAT = nextNodeEntryIndex(4);
        N_LON = nextNodeEntryIndex(4);
        if (nodeAccess.is3D())
            N_ELE = nextNodeEntryIndex(4);
        else
            N_ELE = -1;

        if (extStorage.isRequireNodeField())
            N_ADDITIONAL = nextNodeEntryIndex(4);
        else
            N_ADDITIONAL = -1;

        initNodeAndEdgeEntrySize();
        initialized = true;
    }

    /**
     * Initializes the node area with the empty edge value and default additional value.
     */
    void initNodeRefs(long oldCapacity, long newCapacity) {
        for (long pointer = oldCapacity + N_EDGE_REF; pointer < newCapacity; pointer += nodeEntryBytes) {
            nodes.setInt(pointer, EdgeIterator.NO_EDGE);
        }
        if (extStorage.isRequireNodeField()) {
            for (long pointer = oldCapacity + N_ADDITIONAL; pointer < newCapacity; pointer += nodeEntryBytes) {
                nodes.setInt(pointer, extStorage.getDefaultNodeFieldValue());
            }
        }
    }

    protected final int nextEdgeEntryIndex(int sizeInBytes) {
        int tmp = edgeEntryIndex;
        edgeEntryIndex += sizeInBytes;
        return tmp;
    }

    protected final int nextNodeEntryIndex(int sizeInBytes) {
        int tmp = nodeEntryIndex;
        nodeEntryIndex += sizeInBytes;
        return tmp;
    }

    protected final void initNodeAndEdgeEntrySize() {
        nodeEntryBytes = nodeEntryIndex;
        edgeEntryBytes = edgeEntryIndex;
    }

    /**
     * Check if byte capacity of DataAcess nodes object is sufficient to include node index, else
     * extend byte capacity
     */
    final void ensureNodeIndex(int nodeIndex) {
        if (!initialized)
            throw new AssertionError("The graph has not yet been initialized.");

        if (nodeIndex < nodeCount)
            return;

        long oldNodes = nodeCount;
        nodeCount = nodeIndex + 1;
        boolean capacityIncreased = nodes.ensureCapacity((long) nodeCount * nodeEntryBytes);
        if (capacityIncreased) {
            long newBytesCapacity = nodes.getCapacity();
            initNodeRefs(oldNodes * nodeEntryBytes, newBytesCapacity);
        }
    }

    @Override
    public int getNodes() {
        return nodeCount;
    }

    @Override
    public int getEdges() {
        return getAllEdges().length();
    }

    @Override
    public NodeAccess getNodeAccess() {
        return nodeAccess;
    }

    @Override
    public BBox getBounds() {
        return bounds;
    }

    @Override
    public EdgeIteratorState edge(int a, int b, double distance, boolean bothDirection) {
        return edge(a, b).setDistance(distance);
    }

    void setSegmentSize(int bytes) {
        checkInit();
        nodes.setSegmentSize(bytes);
        edges.setSegmentSize(bytes);
        wayGeometry.setSegmentSize(bytes);
        extStorage.setSegmentSize(bytes);
    }

    synchronized void freeze() {
        if (isFrozen())
            throw new IllegalStateException("base graph already frozen");

        frozen = true;
    }

    synchronized boolean isFrozen() {
        return frozen;
    }

    public void checkFreeze() {
        if (isFrozen())
            throw new IllegalStateException("Cannot add edge or node after baseGraph.freeze was called");
    }

    public void close() {
        wayGeometry.close();
        edges.close();
        nodes.close();
        extStorage.close();
    }

    long getCapacity() {
        return edges.getCapacity() + nodes.getCapacity()
                + wayGeometry.getCapacity() + extStorage.getCapacity();
    }

    long getMaxGeoRef() {
        return maxGeoRef;
    }

    public void loadExisting() {
        if (!nodes.loadExisting())
            throw new IllegalStateException("Cannot load nodes. corrupt file or directory? " + dir);

        if (!edges.loadExisting())
            throw new IllegalStateException("Cannot load edges. corrupt file or directory? " + dir);

        if (!wayGeometry.loadExisting())
            throw new IllegalStateException("Cannot load geometry. corrupt file or directory? " + dir);

        if (!extStorage.loadExisting())
            throw new IllegalStateException("Cannot load extended storage. corrupt file or directory? " + dir);

        // first define header indices of this storage
        initStorage();

        // now load some properties from stored data
        loadNodesHeader();
        loadEdgesHeader();
        loadWayGeometryHeader();
    }

    /**
     * This method copies the properties of one {@link EdgeIteratorState} to another.
     *
     * @return the updated iterator the properties where copied to.
     */
    EdgeIteratorState copyProperties(EdgeIteratorState from, CommonEdgeIterator to) {
        boolean reverse = from.get(REVERSE_STATE);
        if (to.reverse)
            reverse = !reverse;
        // in case reverse is true we have to swap the nodes to store flags correctly in its "storage direction"
        int nodeA = reverse ? from.getAdjNode() : from.getBaseNode();
        int nodeB = reverse ? from.getBaseNode() : from.getAdjNode();
        long edgePointer = edgeAccess.toPointer(to.getEdge());
        int linkA = reverse ? edgeAccess.getLinkB(edgePointer) : edgeAccess.getLinkA(edgePointer);
        int linkB = reverse ? edgeAccess.getLinkA(edgePointer) : edgeAccess.getLinkB(edgePointer);
        edgeAccess.writeEdge(to.getEdge(), nodeA, nodeB, linkA, linkB);
        edgeAccess.writeFlags(edgePointer, from.getFlags());

        // copy the rest with higher level API
        to.setDistance(from.getDistance()).
                setWayGeometry(from.fetchWayGeometry(0));

        if (E_ADDITIONAL >= 0)
            to.setAdditionalField(from.getAdditionalField());
        return to;
    }

    /**
     * Create edge between nodes a and b
     *
     * @return EdgeIteratorState of newly created edge
     */
    @Override
    public EdgeIteratorState edge(int nodeA, int nodeB) {
        if (isFrozen())
            throw new IllegalStateException("Cannot create edge if graph is already frozen");

        ensureNodeIndex(Math.max(nodeA, nodeB));
        int edgeId = edgeAccess.internalEdgeAdd(nextEdgeId(), nodeA, nodeB);
        EdgeIterable iter = new EdgeIterable(this, edgeAccess, EdgeFilter.ALL_EDGES);
        boolean ret = iter.init(edgeId, nodeB);
        assert ret;
        if (extStorage.isRequireEdgeField())
            iter.setAdditionalField(extStorage.getDefaultEdgeFieldValue());

        return iter;
    }

    // for test only
    void setEdgeCount(int cnt) {
        edgeCount = cnt;
    }

    /**
     * Determine next free edgeId and ensure byte capacity to store edge
     *
     * @return next free edgeId
     */
    protected int nextEdgeId() {
        int nextEdge = edgeCount;
        edgeCount++;
        if (edgeCount < 0)
            throw new IllegalStateException("too many edges. new edge id would be negative. " + toString());

        edges.ensureCapacity(((long) edgeCount + 1) * edgeEntryBytes);
        return nextEdge;
    }

    @Override
    public EdgeIteratorState getEdgeIteratorState(int edgeId, int adjNode) {
        if (!edgeAccess.isInBounds(edgeId))
            throw new IllegalStateException("edgeId " + edgeId + " out of bounds");
        checkAdjNodeBounds(adjNode);
        return edgeAccess.getEdgeProps(edgeId, adjNode);
    }

    final void checkAdjNodeBounds(int adjNode) {
        if (adjNode < 0 && adjNode != Integer.MIN_VALUE || adjNode >= nodeCount)
            throw new IllegalStateException("adjNode " + adjNode + " out of bounds [0," + nf(nodeCount) + ")");
    }

    @Override
    public EdgeExplorer createEdgeExplorer(EdgeFilter filter) {
        return new EdgeIterable(this, edgeAccess, filter);
    }

    @Override
    public EdgeExplorer createEdgeExplorer() {
        return createEdgeExplorer(EdgeFilter.ALL_EDGES);
    }

    @Override
    public AllEdgesIterator getAllEdges() {
        return new AllEdgeIterator(this, edgeAccess);
    }

    protected void trimToSize() {
        long nodeCap = (long) nodeCount * nodeEntryBytes;
        nodes.trimTo(nodeCap);
//        long edgeCap = (long) (edgeCount + 1) * edgeEntrySize;
//        edges.trimTo(edgeCap * 4);
    }

    @Override
    public GraphExtension getExtension() {
        return extStorage;
    }

    @Override
    public int getOtherNode(int edge, int node) {
        long edgePointer = edgeAccess.toPointer(edge);
        return edgeAccess.getOtherNode(node, edgePointer);
    }

    @Override
    public boolean isAdjacentToNode(int edge, int node) {
        long edgePointer = edgeAccess.toPointer(edge);
        return edgeAccess.isAdjacentToNode(node, edgePointer);
    }

    public void setAdditionalEdgeField(long edgePointer, int value) {
        if (extStorage.isRequireEdgeField() && E_ADDITIONAL >= 0)
            edges.setInt(edgePointer + E_ADDITIONAL, value);
        else
            throw new AssertionError("This graph does not support an additional edge field.");
    }

    private void setWayGeometry_(PointList pillarNodes, long edgePointer, boolean reverse) {
        if (pillarNodes != null && !pillarNodes.isEmpty()) {
            if (pillarNodes.getDimension() != nodeAccess.getDimension())
                throw new IllegalArgumentException("Cannot use pointlist which is " + pillarNodes.getDimension()
                        + "D for graph which is " + nodeAccess.getDimension() + "D");

            long existingGeoRef = Helper.toUnsignedLong(edges.getInt(edgePointer + E_GEO));

            int len = pillarNodes.getSize();
            int dim = nodeAccess.getDimension();
            if (existingGeoRef > 0) {
                final int count = wayGeometry.getInt(existingGeoRef * 4L);
                if (len <= count) {
                    setWayGeometryAtGeoRef(pillarNodes, edgePointer, reverse, existingGeoRef);
                    return;
                }
            }

            long nextGeoRef = nextGeoRef(len * dim);
            setWayGeometryAtGeoRef(pillarNodes, edgePointer, reverse, nextGeoRef);
        } else {
            edges.setInt(edgePointer + E_GEO, 0);
        }
    }

    private void setWayGeometryAtGeoRef(PointList pillarNodes, long edgePointer, boolean reverse, long geoRef) {
        int len = pillarNodes.getSize();
        int dim = nodeAccess.getDimension();
        long geoRefPosition = (long) geoRef * 4;
        int totalLen = len * dim * 4 + 4;
        ensureGeometry(geoRefPosition, totalLen);
        byte[] wayGeometryBytes = createWayGeometryBytes(pillarNodes, reverse);
        wayGeometry.setBytes(geoRefPosition, wayGeometryBytes, wayGeometryBytes.length);
        edges.setInt(edgePointer + E_GEO, Helper.toSignedInt(geoRef));
    }

    private byte[] createWayGeometryBytes(PointList pillarNodes, boolean reverse) {
        int len = pillarNodes.getSize();
        int dim = nodeAccess.getDimension();
        int totalLen = len * dim * 4 + 4;
        byte[] bytes = new byte[totalLen];
        bitUtil.fromInt(bytes, len, 0);
        if (reverse)
            pillarNodes.reverse();

        int tmpOffset = 4;
        boolean is3D = nodeAccess.is3D();
        for (int i = 0; i < len; i++) {
            double lat = pillarNodes.getLatitude(i);
            bitUtil.fromInt(bytes, Helper.degreeToInt(lat), tmpOffset);
            tmpOffset += 4;
            bitUtil.fromInt(bytes, Helper.degreeToInt(pillarNodes.getLongitude(i)), tmpOffset);
            tmpOffset += 4;

            if (is3D) {
                bitUtil.fromInt(bytes, Helper.eleToInt(pillarNodes.getElevation(i)), tmpOffset);
                tmpOffset += 4;
            }
        }
        return bytes;
    }

    private PointList fetchWayGeometry_(long edgePointer, boolean reverse, int mode, int baseNode, int adjNode) {
        long geoRef = Helper.toUnsignedLong(edges.getInt(edgePointer + E_GEO));
        int count = 0;
        byte[] bytes = null;
        if (geoRef > 0) {
            geoRef *= 4L;
            count = wayGeometry.getInt(geoRef);

            geoRef += 4L;
            bytes = new byte[count * nodeAccess.getDimension() * 4];
            wayGeometry.getBytes(geoRef, bytes, bytes.length);
        } else if (mode == 0)
            return PointList.EMPTY;

        PointList pillarNodes = new PointList(count + mode, nodeAccess.is3D());
        if (reverse) {
            if ((mode & 2) != 0)
                pillarNodes.add(nodeAccess, adjNode);
        } else if ((mode & 1) != 0)
            pillarNodes.add(nodeAccess, baseNode);

        int index = 0;
        for (int i = 0; i < count; i++) {
            double lat = Helper.intToDegree(bitUtil.toInt(bytes, index));
            index += 4;
            double lon = Helper.intToDegree(bitUtil.toInt(bytes, index));
            index += 4;
            if (nodeAccess.is3D()) {
                pillarNodes.add(lat, lon, Helper.intToEle(bitUtil.toInt(bytes, index)));
                index += 4;
            } else {
                pillarNodes.add(lat, lon);
            }
        }

        if (reverse) {
            if ((mode & 1) != 0)
                pillarNodes.add(nodeAccess, baseNode);

            pillarNodes.reverse();
        } else if ((mode & 2) != 0)
            pillarNodes.add(nodeAccess, adjNode);

        return pillarNodes;
    }

    GHBitSet getRemovedNodes() {
        if (removedNodes == null)
            removedNodes = new GHBitSetImpl(getNodes());

        return removedNodes;
    }

    private void ensureGeometry(long bytePos, int byteLength) {
        wayGeometry.ensureCapacity(bytePos + byteLength);
    }

    private long nextGeoRef(int arrayLength) {
        long tmp = maxGeoRef;
        maxGeoRef += arrayLength + 1L;
        if (maxGeoRef >= 0xFFFFffffL)
            throw new IllegalStateException("Geometry too large, does not fit in 32 bits " + maxGeoRef);

        return tmp;
    }

    protected static class EdgeIterable extends CommonEdgeIterator implements EdgeExplorer, EdgeIterator {
        final EdgeFilter filter;
        int nextEdgeId;

        public EdgeIterable(BaseGraph baseGraph, EdgeAccess edgeAccess, EdgeFilter filter) {
            super(-1, edgeAccess, baseGraph);

            if (filter == null)
                throw new IllegalArgumentException("Instead null filter use EdgeFilter.ALL_EDGES");
            this.filter = filter;
        }

        final void setEdgeId(int edgeId) {
            this.nextEdgeId = this.edgeId = edgeId;
        }

        /**
         * @return false if the edge has not a node equal to expectedAdjNode
         */
        final boolean init(int tmpEdgeId, int expectedAdjNode) {
            setEdgeId(tmpEdgeId);
            if (!EdgeIterator.Edge.isValid(edgeId))
                throw new IllegalArgumentException("fetching the edge requires a valid edgeId but was " + edgeId);

            selectEdgeAccess();
            edgePointer = edgeAccess.toPointer(tmpEdgeId);
            baseNode = edgeAccess.getNodeA(edgePointer);
            adjNode = edgeAccess.getNodeB(edgePointer);
            if (EdgeAccess.isInvalidNodeB(adjNode))
                throw new IllegalStateException("content of edgeId " + edgeId + " is marked as invalid - ie. the edge is already removed!");

            // a next() call should return false
            nextEdgeId = EdgeIterator.NO_EDGE;
            if (expectedAdjNode == adjNode || expectedAdjNode == Integer.MIN_VALUE) {
                reverse = false;
                return true;
            } else if (expectedAdjNode == baseNode) {
                reverse = true;
                baseNode = adjNode;
                adjNode = expectedAdjNode;
                return true;
            }
            return false;
        }

        final void _setBaseNode(int baseNode) {
            this.baseNode = baseNode;
        }

        @Override
        public EdgeIterator setBaseNode(int baseNode) {
            // always use base graph edge access
            setEdgeId(baseGraph.edgeAccess.getEdgeRef(baseNode));
            _setBaseNode(baseNode);
            return this;
        }

        protected void selectEdgeAccess() {
        }

        @Override
        public final boolean next() {
            while (true) {
                if (!EdgeIterator.Edge.isValid(nextEdgeId))
                    return false;

                selectEdgeAccess();
                edgePointer = edgeAccess.toPointer(nextEdgeId);
                edgeId = nextEdgeId;
                int nodeA = edgeAccess.getNodeA(edgePointer);
                boolean baseNodeIsNodeA = baseNode == nodeA;
                adjNode = baseNodeIsNodeA ? edgeAccess.getNodeB(edgePointer) : nodeA;
                reverse = !baseNodeIsNodeA;
                freshFlags = false;

                // position to next edge
                nextEdgeId = baseNodeIsNodeA ? edgeAccess.getLinkA(edgePointer) : edgeAccess.getLinkB(edgePointer);
                assert nextEdgeId != edgeId : ("endless loop detected for base node: " + baseNode + ", adj node: " + adjNode
                        + ", edge pointer: " + edgePointer + ", edge: " + edgeId);

                if (filter.accept(this))
                    return true;
            }
        }

        @Override
        public EdgeIteratorState detach(boolean reverseArg) {
            if (edgeId == nextEdgeId || !EdgeIterator.Edge.isValid(edgeId))
                throw new IllegalStateException("call next before detaching or setEdgeId (edgeId:" + edgeId + " vs. next " + nextEdgeId + ")");

            EdgeIterable iter = edgeAccess.createSingleEdge(filter);
            boolean ret;
            if (reverseArg) {
                ret = iter.init(edgeId, baseNode);
                // for #162
                iter.reverse = !reverse;
            } else
                ret = iter.init(edgeId, adjNode);
            assert ret;
            return iter;
        }
    }

    /**
     * Include all edges of this storage in the iterator.
     */
    protected static class AllEdgeIterator extends CommonEdgeIterator implements AllEdgesIterator {
        public AllEdgeIterator(BaseGraph baseGraph) {
            this(baseGraph, baseGraph.edgeAccess);
        }

        private AllEdgeIterator(BaseGraph baseGraph, EdgeAccess edgeAccess) {
            super(-1, edgeAccess, baseGraph);
        }

        @Override
        public int length() {
            return baseGraph.edgeCount;
        }

        @Override
        public boolean next() {
            while (true) {
                edgeId++;
                edgePointer = (long) edgeId * edgeAccess.getEntryBytes();
                if (!checkRange())
                    return false;

                adjNode = edgeAccess.getNodeB(edgePointer);
                // some edges are deleted and are marked via a negative node
                if (EdgeAccess.isInvalidNodeB(adjNode))
                    continue;

                baseNode = edgeAccess.getNodeA(edgePointer);
                freshFlags = false;
                reverse = false;
                return true;
            }
        }

        protected boolean checkRange() {
            return edgeId < baseGraph.edgeCount;
        }

        @Override
        public final EdgeIteratorState detach(boolean reverseArg) {
            if (edgePointer < 0)
                throw new IllegalStateException("call next before detaching");

            AllEdgeIterator iter = new AllEdgeIterator(baseGraph, edgeAccess);
            iter.edgeId = edgeId;
            iter.edgePointer = edgePointer;
            if (reverseArg) {
                iter.reverse = !this.reverse;
                iter.baseNode = adjNode;
                iter.adjNode = baseNode;
            } else {
                iter.reverse = this.reverse;
                iter.baseNode = baseNode;
                iter.adjNode = adjNode;
            }
            return iter;
        }
    }

    /**
     * Common private super class for AllEdgesIteratorImpl and EdgeIterable
     */
    static abstract class CommonEdgeIterator implements EdgeIteratorState {
        final BaseGraph baseGraph;
        long edgePointer;
        int baseNode;
        int adjNode;
        EdgeAccess edgeAccess;
        // we need reverse if detach is called
        boolean reverse = false;
        boolean freshFlags;
        int edgeId = -1;
        private final IntsRef baseIntsRef;
        int chFlags;

        public CommonEdgeIterator(long edgePointer, EdgeAccess edgeAccess, BaseGraph baseGraph) {
            this.edgePointer = edgePointer;
            this.edgeAccess = edgeAccess;
            this.baseGraph = baseGraph;
            this.baseIntsRef = new IntsRef(baseGraph.bytesForFlags / 4);
        }

        @Override
        public final int getBaseNode() {
            return baseNode;
        }

        @Override
        public final int getAdjNode() {
            return adjNode;
        }

        @Override
        public final double getDistance() {
            return edgeAccess.getDist(edgePointer);
        }

        @Override
        public final EdgeIteratorState setDistance(double dist) {
            edgeAccess.setDist(edgePointer, dist);
            return this;
        }

        @Override
        public IntsRef getFlags() {
            if (!freshFlags) {
                edgeAccess.readFlags(edgePointer, baseIntsRef);
                freshFlags = true;
            }
            return baseIntsRef;
        }

        @Override
        public final EdgeIteratorState setFlags(IntsRef edgeFlags) {
            assert edgeId < baseGraph.edgeCount : "must be edge but was shortcut: " + edgeId + " >= " + baseGraph.edgeCount + ". Use setFlagsAndWeight";
            edgeAccess.writeFlags(edgePointer, edgeFlags);
            for (int i = 0; i < edgeFlags.ints.length; i++) {
                baseIntsRef.ints[i] = edgeFlags.ints[i];
            }
            freshFlags = true;
            return this;
        }

        @Override
        public final int getAdditionalField() {
            return baseGraph.edges.getInt(edgePointer + baseGraph.E_ADDITIONAL);
        }

        @Override
        public final EdgeIteratorState setAdditionalField(int value) {
            baseGraph.setAdditionalEdgeField(edgePointer, value);
            return this;
        }

        @Override
        public boolean get(BooleanEncodedValue property) {
            return property.getBool(reverse, getFlags());
        }

        @Override
        public EdgeIteratorState set(BooleanEncodedValue property, boolean value) {
            property.setBool(reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public boolean getReverse(BooleanEncodedValue property) {
            return property.getBool(!reverse, getFlags());
        }

        @Override
        public EdgeIteratorState setReverse(BooleanEncodedValue property, boolean value) {
            property.setBool(!reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public int get(IntEncodedValue property) {
            return property.getInt(reverse, getFlags());
        }

        @Override
        public EdgeIteratorState set(IntEncodedValue property, int value) {
            property.setInt(reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public int getReverse(IntEncodedValue property) {
            return property.getInt(!reverse, getFlags());
        }

        @Override
        public EdgeIteratorState setReverse(IntEncodedValue property, int value) {
            property.setInt(!reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public double get(DecimalEncodedValue property) {
            return property.getDecimal(reverse, getFlags());
        }

        @Override
        public EdgeIteratorState set(DecimalEncodedValue property, double value) {
            property.setDecimal(reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public double getReverse(DecimalEncodedValue property) {
            return property.getDecimal(!reverse, getFlags());
        }

        @Override
        public EdgeIteratorState setReverse(DecimalEncodedValue property, double value) {
            property.setDecimal(!reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public <T extends Enum> T get(EnumEncodedValue<T> property) {
            return property.getEnum(reverse, getFlags());
        }

        @Override
        public <T extends Enum> EdgeIteratorState set(EnumEncodedValue<T> property, T value) {
            property.setEnum(reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public <T extends Enum> T getReverse(EnumEncodedValue<T> property) {
            return property.getEnum(!reverse, getFlags());
        }

        @Override
        public <T extends Enum> EdgeIteratorState setReverse(EnumEncodedValue<T> property, T value) {
            property.setEnum(!reverse, getFlags(), value);
            edgeAccess.writeFlags(edgePointer, getFlags());
            return this;
        }

        @Override
        public final EdgeIteratorState copyPropertiesFrom(EdgeIteratorState edge) {
            return baseGraph.copyProperties(edge, this);
        }

        @Override
        public EdgeIteratorState setWayGeometry(PointList pillarNodes) {
            baseGraph.setWayGeometry_(pillarNodes, edgePointer, reverse);
            return this;
        }

        @Override
        public PointList fetchWayGeometry(int mode) {
            return baseGraph.fetchWayGeometry_(edgePointer, reverse, mode, getBaseNode(), getAdjNode());
        }

        @Override
        public int getEdge() {
            return edgeId;
        }

        @Override
        public int getOrigEdgeFirst() {
            return getEdge();
        }

        @Override
        public int getOrigEdgeLast() {
            return getEdge();
        }

        @Override
        public final String toString() {
            return getEdge() + " " + getBaseNode() + "-" + getAdjNode();
        }
    }
}
