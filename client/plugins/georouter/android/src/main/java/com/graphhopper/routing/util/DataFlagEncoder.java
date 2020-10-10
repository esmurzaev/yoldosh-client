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
package com.graphhopper.routing.util;

import com.graphhopper.routing.profiles.*;
import com.graphhopper.routing.weighting.GenericWeighting;
import com.graphhopper.storage.IntsRef;
import com.graphhopper.util.EdgeIteratorState;
import com.graphhopper.util.PMap;

import java.util.*;

/**
 * This encoder tries to store all way information into a 32 or 64bit value. Later extendable to
 * multiple ints or bytes. The assumption is that edge.getFlags is cheap and can be later replaced
 * by e.g. one or more (cheap) calls of edge.getData(index).
 * <p>
 * Currently limited to motor vehicle but later could handle different modes like foot or bike too.
 *
 * @author Peter Karich
 */
public class DataFlagEncoder extends AbstractFlagEncoder {

    private static final Map<String, Double> DEFAULT_SPEEDS = new LinkedHashMap<String, Double>() {
        {
            put("motorway", 100d);
            put("motorway_link", 70d);
            put("motorroad", 90d);
            put("trunk", 70d);
            put("trunk_link", 65d);
            put("primary", 65d);
            put("primary_link", 60d);
            put("secondary", 60d);
            put("secondary_link", 50d);
            put("tertiary", 50d);
            put("tertiary_link", 40d);
            put("unclassified", 30d);
            put("residential", 30d);
            put("living_street", 5d);
            put("service", 20d);
            put("road", 20d);
            put("forestry", 15d);
            put("track", 15d);
        }
    };

    private EnumEncodedValue<RoadEnvironment> roadEnvironmentEnc;

    public DataFlagEncoder() {
        this(5, 5, 0);
    }

    public DataFlagEncoder(PMap properties) {
        this((int) properties.getLong("speed_bits", 5),
                properties.getDouble("speed_factor", 5),
                properties.getBool("turn_costs", false) ? 1 : 0);
        this.properties = properties;
    }

    public DataFlagEncoder(int speedBits, double speedFactor, int maxTurnCosts) {
        // TODO include turn information
        super(speedBits, speedFactor, maxTurnCosts);

        maxPossibleSpeed = (int) MaxSpeed.UNLIMITED_SIGN_SPEED;
        restrictions.addAll(Arrays.asList("motorcar", "motor_vehicle", "vehicle", "access"));
    }

    @Override
    public void createEncodedValues(List<EncodedValue> registerNewEncodedValue, String prefix, int index) {
        // TODO support different vehicle types, currently just roundabout and fwd&bwd for one vehicle type
        super.createEncodedValues(registerNewEncodedValue, prefix, index);

        for (String key : Arrays.asList(RoadClass.KEY, RoadEnvironment.KEY, RoadAccess.KEY, MaxSpeed.KEY)) {
            if (!encodedValueLookup.hasEncodedValue(key))
                throw new IllegalStateException("To use DataFlagEncoder and the GenericWeighting you need to add " +
                        "the encoded value " + key + " before this '" + toString() + "' flag encoder. Order is important! " +
                        "E.g. use the config: graph.encoded_values: " + key);
        }

        // workaround to init AbstractWeighting.avSpeedEnc variable that GenericWeighting does not need
        speedEncoder = new UnsignedDecimalEncodedValue("fake", 1, 1, false);
        roadEnvironmentEnc = getEnumEncodedValue(RoadEnvironment.KEY, RoadEnvironment.class);
    }

    protected void flagsDefault(IntsRef edgeFlags, boolean forward, boolean backward) {
        accessEnc.setBool(false, edgeFlags, forward);
        accessEnc.setBool(true, edgeFlags, backward);
    }

    @Override
    protected void setSpeed(boolean reverse, IntsRef edgeFlags, double speed) {
        throw new RuntimeException("do not call setSpeed");
    }

    @Override
    double getSpeed(boolean reverse, IntsRef flags) {
        throw new UnsupportedOperationException("Calculate speed via more customizable Weighting.calcMillis method");
    }

    @Override
    public double getMaxSpeed() {
        throw new RuntimeException("do not call getMaxSpeed");
    }

    public double getMaxPossibleSpeed() {
        return maxPossibleSpeed;
    }

    @Override
    public boolean supports(Class<?> feature) {
        boolean ret = super.supports(feature);
        if (ret)
            return true;

        return GenericWeighting.class.isAssignableFrom(feature);
    }

    @Override
    public int getVersion() {
        return 4;
    }

    @Override
    public String toString() {
        return "generic";
    }

    /**
     * This method creates a Config map out of the PMap. Later on this conversion should not be
     * necessary when we read JSON.
     */
    public WeightingConfig createWeightingConfig(PMap pMap) {
        HashMap<String, Double> customSpeedMap = new HashMap<>(DEFAULT_SPEEDS.size());
        double[] speedArray = new double[DEFAULT_SPEEDS.size()];
        for (Map.Entry<String, Double> e : DEFAULT_SPEEDS.entrySet()) {
            double val = pMap.getDouble(e.getKey(), e.getValue());
            customSpeedMap.put(e.getKey(), val);
            RoadClass rc = RoadClass.find(e.getKey());
            speedArray[rc.ordinal()] = val;
        }

        // use defaults per road class in the map for average speed estimate
        return new WeightingConfig(getEnumEncodedValue(RoadClass.KEY, RoadClass.class), speedArray);
    }

    public static class WeightingConfig {
        private final double[] speedArray;
        private final EnumEncodedValue<RoadClass> roadClassEnc;

        public WeightingConfig(EnumEncodedValue<RoadClass> roadClassEnc, double[] speedArray) {
            this.roadClassEnc = roadClassEnc;
            this.speedArray = speedArray;
        }

        public double getSpeed(EdgeIteratorState edgeState) {
            RoadClass rc = edgeState.get(roadClassEnc);
            if (rc.ordinal() >= speedArray.length)
                throw new IllegalStateException("RoadClass not found in speed map " + rc);

            return speedArray[rc.ordinal()];
        }

        public double getMaxSpecifiedSpeed() {
            double tmpSpeed = 0;
            for (double speed : speedArray) {
                if (speed > tmpSpeed)
                    tmpSpeed = speed;
            }
            return tmpSpeed;
        }
    }
}
