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
import com.graphhopper.storage.Directory;
import com.graphhopper.storage.IntsRef;
import com.graphhopper.util.EdgeIteratorState;
import com.graphhopper.util.Helper;
import com.graphhopper.util.PMap;

import java.util.*;

import static com.graphhopper.util.Helper.toLowerCase;

/**
 * Manager class to register encoder, assign their flag values and check objects with all encoders
 * during parsing. Create one via:
 * <p>
 * EncodingManager.start(4).add(new CarFlagEncoder()).build();
 *
 * @author Peter Karich
 * @author Nop
 */
public class EncodingManager implements EncodedValueLookup {
    private static final String ERR = "Encoders are requesting %s bits, more than %s bits of %s flags. ";
    private final List<AbstractFlagEncoder> edgeEncoders = new ArrayList<>();
    private final Map<String, EncodedValue> encodedValueMap = new LinkedHashMap<>();
    private final int bitsForEdgeFlags;
    private final int bitsForTurnFlags = 8 * 4;
    private int nextNodeBit = 0;
    private int nextRelBit = 0;
    private int nextTurnBit = 0;
    private EncodedValue.InitializerConfig config;

    /**
     * Starts the build process of an EncodingManager
     */
    public static Builder start() {
        return new Builder(4);
    }

    private EncodingManager(int bytes) {
        if (bytes <= 0 || (bytes / 4) * 4 != bytes)
            throw new IllegalStateException("bytesForEdgeFlags can be only a multiple of 4");

        this.bitsForEdgeFlags = bytes * 8;
        this.config = new EncodedValue.InitializerConfig();
    }

    public static class Builder {
        private EncodingManager em;

        public Builder(int bytes) {
            em = new EncodingManager(bytes);
        }

        /**
         * For backward compatibility provide a way to add multiple FlagEncoders
         */
        public Builder addAll(FlagEncoderFactory factory, String flagEncodersStr) {
            for (FlagEncoder fe : parseEncoderString(factory, flagEncodersStr)) {
                add(fe);
            }
            return this;
        }

        public Builder addAll(EncodedValueFactory factory, String encodedValueString) {
            em.add(this, factory, encodedValueString);
            return this;
        }

        public Builder add(FlagEncoder encoder) {
            check();
            em.addEncoder((AbstractFlagEncoder) encoder);
            return this;
        }

        public Builder add(EncodedValue encodedValue) {
            check();
            if (!em.edgeEncoders.isEmpty())
                throw new IllegalArgumentException("Always add shared EncodedValues before FlagEncoders to ensure they can be loaded first");

            em.addEncodedValue(encodedValue, false);
            return this;
        }

        private void check() {
            if (em == null)
                throw new IllegalStateException("Cannot call method after Builder.build() was called");
        }

        public EncodingManager build() {
            check();
            if (em.encodedValueMap.isEmpty())
                throw new IllegalStateException("No EncodedValues found");

            EncodingManager tmp = em;
            em = null;
            return tmp;
        }
    }

    static List<FlagEncoder> parseEncoderString(FlagEncoderFactory factory, String encoderList) {
        String[] entries = encoderList.split(",");
        List<FlagEncoder> resultEncoders = new ArrayList<>();

        for (String entry : entries) {
            entry = toLowerCase(entry.trim());
            if (entry.isEmpty())
                continue;

            String entryVal = "";
            if (entry.contains("|")) {
                entryVal = entry;
                entry = entry.split("\\|")[0];
            }
            PMap configuration = new PMap(entryVal);
            resultEncoders.add(factory.createFlagEncoder(entry, configuration));
        }
        return resultEncoders;
    }

    private void add(Builder builder, EncodedValueFactory factory, String evList) {
        if (!evList.equals(toLowerCase(evList)))
            throw new IllegalArgumentException("Use lower case for EncodedValues: " + evList);

        for (String entry : evList.split(",")) {
            entry = toLowerCase(entry.trim());
            if (entry.isEmpty())
                continue;

            EncodedValue evObject = factory.create(entry);
            builder.add(evObject);
            PMap map = new PMap(entry);
            if (!map.has("version"))
                throw new IllegalArgumentException("encoded value must have a version specified but it was " + entry);
        }
    }

    public int getBytesForFlags() {
        return bitsForEdgeFlags / 8;
    }

    private void addEncoder(AbstractFlagEncoder encoder) {
        if (encoder.isRegistered())
            throw new IllegalStateException("You must not register a FlagEncoder (" + encoder.toString() + ") twice!");

        for (FlagEncoder fe : edgeEncoders) {
            if (fe.toString().equals(encoder.toString()))
                throw new IllegalArgumentException("Cannot register edge encoder. Name already exists: " + fe.toString());
        }

        encoder.setRegistered(true);

        int encoderCount = edgeEncoders.size();
        int usedBits = encoder.defineNodeBits(encoderCount, nextNodeBit);
        if (usedBits > bitsForEdgeFlags)
            throw new IllegalArgumentException(String.format(Locale.ROOT, ERR, usedBits, bitsForEdgeFlags, "node"));
        encoder.setNodeBitMask(usedBits - nextNodeBit, nextNodeBit);
        nextNodeBit = usedBits;

        encoder.setEncodedValueLookup(this);
        List<EncodedValue> list = new ArrayList<>();
        encoder.createEncodedValues(list, encoder.toString(), encoderCount);
        for (EncodedValue ev : list) {
            addEncodedValue(ev, true);
        }

        usedBits = encoder.defineRelationBits(encoderCount, nextRelBit);
        if (usedBits > bitsForEdgeFlags)
            throw new IllegalArgumentException(String.format(Locale.ROOT, ERR, usedBits, bitsForEdgeFlags, "relation"));
        encoder.setRelBitMask(usedBits - nextRelBit, nextRelBit);
        nextRelBit = usedBits;

        // turn flag bits are independent from edge encoder bits
        usedBits = encoder.defineTurnBits(encoderCount, nextTurnBit);
        if (usedBits > bitsForTurnFlags)
            throw new IllegalArgumentException(String.format(Locale.ROOT, ERR, usedBits, bitsForTurnFlags, "turn"));
        nextTurnBit = usedBits;

        edgeEncoders.add(encoder);
    }

    private void addEncodedValue(EncodedValue ev, boolean encValBoundToFlagEncoder) {
        if (encodedValueMap.containsKey(ev.getName()))
            throw new IllegalStateException("EncodedValue " + ev.getName() + " already exists " + encodedValueMap.get(ev.getName()) + " vs " + ev);
        if (!encValBoundToFlagEncoder && ev.getName().contains(SPECIAL_SEPARATOR))
            throw new IllegalArgumentException("EncodedValue " + ev.getName() + " must not contain '" + SPECIAL_SEPARATOR + "' as reserved for FlagEncoder");

        ev.init(config);
        if (config.getRequiredBits() > getBytesForFlags() * 8)
            throw new IllegalArgumentException(String.format(Locale.ROOT, ERR + "(Attempt to add EncodedValue " + ev.getName() + ") ",
                    config.getRequiredBits(), bitsForEdgeFlags, "edge") +
                    "Decrease the number of vehicles or increase the flags to more bytes via graph.bytes_for_flags: " + (config.getRequiredBits() / 32 * 4 + 4));

        encodedValueMap.put(ev.getName(), ev);
    }

    public boolean hasEncodedValue(String key) {
        return encodedValueMap.get(key) != null;
    }

    public FlagEncoder getEncoder(String name) {
        return getEncoder(name, true);
    }

    private FlagEncoder getEncoder(String name, boolean throwExc) {
        for (FlagEncoder encoder : edgeEncoders) {
            if (name.equalsIgnoreCase(encoder.toString()))
                return encoder;
        }
        if (throwExc)
            throw new IllegalArgumentException("Encoder for " + name + " not found. Existing: ");
        return null;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        EncodingManager that = (EncodingManager) o;
        return bitsForEdgeFlags == that.bitsForEdgeFlags &&
                edgeEncoders.equals(that.edgeEncoders) &&
                encodedValueMap.equals(that.encodedValueMap);
    }

    @Override
    public int hashCode() {
        return Objects.hash(edgeEncoders, encodedValueMap, bitsForEdgeFlags);
    }

    @Override
    public BooleanEncodedValue getBooleanEncodedValue(String key) {
        return getEncodedValue(key, BooleanEncodedValue.class);
    }

    @Override
    public IntEncodedValue getIntEncodedValue(String key) {
        return getEncodedValue(key, IntEncodedValue.class);
    }

    @Override
    public DecimalEncodedValue getDecimalEncodedValue(String key) {
        return getEncodedValue(key, DecimalEncodedValue.class);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T extends Enum> EnumEncodedValue<T> getEnumEncodedValue(String key, Class<T> type) {
        return (EnumEncodedValue<T>) getEncodedValue(key, EnumEncodedValue.class);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T extends EncodedValue> T getEncodedValue(String key, Class<T> encodedValueType) {
        EncodedValue ev = encodedValueMap.get(key);
        if (ev == null)
            throw new IllegalArgumentException("Cannot find EncodedValue " + key + " in collection: " + ev);
        return (T) ev;
    }

    private static String SPECIAL_SEPARATOR = "-";

    /**
     * All EncodedValue names that are created from a FlagEncoder should use this method to mark them as
     * "none-shared" across the other FlagEncoders. E.g. average_speed for the CarFlagEncoder will
     * be named car-average_speed
     */
    public static String getKey(FlagEncoder encoder, String str) {
        return getKey(encoder.toString(), str);
    }

    public static String getKey(String prefix, String str) {
        return prefix + SPECIAL_SEPARATOR + str;
    }
}