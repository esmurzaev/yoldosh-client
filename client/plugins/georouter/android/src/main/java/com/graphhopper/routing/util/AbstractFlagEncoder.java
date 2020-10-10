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
import com.graphhopper.routing.weighting.TurnWeighting;
import com.graphhopper.storage.IntsRef;
import com.graphhopper.util.*;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Abstract class which handles flag decoding and encoding. Every encoder should be registered to a
 * EncodingManager to be usable. If you want the full long to be stored you need to enable this in
 * the GraphHopperStorage.
 *
 * @author Peter Karich
 * @author Nop
 * @see EncodingManager
 */
public abstract class AbstractFlagEncoder implements FlagEncoder {
    /* restriction definitions where order is important */
    protected final List<String> restrictions = new ArrayList<>(5);
    protected final Set<String> intendedValues = new HashSet<>(5);
    protected final Set<String> restrictedValues = new HashSet<>(5);
    protected final Set<String> ferries = new HashSet<>(5);
    protected final Set<String> oneways = new HashSet<>(5);
    // http://wiki.openstreetmap.org/wiki/Mapfeatures#Barrier
    protected final Set<String> absoluteBarriers = new HashSet<>(5);
    protected final Set<String> potentialBarriers = new HashSet<>(5);
    protected final int speedBits;
    protected final double speedFactor;
    protected double speedDefault;
    private final int maxTurnCosts;
    private long encoderBit;
    protected BooleanEncodedValue accessEnc;
    protected BooleanEncodedValue roundaboutEnc;
    protected DecimalEncodedValue speedEncoder;
    protected PMap properties;
    // This value determines the maximal possible speed of any road regardless of the maxspeed value
    // lower values allow more compact representation of the routing graph
    protected int maxPossibleSpeed;
    /* Edge Flag Encoder fields */
    private long nodeBitMask;
    private long relBitMask;
    private EncodedValueOld turnCostEncoder;
    private long turnRestrictionBit;
    private boolean blockByDefault = true;
    private boolean blockFords = true;
    private boolean registered;
    protected EncodedValueLookup encodedValueLookup;

    // Speeds from CarFlagEncoder
    protected static final double UNKNOWN_DURATION_FERRY_SPEED = 5;
    protected static final double SHORT_TRIP_FERRY_SPEED = 20;
    protected static final double LONG_TRIP_FERRY_SPEED = 30;

    public AbstractFlagEncoder(PMap properties) {
        throw new RuntimeException("This method must be overridden in derived classes");
    }

    public AbstractFlagEncoder(String propertiesStr) {
        this(new PMap(propertiesStr));
    }

    /**
     * @param speedBits    specify the number of bits used for speed
     * @param speedFactor  specify the factor to multiple the stored value (can be used to increase
     *                     or decrease accuracy of speed value)
     * @param maxTurnCosts specify the maximum value used for turn costs, if this value is reached a
     *                     turn is forbidden and results in costs of positive infinity.
     */
    protected AbstractFlagEncoder(int speedBits, double speedFactor, int maxTurnCosts) {
        this.maxTurnCosts = maxTurnCosts <= 0 ? 0 : maxTurnCosts;
        this.speedBits = speedBits;
        this.speedFactor = speedFactor;
        oneways.add("yes");
        oneways.add("true");
        oneways.add("1");
        oneways.add("-1");

        ferries.add("shuttle_train");
        ferries.add("ferry");
    }

    @Override
    public boolean isRegistered() {
        return registered;
    }

    public void setRegistered(boolean registered) {
        this.registered = registered;
    }

    /**
     * Should potential barriers block when no access limits are given?
     */
    public void setBlockByDefault(boolean blockByDefault) {
        this.blockByDefault = blockByDefault;
    }

    public boolean isBlockFords() {
        return blockFords;
    }

    public void setBlockFords(boolean blockFords) {
        this.blockFords = blockFords;
    }

    /**
     * Defines the bits for the node flags, which are currently used for barriers only.
     * <p>
     *
     * @return incremented shift value pointing behind the last used bit
     */
    public int defineNodeBits(int index, int shift) {
        return shift;
    }

    /**
     * Defines bits used for edge flags used for access, speed etc.
     *
     * @return incremented shift value pointing behind the last used bit
     */
    public void createEncodedValues(List<EncodedValue> registerNewEncodedValue, String prefix, int index) {
        // define the first 2 speedBits in flags for routing
        registerNewEncodedValue.add(accessEnc = new SimpleBooleanEncodedValue(EncodingManager.getKey(prefix, "access"), true));
        roundaboutEnc = getBooleanEncodedValue(Roundabout.KEY);
        encoderBit = 1L << index;
    }

    /**
     * Defines the bits which are used for relation flags.
     *
     * @return incremented shift value pointing behind the last used bit
     */
    public int defineRelationBits(int index, int shift) {
        return shift;
    }

    /**
     * Sets default flags with specified access.
     */
    protected void flagsDefault(IntsRef edgeFlags, boolean forward, boolean backward) {
        if (forward)
            speedEncoder.setDecimal(false, edgeFlags, speedDefault);
        if (backward && speedEncoder.isStoreTwoDirections())
            speedEncoder.setDecimal(true, edgeFlags, speedDefault);
        accessEnc.setBool(false, edgeFlags, forward);
        accessEnc.setBool(true, edgeFlags, backward);
    }

    @Override
    public double getMaxSpeed() {
        return maxPossibleSpeed;
    }
    
    @Override
    public int hashCode() {
        int hash = 7;
        hash = 61 * hash + this.accessEnc.hashCode();
        hash = 61 * hash + this.toString().hashCode();
        return hash;
    }
    
    @Override
    public boolean equals(Object obj) {
        if (obj == null)
            return false;

        if (getClass() != obj.getClass())
            return false;
        AbstractFlagEncoder afe = (AbstractFlagEncoder) obj;
        return toString().equals(afe.toString()) && encoderBit == afe.encoderBit && accessEnc.equals(afe.accessEnc);
    }

    /**
     * @return the speed in km/h
     */
    public static double parseSpeed(String str) {
        if (Helper.isEmpty(str))
            return -1;

        // on some German autobahns and a very few other places
        if ("none".equals(str))
            return MaxSpeed.UNLIMITED_SIGN_SPEED;

        if (str.endsWith(":rural") || str.endsWith(":trunk"))
            return 80;

        if (str.endsWith(":urban"))
            return 50;

        if (str.equals("walk") || str.endsWith(":living_street"))
            return 6;

        try {
            int val;
            // see https://en.wikipedia.org/wiki/Knot_%28unit%29#Definitions
            int mpInteger = str.indexOf("mp");
            if (mpInteger > 0) {
                str = str.substring(0, mpInteger).trim();
                val = Integer.parseInt(str);
                return val * DistanceCalcEarth.KM_MILE;
            }

            int knotInteger = str.indexOf("knots");
            if (knotInteger > 0) {
                str = str.substring(0, knotInteger).trim();
                val = Integer.parseInt(str);
                return val * 1.852;
            }

            int kmInteger = str.indexOf("km");
            if (kmInteger > 0) {
                str = str.substring(0, kmInteger).trim();
            } else {
                kmInteger = str.indexOf("kph");
                if (kmInteger > 0) {
                    str = str.substring(0, kmInteger).trim();
                }
            }

            return Integer.parseInt(str);
        } catch (Exception ex) {
            return -1;
        }
    }

    void setRelBitMask(int usedBits, int shift) {
        relBitMask = (1L << usedBits) - 1;
        relBitMask <<= shift;
    }

    long getRelBitMask() {
        return relBitMask;
    }

    void setNodeBitMask(int usedBits, int shift) {
        nodeBitMask = (1L << usedBits) - 1;
        nodeBitMask <<= shift;
    }

    long getNodeBitMask() {
        return nodeBitMask;
    }

    /**
     * Defines the bits reserved for storing turn restriction and turn cost
     * <p>
     *
     * @param shift bit offset for the first bit used by this encoder
     * @return incremented shift value pointing behind the last used bit
     */
    public int defineTurnBits(int index, int shift) {
        if (maxTurnCosts == 0)
            return shift;

            // optimization for turn restrictions only
        else if (maxTurnCosts == 1) {
            turnRestrictionBit = 1L << shift;
            return shift + 1;
        }

        int turnBits = Helper.countBitValue(maxTurnCosts);
        turnCostEncoder = new EncodedValueOld("TurnCost", shift, turnBits, 1, 0, maxTurnCosts) {
            // override to avoid expensive Math.round
            @Override
            public final long getValue(long flags) {
                // find value
                flags &= mask;
                flags >>>= shift;
                return flags;
            }
        };
        return shift + turnBits;
    }

    @Override
    public boolean isTurnRestricted(long flags) {
        if (maxTurnCosts == 0)
            return false;

        else if (maxTurnCosts == 1)
            return (flags & turnRestrictionBit) != 0;

        return turnCostEncoder.getValue(flags) == maxTurnCosts;
    }

    @Override
    public double getTurnCost(long flags) {
        if (maxTurnCosts == 0)
            return 0;

        else if (maxTurnCosts == 1)
            return ((flags & turnRestrictionBit) == 0) ? 0 : Double.POSITIVE_INFINITY;

        long cost = turnCostEncoder.getValue(flags);
        if (cost == maxTurnCosts)
            return Double.POSITIVE_INFINITY;

        return cost;
    }

    @Override
    public long getTurnFlags(boolean restricted, double costs) {
        if (maxTurnCosts == 0)
            return 0;

        else if (maxTurnCosts == 1) {
            if (costs != 0)
                throw new IllegalArgumentException("Only restrictions are supported");

            return restricted ? turnRestrictionBit : 0;
        }

        if (restricted) {
            if (costs != 0 || Double.isInfinite(costs))
                throw new IllegalArgumentException("Restricted turn can only have infinite costs (or use 0)");
        } else if (costs >= maxTurnCosts)
            throw new IllegalArgumentException("Cost is too high. Or specify restricted == true");

        if (costs < 0)
            throw new IllegalArgumentException("Turn costs cannot be negative");

        if (costs >= maxTurnCosts || restricted)
            costs = maxTurnCosts;
        return turnCostEncoder.setValue(0L, (int) costs);
    }

    public final DecimalEncodedValue getAverageSpeedEnc() {
        if (speedEncoder == null)
            throw new NullPointerException("FlagEncoder " + toString() + " not yet initialized");
        return speedEncoder;
    }

    public final BooleanEncodedValue getAccessEnc() {
        if (accessEnc == null)
            throw new NullPointerException("FlagEncoder " + toString() + " not yet initialized");
        return accessEnc;
    }

    /**
     * Most use cases do not require this method. Will still keep it accessible so that one can disable it
     * until the averageSpeedEncodedValue is moved out of the FlagEncoder.
     *
     * @Deprecated
     */
    protected void setSpeed(boolean reverse, IntsRef edgeFlags, double speed) {
        if (speed < 0 || Double.isNaN(speed))
            throw new IllegalArgumentException("Speed cannot be negative or NaN: " + speed + ", flags:" + BitUtil.LITTLE.toBitString(edgeFlags));

        if (speed < speedFactor / 2) {
            speedEncoder.setDecimal(reverse, edgeFlags, 0);
            accessEnc.setBool(reverse, edgeFlags, false);
            return;
        }

        if (speed > getMaxSpeed())
            speed = getMaxSpeed();

        speedEncoder.setDecimal(reverse, edgeFlags, speed);
    }

    double getSpeed(IntsRef edgeFlags) {
        return getSpeed(false, edgeFlags);
    }

    double getSpeed(boolean reverse, IntsRef edgeFlags) {
        double speedVal = speedEncoder.getDecimal(reverse, edgeFlags);
        if (speedVal < 0)
            throw new IllegalStateException("Speed was negative!? " + speedVal);

        return speedVal;
    }

    protected String getPropertiesString() {
        return "speed_factor=" + speedFactor + "|speed_bits=" + speedBits + "|turn_costs=" + (maxTurnCosts > 0);
    }

    @Override
    public <T extends EncodedValue> T getEncodedValue(String key, Class<T> encodedValueType) {
        return encodedValueLookup.getEncodedValue(key, encodedValueType);
    }

    @Override
    public BooleanEncodedValue getBooleanEncodedValue(String key) {
        return encodedValueLookup.getBooleanEncodedValue(key);
    }

    @Override
    public IntEncodedValue getIntEncodedValue(String key) {
        return encodedValueLookup.getIntEncodedValue(key);
    }

    @Override
    public DecimalEncodedValue getDecimalEncodedValue(String key) {
        return encodedValueLookup.getDecimalEncodedValue(key);
    }

    @Override
    public <T extends Enum> EnumEncodedValue<T> getEnumEncodedValue(String key, Class<T> enumType) {
        return encodedValueLookup.getEnumEncodedValue(key, enumType);
    }

    public void setEncodedValueLookup(EncodedValueLookup encodedValueLookup) {
        this.encodedValueLookup = encodedValueLookup;
    }

    @Override
    public boolean supports(Class<?> feature) {
        if (TurnWeighting.class.isAssignableFrom(feature))
            return maxTurnCosts > 0;

        return false;
    }

    @Override
    public boolean hasEncodedValue(String key) {
        return encodedValueLookup.hasEncodedValue(key);
    }
}
