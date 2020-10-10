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

import com.graphhopper.util.shapes.BBox;

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.MappedByteBuffer;
import java.nio.charset.Charset;
import java.text.DateFormat;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.Map.Entry;

/**
 * @author Peter Karich
 */
public class Helper {
    public static final DistanceCalc DIST_EARTH = new DistanceCalcEarth();
    public static final DistanceCalc3D DIST_3D = new DistanceCalc3D();
    public static final DistancePlaneProjection DIST_PLANE = new DistancePlaneProjection();
    public static final AngleCalc ANGLE_CALC = new AngleCalc();
    public static final Charset UTF_CS = Charset.forName("UTF-8");
    public static final TimeZone UTC = TimeZone.getTimeZone("UTC");
    public static final long MB = 1L << 20;
    // +- 180 and +-90 => let use use 400
    private static final float DEGREE_FACTOR = Integer.MAX_VALUE / 400f;
    // milli meter is a bit extreme but we have integers
    private static final float ELE_FACTOR = 1000f;

    private Helper() {
    }

    public static String toLowerCase(String string) {
        return string.toLowerCase(Locale.ROOT);
    }

    public static String toUpperCase(String string) {
        return string.toUpperCase(Locale.ROOT);
    }

    static String packageToPath(Package pkg) {
        return pkg.getName().replaceAll("\\.", File.separator);
    }

    public static int countBitValue(int maxTurnCosts) {
        if (maxTurnCosts < 0)
            throw new IllegalArgumentException("maxTurnCosts cannot be negative " + maxTurnCosts);

        int counter = 0;
        while (maxTurnCosts > 0) {
            maxTurnCosts >>= 1;
            counter++;
        }
        return counter++;
    }

    public static List<String> readFile(String file) throws IOException {
        return readFile(new InputStreamReader(new FileInputStream(file), UTF_CS));
    }

    public static List<String> readFile(Reader simpleReader) throws IOException {
        BufferedReader reader = new BufferedReader(simpleReader);
        try {
            List<String> res = new ArrayList<>();
            String line;
            while ((line = reader.readLine()) != null) {
                res.add(line);
            }
            return res;
        } finally {
            reader.close();
        }
    }

    public static int idealIntArraySize(int need) {
        return idealByteArraySize(need * 4) / 4;
    }

    public static int idealByteArraySize(int need) {
        for (int i = 4; i < 32; i++) {
            if (need <= (1 << i) - 12) {
                return (1 << i) - 12;
            }
        }
        return need;
    }

    public static boolean removeDir(File file) {
        if (!file.exists()) {
            return true;
        }

        if (file.isDirectory()) {
            for (File f : file.listFiles()) {
                removeDir(f);
            }
        }

        return file.delete();
    }

    public static long getTotalMB() {
        return Runtime.getRuntime().totalMemory() / MB;
    }

    public static long getUsedMB() {
        return (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()) / MB;
    }

    public static String getMemInfo() {
        return "totalMB:" + getTotalMB() + ", usedMB:" + getUsedMB();
    }

    public static int getSizeOfObjectRef(int factor) {
        // pointer to class, flags, lock
        return factor * (4 + 4 + 4);
    }

    public static int getSizeOfLongArray(int length, int factor) {
        // pointer to class, flags, lock, size
        return factor * (4 + 4 + 4 + 4) + 8 * length;
    }

    public static int getSizeOfObjectArray(int length, int factor) {
        // improvements: add 4byte to make a multiple of 8 in some cases plus compressed oop
        return factor * (4 + 4 + 4 + 4) + 4 * length;
    }

    public static void close(Closeable cl) {
        try {
            if (cl != null)
                cl.close();
        } catch (IOException ex) {
            throw new RuntimeException("Couldn't close resource", ex);
        }
    }

    public static boolean isEmpty(String str) {
        return str == null || str.trim().length() == 0;
    }

    /**
     * Determines if the specified ByteBuffer is one which maps to a file!
     */
    public static boolean isFileMapped(ByteBuffer bb) {
        if (bb instanceof MappedByteBuffer) {
            try {
                ((MappedByteBuffer) bb).isLoaded();
                return true;
            } catch (UnsupportedOperationException ex) {
            }
        }
        return false;
    }

    public static String pruneFileEnd(String file) {
        int index = file.lastIndexOf(".");
        if (index < 0)
            return file;
        return file.substring(0, index);
    }

    public static List<Double> createDoubleList(double[] values) {
        List<Double> list = new ArrayList<>();
        for (double v : values) {
            list.add(v);
        }
        return list;
    }

    /**
     * Converts into an integer to be compatible with the still limited DataAccess class (accepts
     * only integer values). But this conversion also reduces memory consumption where the precision
     * loss is acceptable. As +- 180° and +-90° are assumed as maximum values.
     * <p>
     *
     * @return the integer of the specified degree
     */
    public static final int degreeToInt(double deg) {
        if (deg >= Double.MAX_VALUE)
            return Integer.MAX_VALUE;
        if (deg <= -Double.MAX_VALUE)
            return -Integer.MAX_VALUE;
        return (int) (deg * DEGREE_FACTOR);
    }

    /**
     * Converts back the integer value.
     * <p>
     *
     * @return the degree value of the specified integer
     */
    public static final double intToDegree(int storedInt) {
        if (storedInt == Integer.MAX_VALUE)
            return Double.MAX_VALUE;
        if (storedInt == -Integer.MAX_VALUE)
            return -Double.MAX_VALUE;
        return (double) storedInt / DEGREE_FACTOR;
    }

    /**
     * Converts elevation value (in meters) into integer for storage.
     */
    public static final int eleToInt(double ele) {
        if (ele >= Integer.MAX_VALUE)
            return Integer.MAX_VALUE;
        return (int) (ele * ELE_FACTOR);
    }

    /**
     * Converts the integer value retrieved from storage into elevation (in meters). Do not expect
     * more precision than meters although it currently is!
     */
    public static final double intToEle(int integEle) {
        if (integEle == Integer.MAX_VALUE)
            return Double.MAX_VALUE;
        return integEle / ELE_FACTOR;
    }

    public static String nf(long no) {
        // I like french localization the most: 123654 will be 123 654 instead
        // of comma vs. point confusion for English/German people.
        // NumberFormat is not thread safe => but getInstance looks like it's cached
        return NumberFormat.getInstance(Locale.FRANCE).format(no);
    }

    public static String firstBig(String sayText) {
        if (sayText == null || sayText.length() <= 0) {
            return sayText;
        }

        return Character.toUpperCase(sayText.charAt(0)) + sayText.substring(1);
    }

    /**
     * Round the value to the specified exponent
     */
    public static double round(double value, int exponent) {
        double factor = Math.pow(10, exponent);
        return Math.round(value * factor) / factor;
    }

    public static final double round6(double value) {
        return Math.round(value * 1e6) / 1e6;
    }

    public static final double round4(double value) {
        return Math.round(value * 1e4) / 1e4;
    }

    public static final double round2(double value) {
        return Math.round(value * 100) / 100d;
    }

    /**
     * This method handles the specified (potentially negative) int as unsigned bit representation
     * and returns the positive converted long.
     */
    public static final long toUnsignedLong(int x) {
        return ((long) x) & 0xFFFFffffL;
    }

    /**
     * Converts the specified long back into a signed int (reverse method for toUnsignedLong)
     */
    public static final int toSignedInt(long x) {
        return (int) x;
    }

    public static final String camelCaseToUnderScore(String key) {
        if (key.isEmpty())
            return key;

        StringBuilder sb = new StringBuilder(key.length());
        for (int i = 0; i < key.length(); i++) {
            char c = key.charAt(i);
            if (Character.isUpperCase(c))
                sb.append("_").append(Character.toLowerCase(c));
            else
                sb.append(c);
        }

        return sb.toString();
    }
}
